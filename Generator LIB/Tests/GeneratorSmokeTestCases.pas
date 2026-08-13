unit GeneratorSmokeTestCases;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  TestConsoleRunner;

function GetGeneratorSmokeTests: TArray<TTestCase>;

implementation

uses
  System.IOUtils,
  REST.Json.Types,
  JsonToDelphi.Runtime.DTO,
  JsonToDelphi.Generator.Core.Settings,
  JsonToDelphi.Generator.Delphi,
  JsonToDelphi.Generator.Core.Builder,
  JsonToDelphi.Generator.Core.Errors,
  JsonToDelphi.Generator.Delphi.Writer,
  JsonToDelphi.Generator.Delphi.Settings,
  JsonToDelphi.Generator.Core.Model,
  JsonToDelphi.Generator.CSharp,
  JsonToDelphi.Generator.CSharp.Settings,
  JsonToDelphi.GUI.DemoData;

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

procedure TestSemanticTypeInference;
var
  Generator: TJsonToDelphiGenerator;
  IdsField: TGeneratorField;
begin
  Generator := TJsonToDelphiGenerator.Create;
  try
    Generator.Parse('{"id":"550e8400-e29b-41d4-a716-446655440000",' +
      '"birthDate":"1970-04-15","opensAt":"08:30:00","preciseTime":"14:35:27.125",' +
      '"createdAt":"2026-08-05T14:35:27Z","homepage":"https://example.com/customer/42",' +
      '"contact":"mailto:demo@example.com","relativePath":"/customer/42","plainText":"example.com",' +
      '"ids":["550e8400-e29b-41d4-a716-446655440000","6ba7b810-9dad-11d1-80b4-00c04fd430c8"]}');

    Check(Generator.Model.RootClass.FindField('id').DataType.SemanticKind = svkGuid, 'GUID strings must be inferred as svkGuid');
    Check(Generator.Model.RootClass.FindField('birthDate').DataType.SemanticKind = svkDate, 'ISO dates must be inferred as svkDate');
    Check(Generator.Model.RootClass.FindField('opensAt').DataType.SemanticKind = svkTime, 'ISO times must be inferred as svkTime');
    Check(Generator.Model.RootClass.FindField('preciseTime').DataType.SemanticKind = svkTime, 'ISO times with milliseconds must be inferred as svkTime');
    Check(Generator.Model.RootClass.FindField('createdAt').DataType.SemanticKind = svkDateTime, 'ISO date-times must remain svkDateTime');
    Check(Generator.Model.RootClass.FindField('homepage').DataType.SemanticKind = svkUri, 'Absolute URLs must be inferred as svkUri');
    Check(Generator.Model.RootClass.FindField('contact').DataType.SemanticKind = svkUri, 'Absolute URIs must be inferred as svkUri');
    Check(Generator.Model.RootClass.FindField('relativePath').DataType.SemanticKind = svkString, 'Relative paths must remain strings');
    Check(Generator.Model.RootClass.FindField('plainText').DataType.SemanticKind = svkString, 'Domain-like text without a URI scheme must remain strings');

    IdsField := Generator.Model.RootClass.FindField('ids');
    Check(IdsField.DataType.JsonKind = jvkArray, 'GUID arrays must remain arrays');
    Check(IdsField.DataType.ElementType.SemanticKind = svkGuid, 'GUID array elements must retain svkGuid');
  finally
    Generator.Free;
  end;
end;

procedure TestDelphiSemanticTypeGeneration;
var
  Generator: TJsonToDelphiGenerator;
  Source: string;
