unit Tests.Generator.ObjectMatrixRuntime;

interface

uses
  DUnitX.TestFramework,
  System.Generics.Collections,
  REST.Json.Types,
  JsonToDelphi.Runtime.DTO;

{$M+}
{$RTTI EXPLICIT METHODS([vcPublic])}

type
  [TestFixture]
  TObjectMatrixRuntimeTests = class
  public
    [Test] procedure OwnsRowsAndObjectsAndRefreshesArray;
    [Test] procedure RoundTripsJson;
  end;

  TPerson = class
  private
    FName: string;
  public
    constructor Create; virtual;
  published
    property Name: string read FName write FName;
  end;

  TObjectMatrixDTO = class(TJsonDTO)
  private
    [JSONName('people'), JSONMarshalled(False)]
    FPeopleArray: TArray<TArray<TPerson>>;
    [JSONMarshalled(False)]
    FPeople: TObjectList<TObjectList<TPerson>>;
    function GetPeople: TObjectList<TObjectList<TPerson>>;
  protected
    function GetAsJson: string; override;
    procedure SetAsJson(aValue: string); override;
  published
    [JSONMarshalled(False)]
    property People: TObjectList<TObjectList<TPerson>> read GetPeople;
  public
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils;

constructor TPerson.Create;
begin
  inherited;
end;

type
  TTrackedObject = class
  public
    class var DestroyedCount: Integer;
    destructor Destroy; override;
  end;

  TArrayMapperAccess = class(TArrayMapper)
  public
    function Build<T: class>(var AList: TObjectList<TObjectList<T>>;
      ASource: TArray<TArray<T>>): TObjectList<TObjectList<T>>;
    procedure Refresh<T: class>(ASource: TObjectList<TObjectList<T>>;
      var ADestination: TArray<TArray<T>>);
  end;

function TArrayMapperAccess.Build<T>(var AList: TObjectList<TObjectList<T>>;
  ASource: TArray<TArray<T>>): TObjectList<TObjectList<T>>;
begin
  Result := ObjectList2D<T>(AList, ASource);
end;

procedure TArrayMapperAccess.Refresh<T>(ASource: TObjectList<TObjectList<T>>;
  var ADestination: TArray<TArray<T>>);
begin
  RefreshObjectArray2D<T>(ASource, ADestination);
end;

destructor TTrackedObject.Destroy;
begin
  Inc(DestroyedCount);
  inherited;
end;

destructor TObjectMatrixDTO.Destroy;
begin
  GetPeople.Free;
  inherited;
end;

function TObjectMatrixDTO.GetAsJson: string;
begin
  Result := inherited;
  Result := SaveObjectList2D<TPerson>(FPeople, Result, 'people');
end;

function TObjectMatrixDTO.GetPeople: TObjectList<TObjectList<TPerson>>;
begin
  Result := ObjectList2D<TPerson>(FPeople, FPeopleArray);
end;

procedure TObjectMatrixDTO.SetAsJson(aValue: string);
begin
  LoadObjectList2D<TPerson>(FPeople, aValue, 'people');
end;

procedure TObjectMatrixRuntimeTests.OwnsRowsAndObjectsAndRefreshesArray;
var
  Mapper: TArrayMapperAccess;
  Matrix: TObjectList<TObjectList<TTrackedObject>>;
  Source: TArray<TArray<TTrackedObject>>;
begin
  TTrackedObject.DestroyedCount := 0;
  Matrix := nil;
  Mapper := TArrayMapperAccess.Create;
  try
    SetLength(Source, 2);
    SetLength(Source[0], 1);
    SetLength(Source[1], 1);
    Source[0][0] := TTrackedObject.Create;
    Source[1][0] := TTrackedObject.Create;

    Assert.AreEqual<Integer>(2, Mapper.Build<TTrackedObject>(Matrix, Source).Count);
    Assert.IsTrue(Matrix.OwnsObjects);
    Assert.IsTrue(Matrix[0].OwnsObjects);
    Assert.IsTrue(Matrix[1].OwnsObjects);

    SetLength(Source, 0);
    Mapper.Refresh<TTrackedObject>(Matrix, Source);
    Assert.AreEqual<Integer>(2, Length(Source));
    Assert.AreEqual<Integer>(1, Length(Source[0]));
  finally
    Matrix.Free;
    Mapper.Free;
    SetLength(Source, 0);
  end;

  Assert.AreEqual<Integer>(2, TTrackedObject.DestroyedCount);
end;

procedure TObjectMatrixRuntimeTests.RoundTripsJson;
var
  DTO: TObjectMatrixDTO;
  Json: string;
begin
  DTO := TObjectMatrixDTO.Create;
  try
    try
      DTO.AsJson := '{"people":[[{"name":"Ada"}],[{"name":"Grace"}]]}';
    except
      on E: Exception do
        raise Exception.Create('Loading object matrix failed: ' + E.Message);
    end;
    Assert.AreEqual<Integer>(2, DTO.People.Count);
    Assert.AreEqual('Ada', DTO.People[0][0].Name);
    DTO.People[1][0].Name := 'Hopper';
    try
      Json := DTO.AsJson;
    except
      on E: Exception do
        raise Exception.Create('Saving object matrix failed: ' + E.Message);
    end;
    Assert.IsTrue(Json.Contains('"name":"Hopper"'));
  finally
    DTO.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TObjectMatrixRuntimeTests);

end.
