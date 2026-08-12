program LegacyCompatibilityTests;

{$APPTYPE CONSOLE}

uses
  System.Classes,
  System.SysUtils,
  Pkg.Json.Mapper,
  Pkg.Json.Generator.Delphi in '..\Delphi\Pkg.Json.Generator.Delphi.pas',
  Pkg.Json.Generator.Builder in '..\Core\Pkg.Json.Generator.Builder.pas',
  Pkg.Json.Generator.DelphiWriter in '..\Delphi\Pkg.Json.Generator.DelphiWriter.pas',
  Pkg.Json.Generator.Model in '..\Core\Pkg.Json.Generator.Model.pas',
  Pkg.Json.Generator.DelphiSettings in '..\Delphi\Pkg.Json.Generator.DelphiSettings.pas',
  TestConsoleRunner in 'TestConsoleRunner.pas';

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
      raise Exception.CreateFmt('Generated source differs for %s', [ADescription]);
  finally
    Refactored.Free;
    Legacy.Free;
  end;
end;

procedure TestScalarFields;
begin
  Compare('{"name":"Ada","age":42,"enabled":true}', 'scalar fields');
end;

procedure TestNestedObjects;
begin
  Compare('{"customer":{"name":"Ada","address":{"city":"London"}}}', 'nested objects');
end;

procedure TestObjectArrays;
begin
  Compare('{"items":[{"sku":"A","quantity":1},{"sku":"B","quantity":2}]}', 'object arrays');
end;

function GetTests: TArray<TTestCase>;
begin
  Result := [
    TTestCase.Create('Scalar fields', TestScalarFields),
    TTestCase.Create('Nested objects', TestNestedObjects),
    TTestCase.Create('Object arrays', TestObjectArrays)
  ];
end;

var
  Failed: Integer;
begin
  Failed := RunTests('Legacy Compatibility Tests', GetTests);
  if Failed > 0 then
    Halt(1);
end.
