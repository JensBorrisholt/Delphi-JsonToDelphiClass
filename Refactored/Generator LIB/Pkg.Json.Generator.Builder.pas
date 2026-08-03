unit Pkg.Json.Generator.Builder;

interface

uses
  System.Json, System.SysUtils,
  Pkg.Json.Generator.Model, Pkg.Json.Generator.Naming,
  Pkg.Json.Generator.Options, Pkg.Json.Generator.Errors,
  Pkg.Json.JsonValueHelper;

type
  TJsonModelBuilder = class
  private
    FModel: TGeneratorModel;
    FNaming: TDelphiNaming;
    function AddClass(AParent: TGeneratorClass; const AJsonName: string; ANeedsSourceCode: Boolean = True): TGeneratorClass;
    function AddField(AClass: TGeneratorClass; const AJsonName: string; AKind: TGeneratorFieldKind; AValueType: TJsonType): TGeneratorField;
    function ArrayItemType(AArray: TJSONArray): TJsonType;
    function NestedArrayItemType(AArray: TJSONArray): TJsonType;
    procedure ProcessObject(AObject: TJSONObject; AClass: TGeneratorClass);
    procedure ProcessValue(const AJsonName: string; AValue: TJSONValue; AClass: TGeneratorClass);
  public
    constructor Create(AModel: TGeneratorModel; const AOptions: TGeneratorOptions);
    destructor Destroy; override;
    procedure Build(const AJson, ARootClassName: string);
  end;

implementation

uses
  Pkg.Json.Generator.Validation;

constructor TJsonModelBuilder.Create(AModel: TGeneratorModel; const AOptions: TGeneratorOptions);
begin
  inherited Create;
  FModel := AModel;
  FNaming := TDelphiNaming.Create(AOptions);
end;

destructor TJsonModelBuilder.Destroy;
begin
  FNaming.Free;
  inherited;
end;

function TJsonModelBuilder.AddClass(AParent: TGeneratorClass; const AJsonName: string; ANeedsSourceCode: Boolean): TGeneratorClass;
begin
  { Classes with the same JSON property name share one generated class.
    For example, customer.address and supplier.address both use TAddress.
    The lookup is limited to the model currently being generated. }
  Result := FModel.FindClass(AJsonName);
  if Result <> nil then
    Exit;
  Result := TGeneratorClass.Create;
  Result.Parent := AParent;
  Result.JsonName := AJsonName;
  Result.Name := FNaming.ClassName(AJsonName);
  Result.NeedsSourceCode := ANeedsSourceCode;
  FModel.Classes.Add(Result);
end;

function TJsonModelBuilder.AddField(AClass: TGeneratorClass; const AJsonName: string; AKind: TGeneratorFieldKind; AValueType: TJsonType): TGeneratorField;
begin
  Result := AClass.FindField(AJsonName);
  if Result <> nil then
    Exit;
  Result := TGeneratorField.Create;
  Result.JsonName := AJsonName;
  Result.DelphiName := FNaming.Identifier(AJsonName);
  Result.NeedsJsonNameAttribute := FNaming.NeedsJsonNameAttribute(AJsonName, Result.DelphiName);
  Result.Kind := AKind;
  Result.ValueType := AValueType;
  AClass.Fields.Add(Result);
end;

function TJsonModelBuilder.ArrayItemType(AArray: TJSONArray): TJsonType;
var
  Item: TJSONValue;
begin
  Result := jtUnknown;
  for Item in AArray do
  begin
    Result := TJsonValueHelper.GetJsonType(Item);
    if Result <> jtUnknown then
      Exit;
  end;
end;

function TJsonModelBuilder.NestedArrayItemType(
  AArray: TJSONArray): TJsonType;
var
  Item: TJSONValue;
begin
  Result := jtUnknown;
  for Item in AArray do
    if Item is TJSONArray then
    begin
      Result := ArrayItemType(TJSONArray(Item));
      if Result <> jtUnknown then
        Exit;
    end;
end;

