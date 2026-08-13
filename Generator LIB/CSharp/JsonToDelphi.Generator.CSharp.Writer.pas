unit JsonToDelphi.Generator.CSharp.Writer;

interface

uses
  System.Classes, System.Generics.Collections,
  JsonToDelphi.Generator.Core.Model,
  JsonToDelphi.Generator.CSharp.Naming,
  JsonToDelphi.Generator.CSharp.Settings;

type
  TCSharpWriter = class
  private
    FClassNames: TDictionary<TGeneratorClass, string>;
    FPropertyNames: TDictionary<TGeneratorField, string>;
    FNaming: TCSharpNaming;
    FSettings: TCSharpSettings;
    function ClassName(AClass: TGeneratorClass): string;
    function FieldType(AField: TGeneratorField): string;
    function IsValueType(AType: TGeneratorType): Boolean;
    function JsonPropertyNameAttribute(AField: TGeneratorField): string;
    function PropertyInitializer(AField: TGeneratorField): string;
    function PropertyName(AField: TGeneratorField): string;
    function TypeName(AType: TGeneratorType): string;
    procedure PrepareNames(AModel: TGeneratorModel);
    procedure WriteClass(ALines: TStrings; AClass: TGeneratorClass);
  public
    constructor Create(const ASettings: TCSharpSettings);
    destructor Destroy; override;
    function GeneratedClassName(AModel: TGeneratorModel; AClass: TGeneratorClass): string;
    function WriteSource(AModel: TGeneratorModel): string;
  end;

implementation

uses
  System.SysUtils;

constructor TCSharpWriter.Create(const ASettings: TCSharpSettings);
begin
  inherited Create;
  FSettings := ASettings;
  FNaming := TCSharpNaming.Create(ASettings);
  FClassNames := TDictionary<TGeneratorClass, string>.Create;
  FPropertyNames := TDictionary<TGeneratorField, string>.Create;
end;

destructor TCSharpWriter.Destroy;
begin
  FPropertyNames.Free;
  FClassNames.Free;
  FNaming.Free;
  inherited;
end;

function TCSharpWriter.ClassName(AClass: TGeneratorClass): string;
begin
  if not FClassNames.TryGetValue(AClass, Result) then
    raise EInvalidOperation.CreateFmt('No C# name exists for model class %s', [AClass.Identity]);
end;

function TCSharpWriter.FieldType(AField: TGeneratorField): string;
var
  Nullable: Boolean;
begin
  Result := TypeName(AField.DataType);
  Nullable := AField.DataType.Nullable or AField.IsOptional;

  if FSettings.UseNullableTypes and IsValueType(AField.DataType) then
    Nullable := True;

  if Nullable and not Result.EndsWith('?') then
    Result := Result + '?';
end;

function TCSharpWriter.GeneratedClassName(AModel: TGeneratorModel; AClass: TGeneratorClass): string;
begin
  PrepareNames(AModel);
  Result := ClassName(AClass);
end;

function TCSharpWriter.IsValueType(AType: TGeneratorType): Boolean;
var
  Leaf: TGeneratorType;
begin
  if AType.JsonKind = jvkArray then
    Exit(False);

  Leaf := AType.LeafType;
  Result := (Leaf <> nil) and (Leaf.SemanticKind in [svkBoolean, svkInteger, svkInteger64, svkFloat, svkDate, svkTime, svkDateTime, svkGuid, svkBytes]);
end;

function TCSharpWriter.JsonPropertyNameAttribute(AField: TGeneratorField): string;
begin
  Result := Format('[JsonPropertyName("%s")]', [AField.JsonName.Replace('"', '\"')]);
end;

function TCSharpWriter.PropertyInitializer(AField: TGeneratorField): string;
var
  DataType: TGeneratorType;
begin
  Result := '';
  DataType := AField.DataType;

  if DataType.JsonKind = jvkArray then
  begin
    if not (DataType.Nullable or AField.IsOptional) then
      Exit(' = [];');
    Exit;
  end;

  if DataType.SemanticKind = svkObject then
  begin
    if not (DataType.Nullable or AField.IsOptional) then
      Exit(' = new();');
    Exit;
  end;

  if (DataType.SemanticKind = svkString) and not (DataType.Nullable or AField.IsOptional) then
    Result := ' = string.Empty;';
  if (DataType.SemanticKind = svkUnknown) and not (DataType.Nullable or AField.IsOptional) then
    Result := ' = new object();';
