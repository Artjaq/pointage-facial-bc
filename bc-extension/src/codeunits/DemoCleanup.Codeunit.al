codeunit 50122 "PRF Demo Cleanup"
{
    Access = Internal;

    // Supprime UNIQUEMENT les données démo PRF (ressources ALAIN/ANNETTE/CHRISTIAN)
    // dans la société courante via la couche métier BC.
    // Les feuilles de temps préexistantes d'autres ressources (ex. R0020/R0030) sont préservées.
    // Exécuter via : Invoke-NAVCodeunit -CodeunitId 50122 -CompanyName "CRONUS (Suisse) SA"
    trigger OnRun()
    begin
        CleanupTimeSheets();
        CleanupPRFData();
    end;

    local procedure CleanupTimeSheets()
    var
        TSHeader: Record "Time Sheet Header";
    begin
        // Filtre sur les 3 ressources démo PRF uniquement — NE PAS supprimer les feuilles
        // préexistantes d'autres ressources (R0020/R0030 dans CRONUS (Suisse) SA etc.)
        TSHeader.SetFilter("Resource No.", 'ALAIN|ANNETTE|CHRISTIAN|CONRAD|GEBHARD|JANA');
        TSHeader.DeleteAll(true); // DeleteAll(true) déclenche OnDelete sur chaque en-tête :
                                  // cascade vers Time Sheet Line + Time Sheet Detail + My Time Sheets.
    end;

    local procedure CleanupPRFData()
    var
        Pointage: Record "PRF Pointage Reconnaissance";
        Prevision: Record "PRF Prevision Charge";
    begin
        Pointage.SetFilter("Code Ressource", 'ALAIN|ANNETTE|CHRISTIAN|CONRAD|GEBHARD|JANA');
        Pointage.DeleteAll(false);
        Prevision.SetFilter("Code Collaborateur", 'ALAIN|ANNETTE|CHRISTIAN|CONRAD|GEBHARD|JANA');
        Prevision.DeleteAll(false);
    end;
}
