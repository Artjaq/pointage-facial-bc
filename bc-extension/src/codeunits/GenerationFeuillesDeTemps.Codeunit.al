// Codeunit 50120 : agrégation des pointages vers feuilles de temps BC natives.
// Appelé par Job Queue Entry (Object Type = Codeunit, Object ID = 50120).
// Objets feuilles de temps standard utilisés (à confirmer avec symboles téléchargés) :
//   Table 950 "Time Sheet Header", Table 951 "Time Sheet Line", Table 952 "Time Sheet Detail"
//   Codeunit 950 "Time Sheet Management"
codeunit 50120 "PRF Gen. Feuilles de Temps"
{
    trigger OnRun()
    begin
        RunAggregation();
    end;

    // Point d'entrée public — peut être appelé directement ou via Job Queue.
    procedure RunAggregation()
    var
        NbPointagesTraites: Integer;
        NbFeuillesModifiees: Integer;
        NbAvertissements: Integer;
        ResultMsg: Text;
    begin
        NbPointagesTraites := 0;
        NbFeuillesModifiees := 0;
        NbAvertissements := 0;

        TraiterPointagesParRessourceEtJour(NbPointagesTraites, NbFeuillesModifiees, NbAvertissements);

        ResultMsg := StrSubstNo(
            'Traitement terminé.\Pointages traités : %1\Feuilles créées/mises à jour : %2\Avertissements : %3',
            NbPointagesTraites, NbFeuillesModifiees, NbAvertissements);
        Message(ResultMsg);
    end;

    // Parcourt tous les pointages Validé + non Traité, groupés par ressource et par jour.
    local procedure TraiterPointagesParRessourceEtJour(var NbPointages: Integer; var NbFeuilles: Integer; var NbAvert: Integer)
    var
        Pointage: Record "PRF Pointage Reconnaissance";
        CurrResourceCode: Code[20];
        CurrDate: Date;
        EntreeDateTime: DateTime;
        HasOpenEntry: Boolean;
        DayHours: Decimal;
        TSHeaderNo: Code[20];
    begin
        // RG-14 : seuls les pointages Validé et non Traité sont traités
        Pointage.SetRange("Statut", Pointage."Statut"::Valide);
        Pointage.SetRange("Traite", false);
        Pointage.SetCurrentKey("Code Ressource", "Date-Heure");

        if not Pointage.FindSet(true) then
            exit;

        CurrResourceCode := '';
        CurrDate := 0D;
        HasOpenEntry := false;
        EntreeDateTime := 0DT;
        DayHours := 0;

        repeat
            // Changement de ressource ou de journée → flush du groupe précédent
            if (Pointage."Code Ressource" <> CurrResourceCode) or (DT2Date(Pointage."Date-Heure") <> CurrDate) then begin
                if CurrResourceCode <> '' then begin
                    // Paire incomplète en fin de journée précédente (RG : ne pas comptabiliser)
                    if HasOpenEntry then begin
                        LogWarning(StrSubstNo('Entrée sans Sortie : ressource %1 le %2 — non comptabilisé.',
                            CurrResourceCode, CurrDate));
                        NbAvert += 1;
                        HasOpenEntry := false;
                    end;
                    // Écriture vers feuille de temps si heures > 0
                    if DayHours > 0 then begin
                        TSHeaderNo := EcrireVersFeuilleTemps(CurrResourceCode, CurrDate, DayHours, NbFeuilles, NbAvert);
                        if TSHeaderNo <> '' then
                            MarquerPointagesTraites(CurrResourceCode, CurrDate, TSHeaderNo, NbPointages);
                    end;
                    DayHours := 0;
                end;
                CurrResourceCode := Pointage."Code Ressource";
                CurrDate := DT2Date(Pointage."Date-Heure");
                HasOpenEntry := false;
                EntreeDateTime := 0DT;
                DayHours := 0;
            end;

            // Appariement séquentiel Entrée → Sortie
            if Pointage."Type" = Pointage."Type"::Entree then begin
                if HasOpenEntry then begin
                    // Double Entrée consécutive : la première est abandonnée
                    LogWarning(StrSubstNo('Double Entrée consécutive ignorée : ressource %1 à %2.',
                        Pointage."Code Ressource", Pointage."Date-Heure"));
                    NbAvert += 1;
                end;
                EntreeDateTime := Pointage."Date-Heure";
                HasOpenEntry := true;
            end else begin
                // Sortie
                if HasOpenEntry then begin
                    DayHours += CalcDiffHeures(EntreeDateTime, Pointage."Date-Heure");
                    HasOpenEntry := false;
                    EntreeDateTime := 0DT;
                end else begin
                    // Sortie sans Entrée précédente
                    LogWarning(StrSubstNo('Sortie sans Entrée préalable ignorée : ressource %1 à %2.',
                        Pointage."Code Ressource", Pointage."Date-Heure"));
                    NbAvert += 1;
                end;
            end;
        until Pointage.Next() = 0;

        // Flush du dernier groupe
        if CurrResourceCode <> '' then begin
            if HasOpenEntry then begin
                LogWarning(StrSubstNo('Entrée sans Sortie : ressource %1 le %2 — non comptabilisé.',
                    CurrResourceCode, CurrDate));
                NbAvert += 1;
            end;
            if DayHours > 0 then begin
                TSHeaderNo := EcrireVersFeuilleTemps(CurrResourceCode, CurrDate, DayHours, NbFeuilles, NbAvert);
                if TSHeaderNo <> '' then
                    MarquerPointagesTraites(CurrResourceCode, CurrDate, TSHeaderNo, NbPointages);
            end;
        end;
    end;

    // Cherche ou crée l'en-tête de feuille de temps et écrit le détail du jour.
    // Retourne le No. de l'en-tête ou '' en cas d'erreur.
    local procedure EcrireVersFeuilleTemps(ResourceCode: Code[20]; WorkDate: Date; Hours: Decimal; var NbFeuilles: Integer; var NbAvert: Integer): Code[20]
    var
        TSHeader: Record "Time Sheet Header"; // TODO confirmer avec symboles (Table 950)
        TSLine: Record "Time Sheet Line";    // TODO confirmer avec symboles (Table 951)
        SheetStartDate: Date;
        CreatedHeader: Boolean;
        LineNo: Integer;
    begin
        // RG-11 : Code Ressource obligatoire (déjà garanti par la table source, sécurité defensive)
        if ResourceCode = '' then begin
            LogWarning('Ressource vide — pointage ignoré.');
            NbAvert += 1;
            exit('');
        end;

        SheetStartDate := GetWeekStartDate(WorkDate);

        if not FindOrCreateTSHeader(ResourceCode, SheetStartDate, TSHeader, CreatedHeader) then begin
            LogWarning(StrSubstNo('Impossible de trouver/créer la feuille de temps : ressource %1, semaine %2.',
                ResourceCode, SheetStartDate));
            NbAvert += 1;
            exit('');
        end;

        if CreatedHeader then
            NbFeuilles += 1;

        // RG-15 : ne pas écrire sur une feuille déjà approuvée
        // TODO confirmer avec symboles le champ Status et ses valeurs enum/option
        // if TSHeader.Status = TSHeader.Status::Approved then begin
        //     LogWarning(StrSubstNo('Feuille approuvée ignorée : %1 ressource %2.', TSHeader."No.", ResourceCode));
        //     NbAvert += 1;
        //     exit(TSHeader."No.");
        // end;

        if not FindOrCreateTSLine(TSHeader, TSLine, LineNo) then begin
            LogWarning(StrSubstNo('Impossible de créer/trouver ligne feuille de temps : %1.', TSHeader."No."));
            NbAvert += 1;
            exit('');
        end;

        // RG-13 : idempotence — UpsertTSDetail remplace, n'additionne pas
        UpsertTSDetail(TSHeader."No.", LineNo, WorkDate, Hours);

        exit(TSHeader."No.");
    end;

    // Cherche un en-tête pour la ressource/semaine ou en crée un.
    // TODO confirmer avec symboles les champs et le comportement de l'OnInsert de Time Sheet Header.
    local procedure FindOrCreateTSHeader(ResourceCode: Code[20]; StartDate: Date; var TSHeader: Record "Time Sheet Header"; var Created: Boolean): Boolean
    begin
        Created := false;

        TSHeader.SetRange("Resource No.", ResourceCode); // TODO confirmer avec symboles le nom de champ
        TSHeader.SetRange("Starting Date", StartDate);   // TODO confirmer avec symboles
        if TSHeader.FindFirst() then
            exit(true);

        // Création directe — privilégier Time Sheet Management si une procédure existe.
        // TODO confirmer avec symboles : Codeunit "Time Sheet Management" (950) a-t-il CreateTimeSheet() ?
        TSHeader.Init();
        TSHeader.Validate("Resource No.", ResourceCode); // TODO confirmer avec symboles
        TSHeader.Validate("Starting Date", StartDate);   // TODO confirmer avec symboles
        TSHeader."Ending Date" := StartDate + 6;         // TODO confirmer avec symboles - période 7 jours
        // TSHeader."Owner User ID" := CopyStr(UserId(), 1, MaxStrLen(TSHeader."Owner User ID")); // TODO si obligatoire
        if not TSHeader.Insert(true) then // TODO confirmer - peut nécessiter champs additionnels
            exit(false);

        Created := true;
        exit(true);
    end;

    // Cherche une ligne de type Ressource dans la feuille ou en crée une.
    // TODO confirmer avec symboles : nom du champ Type, valeur option/enum Resource.
    local procedure FindOrCreateTSLine(TSHeader: Record "Time Sheet Header"; var TSLine: Record "Time Sheet Line"; var LineNo: Integer): Boolean
    begin
        TSLine.SetRange("Time Sheet No.", TSHeader."No."); // TODO confirmer avec symboles
        // TODO confirmer avec symboles : TSLine.SetRange(Type, TSLine.Type::Resource);
        // En attendant, chercher la première ligne existante sans filtre Type
        if TSLine.FindFirst() then begin
            // RG-15 : ligne approuvée → sauter
            // TODO confirmer avec symboles le champ Status et ses valeurs
            // if TSLine.Status = TSLine.Status::Approved then
            //     exit(false);
            LineNo := TSLine."Line No."; // TODO confirmer avec symboles
            exit(true);
        end;

        // Calcul du prochain LineNo (incréments de 10 000, convention BC)
        TSLine.SetRange("Time Sheet No.", TSHeader."No.");
        if TSLine.FindLast() then
            LineNo := TSLine."Line No." + 10000
        else
            LineNo := 10000;

        TSLine.Init();
        TSLine."Time Sheet No." := TSHeader."No.";  // TODO confirmer avec symboles
        TSLine."Line No." := LineNo;                // TODO confirmer avec symboles
        // TSLine.Type := TSLine.Type::Resource;    // TODO confirmer avec symboles - Type option/enum
        TSLine.Description := 'Présence';           // TODO confirmer avec symboles si champ libre
        if not TSLine.Insert(true) then             // TODO confirmer - peut nécessiter champs additionnels
            exit(false);

        exit(true);
    end;

    // Écrit ou met à jour le détail de feuille pour un jour donné (idempotence : REPLACE, pas cumul).
    // TODO confirmer avec symboles les noms de champs de Time Sheet Detail (Table 952).
    local procedure UpsertTSDetail(TSHeaderNo: Code[20]; LineNo: Integer; WorkDate: Date; Hours: Decimal)
    var
        TSDetail: Record "Time Sheet Detail"; // TODO confirmer avec symboles (Table 952)
    begin
        TSDetail.SetRange("Time Sheet No.", TSHeaderNo);      // TODO confirmer avec symboles
        TSDetail.SetRange("Time Sheet Line No.", LineNo);     // TODO confirmer avec symboles
        TSDetail.SetRange(Date, WorkDate);                    // TODO confirmer avec symboles

        if TSDetail.FindFirst() then begin
            // RG-15 : détail approuvé → ne pas modifier
            // TODO confirmer avec symboles le champ Status
            // if TSDetail.Status = TSDetail.Status::Approved then
            //     exit;
            TSDetail.Quantity := Hours; // TODO confirmer avec symboles - "Quantity" ou "Posted Quantity"
            TSDetail.Modify(true);
        end else begin
            TSDetail.Init();
            TSDetail."Time Sheet No." := TSHeaderNo;      // TODO confirmer avec symboles
            TSDetail."Time Sheet Line No." := LineNo;     // TODO confirmer avec symboles
            TSDetail.Date := WorkDate;                    // TODO confirmer avec symboles
            TSDetail.Quantity := Hours;                   // TODO confirmer avec symboles
            TSDetail.Insert(true);                        // TODO confirmer
        end;
    end;

    // Marque tous les pointages de la ressource/journée comme Traité et renseigne l'en-tête.
    // RG-13 : idempotence garantie par le filtre Traite = false.
    local procedure MarquerPointagesTraites(ResourceCode: Code[20]; WorkDate: Date; TSHeaderNo: Code[20]; var NbPointages: Integer)
    var
        Pointage: Record "PRF Pointage Reconnaissance";
        DateDebutJour: DateTime;
        DateFinJour: DateTime;
    begin
        DateDebutJour := CreateDateTime(WorkDate, 000000T);
        DateFinJour := CreateDateTime(WorkDate, 235959.999T);

        Pointage.SetRange("Code Ressource", ResourceCode);
        Pointage.SetRange("Statut", Pointage."Statut"::Valide);
        Pointage.SetRange("Traite", false);
        Pointage.SetFilter("Date-Heure", '>=%1&<=%2', DateDebutJour, DateFinJour);

        if Pointage.FindSet(true) then
            repeat
                Pointage."Traite" := true;
                Pointage."No. Feuille Temps" := TSHeaderNo;
                Pointage."Date Traitement" := CurrentDateTime();
                Pointage.Modify(false); // Pas de validation complète pour performance
                NbPointages += 1;
            until Pointage.Next() = 0;
    end;

    // Retourne le premier jour de la semaine (Lundi) pour la date donnée.
    // TODO confirmer avec symboles : lire le premier jour configuré dans Resources Setup
    // (champ "Time Sheet First Weekday" ou équivalent) plutôt que forcer Lundi.
    local procedure GetWeekStartDate(WorkDate: Date): Date
    var
        DayOfWeek: Integer;
    begin
        // Date2DWY(Date, 1) : jour de la semaine, 1=Lundi … 7=Dimanche (norme ISO en BC)
        DayOfWeek := Date2DWY(WorkDate, 1);
        exit(WorkDate - (DayOfWeek - 1));
    end;

    // Calcule la différence en heures entre deux DateTime.
    // Time - Time retourne un Integer en millisecondes en AL.
    local procedure CalcDiffHeures(EntreeTime: DateTime; SortieTime: DateTime): Decimal
    var
        DateDiffJours: Integer;
        TimeDiffMs: Integer;
    begin
        DateDiffJours := DT2Date(SortieTime) - DT2Date(EntreeTime);
        TimeDiffMs := DT2Time(SortieTime) - DT2Time(EntreeTime); // millisecondes
        exit((DateDiffJours * 86400000 + TimeDiffMs) / 3600000);
    end;

    // Journalise un avertissement non-bloquant.
    // TODO : remplacer par Error Log (Table 1400 "Error Log") ou Activity Log si disponible.
    local procedure LogWarning(Msg: Text)
    begin
        // Pour l'instant, les avertissements sont comptés et affichés dans le message final.
        // Activation possible d'un journal BC via Error Message ou Activity Log.
        // Exemple : activer avec CODEUNIT.RUN pour capture dans Job Queue Log Entry.
        Message(Msg); // Remplacer par une vraie journalisation en production
    end;
}
