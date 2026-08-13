unit JsonToDelphi.Generator.Delphi.Writer;

interface

uses
  System.Classes, System.Generics.Collections,
  JsonToDelphi.Generator.Core.Model, JsonToDelphi.Generator.Delphi.Naming,
  JsonToDelphi.Generator.Delphi.Settings;

type
  TDelphiUnitWriter = class
  private
    FClassNames: TDictionary<TGeneratorClass, string>;
    FFieldNames: TDictionary<TGeneratorField, string>;
    FNaming: TDelphiNaming;
    FOptions: TDelphiSettings;
    function ArrayStorageType(AField: TGeneratorField): string;
    function ClassName(AClass: TGeneratorClass): string;
    function DateAttribute(AField: TGeneratorField): string;
    function FieldName(AField: TGeneratorField): string;
    function FieldType(AField: TGeneratorField): string;
    function HasArrays(AClass: TGeneratorClass): Boolean;
    function HasComplexFields(AClass: TGeneratorClass): Boolean;
    function HasMatrices(AModel: TGeneratorModel): Boolean;
    function HasObjectMatrix(AClass: TGeneratorClass): Boolean;
    function HasSemanticKind(AModel: TGeneratorModel; AKind: TSemanticValueKind): Boolean;
    function JsonNameAttribute(AField: TGeneratorField): string;
    function ListStorageType(AField: TGeneratorField): string;
    function ListType(AField: TGeneratorField): string;
    function NeedsJsonNameAttribute(AField: TGeneratorField): Boolean;
    procedure PrepareNames(AModel: TGeneratorModel);
    function PropertyName(AField: TGeneratorField): string;
    procedure WriteClassDeclaration(ALines: TStrings; AClass: TGeneratorClass; const ABaseClass: string);
    procedure WriteClassImplementation(ALines: TStrings; AClass: TGeneratorClass);
    procedure WriteForwardDeclarations(ALines: TStrings; AModel: TGeneratorModel);
  public
    constructor Create(const AOptions: TDelphiSettings);
    destructor Destroy; override;
    function GeneratedClassName(AModel: TGeneratorModel; AClass: TGeneratorClass): string;
    function WriteUnit(AModel: TGeneratorModel; const AUnitName: string): string;
  end;

implementation

uses
  System.SysUtils, System.StrUtils, JsonToDelphi.Runtime.ReservedWords;

constructor TDelphiUnitWriter.Create(const AOptions: TDelphiSettings);
begin
  inherited Create;
  FOptions := AOptions;
  FNaming := TDelphiNaming.Create(AOptions);
  FClassNames := TDictionary<TGeneratorClass, string>.Create;
  FFieldNames := TDictionary<TGeneratorField, string>.Create;
end;

destructor TDelphiUnitWriter.Destroy;
begin
  FFieldNames.Free;
  FClassNames.Free;
  FNaming.Free;
  inherited;
end;

function TDelphiUnitWriter.ArrayStorageType(AField: TGeneratorField): string;
begin
  if AField.DataType.ArrayDepth = 2 then
    Result := 'TArray<TArray<' + FieldType(AField) + '>>'
  else
    Result := 'TArray<' + FieldType(AField) + '>';
end;

function TDelphiUnitWriter.ClassName(AClass: TGeneratorClass): string;
begin
  if not FClassNames.TryGetValue(AClass, Result) then
    raise EInvalidOperation.CreateFmt('No Delphi name exists for model class %s', [AClass.Identity]);
end;

function TDelphiUnitWriter.DateAttribute(AField: TGeneratorField): string;
begin
  if FOptions.SuppressZeroDate and (AField.DataType.SemanticKind in [svkDate, svkDateTime]) then
    Result := 'SuppressZero'
  else
    Result := '';
end;

function TDelphiUnitWriter.FieldName(AField: TGeneratorField): string;
begin
  if not FFieldNames.TryGetValue(AField, Result) then
    raise EInvalidOperation.CreateFmt('No Delphi name exists for model field %s', [AField.JsonPath]);
end;

function TDelphiUnitWriter.HasObjectMatrix(AClass: TGeneratorClass): Boolean;
var
  Field: TGeneratorField;
