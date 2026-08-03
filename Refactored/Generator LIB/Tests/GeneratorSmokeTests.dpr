program GeneratorSmokeTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Pkg.Json.Generator in '..\Pkg.Json.Generator.pas',
  Pkg.Json.Generator.Builder in '..\Pkg.Json.Generator.Builder.pas',
  Pkg.Json.Generator.Errors in '..\Pkg.Json.Generator.Errors.pas',
  Pkg.Json.Generator.DelphiWriter in '..\Pkg.Json.Generator.DelphiWriter.pas',
  Pkg.Json.Generator.Model in '..\Pkg.Json.Generator.Model.pas',
  Pkg.Json.Generator.Naming in '..\Pkg.Json.Generator.Naming.pas',
  Pkg.Json.Generator.Options in '..\Pkg.Json.Generator.Options.pas';

procedure Check(ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

function DefaultOptions: TGeneratorOptions;
begin
  Result.AddJsonPropertyAttributes := False;
  Result.PostFixClassNames := False;
  Result.PostFix := 'DTO';
  Result.UsePascalCase := True;
  Result.SuppressZeroDate := True;
end;

procedure TestObjectGeneration;
var
  Generator: TJsonToDelphiGenerator;
  Source: string;
begin
  Generator := TJsonToDelphiGenerator.Create(DefaultOptions);
  try
    Generator.RootClassName := 'Order';
    Generator.DestinationUnitName := 'OrderDTO';
    Generator.Parse('{"id":1,"created_at":"2025-01-02T03:04:05Z",' +
      '"customer":{"name":"Ada"},"lines":[{"sku":"A"},{"sku":"B"}]}');
    Source := Generator.GenerateUnit;
    Check(Source.Contains('unit OrderDTO;'), 'Unit name was not generated');
    Check(Source.Contains('TOrder = class(TJsonDTO)'), 'Root class missing');
    Check(Source.Contains('TLines = class'), 'Array item class missing');
    Check(Source.Contains('[SuppressZero, JSONName(''created_at'')]'),
      'Date/JSON attributes missing');
    Check(Source.Contains('property Lines: TObjectList<TLines>'),
      'Object array property missing');
  finally
    Generator.Free;
  end;
end;

procedure TestPrimitiveRootArray;
var
  Generator: TJsonToDelphiGenerator;
  Source: string;
begin
  Generator := TJsonToDelphiGenerator.Create(DefaultOptions);
  try
    Generator.Parse('[1,2,3]');
    Source := Generator.GenerateUnit;
    Check(Source.Contains('property Items: TList<Integer>'),
      'Primitive root arrays must be supported');
  finally
    Generator.Free;
  end;
end;

procedure TestEmptyArray;
var
  Generator: TJsonToDelphiGenerator;
  Source: string;
begin
  Generator := TJsonToDelphiGenerator.Create(DefaultOptions);
  try
    Generator.Parse('{"values":[]}');
    Source := Generator.GenerateUnit;
    Check(Source.Contains('property Values: TList<string>'),
      'Empty arrays must have a safe fallback type');
  finally
    Generator.Free;
  end;
end;

procedure TestArrayTypeConflictLocation;
const
  Json = '[[1,2],["3","4"]]';
var
  Generator: TJsonToDelphiGenerator;
begin
  Generator := TJsonToDelphiGenerator.Create(DefaultOptions);
  try
    try
      Generator.Parse(Json);
      Check(False, 'Mixed nested array types must be rejected');
    except
      on E: EJsonGenerator do
      begin
        Check(E.JsonPath = '$[1]', 'Conflict path must identify the second row');
        Check(Copy(Json, E.Position + 1, E.SelectionLength) = '["3","4"]',
          'Conflict source range must identify the conflicting element');
        Check(E.Message.Contains('expected Integer, found string'),
          'Conflict message must describe both element types');
      end;
    end;
  finally
    Generator.Free;
  end;
end;

begin
  try
    TestObjectGeneration;
    TestPrimitiveRootArray;
    TestEmptyArray;
    TestArrayTypeConflictLocation;
    Writeln('All generator smoke tests passed.');
  except
    on E: Exception do
    begin
      Writeln(E.ClassName + ': ' + E.Message);
      Halt(1);
    end;
  end;
end.
