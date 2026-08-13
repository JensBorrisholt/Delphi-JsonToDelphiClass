program DemoProjectSmokeTest;

{$APPTYPE CONSOLE}
{$R '..\DemoTemplate.res'}

uses
  System.SysUtils,
  JsonToDelphi.Generator.Delphi in '..\..\Generator LIB\Delphi\JsonToDelphi.Generator.Delphi.pas',
  JsonToDelphi.Generator.Core.Builder in '..\..\Generator LIB\Core\JsonToDelphi.Generator.Core.Builder.pas',
  JsonToDelphi.Generator.Core.Errors in '..\..\Generator LIB\Core\JsonToDelphi.Generator.Core.Errors.pas',
  JsonToDelphi.Generator.Core.Validation in '..\..\Generator LIB\Core\JsonToDelphi.Generator.Core.Validation.pas',
  JsonToDelphi.Generator.Core.TypeUnification in '..\..\Generator LIB\Core\JsonToDelphi.Generator.Core.TypeUnification.pas',
  JsonToDelphi.Generator.Delphi.Writer in '..\..\Generator LIB\Delphi\JsonToDelphi.Generator.Delphi.Writer.pas',
  JsonToDelphi.Generator.Delphi.Naming in '..\..\Generator LIB\Delphi\JsonToDelphi.Generator.Delphi.Naming.pas',
  JsonToDelphi.Generator.Delphi.Settings in '..\..\Generator LIB\Delphi\JsonToDelphi.Generator.Delphi.Settings.pas',
  JsonToDelphi.Generator.Core.Model in '..\..\Generator LIB\Core\JsonToDelphi.Generator.Core.Model.pas',
  JsonToDelphi.GUI.DemoProject in '..\JsonToDelphi.GUI.DemoProject.pas';

var
  Destination: string;
  Generator: TJsonToDelphiGenerator;
begin
  try
    if ParamCount <> 1 then
      raise Exception.Create('Destination directory argument required');
    Destination := ParamStr(1);
    Generator := TJsonToDelphiGenerator.Create;
    try
      Generator.RootClassName := 'Root';
      Generator.DestinationUnitName := 'RootU';
      Generator.Parse('{"name":"Ada","items":[{"id":1},{"id":2}],' +
        '"people":[[{"name":"Ada"}],[{"name":"Grace"}]]}');
      TDemoProjectGenerator.Generate(Destination, 'RootU',
        Generator.GeneratedRootClassName, Generator.Json,
        Generator.GenerateUnit,
        dpfVCL);
    finally
      Generator.Free;
    end;
    Writeln('Demo project generated.');
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, 'Demo project smoke test failed: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
