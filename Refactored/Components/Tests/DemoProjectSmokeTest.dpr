program DemoProjectSmokeTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Pkg.Json.Generator in '..\..\Generator LIB\Pkg.Json.Generator.pas',
  Pkg.Json.Generator.Builder in '..\..\Generator LIB\Pkg.Json.Generator.Builder.pas',
  Pkg.Json.Generator.DelphiWriter in '..\..\Generator LIB\Pkg.Json.Generator.DelphiWriter.pas',
  Pkg.Json.Generator.Model in '..\..\Generator LIB\Pkg.Json.Generator.Model.pas',
  Pkg.Json.Generator.Naming in '..\..\Generator LIB\Pkg.Json.Generator.Naming.pas',
  Pkg.Json.Generator.Options in '..\..\Generator LIB\Pkg.Json.Generator.Options.pas',
  Pkg.Json.GeneratorGUI.DemoProject in '..\Pkg.Json.GeneratorGUI.DemoProject.pas';

function DefaultOptions: TGeneratorOptions;
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
        Generator.Model.RootClass.Name, Generator.Json, Generator.GenerateUnit,
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
