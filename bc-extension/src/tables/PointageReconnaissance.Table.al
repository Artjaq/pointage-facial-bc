// Plage ID utilisée : 50100-50149
// Table 50100 : stockage des pointages bruts envoyés par le script Python via OData POST.
// Aucune donnée biométrique : uniquement ID collaborateur, horodatage, type, score.
table 50100 "PRF Pointage Reconnaissance"
{
    DataClassification = CustomerContent;
    Caption = 'Pointage Reconnaissance';

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = CustomerContent;
        }
        field(2; "No. Series"; Code[20])
        {
            Caption = 'No. Souche';
            DataClassification = SystemMetadata;
            TableRelation = "No. Series";
        }
        field(3; "Code Collaborateur"; Code[20])
        {
            Caption = 'Code Collaborateur';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(4; "Code Ressource"; Code[20])
        {
            Caption = 'Code Ressource';
            DataClassification = CustomerContent;
            NotBlank = true;
            TableRelation = Resource."No.";
        }
        field(5; "Date-Heure"; DateTime)
        {
            Caption = 'Date-Heure';
            DataClassification = CustomerContent;
        }
        field(6; "Type"; Option)
        {
            Caption = 'Type';
            DataClassification = CustomerContent;
            OptionMembers = Entree,Sortie;
            OptionCaption = 'Entrée,Sortie';
        }
        field(7; "Score Concordance"; Decimal)
        {
            Caption = 'Score Concordance';
            DataClassification = CustomerContent;
            MinValue = 0;
            MaxValue = 1;
            DecimalPlaces = 2 : 4;
        }
        field(8; "Source Poste"; Code[20])
        {
            Caption = 'Source Poste';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(9; "Statut"; Option)
        {
            Caption = 'Statut';
            DataClassification = CustomerContent;
            OptionMembers = Valide,AVerifier;
            OptionCaption = 'Validé,À vérifier';
            InitValue = Valide;
        }
        field(10; "Traite"; Boolean)
        {
            Caption = 'Traité';
            DataClassification = CustomerContent;
            InitValue = false;
        }
        field(11; "No. Feuille Temps"; Code[20])
        {
            Caption = 'No. Feuille Temps';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(12; "Date Traitement"; DateTime)
        {
            Caption = 'Date Traitement';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        key(K1; "Code Ressource", "Date-Heure", "Type") { Unique = true; }
        key(K2; "Statut", "Traite") { }
    }

    trigger OnInsert()
    var
        NoSeries: Codeunit "No. Series"; // Business Foundation — disponible en BC 22+
    begin
        if Rec."No." = '' then begin
            Rec."No. Series" := GetNoSeriesCode();
            Rec."No." := NoSeries.GetNextNo(Rec."No. Series", Today(), true);
        end;
        ValidateDateHeure();
    end;

    trigger OnModify()
    begin
        ValidateDateHeure();
    end;

    local procedure ValidateDateHeure()
    begin
        if (Rec."Date-Heure" <> 0DT) and (Rec."Date-Heure" > CurrentDateTime()) then
            Error('La date-heure de pointage ne peut pas être dans le futur. Valeur reçue : %1', Rec."Date-Heure");
    end;

    local procedure GetNoSeriesCode(): Code[20]
    begin
        // Souche à créer manuellement dans BC : Code='PRF-PONT', début='PTG-00001'
        // Voir README section "Prérequis - Souche de numéros".
        exit('PRF-PONT');
    end;
}
