unit Pkg.Json.Generator.DelphiWriter;

interface

uses
  System.Classes,
  Pkg.Json.Generator.Model, Pkg.Json.Generator.Options;

type
  TDelphiUnitWriter = class
  private
    FOptions: TGeneratorOptions;
    function DateAttribute(AField: TGeneratorField): string;
    function FieldType(AField: TGeneratorField): string;
    function HasArrays(AClass: TGeneratorClass): Boolean;
    function HasComplexFields(AClass: TGeneratorClass): Boolean;
    function JsonNameAttribute(AField: TGeneratorField): string;
    function ListType(AField: TGeneratorField): string;
    function ListStorageType(AField: TGeneratorField): string;
    function PropertyName(AField: TGeneratorField): string;
    function ArrayStorageType(AField: TGeneratorField): string;
    procedure WriteClassDeclaration(ALines: TStrings; AClass: TGeneratorClass;
      const ABaseClass: string);
    procedure WriteClassImplementation(ALines: TStrings; AClass: TGeneratorClass);
    procedure WriteForwardDeclarations(ALines: TStrings; AModel: TGeneratorModel);
  public
    constructor Create(const AOptions: TGeneratorOptions);
    function WriteUnit(AModel: TGeneratorModel; const AUnitName: string): string;
  end;

implementation

uses
  System.Generics.Collections, System.SysUtils, System.StrUtils,
  Pkg.Json.JsonValueHelper, Pkg.Json.ReservedWords;

constructor TDelphiUnitWriter.Create(const AOptions: TGeneratorOptions);
begin
  inherited Create;
  FOptions := AOptions;
end;

function TDelphiUnitWriter.DateAttribute(AField: TGeneratorField): string;
begin
  if FOptions.SuppressZeroDate and (AField.ValueType = jtDateTime) then
    Result := 'SuppressZero'
  else
    Result := '';
end;

function TDelphiUnitWriter.FieldType(AField: TGeneratorField): string;
var
  ValueType: TJsonType;
begin
  if AField.Kind = gfObject then
    Exit(AField.FieldClass.Name);
  if AField.Kind = gfArray then
  begin
    if AField.ContainedType = jtObject then
      Exit(AField.FieldClass.Name);
    ValueType := AField.ContainedType;
  end
  else
    ValueType := AField.ValueType;
  case ValueType of
    jtTrue, jtFalse: Result := 'Boolean';
    jtNumber: Result := 'Double';
    jtDateTime: Result := 'TDateTime';
    jtBytes: Result := 'Byte';
    jtInteger: Result := 'Integer';
    jtInteger64: Result := 'Int64';
  else
    Result := 'string';
  end;
end;

function TDelphiUnitWriter.HasArrays(AClass: TGeneratorClass): Boolean;
var
  Field: TGeneratorField;
begin
  for Field in AClass.Fields do
    if Field.Kind = gfArray then
      Exit(True);
  Result := False;
end;

function TDelphiUnitWriter.HasComplexFields(AClass: TGeneratorClass): Boolean;
var
  Field: TGeneratorField;
begin
  for Field in AClass.Fields do
    if Field.Kind = gfObject then
      Exit(True);
  Result := False;
end;

