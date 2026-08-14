unit RootU;

interface

uses
  JsonToDelphi.Runtime.DTO, JsonToDelphi.Runtime.Matrix, System.Generics.Collections, REST.Json.Types;

{$M+}

type
  TPeople = class
  private
    FName: string;
  published
    property Name: string read FName write FName;
  end;

  TItems = class
  private
    FId: Integer;
  published
    property Id: Integer read FId write FId;
  end;

  TRoot = class(TJsonDTO)
  private
    [JSONName('items'), JSONMarshalled(False)]
    FItemsArray: TArray<TItems>;
    [GenericListReflect]
    FItems: TObjectList<TItems>;
    [JSONName('matrix')]
    FMatrixArray: TArray<TArray<Integer>>;
    [JSONMarshalled(False)]
    FMatrix: TMatrix<Integer>;
    FName: string;
    [JSONMarshalled(False)]
    FPeople: TObjectMatrix<TPeople>;
    function GetItems: TObjectList<TItems>;
    function GetMatrix: TMatrix<Integer>;
    function GetPeople: TObjectMatrix<TPeople>;
  protected
    function GetAsJson: string; override;
    procedure SetAsJson(aValue: string); override;
  published
    property Items: TObjectList<TItems> read GetItems;
    property Matrix: TMatrix<Integer> read GetMatrix;
    property Name: string read FName write FName;
    [JSONMarshalled(False)]
    property People: TObjectMatrix<TPeople> read GetPeople;
  public
    destructor Destroy; override;
  end;

implementation

{ TRoot }

destructor TRoot.Destroy;
begin
  FItems.Free;
  FMatrix.Free;
  FPeople.Free;
  inherited;
end;

function TRoot.GetItems: TObjectList<TItems>;
begin
  Result := ObjectList<TItems>(FItems, FItemsArray);
end;

function TRoot.GetMatrix: TMatrix<Integer>;
begin
  if FMatrix = nil then
    FMatrix := TMatrix<Integer>.Create(FMatrixArray);
  Result := FMatrix;
end;

function TRoot.GetPeople: TObjectMatrix<TPeople>;
begin
  if FPeople = nil then
    FPeople := TObjectMatrix<TPeople>.Create;
  Result := FPeople;
end;

function TRoot.GetAsJson: string;
begin
  RefreshArray<TItems>(FItems, FItemsArray);
  if FMatrix <> nil then
    FMatrixArray := FMatrix.ToArray;
  Result := inherited;
  Result := SaveObjectMatrix<TPeople>(FPeople, Result, 'people');
end;

procedure TRoot.SetAsJson(aValue: string);
begin
  SetAsJsonWithoutFields(aValue, ['people']);
  GetPeople;
  LoadObjectMatrix<TPeople>(FPeople, aValue, 'people');
end;

end.
