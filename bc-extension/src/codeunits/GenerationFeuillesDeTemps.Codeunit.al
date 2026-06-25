// Codeunit 50120 : agrégation des pointages vers feuilles de temps BC natives.
// Appelé par Job Queue Entry (Object Type = Codeunit, Object ID = 50120).
// Objets feuilles de temps standard utilisés :
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
        if CurrentClientType() in [ClientType::Web, ClientType::Windows, ClientType::Tablet, ClientType::Phone] then
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
        TSHeader: Record "Time Sheet Header";
        TSLine: Record "Time Sheet Line";
        SheetStartDate: Date;
        CreatedHeader: Boolean;
        LineNo: Integer;
    begin
        // RG-11 : Code Ressource obligatoire (déjà garanti par la table source, sécurité défensive)
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

        // RG-15 : le statut d'approbation est par ligne (Time Sheet Header n'a pas de champ Status).
        // Le contrôle s'effectue dans FindOrCreateTSLine (TSLine.Status) et UpsertTSDetail (TSDetail.Status).

        if not FindOrCreateTSLine(TSHeader, TSLine, LineNo) then begin
            LogWarning(StrSubstNo('Impossible de créer/trouver ligne feuille de temps : %1.', TSHeader."No."));
            NbAvert += 1;
            exit('');
        end;

        // Recalcul complet : total des heures depuis TOUS les pointages Valide du jour
        // (Traite=true et false confondus) — idempotent quel que soit le nombre de runs.
        UpsertTSDetail(TSHeader."No.", LineNo, WorkDate, CalcTotalHeuresJour(ResourceCode, WorkDate));

        exit(TSHeader."No.");
    end;

    // Cherche un en-tête pour la ressource/semaine ou en crée un.
    // Prérequis : souche de numéros "Time Sheet Nos." configurée dans Resources Setup (ARBZEITTAB).
    // IMPORTANT : le No. doit être assigné AVANT Validate("Resource No.") et Insert,
    // car OnInsert appelle AddToMyTimeSheets(UserID) qui lit "No." directement.
    // Motif identique au rapport standard "Create Time Sheets" (Report 950).
    local procedure FindOrCreateTSHeader(ResourceCode: Code[20]; StartDate: Date; var TSHeader: Record "Time Sheet Header"; var Created: Boolean): Boolean
    var
        ResourcesSetup: Record "Resources Setup";
        NoSeries: Codeunit "No. Series";
    begin
        Created := false;

        TSHeader.SetRange("Resource No.", ResourceCode);
        TSHeader.SetRange("Starting Date", StartDate);
        if TSHeader.FindFirst() then
            exit(true);

        ResourcesSetup.Get();
        TSHeader.Init();
        TSHeader."No." := NoSeries.GetNextNo(ResourcesSetup."Time Sheet Nos.", Today());
        TSHeader."Starting Date" := StartDate;
        TSHeader."Ending Date" := StartDate + 6;
        TSHeader.Validate("Resource No.", ResourceCode);
        if not TSHeader.Insert(true) then
            exit(false);

        Created := true;
        exit(true);
    end;

    // Cherche une ligne de type Ressource dans la feuille ou en crée une.
    local procedure FindOrCreateTSLine(TSHeader: Record "Time Sheet Header"; var TSLine: Record "Time Sheet Line"; var LineNo: Integer): Boolean
    begin
        TSLine.SetRange("Time Sheet No.", TSHeader."No.");
        TSLine.SetRange(TSLine.Type, "Time Sheet Line Type"::Resource);
        if TSLine.FindFirst() then begin
            // RG-15 : ligne approuvée → ne pas modifier
            if TSLine.Status = "Time Sheet Status"::Approved then
                exit(false);
            LineNo := TSLine."Line No.";
            exit(true);
        end;

        // Calcul du prochain LineNo (incréments de 10 000, convention BC)
        TSLine.SetRange("Time Sheet No.", TSHeader."No.");
        TSLine.SetRange(TSLine.Type); // Effacer le filtre Type pour FindLast sur toutes les lignes
        if TSLine.FindLast() then
            LineNo := TSLine."Line No." + 10000
        else
            LineNo := 10000;

        TSLine.Init();
        TSLine."Time Sheet No." := TSHeader."No.";
        TSLine."Line No." := LineNo;
        TSLine.Type := "Time Sheet Line Type"::Resource;
        TSLine.Description := 'Présence';
        if not TSLine.Insert(true) then
            exit(false);

        exit(true);
    end;

    // Écrit ou met à jour le détail de feuille pour un jour donné.
    // Hours est le total complet recalculé par CalcTotalHeuresJour — := est correct (pas +=).
    local procedure UpsertTSDetail(TSHeaderNo: Code[20]; LineNo: Integer; WorkDate: Date; Hours: Decimal)
    var
        TSDetail: Record "Time Sheet Detail";
    begin
        TSDetail.SetRange("Time Sheet No.", TSHeaderNo);
        TSDetail.SetRange("Time Sheet Line No.", LineNo);
        TSDetail.SetRange(Date, WorkDate);

        if TSDetail.FindFirst() then begin
            // RG-15 : détail approuvé → ne pas modifier
            if TSDetail.Status = "Time Sheet Status"::Approved then
                exit;
            TSDetail.Quantity := Hours;
            TSDetail.Modify(true);
        end else begin
            TSDetail.Init();
            TSDetail."Time Sheet No." := TSHeaderNo;
            TSDetail."Time Sheet Line No." := LineNo;
            TSDetail.Date := WorkDate;
            TSDetail.Quantity := Hours;
            TSDetail.Insert(true);
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

    // Relit tous les pointages Valide d'une journée (sans filtre Traite) et recalcule
    // les heures totales par appariement séquentiel Entrée→Sortie.
    // Une Entrée sans Sortie en fin de journée est ignorée silencieusement (HasOpen non relu après exit).
    local procedure CalcTotalHeuresJour(ResourceCode: Code[20]; WorkDate: Date): Decimal
    var
        Pointage: Record "PRF Pointage Reconnaissance";
        EntreeDateTime: DateTime;
        HasOpen: Boolean;
        Total: Decimal;
    begin
        Pointage.SetRange("Code Ressource", ResourceCode);
        Pointage.SetRange("Statut", Pointage."Statut"::Valide);
        Pointage.SetFilter("Date-Heure", '>=%1&<=%2',
            CreateDateTime(WorkDate, 000000T), CreateDateTime(WorkDate, 235959.999T));
        Pointage.SetCurrentKey("Code Ressource", "Date-Heure");
        if not Pointage.FindSet() then exit(0);
        HasOpen := false;
        EntreeDateTime := 0DT;
        Total := 0;
        repeat
            if Pointage."Type" = Pointage."Type"::Entree then begin
                EntreeDateTime := Pointage."Date-Heure";
                HasOpen := true;
            end else begin
                if HasOpen then begin
                    Total += CalcDiffHeures(EntreeDateTime, Pointage."Date-Heure");
                    HasOpen := false;
                end;
            end;
        until Pointage.Next() = 0;
        exit(Total);
    end;

    // Retourne le premier jour de la semaine (Lundi ISO) pour la date donnée.
    // Suppose Lundi comme premier jour de semaine (configuration par défaut BC en Europe).
    // Si Resources Setup définit un autre premier jour, adapter cette logique.
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

    // Journalise un avertissement non-bloquant via la télémétrie BC (visible dans Event Log).
    local procedure LogWarning(Msg: Text)
    begin
        Session.LogMessage('PRF0001', Msg, Verbosity::Warning, DataClassification::SystemMetadata,
            TelemetryScope::ExtensionPublisher, 'Category', 'PRF Pointage');
    end;
}