function TDelphiUnitWriter.JsonNameAttribute(AField: TGeneratorField): string;
begin
  Result := 'JSONName(' + AnsiQuotedStr(AField.JsonName, #39) + ')';
end;

function TDelphiUnitWriter.ListType(AField: TGeneratorField): string;
begin
  if AField.ContainedType = jtObject then
    Result := 'TObjectList'
  else
    Result := 'TList';
end;

function TDelphiUnitWriter.ArrayStorageType(
  AField: TGeneratorField): string;
begin
  if AField.ArrayDepth = 2 then
    Result := 'TArray<TArray<' + FieldType(AField) + '>>'
  else
    Result := 'TArray<' + FieldType(AField) + '>';
end;

function TDelphiUnitWriter.ListStorageType(
  AField: TGeneratorField): string;
begin
  if AField.ArrayDepth = 2 then
    Result := 'TObjectList<TList<' + FieldType(AField) + '>>'
  else
    Result := ListType(AField) + '<' + FieldType(AField) + '>';
end;

function TDelphiUnitWriter.PropertyName(AField: TGeneratorField): string;
begin
  if ReservedWords.IndexOf(AField.DelphiName.ToLower) >= 0 then
    Result := '&' + AField.DelphiName
  else
    Result := AField.DelphiName;
end;

procedure TDelphiUnitWriter.WriteClassDeclaration(ALines: TStrings;
  AClass: TGeneratorClass; const ABaseClass: string);
var
  Attribute: string;
  BaseSuffix: string;
  Field: TGeneratorField;
begin
  if not AClass.NeedsSourceCode then
    Exit;
  if ABaseClass = '' then BaseSuffix := '' else BaseSuffix := '(' + ABaseClass + ')';
  ALines.Add('  ' + AClass.Name + ' = class' + BaseSuffix);
  if AClass.Fields.Count > 0 then ALines.Add('  private');
  for Field in AClass.Fields do
    case Field.Kind of
      gfArray:
        begin
          ALines.AddFormat('    [%s%s]', [JsonNameAttribute(Field),
            IfThen(Field.ContainedType = jtObject, ', JSONMarshalled(False)', '')]);
          ALines.AddFormat('    F%sArray: %s;', [Field.DelphiName,
            ArrayStorageType(Field)]);
          if Field.ArrayDepth = 2 then ALines.Add('    [JSONMarshalled(False)]')
          else if Field.ContainedType = jtObject then ALines.Add('    [GenericListReflect]')
          else ALines.Add('    [JSONMarshalled(False)]');
          ALines.AddFormat('    F%s: %s;', [Field.DelphiName,
            ListStorageType(Field)]);
        end;
      gfObject:
        begin
          if Field.NeedsJsonNameAttribute then
            ALines.Add('    [' + JsonNameAttribute(Field) + ']');
          ALines.AddFormat('    F%s: %s;', [Field.DelphiName, FieldType(Field)]);
        end;
      gfScalar:
        begin
          Attribute := DateAttribute(Field);
          if Field.NeedsJsonNameAttribute then
          begin
            if Attribute <> '' then Attribute := Attribute + ', ';
            Attribute := Attribute + JsonNameAttribute(Field);
          end;
          if Attribute <> '' then ALines.Add('    [' + Attribute + ']');
          ALines.AddFormat('    F%s: %s;', [Field.DelphiName, FieldType(Field)]);
        end;
    end;
  for Field in AClass.Fields do
    if Field.Kind = gfArray then
      ALines.AddFormat('    function Get%s: %s;', [Field.DelphiName,
        ListStorageType(Field)]);
  if HasArrays(AClass) then
  begin
    ALines.Add('  protected');
    ALines.Add('    function GetAsJson: string; override;');
  end;
  if AClass.Fields.Count > 0 then ALines.Add('  published');
  for Field in AClass.Fields do
    if Field.Kind = gfArray then
      ALines.AddFormat('    property %s: %s read Get%s;', [PropertyName(Field),
        ListStorageType(Field), Field.DelphiName])
    else if Field.Kind = gfObject then
      ALines.AddFormat('    property %s: %s read F%s;', [PropertyName(Field),
        FieldType(Field), Field.DelphiName])
    else
      ALines.AddFormat('    property %s: %s read F%s write F%s;', [PropertyName(Field),
        FieldType(Field), Field.DelphiName, Field.DelphiName]);
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

procedure TDelphiUnitWriter.WriteClassImplementation(ALines: TStrings;
  AClass: TGeneratorClass);
var
  Field: TGeneratorField;
  Prefix: string;
begin
  if not AClass.NeedsSourceCode or not (HasComplexFields(AClass) or HasArrays(AClass)) then Exit;
  ALines.Add(''); ALines.AddFormat('{ %s }', [AClass.Name]); ALines.Add('');
  if HasComplexFields(AClass) then
  begin
    ALines.AddFormat('constructor %s.Create;', [AClass.Name]);
    ALines.Add('begin'); ALines.Add('  inherited;');
    for Field in AClass.Fields do if Field.Kind = gfObject then
      ALines.AddFormat('  F%s := %s.Create;', [Field.DelphiName, FieldType(Field)]);
    ALines.Add('end;'); ALines.Add('');
  end;
  ALines.AddFormat('destructor %s.Destroy;', [AClass.Name]); ALines.Add('begin');
  for Field in AClass.Fields do
    if Field.Kind = gfObject then ALines.AddFormat('  F%s.Free;', [Field.DelphiName])
    else if Field.Kind = gfArray then ALines.AddFormat('  Get%s.Free;', [Field.DelphiName]);
  ALines.Add('  inherited;'); ALines.Add('end;');
  for Field in AClass.Fields do if Field.Kind = gfArray then
  begin
    if Field.ArrayDepth = 2 then
    begin
      ALines.Add('');
      ALines.AddFormat('function %s.Get%s: %s;', [AClass.Name,
        Field.DelphiName, ListStorageType(Field)]);
      ALines.Add('begin');
      ALines.AddFormat('  Result := List2D<%s>(F%s, F%sArray);',
        [FieldType(Field), Field.DelphiName, Field.DelphiName]);
      ALines.Add('end;');
      Continue;
    end;
    if Field.ContainedType = jtObject then Prefix := 'Object' else Prefix := '';
    ALines.Add('');
    ALines.AddFormat('function %s.Get%s: T%sList<%s>;', [AClass.Name,
      Field.DelphiName, Prefix, FieldType(Field)]);
    ALines.Add('begin');
    ALines.AddFormat('  Result := %sList<%s>(F%s, F%sArray);', [Prefix,
      FieldType(Field), Field.DelphiName, Field.DelphiName]);
    ALines.Add('end;');
  end;
  if HasArrays(AClass) then
  begin
    ALines.Add(''); ALines.AddFormat('function %s.GetAsJson: string;', [AClass.Name]);
    ALines.Add('begin');
    for Field in AClass.Fields do if Field.Kind = gfArray then
      if Field.ArrayDepth = 2 then
        ALines.AddFormat('  RefreshArray2D<%s>(F%s, F%sArray);',
          [FieldType(Field), Field.DelphiName, Field.DelphiName])
      else
        ALines.AddFormat('  RefreshArray<%s>(F%s, F%sArray);',
          [FieldType(Field), Field.DelphiName, Field.DelphiName]);
    ALines.Add('  Result := inherited;'); ALines.Add('end;');
  end;
end;

procedure TDelphiUnitWriter.WriteForwardDeclarations(ALines: TStrings;
  AModel: TGeneratorModel);
var
  I: Integer;
  Names: TStringList;
  Field: TGeneratorField;
begin
  Names := TStringList.Create;
  try
    Names.Sorted := True; Names.Duplicates := dupIgnore;
    for I := AModel.Classes.Count - 1 downto 1 do
      for Field in AModel.Classes[I].Fields do
        if Field.Kind in [gfObject, gfArray] then
          if (Field.FieldClass <> nil) and Field.FieldClass.NeedsSourceCode then
            Names.Add(Field.FieldClass.Name);
    { Retain the legacy output rule. A single subtype does not require a
      forward declaration with the current reverse declaration order. }
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

function TDelphiUnitWriter.WriteUnit(AModel: TGeneratorModel;
  const AUnitName: string): string;
var
  I: Integer;
  Lines: TStringList;
  BaseClass: string;
begin
  if AModel.RootClass = nil then raise EInvalidOperation.Create('No model has been built');
  Lines := TStringList.Create;
  try
    Lines.TrailingLineBreak := False;
    Lines.Add('unit ' + AUnitName + ';'); Lines.Add(''); Lines.Add('interface'); Lines.Add('');
    Lines.Add('uses'); Lines.Add('  Pkg.Json.DTO, System.Generics.Collections, REST.Json.Types;');
    Lines.Add(''); Lines.Add('{$M+}'); Lines.Add(''); Lines.Add('type');
    WriteForwardDeclarations(Lines, AModel);
    for I := AModel.Classes.Count - 1 downto 1 do
    begin
      if HasArrays(AModel.Classes[I]) then BaseClass := 'TJsonDTO' else BaseClass := '';
      WriteClassDeclaration(Lines, AModel.Classes[I], BaseClass);
    end;
    WriteClassDeclaration(Lines, AModel.RootClass, 'TJsonDTO');
    Lines.Add('implementation');
    for I := AModel.Classes.Count - 1 downto 0 do
      WriteClassImplementation(Lines, AModel.Classes[I]);
    Lines.Add(''); Lines.Add('end.');
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

end.