end;

function TCSharpWriter.PropertyName(AField: TGeneratorField): string;
begin
  if not FPropertyNames.TryGetValue(AField, Result) then
    raise EInvalidOperation.CreateFmt('No C# name exists for model field %s', [AField.JsonPath]);
end;

procedure TCSharpWriter.PrepareNames(AModel: TGeneratorModel);
var
  GeneratorClass: TGeneratorClass;
  Field: TGeneratorField;
begin
  FClassNames.Clear;
  FPropertyNames.Clear;
  FreeAndNil(FNaming);
  FNaming := TCSharpNaming.Create(FSettings);

  for GeneratorClass in AModel.Classes do
  begin
    FClassNames.Add(GeneratorClass, FNaming.ClassName(GeneratorClass.JsonName));
    for Field in GeneratorClass.Fields do
      FPropertyNames.Add(Field, FNaming.Identifier(Field.JsonName));
  end;
end;

function TCSharpWriter.TypeName(AType: TGeneratorType): string;
var
  ElementName: string;
begin
  if AType = nil then
    Exit('string');

  if AType.JsonKind = jvkArray then
  begin
    ElementName := TypeName(AType.ElementType);
    if FSettings.UseReadonlyLists then
      Exit('IReadOnlyList<' + ElementName + '>');
    Exit('List<' + ElementName + '>');
  end;

  if AType.SemanticKind = svkObject then
    Exit(ClassName(AType.ObjectClass));

  case AType.SemanticKind of
    svkBoolean:
      Result := 'bool';
    svkInteger:
      Result := 'int';
    svkInteger64:
      Result := 'long';
    svkFloat:
      Result := 'double';
    svkDate:
      Result := 'DateOnly';
    svkTime:
      Result := 'TimeOnly';
    svkDateTime:
      Result := 'DateTimeOffset';
    svkGuid:
      Result := 'Guid';
    svkUri:
      Result := 'Uri';
    svkBytes:
      Result := 'byte';
  else
    Result := 'object';
  end;
end;

procedure TCSharpWriter.WriteClass(ALines: TStrings; AClass: TGeneratorClass);
var
  Accessor: string;
  Field: TGeneratorField;
  Kind: string;
begin
  if FSettings.UseRecords then
    Kind := 'record'
  else
    Kind := 'class';

  ALines.Add(Format('public sealed %s %s', [Kind, ClassName(AClass)]));
  ALines.Add('{');

  if FSettings.GenerateImmutableClasses or FSettings.UseRecords then
    Accessor := 'init'
  else
    Accessor := 'set';

  for Field in AClass.Fields do
  begin
    if FNaming.NeedsJsonPropertyNameAttribute(Field.JsonName, PropertyName(Field)) then
      ALines.Add('    ' + JsonPropertyNameAttribute(Field));
    ALines.Add(Format('    public %s %s { get; %s; }%s', [FieldType(Field), PropertyName(Field), Accessor, PropertyInitializer(Field)]));
  end;

  ALines.Add('}');
  ALines.Add('');
end;

function TCSharpWriter.WriteSource(AModel: TGeneratorModel): string;
var
  GeneratorClass: TGeneratorClass;
  Lines: TStringList;
begin
  PrepareNames(AModel);
  Lines := TStringList.Create;
  try
    Lines.LineBreak := sLineBreak;
    Lines.Add('#nullable enable');
    Lines.Add('');
    Lines.Add('using System;');
    Lines.Add('using System.Collections.Generic;');
    Lines.Add('using System.Text.Json.Serialization;');
    Lines.Add('');

    if FSettings.NamespaceName.Trim <> '' then
    begin
      Lines.Add('namespace ' + FSettings.NamespaceName.Trim + ';');
      Lines.Add('');
    end;

    for GeneratorClass in AModel.Classes do
      WriteClass(Lines, GeneratorClass);

    Lines.TrailingLineBreak := False;
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

end.
