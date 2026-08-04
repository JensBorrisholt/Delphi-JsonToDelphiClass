program GeneratorSmokeTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  System.Generics.Collections,
  REST.Json.Types,
  Pkg.Json.DTO,
  Pkg.Json.Generator.Settings in '..\Core\Pkg.Json.Generator.Settings.pas',
  Pkg.Json.Generator.Delphi in '..\Delphi\Pkg.Json.Generator.Delphi.pas',
  Pkg.Json.Generator.Builder in '..\Core\Pkg.Json.Generator.Builder.pas',
  Pkg.Json.Generator.Errors in '..\Core\Pkg.Json.Generator.Errors.pas',
  Pkg.Json.Generator.DelphiWriter in '..\Delphi\Pkg.Json.Generator.DelphiWriter.pas',
  Pkg.Json.Generator.DelphiSettings in '..\Delphi\Pkg.Json.Generator.DelphiSettings.pas',
  Pkg.Json.Generator.Model in '..\Core\Pkg.Json.Generator.Model.pas',
  Pkg.Json.Generator.CSharp in '..\CSharp\Pkg.Json.Generator.CSharp.pas',
  Pkg.Json.Generator.CSharpSettings in '..\CSharp\Pkg.Json.Generator.CSharpSettings.pas';

type
  TMatrixDTO = class(TJsonDTO)
  private
    [JSONName('matrix')]
    FMatrixArray: TArray<TArray<Integer>>;
    [JSONMarshalled(False)]
    FMatrix: TObjectList<TList<Integer>>;
    function GetMatrix: TObjectList<TList<Integer>>;
  protected
    function GetAsJson: string; override;
  public
    destructor Destroy; override;
    property Matrix: TObjectList < TList < Integer >> read GetMatrix;
  end;

destructor TMatrixDTO.Destroy;
begin
  GetMatrix.Free;
  inherited;
end;

function TMatrixDTO.GetAsJson: string;
begin
  RefreshArray2D<Integer>(FMatrix, FMatrixArray);
  Result := inherited;
end;

function TMatrixDTO.GetMatrix: TObjectList<TList<Integer>>;
begin
  Result := List2D<Integer>(FMatrix, FMatrixArray);
end;

