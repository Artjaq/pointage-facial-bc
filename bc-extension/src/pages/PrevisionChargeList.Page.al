page 50115 "PRF Previsions Charge List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Prévisions de Charge';
    SourceTable = "PRF Prevision Charge";
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Code Collaborateur"; Rec."Code Collaborateur")
                {
                    ApplicationArea = All;
                }
                field("Date"; Rec."Date")
                {
                    ApplicationArea = All;
                }
                field("Heures Prevues"; Rec."Heures Prevues")
                {
                    ApplicationArea = All;
                }
                field("Poste"; Rec."Poste")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
