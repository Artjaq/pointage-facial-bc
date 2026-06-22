// Page 50111 : API OData pour lecture des projets BC (Jobs).
// Cette itération est GET-only : le formulaire HTML consomme la liste des jobs.
// L'écriture de lignes feuilles de temps de type Projet est marquée TODO ci-dessous.
// URL type : http://<serveur>:7048/BC260/api/prf/pointage/v1.0/companies(<guid>)/jobs
page 50111 "PRF Saisie Heures API"
{
    PageType = API;
    APIPublisher = 'prf';
    APIGroup = 'pointage';
    APIVersion = 'v1.0';
    EntityName = 'job';
    EntitySetName = 'jobs';
    SourceTable = Job; // TODO confirmer avec symboles - "Job" (167) ou "Project" selon version BC
    DelayedInsert = false;
    Editable = false; // GET-only dans cette itération
    Caption = 'API Saisie Heures (Jobs)';
    ODataKeyFields = id;

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
                field(number; Rec."No.")
                {
                    Caption = 'No.';
                    Editable = false;
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                    Editable = false;
                }
                field(billToCustomerNumber; Rec."Bill-to Customer No.") // TODO confirmer avec symboles
                {
                    Caption = 'Client facturé No.';
                    Editable = false;
                }
                field(status; Rec.Status) // TODO confirmer avec symboles - champ "Status" ou "Blocked"
                {
                    Caption = 'Statut';
                    Editable = false;
                }
                field(personResponsible; Rec."Person Responsible") // TODO confirmer avec symboles
                {
                    Caption = 'Responsable';
                    Editable = false;
                }
            }
        }
    }

    // TODO Écriture lignes feuilles de temps de type Projet (prochaine itération) :
    //
    // Le formulaire HTML enverrait un POST avec : codeRessource, jobNo, jobTaskNo, date, heures.
    // Implémenter une page API séparée (ex. 50112 "PRF Saisie Heures Ligne API") avec
    // SourceTable = "PRF Pointage Reconnaissance" ou une table tampon dédiée, et dans
    // OnInsert/ModifyRecord appeler la procédure EcrireVersFeuilleTempsJob() dans
    // codeunit 50120 "PRF Gen. Feuilles de Temps" (à factoriser avec la logique existante).
    //
    // Signature cible (à ajouter dans le codeunit 50120) :
    // procedure EcrireVersFeuilleTempsJob(
    //     ResourceCode: Code[20]; JobNo: Code[20]; JobTaskNo: Code[20];
    //     WorkDate: Date; Hours: Decimal): Code[20]
    // → retourne No. Feuille Temps ou '' si erreur
}
