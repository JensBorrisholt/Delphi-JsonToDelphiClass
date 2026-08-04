library GeneratorLIB;

uses
  System.SysUtils,
  Pkg.Json.Generator.Settings in 'Core\Pkg.Json.Generator.Settings.pas',
  Pkg.Json.Generator.Delphi in 'Delphi\Pkg.Json.Generator.Delphi.pas',
  Pkg.Json.Generator.Builder in 'Core\Pkg.Json.Generator.Builder.pas',
  Pkg.Json.Generator.Errors in 'Core\Pkg.Json.Generator.Errors.pas',
  Pkg.Json.Generator.Validation in 'Core\Pkg.Json.Generator.Validation.pas',
  Pkg.Json.Generator.DelphiWriter in 'Delphi\Pkg.Json.Generator.DelphiWriter.pas',
  Pkg.Json.Generator.Model in 'Core\Pkg.Json.Generator.Model.pas',
  Pkg.Json.Generator.DelphiNaming in 'Delphi\Pkg.Json.Generator.DelphiNaming.pas',
  Pkg.Json.Generator.DelphiSettings in 'Delphi\Pkg.Json.Generator.DelphiSettings.pas',
  Pkg.Json.Generator.CSharp in 'CSharp\Pkg.Json.Generator.CSharp.pas',
  Pkg.Json.Generator.CSharpNaming in 'CSharp\Pkg.Json.Generator.CSharpNaming.pas',
  Pkg.Json.Generator.CSharpSettings in 'CSharp\Pkg.Json.Generator.CSharpSettings.pas',
  Pkg.Json.Generator.CSharpWriter in 'CSharp\Pkg.Json.Generator.CSharpWriter.pas';

function GenerateUnit(Settings: WideString; Json: WideString; out SourceFile: WideString): WordBool; stdcall;
var
  Generator: TJsonToDelphiGenerator;
  GeneratorSettings: TDelphiSettings;
begin
  Result := False;
  Generator := nil;
  GeneratorSettings := nil;
  try
    try
      GeneratorSettings := TDelphiSettings.Create;
      GeneratorSettings.AsJson := string(Settings);
      Generator := TJsonToDelphiGenerator.Create(GeneratorSettings);
      Generator.RootClassName := 'Root';
      Generator.DestinationUnitName := 'Root';
      Generator.Parse(string(Json));
      SourceFile := Generator.GenerateUnit;
      Result := True;
    except
      SourceFile := '';
    end;
  finally
    Generator.Free;
    GeneratorSettings.Free;
  end;
end;

exports
  GenerateUnit;

end.
