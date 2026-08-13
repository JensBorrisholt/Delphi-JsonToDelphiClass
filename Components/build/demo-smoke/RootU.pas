unit RootU;

interface

uses
  JsonToDelphi.Runtime.DTO, System.Generics.Collections, REST.Json.Types;

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
    FName: string;
    [JSONName('people')]
    FPeopleArray: TArray<TArray<TPeople>>;
    [JSONMarshalled(False)]
    FPeople: TObjectList<TObjectList<TPeople>>;
    function GetItems: TObjectList<TItems>;
    function GetPeople: TObjectList<TObjectList<TPeople>>;
  protected
    function GetAsJson: string; override;
  published
    property Items: TObjectList<TItems> read GetItems;
    property Name: string read FName write FName;
    property People: TObjectList<TObjectList<TPeople>> read GetPeople;
  public
    destructor Destroy; override;
  end;

implementation

{ TRoot }

destructor TRoot.Destroy;
begin
  GetItems.Free;
  GetPeople.Free;
  inherited;
end;

function TRoot.GetItems: TObjectList<TItems>;
begin
  Result := ObjectList<TItems>(FItems, FItemsArray);
end;

function TRoot.GetPeople: TObjectList<TObjectList<TPeople>>;
begin
  Result := ObjectList2D<TPeople>(FPeople, FPeopleArray);
end;

function TRoot.GetAsJson: string;
begin
  RefreshArray<TItems>(FItems, FItemsArray);
  RefreshObjectArray2D<TPeople>(FPeople, FPeopleArray);
  Result := inherited;
end;

end.
