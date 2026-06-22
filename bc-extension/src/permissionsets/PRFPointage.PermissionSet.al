// Permission set à assigner aux utilisateurs du système de pointage et aux comptes
// de service exécutant le Job Queue et recevant les POST OData.
permissionset 50100 "PRF Pointage"
{
    Assignable = true;
    Caption = 'PRF Pointage Reconnaissance';

    Permissions =
        // Accès aux données des tables custom
        tabledata "PRF Pointage Reconnaissance" = RIMD,
        tabledata "PRF Prevision Charge" = RIMD,

        // Exécution des objets
        table "PRF Pointage Reconnaissance" = X,
        table "PRF Prevision Charge" = X,
        page "PRF Pointage Rec. API" = X,
        page "PRF Saisie Heures API" = X,
        codeunit "PRF Gen. Feuilles de Temps" = X,

        // Lecture des objets standard BC nécessaires
        // TODO confirmer avec symboles les noms exacts des tables Time Sheet
        tabledata "Time Sheet Header" = RM,  // TODO confirmer avec symboles - Table 950
        tabledata "Time Sheet Line" = RIMD,  // TODO confirmer avec symboles - Table 951
        tabledata "Time Sheet Detail" = RIMD, // TODO confirmer avec symboles - Table 952
        tabledata Resource = R,
        tabledata Job = R,                   // TODO confirmer avec symboles - Table 167

        // Souche de numéros (pour auto-assignation No. sur les pointages)
        tabledata "No. Series" = R,
        tabledata "No. Series Line" = RM;
}
