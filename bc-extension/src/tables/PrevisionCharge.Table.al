// Table 50101 : prévision de charge hebdomadaire par collaborateur.
// Clé composite (Code Collaborateur, Date) — un seul enregistrement par collaborateur par jour.
table 50101 "PRF Prevision Charge"
{
    DataClassification = CustomerContent;
    Caption = 'Prévision Charge';

    fields
    {
        field(1; "Code Collaborateur"; Code[20])
        {
            Caption = 'Code Collaborateur';
            DataClassification = CustomerContent;
        }
        field(2; "Date"; Date)
        {
            Caption = 'Date';
            DataClassification = CustomerContent;
        }
        field(3; "Heures Prevues"; Decimal)
        {
            Caption = 'Heures Prévues';
            DataClassification = CustomerContent;
            MinValue = 0;
            DecimalPlaces = 2 : 2;
        }
        field(4; "Poste"; Code[20])
        {
            Caption = 'Poste';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Code Collaborateur", "Date")
        {
            Clustered = true;
        }
    }
}