begin
  for Field in AClass.Fields do
    if (Field.DataType.JsonKind = jvkArray) and
      (Field.DataType.ArrayDepth = 2) and
      (Field.DataType.LeafType.SemanticKind = svkObject) then
      Exit(True);
  Result := False;
end;

function TDelphiUnitWriter.FieldType(AField: TGeneratorField): string;
var
  DataType: TGeneratorType;
begin
  DataType := AField.DataType;
  if DataType.JsonKind = jvkArray then
    DataType := DataType.LeafType;

  if DataType = nil then
    Exit('string');

  if DataType.SemanticKind = svkObject then
    Exit(ClassName(DataType.ObjectClass));

  case DataType.SemanticKind of
    svkBoolean:
      Result := 'Boolean';
    svkFloat:
      Result := 'Double';
    svkDate:
      Result := 'TDate';
    svkTime:
      Result := 'TTime';
    svkDateTime:
      Result := 'TDateTime';
    svkGuid:
      Result := 'TGUID';
    svkUri:
      Result := 'TURI';
    svkBytes:
      Result := 'Byte';
    svkInteger:
      Result := 'Integer';
    svkInteger64:
      Result := 'Int64';
  else
    Result := 'string';
  end;
end;

function TDelphiUnitWriter.GeneratedClassName(AModel: TGeneratorModel; AClass: TGeneratorClass): string;
begin
  PrepareNames(AModel);
  Result := ClassName(AClass);
end;

function TDelphiUnitWriter.HasArrays(AClass: TGeneratorClass): Boolean;
var
  Field: TGeneratorField;
begin
  for Field in AClass.Fields do
    if Field.DataType.JsonKind = jvkArray then
      Exit(True);

  Result := False;
end;

function TDelphiUnitWriter.HasComplexFields(AClass: TGeneratorClass): Boolean;
var
  Field: TGeneratorField;
begin
  for Field in AClass.Fields do
    if Field.DataType.SemanticKind = svkObject then
      Exit(True);

  Result := False;
end;

function TDelphiUnitWriter.HasMatrices(AModel: TGeneratorModel): Boolean;
var
  GeneratorClass: TGeneratorClass;
  Field: TGeneratorField;
begin
  for GeneratorClass in AModel.Classes do
    for Field in GeneratorClass.Fields do
      if (Field.DataType.JsonKind = jvkArray) and (Field.DataType.ArrayDepth = 2) then
        Exit(True);
  Result := False;
end;

function TDelphiUnitWriter.HasSemanticKind(AModel: TGeneratorModel; AKind: TSemanticValueKind): Boolean;
var
  GeneratorClass: TGeneratorClass;
  Field: TGeneratorField;
begin
  for GeneratorClass in AModel.Classes do
    for Field in GeneratorClass.Fields do
      if (Field.DataType.LeafType <> nil) and (Field.DataType.LeafType.SemanticKind = AKind) then
        Exit(True);

  Result := False;
end;

