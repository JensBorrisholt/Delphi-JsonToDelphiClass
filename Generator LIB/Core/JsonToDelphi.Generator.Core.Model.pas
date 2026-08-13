unit JsonToDelphi.Generator.Core.Model;

interface

uses
  System.Generics.Collections;

type
  TGeneratorClass = class;

  TJsonValueKind = (jvkUnknown, jvkNull, jvkObject, jvkArray, jvkString, jvkBoolean, jvkNumber);

  TSemanticValueKind = (svkUnknown, svkObject, svkString, svkBoolean, svkInteger, svkInteger64, svkFloat,
    svkDate, svkTime, svkDateTime, svkGuid, svkUri, svkBytes);

  TGeneratorType = class
  private
    FElementType: TGeneratorType;
    FJsonKind: TJsonValueKind;
    FNullable: Boolean;
    FObjectClass: TGeneratorClass;
    FSemanticKind: TSemanticValueKind;
  public
    constructor Create(AJsonKind: TJsonValueKind; ASemanticKind: TSemanticValueKind = svkUnknown);
    destructor Destroy; override;
    function ArrayDepth: Integer;
    function LeafType: TGeneratorType;
    property ElementType: TGeneratorType read FElementType write FElementType;
    property JsonKind: TJsonValueKind read FJsonKind write FJsonKind;
    property Nullable: Boolean read FNullable write FNullable;
    property ObjectClass: TGeneratorClass read FObjectClass write FObjectClass;
    property SemanticKind: TSemanticValueKind read FSemanticKind write FSemanticKind;
  end;

  TGeneratorField = class
  private
    FDataType: TGeneratorType;
    FIsOptional: Boolean;
    FJsonName: string;
    FJsonPath: string;
    FSourceLength: Integer;
    FSourcePosition: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    property DataType: TGeneratorType read FDataType write FDataType;
    property IsOptional: Boolean read FIsOptional write FIsOptional;
    property JsonName: string read FJsonName write FJsonName;
    property JsonPath: string read FJsonPath write FJsonPath;
    property SourceLength: Integer read FSourceLength write FSourceLength;
    property SourcePosition: Integer read FSourcePosition write FSourcePosition;
  end;

  TGeneratorClass = class
  private
    FFields: TObjectList<TGeneratorField>;
    FIdentity: string;
    FJsonName: string;
    FJsonPath: string;
    FParent: TGeneratorClass;
  public
    constructor Create;
    destructor Destroy; override;
    function FindField(const AJsonName: string): TGeneratorField;
    procedure SortFields;
    property Fields: TObjectList<TGeneratorField> read FFields;
    property Identity: string read FIdentity write FIdentity;
    property JsonName: string read FJsonName write FJsonName;
    property JsonPath: string read FJsonPath write FJsonPath;
    property Parent: TGeneratorClass read FParent write FParent;
  end;

  TGeneratorModel = class
  private
    FClasses: TObjectList<TGeneratorClass>;
    FRootClass: TGeneratorClass;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function FindClass(const AJsonName: string): TGeneratorClass;
    property Classes: TObjectList<TGeneratorClass> read FClasses;
    property RootClass: TGeneratorClass read FRootClass write FRootClass;
  end;

implementation

uses
  System.Generics.Defaults, System.SysUtils;

constructor TGeneratorType.Create(AJsonKind: TJsonValueKind; ASemanticKind: TSemanticValueKind);
begin
  inherited Create;
  FJsonKind := AJsonKind;
  FSemanticKind := ASemanticKind;
end;

destructor TGeneratorType.Destroy;
begin
  FElementType.Free;
  inherited;
end;

function TGeneratorType.ArrayDepth: Integer;
var
  Current: TGeneratorType;
begin
  Result := 0;
  Current := Self;
  while (Current <> nil) and (Current.JsonKind = jvkArray) do
  begin
    Inc(Result);
    Current := Current.ElementType;
  end;
end;

function TGeneratorType.LeafType: TGeneratorType;
begin
  Result := Self;
  while (Result <> nil) and (Result.JsonKind = jvkArray) do
    Result := Result.ElementType;
end;

constructor TGeneratorField.Create;
begin
  inherited;
  FSourcePosition := -1;
end;

destructor TGeneratorField.Destroy;
begin
  FDataType.Free;
  inherited;
end;

constructor TGeneratorClass.Create;
begin
  inherited;
  FFields := TObjectList<TGeneratorField>.Create(True);
end;

destructor TGeneratorClass.Destroy;
begin
  FFields.Free;
  inherited;
end;

function TGeneratorClass.FindField(const AJsonName: string): TGeneratorField;
begin
  for Result in FFields do
    if SameText(Result.JsonName, AJsonName) then
      Exit;
  Result := nil;
end;

procedure TGeneratorClass.SortFields;
begin
  FFields.Sort(TComparer<TGeneratorField>.Construct(
    function(const Left, Right: TGeneratorField): Integer
    begin
      Result := CompareStr(Left.JsonName, Right.JsonName);
    end));
end;

constructor TGeneratorModel.Create;
begin
  inherited;
  FClasses := TObjectList<TGeneratorClass>.Create(True);
end;

destructor TGeneratorModel.Destroy;
begin
  FClasses.Free;
  inherited;
end;

procedure TGeneratorModel.Clear;
begin
  FRootClass := nil;
  FClasses.Clear;
end;

function TGeneratorModel.FindClass(const AJsonName: string): TGeneratorClass;
begin
  for Result in FClasses do
    if SameText(Result.JsonName, AJsonName) then
      Exit;
  Result := nil;
end;

end.
