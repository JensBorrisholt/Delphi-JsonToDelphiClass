unit RootU;

interface

uses
  Pkg.Json.DTO, System.Generics.Collections, REST.Json.Types;

{$M+}

type
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
    function GetItems: TObjectList<TItems>;
  protected
    function GetAsJson: string; override;
  published
    property Items: TObjectList<TItems> read GetItems;
    property Name: string read FName write FName;
  public
    destructor Destroy; override;
  end;

implementation

{ TRoot }

destructor TRoot.Destroy;
begin
  GetItems.Free;
  inherited;
end;

function TRoot.GetItems: TObjectList<TItems>;
begin
  Result := ObjectList<TItems>(FItems, FItemsArray);
end;

function TRoot.GetAsJson: string;
begin
  RefreshArray<TItems>(FItems, FItemsArray);
  Result := inherited;
end;

end.