function TDelphiUnitWriter.JsonNameAttribute(AField: TGeneratorField): string;
begin
  Result := 'JSONName(' + AnsiQuotedStr(AField.JsonName, #39) + ')';
end;

function TDelphiUnitWriter.ListStorageType(AField: TGeneratorField): string;
begin
  if AField.DataType.ArrayDepth = 2 then
    if AField.DataType.LeafType.SemanticKind = svkObject then
      Result := 'TObjectMatrix<' + FieldType(AField) + '>'
    else
      Result := 'TMatrix<' + FieldType(AField) + '>'
  else
    Result := ListType(AField) + '<' + FieldType(AField) + '>';
end;

function TDelphiUnitWriter.ListType(AField: TGeneratorField): string;
begin
  if AField.DataType.LeafType.SemanticKind = svkObject then
    Result := 'TObjectList'
  else
    Result := 'TList';
end;

function TDelphiUnitWriter.NeedsJsonNameAttribute(AField: TGeneratorField): Boolean;
begin
  Result := FNaming.NeedsJsonNameAttribute(AField.JsonName, FieldName(AField));
end;

procedure TDelphiUnitWriter.PrepareNames(AModel: TGeneratorModel);
var
  GeneratorClass: TGeneratorClass;
  Field: TGeneratorField;
begin
  FClassNames.Clear;
  FFieldNames.Clear;
  FreeAndNil(FNaming);
  FNaming := TDelphiNaming.Create(FOptions);

  for GeneratorClass in AModel.Classes do
  begin
    FClassNames.Add(GeneratorClass, FNaming.ClassName(GeneratorClass.JsonName));
    for Field in GeneratorClass.Fields do
      FFieldNames.Add(Field, FNaming.Identifier(Field.JsonName));
  end;
end;

function TDelphiUnitWriter.PropertyName(AField: TGeneratorField): string;
begin
  Result := FNaming.PropertyName(FieldName(AField));
end;

procedure TDelphiUnitWriter.WriteClassDeclaration(ALines: TStrings; AClass: TGeneratorClass; const ABaseClass: string);
var
  Attribute: string;
  BaseSuffix: string;
  Field: TGeneratorField;
  Name: string;
begin
  Name := ClassName(AClass);
  if ABaseClass = '' then
    BaseSuffix := ''
  else
    BaseSuffix := '(' + ABaseClass + ')';

  ALines.Add('  ' + Name + ' = class' + BaseSuffix);

  if AClass.Fields.Count > 0 then
    ALines.Add('  private');

  for Field in AClass.Fields do
    if Field.DataType.JsonKind = jvkArray then
    begin
      if not ((Field.DataType.ArrayDepth = 2) and
        (Field.DataType.LeafType.SemanticKind = svkObject)) then
      begin
        ALines.AddFormat('    [%s%s]', [JsonNameAttribute(Field),
          IfThen(Field.DataType.LeafType.SemanticKind = svkObject,
            ', JSONMarshalled(False)', '')]);
        ALines.AddFormat('    F%sArray: %s;', [FieldName(Field), ArrayStorageType(Field)]);
      end;

      if Field.DataType.ArrayDepth = 2 then
        ALines.Add('    [JSONMarshalled(False)]')
      else if Field.DataType.LeafType.SemanticKind = svkObject then
        ALines.Add('    [GenericListReflect]')
      else
        ALines.Add('    [JSONMarshalled(False)]');

      ALines.AddFormat('    F%s: %s;', [FieldName(Field), ListStorageType(Field)]);
    end
    else if Field.DataType.SemanticKind = svkObject then
    begin
      if NeedsJsonNameAttribute(Field) then
        ALines.Add('    [' + JsonNameAttribute(Field) + ']');

      ALines.AddFormat('    F%s: %s;', [FieldName(Field), FieldType(Field)]);
    end
    else
    begin
      Attribute := DateAttribute(Field);

      if NeedsJsonNameAttribute(Field) then
      begin
        if Attribute <> '' then
          Attribute := Attribute + ', ';
        Attribute := Attribute + JsonNameAttribute(Field);
      end;

      if Attribute <> '' then
        ALines.Add('    [' + Attribute + ']');

      ALines.AddFormat('    F%s: %s;', [FieldName(Field), FieldType(Field)]);
    end;

  for Field in AClass.Fields do
    if Field.DataType.JsonKind = jvkArray then
      ALines.AddFormat('    function Get%s: %s;', [FieldName(Field), ListStorageType(Field)]);

  if HasArrays(AClass) then
  begin
    ALines.Add('  protected');
    ALines.Add('    function GetAsJson: string; override;');
    if HasObjectMatrix(AClass) then
      ALines.Add('    procedure SetAsJson(aValue: string); override;');
  end;

  if AClass.Fields.Count > 0 then
    ALines.Add('  published');

  for Field in AClass.Fields do
    if Field.DataType.JsonKind = jvkArray then
    begin
      if (Field.DataType.ArrayDepth = 2) and
        (Field.DataType.LeafType.SemanticKind = svkObject) then
        ALines.Add('    [JSONMarshalled(False)]');
      ALines.AddFormat('    property %s: %s read Get%s;', [PropertyName(Field), ListStorageType(Field), FieldName(Field)])
    end
    else if Field.DataType.SemanticKind = svkObject then
      ALines.AddFormat('    property %s: %s read F%s;', [PropertyName(Field), FieldType(Field), FieldName(Field)])
    else
      ALines.AddFormat('    property %s: %s read F%s write F%s;', [PropertyName(Field), FieldType(Field), FieldName(Field), FieldName(Field)]);

  if HasComplexFields(AClass) or HasArrays(AClass) then
  begin
    ALines.Add('  public');
    if HasComplexFields(AClass) then
      ALines.Add('    constructor Create;' + IfThen(ABaseClass <> '', ' override;', ''));
    ALines.Add('    destructor Destroy; override;');
  end;

  ALines.Add('  end;');
  ALines.Add('');
end;

procedure TDelphiUnitWriter.WriteClassImplementation(ALines: TStrings; AClass: TGeneratorClass);
var
  Field: TGeneratorField;
  Name: string;
  Prefix: string;
begin
  if not(HasComplexFields(AClass) or HasArrays(AClass)) then
    Exit;

  Name := ClassName(AClass);
  ALines.Add('');
  ALines.AddFormat('{ %s }', [Name]);
  ALines.Add('');

  if HasComplexFields(AClass) then
  begin
    ALines.AddFormat('constructor %s.Create;', [Name]);
    ALines.Add('begin');
    ALines.Add('  inherited;');
    for Field in AClass.Fields do
      if Field.DataType.SemanticKind = svkObject then
        ALines.AddFormat('  F%s := %s.Create;', [FieldName(Field), FieldType(Field)]);
    ALines.Add('end;');
    ALines.Add('');
  end;

  ALines.AddFormat('destructor %s.Destroy;', [Name]);
  ALines.Add('begin');

  for Field in AClass.Fields do
    if Field.DataType.SemanticKind = svkObject then
      ALines.AddFormat('  F%s.Free;', [FieldName(Field)])
    else if Field.DataType.JsonKind = jvkArray then
      ALines.AddFormat('  F%s.Free;', [FieldName(Field)]);

  ALines.Add('  inherited;');
  ALines.Add('end;');

  for Field in AClass.Fields do
    if Field.DataType.JsonKind = jvkArray then
    begin
      if Field.DataType.ArrayDepth = 2 then
      begin
        ALines.Add('');
        ALines.AddFormat('function %s.Get%s: %s;', [Name, FieldName(Field), ListStorageType(Field)]);
        ALines.Add('begin');
        ALines.AddFormat('  if F%s = nil then', [FieldName(Field)]);
        if Field.DataType.LeafType.SemanticKind = svkObject then
          ALines.AddFormat('    F%s := TObjectMatrix<%s>.Create;',
            [FieldName(Field), FieldType(Field)])
        else
          ALines.AddFormat('    F%s := TMatrix<%s>.Create(F%sArray);',
            [FieldName(Field), FieldType(Field), FieldName(Field)]);
        ALines.AddFormat('  Result := F%s;', [FieldName(Field)]);
        ALines.Add('end;');
        Continue;
      end;

      if Field.DataType.LeafType.SemanticKind = svkObject then
        Prefix := 'Object'
      else
        Prefix := '';

      ALines.Add('');
      ALines.AddFormat('function %s.Get%s: T%sList<%s>;', [Name, FieldName(Field), Prefix, FieldType(Field)]);
      ALines.Add('begin');
      ALines.AddFormat('  Result := %sList<%s>(F%s, F%sArray);', [Prefix, FieldType(Field), FieldName(Field), FieldName(Field)]);
      ALines.Add('end;');
    end;

  if HasArrays(AClass) then
  begin
    ALines.Add('');
    ALines.AddFormat('function %s.GetAsJson: string;', [Name]);
    ALines.Add('begin');

    for Field in AClass.Fields do
      if Field.DataType.JsonKind = jvkArray then
        if Field.DataType.ArrayDepth = 2 then
        begin
          if Field.DataType.LeafType.SemanticKind <> svkObject then
          begin
            ALines.AddFormat('  if F%s <> nil then', [FieldName(Field)]);
            ALines.AddFormat('    F%sArray := F%s.ToArray;',
              [FieldName(Field), FieldName(Field)]);
          end;
        end
        else
          ALines.AddFormat('  RefreshArray<%s>(F%s, F%sArray);', [FieldType(Field), FieldName(Field), FieldName(Field)]);

    ALines.Add('  Result := inherited;');
    for Field in AClass.Fields do
      if (Field.DataType.JsonKind = jvkArray) and
        (Field.DataType.ArrayDepth = 2) and
        (Field.DataType.LeafType.SemanticKind = svkObject) then
        ALines.AddFormat('  Result := SaveObjectMatrix<%s>(F%s, Result, %s);',
          [FieldType(Field), FieldName(Field), QuotedStr(Field.JsonName)]);
    ALines.Add('end;');

    if HasObjectMatrix(AClass) then
    begin
      ALines.Add('');
      ALines.AddFormat('procedure %s.SetAsJson(aValue: string);', [Name]);
      ALines.Add('begin');
      Prefix := '';
      for Field in AClass.Fields do
        if (Field.DataType.JsonKind = jvkArray) and
          (Field.DataType.ArrayDepth = 2) and
          (Field.DataType.LeafType.SemanticKind = svkObject) then
        begin
          if Prefix <> '' then
            Prefix := Prefix + ', ';
          Prefix := Prefix + QuotedStr(Field.JsonName);
        end;
      ALines.AddFormat('  SetAsJsonWithoutFields(aValue, [%s]);', [Prefix]);
      for Field in AClass.Fields do
        if (Field.DataType.JsonKind = jvkArray) and
          (Field.DataType.ArrayDepth = 2) and
          (Field.DataType.LeafType.SemanticKind = svkObject) then
        begin
          ALines.AddFormat('  Get%s;', [FieldName(Field)]);
          ALines.AddFormat('  LoadObjectMatrix<%s>(F%s, aValue, %s);',
            [FieldType(Field), FieldName(Field), QuotedStr(Field.JsonName)]);
        end;
      ALines.Add('end;');
    end;
  end;
end;

procedure TDelphiUnitWriter.WriteForwardDeclarations(ALines: TStrings; AModel: TGeneratorModel);
var
  Field: TGeneratorField;
  I: Integer;
  Names: TStringList;
begin
  Names := TStringList.Create;
  try
    Names.Sorted := True;
    Names.Duplicates := dupIgnore;
    for I := AModel.Classes.Count - 1 downto 1 do
      for Field in AModel.Classes[I].Fields do
        if (Field.DataType.SemanticKind = svkObject) or ((Field.DataType.JsonKind = jvkArray) and (Field.DataType.LeafType.SemanticKind = svkObject)) then
          Names.Add(ClassName(Field.DataType.LeafType.ObjectClass));

    { Retain the legacy output rule. A single subtype does not require a forward declaration with the current reverse declaration order. }
    if Names.Count > 1 then
    begin
      for I := 0 to Names.Count - 1 do
        ALines.AddFormat('  %s = class;', [Names[I]]);
      ALines.Add('');
    end;

  finally
    Names.Free;
  end;
end;

function TDelphiUnitWriter.WriteUnit(AModel: TGeneratorModel; const AUnitName: string): string;
var
  BaseClass: string;
  I: Integer;
  Lines: TStringList;
begin
  if AModel.RootClass = nil then
    raise EInvalidOperation.Create('No model has been built');
  PrepareNames(AModel);
  Lines := TStringList.Create;
  try
    Lines.TrailingLineBreak := False;
    Lines.Add('unit ' + AUnitName + ';');
    Lines.Add('');
    Lines.Add('interface');
    Lines.Add('');
    Lines.Add('uses');
    BaseClass := '  JsonToDelphi.Runtime.DTO';
    if HasMatrices(AModel) then
      BaseClass := BaseClass + ', JsonToDelphi.Runtime.Matrix';
    BaseClass := BaseClass + ', System.Generics.Collections';
    if HasSemanticKind(AModel, svkUri) then
      BaseClass := BaseClass + ', System.Net.URLClient';
    Lines.Add(BaseClass + ', REST.Json.Types;');
    Lines.Add('');
    Lines.Add('{$M+}');
    Lines.Add('');
    Lines.Add('type');

    WriteForwardDeclarations(Lines, AModel);

    for I := AModel.Classes.Count - 1 downto 1 do
    begin
      if HasArrays(AModel.Classes[I]) then
        BaseClass := 'TJsonDTO'
      else
        BaseClass := '';
      WriteClassDeclaration(Lines, AModel.Classes[I], BaseClass);
    end;

    WriteClassDeclaration(Lines, AModel.RootClass, 'TJsonDTO');
    Lines.Add('implementation');

    for I := AModel.Classes.Count - 1 downto 0 do
      WriteClassImplementation(Lines, AModel.Classes[I]);

    Lines.Add('');
    Lines.Add('end.');
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

end.
