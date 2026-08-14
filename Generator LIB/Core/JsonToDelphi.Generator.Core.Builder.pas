unit JsonToDelphi.Generator.Core.Builder;

interface

uses
  System.Json, System.SysUtils, System.Generics.Collections,
  JsonToDelphi.Generator.Core.Model, JsonToDelphi.Generator.Core.Errors,
  JsonToDelphi.Generator.Core.Validation;

type
  TJsonModelBuilder = class
  private
    FModel: TGeneratorModel;
    FLocations: TDictionary<string, TJsonSourceLocation>;
    function AddClass(AParent: TGeneratorClass; const AJsonName, AJsonPath: string): TGeneratorClass;
    function AddField(AClass: TGeneratorClass; const AJsonName, AJsonPath: string): TGeneratorField;
    function ArrayType(AArray: TJSONArray; AParent: TGeneratorClass; const AJsonName, AJsonPath: string): TGeneratorType;
    function IsDate(const AValue: string): Boolean;
    function IsGuid(const AValue: string): Boolean;
    function IsTime(const AValue: string): Boolean;
    function IsUri(const AValue: string): Boolean;
    procedure MergeType(var ATarget: TGeneratorType; AObserved: TGeneratorType; const AJsonPath: string);
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
  JsonToDelphi.Runtime.JsonValueHelper,
  JsonToDelphi.Generator.Core.TypeUnification;

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
  MergedType: TGeneratorType;
  Index: Integer;
  ItemPath: string;
begin
  Result := TGeneratorType.Create(jvkArray);
  Index := 0;
  for Element in AArray do
  begin
    ItemPath := Format('%s[%d]', [AJsonPath, Index]);

    if Element is TJSONArray then
      ElementType := ArrayType(TJSONArray(Element), AParent, AJsonName, ItemPath)
    else if Element is TJSONObject then
    begin
      ElementClass := AddClass(AParent, AJsonName, AJsonPath + '[]');
      ElementType := TGeneratorType.Create(jvkObject, svkObject);
      ElementType.ObjectClass := ElementClass;
      ProcessObject(TJSONObject(Element), ElementClass, ItemPath);
    end
    else
      ElementType := ScalarType(Element);

    if Result.ElementType = nil then
      Result.ElementType := ElementType
    else
    begin
      MergedType := Result.ExtractElementType;
      MergeType(MergedType, ElementType, ItemPath);
      Result.ElementType := MergedType;
    end;
    Inc(Index);
  end;

  if Result.ElementType = nil then
    Result.ElementType := TGeneratorType.Create(jvkUnknown, svkUnknown);

  if Result.ArrayDepth > 2 then
    raise EJsonGenerator.CreateFmt('Arrays with more than two dimensions are not supported: %s', [AJsonName]);

  if Result.LeafType.SemanticKind = svkObject then
  begin
    ElementClass := Result.LeafType.ObjectClass;
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
  Objects: TList<TJSONObject>;
  Field: TGeneratorField;
  JsonObject: TJSONObject;

  procedure CollectObjects(AValue: TJSONValue);
  var
    Item: TJSONValue;
  begin
    if AValue is TJSONObject then
      Objects.Add(TJSONObject(AValue))
    else if AValue is TJSONArray then
      for Item in TJSONArray(AValue) do
        CollectObjects(Item);
  end;

begin
  Objects := TList<TJSONObject>.Create;
  try
    CollectObjects(AArray);
    for Field in AClass.Fields do
      for JsonObject in Objects do
        if JsonObject.GetValue(Field.JsonName) = nil then
        begin
          Field.IsOptional := True;
          Break;
        end;
  finally
    Objects.Free;
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

procedure TJsonModelBuilder.MergeType(var ATarget: TGeneratorType; AObserved: TGeneratorType;
  const AJsonPath: string);
var
  Location: TJsonSourceLocation;
begin
  if FLocations.TryGetValue(AJsonPath, Location) then
    TGeneratorTypeUnifier.Merge(ATarget, AObserved, AJsonPath, Location.Position, Location.Length)
  else
    TGeneratorTypeUnifier.Merge(ATarget, AObserved, AJsonPath);
end;

procedure TJsonModelBuilder.ProcessValue(const AJsonName, AJsonPath: string; AValue: TJSONValue; AClass: TGeneratorClass);
var
  Field: TGeneratorField;
  FieldClass: TGeneratorClass;
  ObservedType: TGeneratorType;
  TargetType: TGeneratorType;
begin
  Field := AddField(AClass, AJsonName, AJsonPath);

  if AValue is TJSONObject then
  begin
    FieldClass := AddClass(AClass, AJsonName, AJsonPath);
    ObservedType := TGeneratorType.Create(jvkObject, svkObject);
    ObservedType.ObjectClass := FieldClass;
    ProcessObject(TJSONObject(AValue), FieldClass, AJsonPath);
  end
  else if AValue is TJSONArray then
    ObservedType := ArrayType(TJSONArray(AValue), AClass, AJsonName, AJsonPath)
  else
    ObservedType := ScalarType(AValue);

  TargetType := Field.ExtractDataType;
  try
    MergeType(TargetType, ObservedType, AJsonPath);
    Field.DataType := TargetType;
    TargetType := nil;
  finally
    TargetType.Free;
  end;
end;


