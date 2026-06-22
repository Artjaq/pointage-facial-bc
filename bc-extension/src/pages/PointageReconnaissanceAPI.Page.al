// Page 50110 : API OData pour réception des pointages depuis Python.
// Choix : PageType=API plutôt que ListPage exposée en web service, car API donne
// un endpoint OData v4 stable avec SystemId comme clé GUID, plus robuste pour POST.
// URL type : http://<serveur>:7048/BC260/api/prf/pointage/v1.0/companies(<guid>)/pointagesReconnaissance
page 50110 "PRF Pointage Rec. API"
{
    PageType = API;
    APIPublisher = 'prf';
    APIGroup = 'pointage';
    APIVersion = 'v1.0';
    EntityName = 'pointageReconnaissance';
    EntitySetName = 'pointagesReconnaissance';
    SourceTable = "PRF Pointage Reconnaissance";
    DelayedInsert = true; // Nécessaire pour API : l'insert est différé après validation de tous les champs du POST
    Caption = 'API Pointage Reconnaissance';
    ODataKeyFields = id;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                // id = GUID système - clé OData, retourné dans la réponse POST
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(number; Rec."No.")
                {
                    Caption = 'No.';
                    Editable = false; // Assigné automatiquement via No. Series PRF-PONT
                }
                field(codeCollaborateur; Rec."Code Collaborateur")
                {
                    Caption = 'Code Collaborateur';
                }
                field(codeRessource; Rec."Code Ressource")
                {
                    Caption = 'Code Ressource';
                }
                field(dateHeure; Rec."Date-Heure")
                {
                    Caption = 'Date Heure';
                }
                field(pointageType; Rec."Type")
                {
                    Caption = 'Type';
                    // Valeurs JSON : 0 = Entrée, 1 = Sortie (option ordinal)
                    // TODO : envisager un Enum pour sérialisation en string ('Entree'/'Sortie')
                }
                field(scoreConcordance; Rec."Score Concordance")
                {
                    Caption = 'Score Concordance';
                }
                field(sourcePoste; Rec."Source Poste")
                {
                    Caption = 'Source Poste';
                }
                field(statut; Rec."Statut")
                {
                    Caption = 'Statut';
                    // Valeurs JSON : 0 = Validé, 1 = À vérifier (option ordinal)
                }
                field(traite; Rec."Traite")
                {
                    Caption = 'Traité';
                    Editable = false;
                }
                field(noFeuilleTemps; Rec."No. Feuille Temps")
                {
                    Caption = 'No. Feuille Temps';
                    Editable = false;
                }
                field(dateTraitement; Rec."Date Traitement")
                {
                    Caption = 'Date Traitement';
                    Editable = false;
                }
            }
        }
    }
}
