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
        page "PRF Prevision Charge API" = X,
        codeunit "PRF Gen. Feuilles de Temps" = X,
        codeunit "PRF Demo Setup" = X,
        codeunit "PRF Demo Cleanup" = X,

        // Lecture des objets standard BC nécessaires
        tabledata "Time Sheet Header" = RM,   // Table 950
        tabledata "Time Sheet Line" = RIMD,   // Table 951
        tabledata "Time Sheet Detail" = RIMD, // Table 952
        tabledata Resource = R,
        tabledata Job = R,                    // Table 167

        // Souche de numéros (pour auto-assignation No. sur les pointages)
        tabledata "No. Series" = R,
        tabledata "No. Series Line" = RM;
}
