// Page 50113 : API OData GET-only pour Power BI — heures journalières réelles.
// Expose les enregistrements de la table 952 "Time Sheet Detail" (générés par CU 50120)
// enrichis du code ressource (lu sur l'en-tête 950) qui n'existe pas directement sur 952.
// URL : http://<serveur>:7048/BC260/api/prf/pointage/v1.0/companies(<guid>)/heuresJournalieres
page 50113 "PRF Heures Journalieres API"
{
    PageType = API;
    APIPublisher = 'prf';
    APIGroup = 'pointage';
    APIVersion = 'v1.0';
    EntityName = 'heureJournaliere';
    EntitySetName = 'heuresJournalieres';
    SourceTable = "Time Sheet Detail";
    Editable = false;
    Caption = 'API Heures Journalières';
    ODataKeyFields = SystemId;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(timeSheetNo; Rec."Time Sheet No.")
                {
                    Caption = 'No. Feuille';
                    Editable = false;
                }
                field(resourceNo; ResourceNo)
                {
                    Caption = 'Code Ressource';
                    Editable = false;
                }
                field(date; Rec.Date)
                {
                    Caption = 'Date';
                    Editable = false;
                }
                field(quantity; Rec.Quantity)
                {
                    Caption = 'Heures';
                    Editable = false;
                }
                field(status; Rec.Status)
                {
                    Caption = 'Statut';
                    Editable = false;
                }
            }
        }
    }

    var
        ResourceNo: Code[20];

    trigger OnAfterGetRecord()
    var
        TSHeader: Record "Time Sheet Header";
    begin
        if TSHeader.Get(Rec."Time Sheet No.") then
            ResourceNo := TSHeader."Resource No."
        else
            ResourceNo := '';
    end;
}
