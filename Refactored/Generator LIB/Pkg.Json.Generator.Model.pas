unit Pkg.Json.Generator.Model;

interface

uses
  System.Generics.Collections,
  Pkg.Json.JsonValueHelper;

type
  TGeneratorClass = class;

  TGeneratorFieldKind = (gfScalar, gfObject, gfArray);

  TGeneratorField = class
  private
    FArrayDepth: Integer;
    FContainedType: TJsonType;
    FDelphiName: string;
    FFieldClass: TGeneratorClass;
    FJsonName: string;
    FKind: TGeneratorFieldKind;
    FNeedsJsonNameAttribute: Boolean;
    FValueType: TJsonType;
  public
    constructor Create;
    property ArrayDepth: Integer read FArrayDepth write FArrayDepth;
    property ContainedType: TJsonType read FContainedType write FContainedType;
    property DelphiName: string read FDelphiName write FDelphiName;
    property FieldClass: TGeneratorClass read FFieldClass write FFieldClass;
    property JsonName: string read FJsonName write FJsonName;
    property Kind: TGeneratorFieldKind read FKind write FKind;
    property NeedsJsonNameAttribute: Boolean read FNeedsJsonNameAttribute write FNeedsJsonNameAttribute;
    property ValueType: TJsonType read FValueType write FValueType;
  end;

  TGeneratorClass = class
  private
    FArrayProperty: string;
    FFields: TObjectList<TGeneratorField>;
    FJsonName: string;
    FName: string;
    FNeedsSourceCode: Boolean;
    FParent: TGeneratorClass;
  public
    constructor Create;
    destructor Destroy; override;
    function FindField(const AJsonName: string): TGeneratorField;
    procedure SortFields;
    property ArrayProperty: string read FArrayProperty write FArrayProperty;
    property Fields: TObjectList<TGeneratorField> read FFields;
    property JsonName: string read FJsonName write FJsonName;
    property Name: string read FName write FName;
    property NeedsSourceCode: Boolean read FNeedsSourceCode write FNeedsSourceCode;
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

constructor TGeneratorField.Create;
begin
  inherited;
  FArrayDepth := 1;
end;

constructor TGeneratorClass.Create;
begin
  inherited;
  FFields := TObjectList<TGeneratorField>.Create(True);
  FNeedsSourceCode := True;
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
      Result := CompareStr(Left.DelphiName, Right.DelphiName);
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
