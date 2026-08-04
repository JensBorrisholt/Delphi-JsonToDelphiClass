program DemoProjectSmokeTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Pkg.Json.Generator.Delphi in '..\..\Generator LIB\Delphi\Pkg.Json.Generator.Delphi.pas',
  Pkg.Json.Generator.Builder in '..\..\Generator LIB\Core\Pkg.Json.Generator.Builder.pas',
  Pkg.Json.Generator.Errors in '..\..\Generator LIB\Core\Pkg.Json.Generator.Errors.pas',
  Pkg.Json.Generator.Validation in '..\..\Generator LIB\Core\Pkg.Json.Generator.Validation.pas',
  Pkg.Json.Generator.DelphiWriter in '..\..\Generator LIB\Delphi\Pkg.Json.Generator.DelphiWriter.pas',
  Pkg.Json.Generator.DelphiNaming in '..\..\Generator LIB\Delphi\Pkg.Json.Generator.DelphiNaming.pas',
  Pkg.Json.Generator.DelphiSettings in '..\..\Generator LIB\Delphi\Pkg.Json.Generator.DelphiSettings.pas',
  Pkg.Json.Generator.Model in '..\..\Generator LIB\Core\Pkg.Json.Generator.Model.pas',
  Pkg.Json.GeneratorGUI.DemoProject in '..\Pkg.Json.GeneratorGUI.DemoProject.pas';

function DefaultOptions: TDelphiGeneratorSettings;
begin
  Result.AddJsonPropertyAttributes := False;
  Result.PostFixClassNames := False;
  Result.PostFix := 'DTO';
  Result.UsePascalCase := True;
  Result.SuppressZeroDate := True;
end;

var
  Destination: string;
  Generator: TJsonToDelphiGenerator;
begin
  try
    if ParamCount <> 1 then
      raise Exception.Create('Destination directory argument required');
    Destination := ParamStr(1);
    Generator := TJsonToDelphiGenerator.Create(DefaultOptions);
    try
      Generator.RootClassName := 'Root';
      Generator.DestinationUnitName := 'RootU';
      Generator.Parse('{"name":"Ada","items":[{"id":1},{"id":2}]}');
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