function TJsonModelBuilder.IsDate(const AValue: string): Boolean;
var
  Day: Integer;
  DateValue: TDateTime;
  Month: Integer;
  Year: Integer;
begin
  Result := False;
  if (Length(AValue) <> 10) or (AValue[5] <> '-') or (AValue[8] <> '-') then
    Exit;

  if not TryStrToInt(AValue.Substring(0, 4), Year) or
     not TryStrToInt(AValue.Substring(5, 2), Month) or
     not TryStrToInt(AValue.Substring(8, 2), Day) then
    Exit;

  if (Year < 1) or (Year > 9999) or (Month < 1) or (Month > 12) or (Day < 1) or (Day > 31) then
    Exit;

  Result := TryEncodeDate(Word(Year), Word(Month), Word(Day), DateValue);
end;

function TJsonModelBuilder.IsGuid(const AValue: string): Boolean;
var
  I: Integer;
  Value: string;
begin
  Value := AValue;
  if (Length(Value) = 38) and (Value[1] = '{') and (Value[38] = '}') then
    Value := Value.Substring(1, 36);

  Result := (Length(Value) = 36) and (Value[9] = '-') and (Value[14] = '-') and
    (Value[19] = '-') and (Value[24] = '-');
  if not Result then
    Exit;

  for I := 1 to Length(Value) do
    if not (I in [9, 14, 19, 24]) and not CharInSet(Value[I], ['0'..'9', 'A'..'F', 'a'..'f']) then
      Exit(False);
end;

function TJsonModelBuilder.IsTime(const AValue: string): Boolean;
var
  Hour: Integer;
  Minute: Integer;
  Second: Integer;
  Millisecond: Integer;
  TimeValue: TDateTime;
  Parts: TArray<string>;
  SecondParts: TArray<string>;
begin
  Result := False;
  Parts := AValue.Split([':']);
  if not (Length(Parts) in [2, 3]) then
    Exit;

  if (Length(Parts[0]) <> 2) or (Length(Parts[1]) <> 2) or
     not TryStrToInt(Parts[0], Hour) or not TryStrToInt(Parts[1], Minute) then
    Exit;

  Second := 0;
  Millisecond := 0;
  if Length(Parts) = 3 then
  begin
    SecondParts := Parts[2].Split(['.']);
    if (Length(SecondParts) < 1) or (Length(SecondParts) > 2) or (Length(SecondParts[0]) <> 2) or
       not TryStrToInt(SecondParts[0], Second) then
      Exit;

    if Length(SecondParts) = 2 then
    begin
      if (Length(SecondParts[1]) < 1) or (Length(SecondParts[1]) > 3) then
        Exit;
      while Length(SecondParts[1]) < 3 do
        SecondParts[1] := SecondParts[1] + '0';
      if not TryStrToInt(SecondParts[1], Millisecond) then
        Exit;
    end;
  end;

  if (Hour < 0) or (Hour > 23) or (Minute < 0) or (Minute > 59) or
     (Second < 0) or (Second > 59) or (Millisecond < 0) or (Millisecond > 999) then
    Exit;

  Result := TryEncodeTime(Word(Hour), Word(Minute), Word(Second), Word(Millisecond), TimeValue);
end;

function TJsonModelBuilder.IsUri(const AValue: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  if (AValue = '') or not CharInSet(AValue[1], ['A'..'Z', 'a'..'z']) then
    Exit;

  I := 2;
  while (I <= Length(AValue)) and (AValue[I] <> ':') do
  begin
    if not CharInSet(AValue[I], ['A'..'Z', 'a'..'z', '0'..'9', '+', '-', '.']) then
      Exit;
    Inc(I);
  end;

  Result := (I > 2) and (I <= Length(AValue)) and (AValue[I] = ':') and (I < Length(AValue)) and
    not AValue.Contains(' ') and not AValue.Contains(#9) and not AValue.Contains(#13) and not AValue.Contains(#10);
end;

function TJsonModelBuilder.ScalarType(AValue: TJSONValue): TGeneratorType;
var
  Value: string;
begin
  case TJsonValueHelper.GetJsonType(AValue) of
    jtObject:
      Result := TGeneratorType.Create(jvkObject, svkObject);
    jtArray:
      Result := TGeneratorType.Create(jvkArray);
    jtString:
      begin
        Value := AValue.AsType<string>;
        if IsGuid(Value) then
          Result := TGeneratorType.Create(jvkString, svkGuid)
        else if IsDate(Value) then
          Result := TGeneratorType.Create(jvkString, svkDate)
        else if IsTime(Value) then
          Result := TGeneratorType.Create(jvkString, svkTime)
        else if IsUri(Value) then
          Result := TGeneratorType.Create(jvkString, svkUri)
        else
          Result := TGeneratorType.Create(jvkString, svkString);
      end;
    jtTrue, jtFalse:
      Result := TGeneratorType.Create(jvkBoolean, svkBoolean);
    jtNumber:
      Result := TGeneratorType.Create(jvkNumber, svkFloat);
    jtDateTime:
      begin
        Value := AValue.AsType<string>;
        if IsDate(Value) then
          Result := TGeneratorType.Create(jvkString, svkDate)
        else if IsTime(Value) then
          Result := TGeneratorType.Create(jvkString, svkTime)
        else
          Result := TGeneratorType.Create(jvkString, svkDateTime);
      end;
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
