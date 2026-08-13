unit Tests.Generator.ObjectMatrixRuntime;

interface

uses
  DUnitX.TestFramework,
  REST.Json.Types,
  JsonToDelphi.Runtime.DTO,
  JsonToDelphi.Runtime.Matrix;

{$M+}

type
  [TestFixture]
  TObjectMatrixRuntimeTests = class
  public
    [Test]
    procedure RoundTripsJson;
  end;

  TPerson = class
  private
    FName: string;
  published
    property Name: string read FName write FName;
  end;

  TObjectMatrixDTO = class(TJsonDTO)
  private
    [JSONMarshalled(False)]
    FPeople: TObjectMatrix<TPerson>;
    function GetPeople: TObjectMatrix<TPerson>;
  protected
    function GetAsJson: string; override;
    procedure SetAsJson(aValue: string); override;
  published
    [JSONMarshalled(False)]
    property People: TObjectMatrix<TPerson> read GetPeople;
  public
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils;

destructor TObjectMatrixDTO.Destroy;
begin
  FPeople.Free;
  inherited;
end;

function TObjectMatrixDTO.GetAsJson: string;
begin
  Result := inherited;
  Result := SaveObjectMatrix<TPerson>(FPeople, Result, 'people');
end;

function TObjectMatrixDTO.GetPeople: TObjectMatrix<TPerson>;
begin
  if FPeople = nil then
    FPeople := TObjectMatrix<TPerson>.Create;
  Result := FPeople;
end;

procedure TObjectMatrixDTO.SetAsJson(aValue: string);
begin
  GetPeople;
  LoadObjectMatrix<TPerson>(FPeople, aValue, 'people');
end;

procedure TObjectMatrixRuntimeTests.RoundTripsJson;
var
  DTO: TObjectMatrixDTO;
  Json: string;
begin
  DTO := TObjectMatrixDTO.Create;
  try
    DTO.AsJson := '{"people":[[{"name":"Ada"}],[{"name":"Grace"}]]}';
    Assert.AreEqual<Integer>(2, DTO.People.Count);
    Assert.AreEqual('Ada', DTO.People[0][0].Name);
    DTO.People[1][0].Name := 'Hopper';
    Json := DTO.AsJson;
    Assert.IsTrue(Json.Contains('"name":"Hopper"'));
  finally
    DTO.Free;
  end;
end;

initialization

TDUnitX.RegisterTestFixture(TObjectMatrixRuntimeTests);

end.
