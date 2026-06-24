// Ajout d'un FlowField "PRF Resource No." sur la table 952 Time Sheet Detail.
// Nécessaire pour exposer le code ressource via l'API page 50113 sans passer par
// une variable de page (qui génère un champ Edm.String sans MaxLength dans le
// $metadata OData, rejeté par Power BI).
tableextension 50100 "PRF TS Detail Ext" extends "Time Sheet Detail"
{
    fields
    {
        field(50100; "PRF Resource No."; Code[20])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("Time Sheet Header"."Resource No." where("No." = field("Time Sheet No.")));
            Caption = 'Code Ressource';
            Editable = false;
        }
    }
}
