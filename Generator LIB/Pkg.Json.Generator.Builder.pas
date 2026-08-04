unit Pkg.Json.Generator.Builder;

interface

uses
  System.Json, System.SysUtils, System.Generics.Collections,
  Pkg.Json.Generator.Model, Pkg.Json.Generator.Errors,
  Pkg.Json.Generator.Validation;

type
  TJsonModelBuilder = class
  private
    FModel: TGeneratorModel;
    FLocations: TDictionary<string, TJsonSourceLocation>;
    function AddClass(AParent: TGeneratorClass; const AJsonName, AJsonPath: string): TGeneratorClass;
    function AddField(AClass: TGeneratorClass; const AJsonName, AJsonPath: string): TGeneratorField;
    function ArrayType(AArray: TJSONArray; AParent: TGeneratorClass; const AJsonName, AJsonPath: string): TGeneratorType;
    function ScalarType(AValue: TJSONValue): TGeneratorType;
    procedure MarkOptionalFields(AArray: TJSONArray; AClass: TGeneratorClass);
    procedure ProcessObject(AObject: TJSONObject; AClass: TGeneratorClass; const AJsonPath: string);
    procedure ProcessValue(const AJsonName, AJsonPath: string; AValue: TJSONValue; AClass: TGeneratorClass);
  public
    constructor Create(AModel: TGeneratorModel);
    destructor Destroy; override;
    procedure Build(const AJson, ARootClassName: string);
  end;

implementation

uses
  Pkg.Json.JsonValueHelper;

constructor TJsonModelBuilder.Create(AModel: TGeneratorModel);
begin
  inherited Create;
  FModel := AModel;
  FLocations := TDictionary<string, TJsonSourceLocation>.Create;
end;

destructor TJsonModelBuilder.Destroy;
begin
  FLocations.Free;
  inherited;
end;

function TJsonModelBuilder.AddClass(AParent: TGeneratorClass; const AJsonName, AJsonPath: string): TGeneratorClass;
begin
  {
    Keep legacy class reuse by JSON property name.
    Identity is deliberately stored separately from any language-specific generated class name.
  }
  Result := FModel.FindClass(AJsonName);
  if Result <> nil then
    Exit;

  Result := TGeneratorClass.Create;
  Result.Parent := AParent;
  Result.JsonName := AJsonName;
  Result.JsonPath := AJsonPath;
  Result.Identity := AJsonPath;
  FModel.Classes.Add(Result);
end;

function TJsonModelBuilder.AddField(AClass: TGeneratorClass; const AJsonName, AJsonPath: string): TGeneratorField;
var
  Location: TJsonSourceLocation;
begin
  Result := AClass.FindField(AJsonName);
  if Result <> nil then
    Exit;

  Result := TGeneratorField.Create;
  Result.JsonName := AJsonName;
  Result.JsonPath := AJsonPath;

  if FLocations.TryGetValue(AJsonPath, Location) then
  begin
    Result.SourcePosition := Location.Position;
    Result.SourceLength := Location.Length;
  end;

  AClass.Fields.Add(Result);
end;

function TJsonModelBuilder.ArrayType(AArray: TJSONArray; AParent: TGeneratorClass; const AJsonName, AJsonPath: string): TGeneratorType;
var
  Element: TJSONValue;
  ElementClass: TGeneratorClass;
  ElementType: TGeneratorType;
begin
  Result := TGeneratorType.Create(jvkArray);
  for Element in AArray do
  begin
    if Element is TJSONNull then
      Continue;

    if Element is TJSONArray then
      ElementType := ArrayType(TJSONArray(Element), AParent, AJsonName, AJsonPath + '[]')
    else if Element is TJSONObject then
    begin
      ElementClass := AddClass(AParent, AJsonName, AJsonPath + '[]');
      ElementType := TGeneratorType.Create(jvkObject, svkObject);
      ElementType.ObjectClass := ElementClass;
      ProcessObject(TJSONObject(Element), ElementClass, AJsonPath + '[]');
    end
    else
      ElementType := ScalarType(Element);

    if Result.ElementType = nil then
      Result.ElementType := ElementType
    else
    begin
      if (Result.ElementType.SemanticKind = svkInteger) and (ElementType.SemanticKind in [svkInteger64, svkFloat]) then
        Result.ElementType.SemanticKind := ElementType.SemanticKind
      else if (Result.ElementType.SemanticKind = svkInteger64) and (ElementType.SemanticKind = svkFloat) then
        Result.ElementType.SemanticKind := svkFloat;
      ElementType.Free;
    end;
  end;

  if Result.ElementType = nil then
    Result.ElementType := TGeneratorType.Create(jvkUnknown, svkUnknown);

  if Result.ArrayDepth > 2 then
    raise EJsonGenerator.CreateFmt('Arrays with more than two dimensions are not supported: %s', [AJsonName]);

  if (Result.ArrayDepth = 2) and (Result.LeafType.SemanticKind = svkObject) then
    raise EJsonGenerator.CreateFmt('Two-dimensional object arrays are not supported: %s', [AJsonName]);

  if Result.ElementType.SemanticKind = svkObject then
  begin
    ElementClass := Result.ElementType.ObjectClass;
    for Element in AArray do
      if Element is TJSONObject then
        ProcessObject(TJSONObject(Element), ElementClass, AJsonPath + '[]');

    MarkOptionalFields(AArray, ElementClass);
  end;
