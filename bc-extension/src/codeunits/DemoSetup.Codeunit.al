codeunit 50121 "PRF Demo Setup"
{
    Access = Internal;

    // OnRun : crée la souche PRF-PONT et configure les User IDs feuilles de temps.
    // Ciblage entreprise via -CompanyName dans Invoke-NAVCodeunit.
    // Fonctionne dans les deux sociétés CRONUS : seules les ressources existantes sont mises à jour.
    trigger OnRun()
    begin
        CreatePRFNoSeries();
        SetupResourceTimeSheets();
    end;

    local procedure CreatePRFNoSeries()
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        if not NoSeries.Get('PRF-PONT') then begin
            NoSeries.Init();
            NoSeries.Code := 'PRF-PONT';
            NoSeries.Description := 'Pointages PRF';
            NoSeries."Default Nos." := true;
            NoSeries."Manual Nos." := false;
            NoSeries.Insert(false);
        end;

        NoSeriesLine.SetRange("Series Code", 'PRF-PONT');
        if NoSeriesLine.IsEmpty() then begin
            NoSeriesLine.Init();
            NoSeriesLine."Series Code" := 'PRF-PONT';
            NoSeriesLine."Line No." := 10000;
            NoSeriesLine."Starting No." := 'PTG-00001';
            NoSeriesLine."Ending No." := 'PTG-99999';
            NoSeriesLine.Insert(false);
        end;
    end;

    local procedure SetupResourceTimeSheets()
    var
        Resource: Record Resource;
        Codes: List of [Code[20]];
        ResourceCode: Code[20];
    begin
        // Suisse SA : ALAIN, ANNETTE, CHRISTIAN, ISABELLE
        // Schweiz AG : CONRAD, GEBHARD, JANA
        // Seules les ressources existantes dans la société courante sont mises à jour.
        Codes.Add('ALAIN');
        Codes.Add('ANNETTE');
        Codes.Add('CHRISTIAN');
        Codes.Add('ISABELLE');
        Codes.Add('CONRAD');
        Codes.Add('GEBHARD');
        Codes.Add('JANA');
        foreach ResourceCode in Codes do
            if Resource.Get(ResourceCode) then begin
                Resource."Time Sheet Owner User ID" := 'ARTHUR JAQUIER';
                Resource."Time Sheet Approver User ID" := 'ARTHUR JAQUIER';
                Resource.Modify(false);
            end;
    end;
}
