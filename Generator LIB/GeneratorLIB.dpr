library GeneratorLIB;

uses
  System.SysUtils,
  JsonToDelphi.Generator.Core.Settings in 'Core\JsonToDelphi.Generator.Core.Settings.pas',
  JsonToDelphi.Generator.Delphi in 'Delphi\JsonToDelphi.Generator.Delphi.pas',
  JsonToDelphi.Generator.Core.Builder in 'Core\JsonToDelphi.Generator.Core.Builder.pas',
  JsonToDelphi.Generator.Core.Errors in 'Core\JsonToDelphi.Generator.Core.Errors.pas',
  JsonToDelphi.Generator.Core.Validation in 'Core\JsonToDelphi.Generator.Core.Validation.pas',
  JsonToDelphi.Generator.Core.TypeUnification in 'Core\JsonToDelphi.Generator.Core.TypeUnification.pas',
  JsonToDelphi.Generator.Delphi.Writer in 'Delphi\JsonToDelphi.Generator.Delphi.Writer.pas',
  JsonToDelphi.Generator.Core.Model in 'Core\JsonToDelphi.Generator.Core.Model.pas',
  JsonToDelphi.Generator.Delphi.Naming in 'Delphi\JsonToDelphi.Generator.Delphi.Naming.pas',
  JsonToDelphi.Generator.Delphi.Settings in 'Delphi\JsonToDelphi.Generator.Delphi.Settings.pas',
  JsonToDelphi.Generator.CSharp in 'CSharp\JsonToDelphi.Generator.CSharp.pas',
  JsonToDelphi.Generator.CSharp.Naming in 'CSharp\JsonToDelphi.Generator.CSharp.Naming.pas',
  JsonToDelphi.Generator.CSharp.Settings in 'CSharp\JsonToDelphi.Generator.CSharp.Settings.pas',
  JsonToDelphi.Generator.CSharp.Writer in 'CSharp\JsonToDelphi.Generator.CSharp.Writer.pas';

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