end;

procedure TJsonModelBuilder.Build(const AJson, ARootClassName: string);
var
  GeneratorClass: TGeneratorClass;
  JsonValue: TJSONValue;
  RootField: TGeneratorField;
begin
  if AJson.Trim = '' then
    raise EJsonGenerator.Create('JSON must be provided');

  if ARootClassName.Trim = '' then
    raise EJsonGenerator.Create('Root class name must be provided');

  JsonValue := TJSONObject.ParseJSONValue(AJson);
  if JsonValue = nil then
    raise EJsonGenerator.Create('Unable to parse the JSON string');

  try
    TJsonSourceValidator.ValidateArrayTypes(AJson, FLocations);
    FModel.Clear;
    FModel.RootClass := AddClass(nil, ARootClassName, '$');

    if JsonValue is TJSONObject then
      ProcessObject(TJSONObject(JsonValue), FModel.RootClass, '$')
    else if JsonValue is TJSONArray then
    begin
      RootField := AddField(FModel.RootClass, 'Items', '$');
      RootField.DataType := ArrayType(TJSONArray(JsonValue), FModel.RootClass, 'Items', '$');
    end
    else
      raise EJsonGenerator.Create('The JSON root must be an object or array');

    for GeneratorClass in FModel.Classes do
      GeneratorClass.SortFields;
  finally
    JsonValue.Free;
  end;
end;

procedure TJsonModelBuilder.MarkOptionalFields(AArray: TJSONArray; AClass: TGeneratorClass);
var
  Element: TJSONValue;
  Field: TGeneratorField;
begin
  for Field in AClass.Fields do
    for Element in AArray do
      if (Element is TJSONObject) and (TJSONObject(Element).GetValue(Field.JsonName) = nil) then
      begin
        Field.IsOptional := True;
        Break;
      end;
end;

procedure TJsonModelBuilder.ProcessObject(AObject: TJSONObject; AClass: TGeneratorClass; const AJsonPath: string);
var
  Pair: TJSONPair;
  Path: string;
begin
  for Pair in AObject do
  begin
    if AJsonPath = '$' then
      Path := '$.' + Pair.JsonString.Value
    else
      Path := AJsonPath + '.' + Pair.JsonString.Value;

    ProcessValue(Pair.JsonString.Value, Path, Pair.JsonValue, AClass);
  end;
end;

procedure TJsonModelBuilder.ProcessValue(const AJsonName, AJsonPath: string; AValue: TJSONValue; AClass: TGeneratorClass);
var
  Field: TGeneratorField;
  FieldClass: TGeneratorClass;
begin
  Field := AddField(AClass, AJsonName, AJsonPath);
  if Field.DataType <> nil then
  begin
    if AValue is TJSONNull then
      Field.DataType.Nullable := True;
    Exit;
  end;

  if AValue is TJSONObject then
  begin
    FieldClass := AddClass(AClass, AJsonName, AJsonPath);
    Field.DataType := TGeneratorType.Create(jvkObject, svkObject);
    Field.DataType.ObjectClass := FieldClass;
    ProcessObject(TJSONObject(AValue), FieldClass, AJsonPath);
  end
  else if AValue is TJSONArray then
    Field.DataType := ArrayType(TJSONArray(AValue), AClass, AJsonName, AJsonPath)
  else
    Field.DataType := ScalarType(AValue);
end;

function TJsonModelBuilder.ScalarType(AValue: TJSONValue): TGeneratorType;
begin
  case TJsonValueHelper.GetJsonType(AValue) of
    jtObject:
      Result := TGeneratorType.Create(jvkObject, svkObject);
    jtArray:
      Result := TGeneratorType.Create(jvkArray);
    jtString:
      Result := TGeneratorType.Create(jvkString, svkString);
    jtTrue, jtFalse:
      Result := TGeneratorType.Create(jvkBoolean, svkBoolean);
    jtNumber:
      Result := TGeneratorType.Create(jvkNumber, svkFloat);
    jtDateTime:
      Result := TGeneratorType.Create(jvkString, svkDateTime);
    jtBytes:
      Result := TGeneratorType.Create(jvkString, svkBytes);
    jtInteger:
      Result := TGeneratorType.Create(jvkNumber, svkInteger);
    jtInteger64:
      Result := TGeneratorType.Create(jvkNumber, svkInteger64);
  else
    begin
      if AValue is TJSONNull then
      begin
        Result := TGeneratorType.Create(jvkNull, svkUnknown);
        Result.Nullable := True;
      end
      else
        Result := TGeneratorType.Create(jvkUnknown, svkUnknown);
    end;
  end;
end;

end.
