page 50114 "PRF Pointages Rec. List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Pointages Reconnaissance';
    SourceTable = "PRF Pointage Reconnaissance";
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Code Ressource"; Rec."Code Ressource")
                {
                    ApplicationArea = All;
                }
                field("Date-Heure"; Rec."Date-Heure")
                {
                    ApplicationArea = All;
                }
                field("Type"; Rec."Type")
                {
                    ApplicationArea = All;
                }
                field("Score Concordance"; Rec."Score Concordance")
                {
                    ApplicationArea = All;
                }
                field("Statut"; Rec."Statut")
                {
                    ApplicationArea = All;
                }
                field("Traite"; Rec."Traite")
                {
                    ApplicationArea = All;
                }
                field("No. Feuille Temps"; Rec."No. Feuille Temps")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Ascending(false);
    end;
}
