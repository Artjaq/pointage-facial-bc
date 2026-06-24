// Page 50113 : API OData GET-only pour Power BI — heures journalières réelles.
// Expose les enregistrements de la table 952 "Time Sheet Detail" (générés par CU 50120).
// Le code ressource est exposé via le FlowField "PRF Resource No." (TableExtension 50100),
// ce qui garantit Type="Edm.String" MaxLength="20" dans le $metadata OData (requis par Power BI).
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
                field(resourceNo; Rec."PRF Resource No.")
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

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("PRF Resource No.");
    end;
}