begin
  Generator := TJsonToDelphiGenerator.Create;
  try
    Generator.Parse('{"id":"550e8400-e29b-41d4-a716-446655440000",' +
      '"birthDate":"1970-04-15","opensAt":"08:30:00",' +
      '"createdAt":"2026-08-05T14:35:27Z","homepage":"https://example.com/customer/42",' +
      '"dates":["2026-08-01","2026-08-02"]}');
    Source := Generator.GenerateUnit;

    Check(Source.Contains('FId: TGUID;'), 'Delphi GUID mapping missing');
    Check(Source.Contains('FBirthDate: TDate;'), 'Delphi date mapping missing');
    Check(Source.Contains('FOpensAt: TTime;'), 'Delphi time mapping missing');
    Check(Source.Contains('FCreatedAt: TDateTime;'), 'Delphi date-time mapping changed unexpectedly');
    Check(Source.Contains('FHomepage: TURI;'), 'Delphi URI mapping missing');
    Check(Source.Contains('property Dates: TList<TDate>'), 'Delphi date array mapping missing');
    Check(Source.Contains('System.Net.URLClient'), 'Delphi URI unit dependency missing');
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

procedure TestCSharpSemanticTypeGeneration;
var
  Generator: TJsonToCSharpGenerator;
  Settings: TCSharpSettings;
  Source: string;
begin
  Settings := TCSharpSettings.Create;
  Generator := TJsonToCSharpGenerator.Create(Settings);
  try
    Generator.Parse('{"id":"550e8400-e29b-41d4-a716-446655440000",' +
      '"birthDate":"1970-04-15","opensAt":"08:30:00",' +
      '"createdAt":"2026-08-05T14:35:27Z","homepage":"https://example.com/customer/42",' +
      '"dates":["2026-08-01","2026-08-02"]}');
    Source := Generator.GenerateSource;

    Check(Source.Contains('public Guid Id { get; set; }'), 'C# GUID mapping missing');
    Check(Source.Contains('public DateOnly BirthDate { get; set; }'), 'C# date mapping missing');
    Check(Source.Contains('public TimeOnly OpensAt { get; set; }'), 'C# time mapping missing');
    Check(Source.Contains('public DateTimeOffset CreatedAt { get; set; }'), 'C# date-time mapping changed unexpectedly');
    Check(Source.Contains('public Uri Homepage { get; set; }'), 'C# URI mapping missing');
    Check(Source.Contains('public List<DateOnly> Dates { get; set; } = [];'), 'C# date array mapping missing');
  finally
    Generator.Free;
    Settings.Free;
  end;
end;

procedure TestCSharpSemanticValueTypeNullability;
var
  Generator: TJsonToCSharpGenerator;
  Settings: TCSharpSettings;
  Source: string;
begin
  Settings := TCSharpSettings.Create;
  Settings.UseNullableTypes := True;
  Generator := TJsonToCSharpGenerator.Create(Settings);
  try
    Generator.Parse('{"id":"550e8400-e29b-41d4-a716-446655440000","date":"2026-08-05","time":"08:30:00","uri":"https://example.com"}');
    Source := Generator.GenerateSource;

    Check(Source.Contains('public Guid? Id { get; set; }'), 'C# Guid must participate in nullable value-type generation');
    Check(Source.Contains('public DateOnly? Date { get; set; }'), 'C# DateOnly must participate in nullable value-type generation');
    Check(Source.Contains('public TimeOnly? Time { get; set; }'), 'C# TimeOnly must participate in nullable value-type generation');
    Check(Source.Contains('public Uri Uri { get; set; }'), 'C# Uri must remain a reference type');
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


procedure TestDemoDataDiscovery;
var
  DemoDirectory: string;
  FileName: string;
  FoundSemanticTypes: Boolean;
begin
  DemoDirectory := TDemoDataRepository.Directory;
  Check(DemoDirectory <> '', 'Demo Data directory must be discoverable from the test executable');

  FoundSemanticTypes := False;
  for FileName in TDemoDataRepository.FileNames do
    if SameText(FileName, 'Semantic Types.json') then
    begin
      FoundSemanticTypes := True;
      Break;
    end;

  Check(FoundSemanticTypes, 'Semantic Types.json must be available in Demo Data');
end;

procedure TestSemanticDemoData;
var
  Generator: TJsonToDelphiGenerator;
  Json: string;
