program GeneratorSmokeTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Generics.Collections,
  REST.Json.Types,
  Pkg.Json.DTO,
  Pkg.Json.Generator in '..\Pkg.Json.Generator.pas',
  Pkg.Json.Generator.Builder in '..\Pkg.Json.Generator.Builder.pas',
  Pkg.Json.Generator.Errors in '..\Pkg.Json.Generator.Errors.pas',
  Pkg.Json.Generator.DelphiWriter in '..\Pkg.Json.Generator.DelphiWriter.pas',
  Pkg.Json.Generator.Model in '..\Pkg.Json.Generator.Model.pas',
  Pkg.Json.Generator.Naming in '..\Pkg.Json.Generator.Naming.pas',
  Pkg.Json.Generator.Options in '..\Pkg.Json.Generator.Options.pas';

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
    property Matrix: TObjectList<TList<Integer>> read GetMatrix;
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

procedure TestTwoDimensionalArray;
var
  Generator: TJsonToDelphiGenerator;
  Source: string;
begin
  Generator := TJsonToDelphiGenerator.Create(DefaultOptions);
  try
    Generator.Parse('[[1,2],[3,4]]');
    Source := Generator.GenerateUnit;
    Check(Source.Contains('FItemsArray: TArray<TArray<Integer>>;'),
      '2D array bridge must preserve the JSON array shape');
    Check(Source.Contains('property Items: TObjectList<TList<Integer>>'),
      '2D arrays must be exposed as lists');
    Check(Source.Contains('RefreshArray2D<Integer>'),
      '2D lists must be synchronized before serialization');
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
    Check(Json.Contains('[[1,2],[30,4]]'),
      'Changed 2D list values must serialize as nested JSON arrays');
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
  Generator := TJsonToDelphiGenerator.Create(DefaultOptions);
  try
    Generator.Parse('{"enabled":true,' +
      '"created":"2025-01-02T03:04:05Z","maybe":null,' +
      '"matrix":[[1,2],[3,4]],"rows":[{"a":1},{"b":2}]}');
    Check(Generator.Model.RootClass.FindField('enabled').DataType.JsonKind =
      jvkBoolean, 'Boolean values must have one neutral JSON kind');
    Check(Generator.Model.RootClass.FindField('created').DataType.JsonKind =
      jvkString, 'Date-time values must retain their JSON string kind');
    Check(Generator.Model.RootClass.FindField('created').DataType.SemanticKind =
      svkDateTime, 'Date-time interpretation must be stored separately');
    MaybeField := Generator.Model.RootClass.FindField('maybe');
    Check(MaybeField.DataType.Nullable,
      'JSON null must be represented explicitly in the model');
    Check(MaybeField.JsonPath = '$.maybe',
      'Fields must retain their JSON source path');
    Check((MaybeField.SourcePosition >= 0) and
      (MaybeField.SourceLength = Length('null')),
      'Fields must retain their JSON source range');
    MatrixField := Generator.Model.RootClass.FindField('matrix');
    Check(MatrixField.DataType.ArrayDepth = 2,
      'Array dimensions must be represented recursively');
    Check(MatrixField.DataType.ElementType.ElementType.SemanticKind =
      svkInteger, 'The recursive array leaf type must be neutral');
    RowsClass := Generator.Model.FindClass('rows');
    Check((RowsClass <> nil) and (RowsClass.Identity = '$.rows[]'),
      'Class identity must be independent of a generated language name');
    Check(RowsClass.FindField('a').IsOptional and
      RowsClass.FindField('b').IsOptional,
      'Missing object members must be represented as optional');
  finally
    Generator.Free;
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
    Writeln('All generator smoke tests passed.');
  except
    on E: Exception do
    begin
      Writeln(E.ClassName + ': ' + E.Message);
      Halt(1);
    end;
  end;
end.