procedure Check(ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

procedure TestObjectGeneration;
var
  Generator: TJsonToDelphiGenerator;
  Source: string;
begin
  Generator := TJsonToDelphiGenerator.Create;
  try
    Generator.RootClassName := 'Order';
    Generator.DestinationUnitName := 'OrderDTO';
    Generator.Parse('{"id":1,"created_at":"2025-01-02T03:04:05Z",' + '"customer":{"name":"Ada"},"lines":[{"sku":"A"},{"sku":"B"}]}');
    Source := Generator.GenerateUnit;
    Check(Source.Contains('unit OrderDTO;'), 'Unit name was not generated');
    Check(Source.Contains('TOrder = class(TJsonDTO)'), 'Root class missing');
    Check(Source.Contains('TLines = class'), 'Array item class missing');
    Check(Source.Contains('[SuppressZero, JSONName(''created_at'')]'), 'Date/JSON attributes missing');
    Check(Source.Contains('property Lines: TObjectList<TLines>'), 'Object array property missing');
  finally
    Generator.Free;
  end;
end;

procedure TestPrimitiveRootArray;
var
  Generator: TJsonToDelphiGenerator;
  Source: string;
begin
  Generator := TJsonToDelphiGenerator.Create;
  try
    Generator.Parse('[1,2,3]');
    Source := Generator.GenerateUnit;
    Check(Source.Contains('property Items: TList<Integer>'), 'Primitive root arrays must be supported');
  finally
    Generator.Free;
  end;
end;

procedure TestEmptyArray;
var
  Generator: TJsonToDelphiGenerator;
  Source: string;
begin
  Generator := TJsonToDelphiGenerator.Create;
  try
    Generator.Parse('{"values":[]}');
    Source := Generator.GenerateUnit;
    Check(Source.Contains('property Values: TList<string>'), 'Empty arrays must have a safe fallback type');
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
  Generator := TJsonToDelphiGenerator.Create;
  try
    try
      Generator.Parse(Json);
      Check(False, 'Mixed nested array types must be rejected');
    except
      on E: EJsonGenerator do
      begin
        Check(E.JsonPath = '$[1]', 'Conflict path must identify the second row');
        Check(Copy(Json, E.Position + 1, E.SelectionLength) = '["3","4"]', 'Conflict source range must identify the conflicting element');
        Check(E.Message.Contains('expected Integer, found string'), 'Conflict message must describe both element types');
      end;
    end;
  finally
    Generator.Free;
  end;
end;

procedure TestTwoDimensionalArray;
var
  Generator: TJsonToDelphiGenerator;
  Source: string;
begin
  Generator := TJsonToDelphiGenerator.Create;
  try
    Generator.Parse('[[1,2],[3,4]]');
    Source := Generator.GenerateUnit;
    Check(Source.Contains('FItemsArray: TArray<TArray<Integer>>;'), '2D array bridge must preserve the JSON array shape');
    Check(Source.Contains('property Items: TObjectList<TList<Integer>>'), '2D arrays must be exposed as lists');
    Check(Source.Contains('RefreshArray2D<Integer>'), '2D lists must be synchronized before serialization');
  finally
    Generator.Free;
  end;
end;

procedure TestTwoDimensionalArrayRuntime;
var
  DTO: TMatrixDTO;
  Json: string;
begin
  DTO := TMatrixDTO.Create;
  try
    DTO.AsJson := '{"matrix":[[1,2],[3,4]]}';
    Check(DTO.Matrix.Count = 2, '2D JSON must create two list rows');
    Check(DTO.Matrix[1][0] = 3, '2D JSON values must deserialize');
    DTO.Matrix[1][0] := 30;
    Json := DTO.AsJson;
    Check(Json.Contains('[[1,2],[30,4]]'), 'Changed 2D list values must serialize as nested JSON arrays');
  finally
    DTO.Free;
  end;
end;

procedure TestLanguageIndependentModel;
var
  Generator: TJsonToDelphiGenerator;
  MatrixField: TGeneratorField;
  MaybeField: TGeneratorField;
  RowsClass: TGeneratorClass;
begin
  Generator := TJsonToDelphiGenerator.Create;
  try
    Generator.Parse('{"enabled":true,' + '"created":"2025-01-02T03:04:05Z","maybe":null,' + '"matrix":[[1,2],[3,4]],"rows":[{"a":1},{"b":2}]}');
    Check(Generator.Model.RootClass.FindField('enabled').DataType.JsonKind = jvkBoolean, 'Boolean values must have one neutral JSON kind');
    Check(Generator.Model.RootClass.FindField('created').DataType.JsonKind = jvkString, 'Date-time values must retain their JSON string kind');
    Check(Generator.Model.RootClass.FindField('created').DataType.SemanticKind = svkDateTime, 'Date-time interpretation must be stored separately');
    MaybeField := Generator.Model.RootClass.FindField('maybe');
    Check(MaybeField.DataType.Nullable, 'JSON null must be represented explicitly in the model');
    Check(MaybeField.JsonPath = '$.maybe', 'Fields must retain their JSON source path');
    Check((MaybeField.SourcePosition >= 0) and (MaybeField.SourceLength = Length('null')), 'Fields must retain their JSON source range');
    MatrixField := Generator.Model.RootClass.FindField('matrix');
    Check(MatrixField.DataType.ArrayDepth = 2, 'Array dimensions must be represented recursively');
    Check(MatrixField.DataType.ElementType.ElementType.SemanticKind = svkInteger, 'The recursive array leaf type must be neutral');
    RowsClass := Generator.Model.FindClass('rows');
    Check((RowsClass <> nil) and (RowsClass.Identity = '$.rows[]'), 'Class identity must be independent of a generated language name');
    Check(RowsClass.FindField('a').IsOptional and RowsClass.FindField('b').IsOptional, 'Missing object members must be represented as optional');
  finally
    Generator.Free;
  end;
end;

procedure TestCSharpGeneration;
var
  Generator: TJsonToCSharpGenerator;
  Settings: TCSharpSettings;
  Source: string;
begin
  Settings := TCSharpSettings.Create;
  Settings.NamespaceName := 'Demo.Contracts';
  Generator := TJsonToCSharpGenerator.Create(Settings);
  try
    Generator.RootClassName := 'Order';
    Generator.Parse('{"id":1,"created_at":"2025-01-02T03:04:05Z",' +
      '"customer":{"full-name":"Ada"},"lines":[{"sku":"A"},{"sku":"B"}],"maybe":null}');
    Source := Generator.GenerateSource;
    Check(Source.Contains('namespace Demo.Contracts;'), 'C# namespace missing');
    Check(Source.Contains('public sealed class Order'), 'C# root class missing');
    Check(Source.Contains('public int Id { get; set; }'), 'C# integer property missing');
    Check(Source.Contains('public DateTimeOffset CreatedAt { get; set; }'), 'C# date-time property missing');
    Check(Source.Contains('[JsonPropertyName("created_at")]'), 'C# renamed JSON property attribute missing');
    Check(Source.Contains('public List<Lines> Lines { get; set; } = [];'), 'C# object list missing');
    Check(Source.Contains('public object? Maybe { get; set; }'), 'C# nullable JSON null property missing');
    Check(Source.Contains('[JsonPropertyName("full-name")]'), 'C# special JSON name attribute missing');
  finally
    Generator.Free;
    Settings.Free;
  end;
end;

procedure TestCSharpOptions;
var
  Generator: TJsonToCSharpGenerator;
  Settings: TCSharpSettings;
  Source: string;
begin
  Settings := TCSharpSettings.Create;
  Settings.UseRecords := True;
  Settings.UseNullableTypes := True;
  Settings.UseReadonlyLists := True;
  Generator := TJsonToCSharpGenerator.Create(Settings);
  try
    Generator.Parse('{"count":1,"values":[1,2]}');
    Source := Generator.GenerateSource;
    Check(Source.Contains('public sealed record Root'), 'C# record option missing');
    Check(Source.Contains('public int? Count { get; init; }'), 'C# nullable primitive option missing');
    Check(Source.Contains('public IReadOnlyList<int> Values { get; init; } = [];'), 'C# readonly list option missing');
  finally
    Generator.Free;
    Settings.Free;
  end;
end;

procedure TestSettingsSerialization;
var
  FileName: string;
  SourceSettings: TDelphiSettings;
  LoadedSettings: TDelphiSettings;
begin
  FileName := TPath.Combine(TPath.GetTempPath, 'json-generator-settings-test.json');
  SourceSettings := TDelphiSettings.Create;
  LoadedSettings := TDelphiSettings.Create;
  try
    SourceSettings.AddJsonPropertyAttributes := True;
    SourceSettings.PostFixClassNames := True;
    SourceSettings.PostFix := 'Model';
    SourceSettings.UsePascalCase := False;
    SourceSettings.SuppressZeroDate := False;
    SourceSettings.Save(FileName);

    LoadedSettings.Load(FileName);
    Check(LoadedSettings.AddJsonPropertyAttributes, 'Settings Load/Save lost AddJsonPropertyAttributes');
    Check(LoadedSettings.PostFixClassNames, 'Settings Load/Save lost PostFixClassNames');
    Check(LoadedSettings.PostFix = 'Model', 'Settings Load/Save lost PostFix');
    Check(not LoadedSettings.UsePascalCase, 'Settings Load/Save lost UsePascalCase');
    Check(not LoadedSettings.SuppressZeroDate, 'Settings Load/Save lost SuppressZeroDate');
  finally
    LoadedSettings.Free;
    SourceSettings.Free;
    if TFile.Exists(FileName) then
      TFile.Delete(FileName);
  end;
end;

begin
  try
    TestObjectGeneration;
    TestPrimitiveRootArray;
    TestEmptyArray;
    TestTwoDimensionalArray;
    TestTwoDimensionalArrayRuntime;
    TestLanguageIndependentModel;
    TestArrayTypeConflictLocation;
    TestCSharpGeneration;
    TestCSharpOptions;
    TestSettingsSerialization;
    Writeln('All generator smoke tests passed.');
    Readln;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName + ': ' + E.Message);
      Halt(1);
    end;
  end;

end.