begin
  Json := TDemoDataRepository.Load('Semantic Types.json');
  Generator := TJsonToDelphiGenerator.Create;
  try
    Generator.Parse(Json);
    Check(Generator.Model.RootClass.FindField('id').DataType.SemanticKind = svkGuid, 'Semantic demo GUID must infer svkGuid');
    Check(Generator.Model.RootClass.FindField('birthDate').DataType.SemanticKind = svkDate, 'Semantic demo date must infer svkDate');
    Check(Generator.Model.RootClass.FindField('opensAt').DataType.SemanticKind = svkTime, 'Semantic demo time must infer svkTime');
    Check(Generator.Model.RootClass.FindField('createdAt').DataType.SemanticKind = svkDateTime, 'Semantic demo date-time must infer svkDateTime');
    Check(Generator.Model.RootClass.FindField('homepage').DataType.SemanticKind = svkUri, 'Semantic demo URI must infer svkUri');
  finally
    Generator.Free;
  end;
end;

procedure TestTypeUnificationDemoData;
var
  DataType: TGeneratorType;
  Generator: TJsonToDelphiGenerator;
  ItemClass: TGeneratorClass;
begin
  Generator := TJsonToDelphiGenerator.Create;
  try
    Generator.Parse(TDemoDataRepository.Load('Type Unification - Numbers.json'));
    ItemClass := Generator.Model.RootClass.FindField('measurements').DataType.ElementType.ObjectClass;
    Check(ItemClass.FindField('value').DataType.SemanticKind = svkFloat,
      'Numeric demo must unify Integer, Int64 and Float to Float');

    Generator.Parse(TDemoDataRepository.Load('Type Unification - Nullable.json'));
    ItemClass := Generator.Model.RootClass.FindField('readings').DataType.ElementType.ObjectClass;
    DataType := ItemClass.FindField('value').DataType;
    Check((DataType.SemanticKind = svkInteger) and DataType.Nullable,
      'Nullable demo must preserve the concrete type and mark it nullable');

    Generator.Parse(TDemoDataRepository.Load('Type Unification - Objects.json'));
    ItemClass := Generator.Model.RootClass.FindField('people').DataType.ElementType.ObjectClass;
    Check(ItemClass.FindField('id').DataType.SemanticKind = svkInteger64,
      'Object demo must unify field types');
    Check(ItemClass.FindField('name').IsOptional and ItemClass.FindField('active').IsOptional and
      ItemClass.FindField('email').IsOptional, 'Object demo must mark missing fields optional');

    Generator.Parse(TDemoDataRepository.Load('Type Unification - Nested Arrays.json'));
    DataType := Generator.Model.RootClass.FindField('matrix').DataType;
    Check((DataType.ArrayDepth = 2) and (DataType.LeafType.SemanticKind = svkFloat) and
      DataType.LeafType.Nullable, 'Nested array demo must recursively unify its leaf type');
  finally
    Generator.Free;
  end;
end;


function GetGeneratorSmokeTests: TArray<TTestCase>;
begin
  Result := [
    TTestCase.Create('Object generation', TestObjectGeneration),
    TTestCase.Create('Primitive root array', TestPrimitiveRootArray),
    TTestCase.Create('Empty array', TestEmptyArray),
    TTestCase.Create('Two-dimensional array', TestTwoDimensionalArray),
    TTestCase.Create('Two-dimensional array runtime', TestTwoDimensionalArrayRuntime),
    TTestCase.Create('Language-independent model', TestLanguageIndependentModel),
    TTestCase.Create('Semantic type inference', TestSemanticTypeInference),
    TTestCase.Create('Delphi semantic type generation', TestDelphiSemanticTypeGeneration),
    TTestCase.Create('Array type conflict location', TestArrayTypeConflictLocation),
    TTestCase.Create('C# generation', TestCSharpGeneration),
    TTestCase.Create('C# semantic type generation', TestCSharpSemanticTypeGeneration),
    TTestCase.Create('C# semantic value type nullability', TestCSharpSemanticValueTypeNullability),
    TTestCase.Create('C# options', TestCSharpOptions),
    TTestCase.Create('Settings serialization', TestSettingsSerialization),
    TTestCase.Create('Demo data discovery', TestDemoDataDiscovery),
    TTestCase.Create('Semantic demo data', TestSemanticDemoData),
    TTestCase.Create('Type unification demo data', TestTypeUnificationDemoData)
  ];
end;

end.
