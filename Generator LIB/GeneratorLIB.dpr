library GeneratorLIB;

uses
  System.SysUtils,
  Pkg.Json.Settings in '..\Lib\Pkg.Json.Settings.pas',
  Pkg.Json.Generator in 'Pkg.Json.Generator.pas',
  Pkg.Json.Generator.Builder in 'Pkg.Json.Generator.Builder.pas',
  Pkg.Json.Generator.Errors in 'Pkg.Json.Generator.Errors.pas',
  Pkg.Json.Generator.Validation in 'Pkg.Json.Generator.Validation.pas',
  Pkg.Json.Generator.DelphiWriter in 'Pkg.Json.Generator.DelphiWriter.pas',
  Pkg.Json.Generator.Model in 'Pkg.Json.Generator.Model.pas',
  Pkg.Json.Generator.Naming in 'Pkg.Json.Generator.Naming.pas',
  Pkg.Json.Generator.Options in 'Pkg.Json.Generator.Options.pas';

function GenerateUnit(Settings: WideString; Json: WideString; out SourceFile: WideString): WordBool; stdcall;
var
  Generator: TJsonToDelphiGenerator;
begin
  Result := False;
  try
    TSettings.Instance.AsJson := string(Settings);
    Generator := TJsonToDelphiGenerator.Create;
    try
      Generator.RootClassName := 'Root';
      Generator.DestinationUnitName := 'Root';
      Generator.Parse(string(Json));
      SourceFile := Generator.GenerateUnit;
      Result := True;
    finally
      Generator.Free;
    end;
  except
    SourceFile := '';
  end;
end;

exports
  GenerateUnit;

end.
