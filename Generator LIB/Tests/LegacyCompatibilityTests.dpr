program LegacyCompatibilityTests;

{$APPTYPE CONSOLE}

uses
  System.Classes, System.SysUtils,
  Pkg.Json.Mapper,
  Pkg.Json.Generator in '..\Pkg.Json.Generator.pas',
  Pkg.Json.Generator.Builder in '..\Pkg.Json.Generator.Builder.pas',
  Pkg.Json.Generator.DelphiWriter in '..\Pkg.Json.Generator.DelphiWriter.pas',
  Pkg.Json.Generator.Model in '..\Pkg.Json.Generator.Model.pas',
  Pkg.Json.Generator.Naming in '..\Pkg.Json.Generator.Naming.pas',
  Pkg.Json.Generator.Options in '..\Pkg.Json.Generator.Options.pas';

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