procedure TJsonModelBuilder.Build(const AJson, ARootClassName: string);
var
  JsonValue: TJSONValue;
  Item: TJSONValue;
  ItemClass: TGeneratorClass;
  ItemType: TJsonType;
  GeneratorClass: TGeneratorClass;
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
    TJsonSourceValidator.ValidateArrayTypes(AJson);
    FModel.Clear;
    FModel.RootClass := AddClass(nil, ARootClassName);
    case TJsonValueHelper.GetJsonType(JsonValue) of
      jtObject:
        ProcessObject(TJSONObject(JsonValue), FModel.RootClass);
      jtArray:
        begin
          FModel.RootClass.ArrayProperty := 'Items';
          ItemType := ArrayItemType(TJSONArray(JsonValue));
          ItemClass := AddClass(FModel.RootClass, 'Items', ItemType = jtObject);
          RootField := AddField(FModel.RootClass, 'Items', gfArray, jtArray);
          RootField.ContainedType := ItemType;
          RootField.FieldClass := ItemClass;

          if ItemType = jtArray then
          begin
            RootField.ArrayDepth := 2;
            RootField.ContainedType := NestedArrayItemType(
              TJSONArray(JsonValue));
            if RootField.ContainedType = jtArray then
              raise EJsonGenerator.Create(
                'Arrays with more than two dimensions are not supported');
            if RootField.ContainedType = jtObject then
              raise EJsonGenerator.Create(
                'Two-dimensional object arrays are not supported');
          end;

          if ItemType = jtObject then
            for Item in TJSONArray(JsonValue) do
              if Item is TJSONObject then
                ProcessObject(TJSONObject(Item), ItemClass);
        end;
    else
      raise EJsonGenerator.Create('The JSON root must be an object or array');
    end;

    for GeneratorClass in FModel.Classes do
      GeneratorClass.SortFields;
  finally
    JsonValue.Free;
  end;
end;

procedure TJsonModelBuilder.ProcessObject(AObject: TJSONObject; AClass: TGeneratorClass);
var
  Pair: TJSONPair;
begin
  for Pair in AObject do
    ProcessValue(Pair.JsonString.Value, Pair.JsonValue, AClass);
end;

procedure TJsonModelBuilder.ProcessValue(const AJsonName: string; AValue: TJSONValue; AClass: TGeneratorClass);
var
  ArrayValue: TJSONArray;
  Field: TGeneratorField;
  FieldClass: TGeneratorClass;
  Item: TJSONValue;
  ItemType: TJsonType;
begin
  case TJsonValueHelper.GetJsonType(AValue) of
    jtObject:
      begin
        FieldClass := AddClass(AClass, AJsonName);
        Field := AddField(AClass, AJsonName, gfObject, jtObject);
        Field.FieldClass := FieldClass;
        ProcessObject(TJSONObject(AValue), FieldClass);
      end;
    jtArray:
      begin
        ArrayValue := TJSONArray(AValue);
        ItemType := ArrayItemType(ArrayValue);
        if ItemType = jtArray then
        begin
          Field := AddField(AClass, AJsonName, gfArray, jtArray);
          Field.ArrayDepth := 2;
          Field.ContainedType := NestedArrayItemType(ArrayValue);
          if Field.ContainedType = jtArray then
            raise EJsonGenerator.CreateFmt(
              'Arrays with more than two dimensions are not supported: %s',
              [AJsonName]);
          if Field.ContainedType = jtObject then
            raise EJsonGenerator.CreateFmt(
              'Two-dimensional object arrays are not supported: %s',
              [AJsonName]);
          Exit;
        end;
        FieldClass := AddClass(AClass, AJsonName, ItemType = jtObject);
        Field := AddField(AClass, AJsonName, gfArray, jtArray);
        Field.ContainedType := ItemType;
        Field.FieldClass := FieldClass;
        if ItemType = jtObject then
          for Item in ArrayValue do
            if Item is TJSONObject then
              ProcessObject(TJSONObject(Item), FieldClass);
      end;
  else
    AddField(AClass, AJsonName, gfScalar, TJsonValueHelper.GetJsonType(AValue));
  end;
end;

end.
