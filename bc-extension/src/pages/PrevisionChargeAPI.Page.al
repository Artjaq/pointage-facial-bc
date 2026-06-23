// Page 50112 : API OData pour lecture des prévisions de charge hebdomadaire.
// GET pour Power BI ; POST/PATCH disponibles (DelayedInsert=true).
// URL type : http://<serveur>:7048/BC260/api/prf/pointage/v1.0/companies(<guid>)/previsionsCharge
page 50112 "PRF Prevision Charge API"
{
    PageType = API;
    APIPublisher = 'prf';
    APIGroup = 'pointage';
    APIVersion = 'v1.0';
    EntityName = 'previsionCharge';
    EntitySetName = 'previsionsCharge';
    SourceTable = "PRF Prevision Charge";
    DelayedInsert = true;
    Caption = 'API Prévision Charge';
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
                field(codeCollaborateur; Rec."Code Collaborateur")
                {
                    Caption = 'Code Collaborateur';
                }
                field(date; Rec."Date")
                {
                    Caption = 'Date';
                }
                field(heuresPrevues; Rec."Heures Prevues")
                {
                    Caption = 'Heures Prévues';
                }
                field(poste; Rec."Poste")
                {
                    Caption = 'Poste';
                }
            }
        }
    }
}
