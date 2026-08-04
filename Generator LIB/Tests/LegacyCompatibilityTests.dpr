program LegacyCompatibilityTests;

{$APPTYPE CONSOLE}

uses
  System.Classes, System.SysUtils,
  Pkg.Json.Mapper,
  Pkg.Json.Generator.Delphi in '..\Delphi\Pkg.Json.Generator.Delphi.pas',
  Pkg.Json.Generator.Builder in '..\Core\Pkg.Json.Generator.Builder.pas',
  Pkg.Json.Generator.DelphiWriter in '..\Delphi\Pkg.Json.Generator.DelphiWriter.pas',
  Pkg.Json.Generator.Model in '..\Core\Pkg.Json.Generator.Model.pas',
  Pkg.Json.Generator.DelphiSettings in '..\Delphi\Pkg.Json.Generator.DelphiSettings.pas';

function NormalizeWhitespace(const ASource: string): string;
var
  I: Integer;
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  try
    Lines.Text := ASource;
    for I := 0 to Lines.Count - 1 do
      Lines[I] := Lines[I].TrimRight;
    Lines.TrailingLineBreak := False;
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

procedure Compare(const AJson, ADescription: string);
var
  Legacy: TPkgJsonMapper;
  Refactored: TJsonToDelphiGenerator;
  LegacySource: string;
  RefactoredSource: string;
begin
  Legacy := TPkgJsonMapper.Create;
  Refactored := TJsonToDelphiGenerator.Create;
  try
    Legacy.DestinationClassName := 'Root';
    Legacy.DestinationUnitName := 'Root';
    Refactored.RootClassName := 'Root';
    Refactored.DestinationUnitName := 'Root';
    LegacySource := Legacy.Parse(AJson).GenerateUnit;
    RefactoredSource := Refactored.Parse(AJson).GenerateUnit;
    if NormalizeWhitespace(LegacySource) <> NormalizeWhitespace(RefactoredSource) then
    begin
      Writeln('--- Legacy');
      Writeln(LegacySource);
      Writeln('--- Refactored');
      Writeln(RefactoredSource);
      raise Exception.CreateFmt('Generated source differs for %s', [ADescription]);
    end;
  finally
    Refactored.Free;
    Legacy.Free;
  end;
end;

begin
  try
    Compare('{"name":"Ada","age":42,"enabled":true}', 'scalar fields');
    Compare('{"customer":{"name":"Ada","address":{"city":"London"}}}',
      'nested objects');
    Compare('{"items":[{"sku":"A","quantity":1},{"sku":"B","quantity":2}]}',
      'object arrays');
    Writeln('Legacy compatibility tests passed.');
  except
    on E: Exception do
    begin
      Writeln(E.ClassName + ': ' + E.Message);
      Halt(1);
    end;
  end;
end.
