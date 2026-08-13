unit Tests.Runtime.Matrix;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TMatrixTests = class
  public
    [Test]
    procedure AssignsAndConvertsIntegers;
    [Test]
    procedure AssignsAndConvertsStrings;
    [Test]
    procedure SupportsEmptyAndJaggedRows;
    [Test]
    procedure AssignsAndConvertsObjects;
    [Test]
    procedure MatrixOwnsRows;
    [Test]
    procedure ObjectMatrixOwnsRowsAndObjects;
    [Test]
    procedure RepeatedAssignmentReleasesOldContent;
  end;

implementation

uses
  System.Generics.Collections,
  JsonToDelphi.Runtime.Matrix;

type
  TTestObject = class
  private
    FValue: Integer;
  public
    class var DestroyedCount: Integer;
    constructor Create(AValue: Integer);
    destructor Destroy; override;
    property Value: Integer read FValue;
  end;

constructor TTestObject.Create(AValue: Integer);
begin
  inherited Create;
  FValue := AValue;
end;

destructor TTestObject.Destroy;
begin
  Inc(DestroyedCount);
  inherited;
end;

procedure TMatrixTests.AssignsAndConvertsIntegers;
var
  Matrix: TMatrix<Integer>;
  Values: TArray<TArray<Integer>>;
begin
  Values := [[1, 2], [3, 4]];
  Matrix := TMatrix<Integer>.Create(Values);
  try
    Values := Matrix.ToArray;
    Assert.AreEqual<Integer>(2, Length(Values));
    Assert.AreEqual<Integer>(2, Length(Values[0]));
    Assert.AreEqual<Integer>(1, Values[0][0]);
    Assert.AreEqual<Integer>(4, Values[1][1]);
  finally
    Matrix.Free;
  end;
end;

procedure TMatrixTests.AssignsAndConvertsObjects;
var
  Matrix: TObjectMatrix<TTestObject>;
  Values: TArray<TArray<TTestObject>>;
begin
  TTestObject.DestroyedCount := 0;
  Values := [[TTestObject.Create(10)], [TTestObject.Create(20)]];
  Matrix := TObjectMatrix<TTestObject>.Create(Values);
  try
    Values := Matrix.ToArray;
    Assert.AreEqual<Integer>(10, Values[0][0].Value);
    Assert.AreEqual<Integer>(20, Values[1][0].Value);
  finally
    Matrix.Free;
    SetLength(Values, 0);
  end;
  Assert.AreEqual<Integer>(2, TTestObject.DestroyedCount);
end;

procedure TMatrixTests.AssignsAndConvertsStrings;
var
  Matrix: TMatrix<string>;
  Values: TArray<TArray<string>>;
begin
  Values := [['Ada'], ['Grace', 'Hopper']];
  Matrix := TMatrix<string>.Create;
  try
    Matrix.Assign(Values);
    Values := Matrix.ToArray;
    Assert.AreEqual('Ada', Values[0][0]);
    Assert.AreEqual('Grace', Values[1][0]);
    Assert.AreEqual('Hopper', Values[1][1]);
  finally
    Matrix.Free;
  end;
end;

procedure TMatrixTests.MatrixOwnsRows;
var
  Matrix: TMatrix<Integer>;
begin
  Matrix := TMatrix<Integer>.Create;
  try
    Assert.IsTrue(Matrix.OwnsObjects);
    Matrix.Add(TList<Integer>.Create);
    Assert.AreEqual<Integer>(1, Matrix.Count);
  finally
    Matrix.Free;
  end;
end;

procedure TMatrixTests.ObjectMatrixOwnsRowsAndObjects;
var
  Matrix: TObjectMatrix<TTestObject>;
begin
  TTestObject.DestroyedCount := 0;
  Matrix := TObjectMatrix<TTestObject>.Create;
  try
    Assert.IsTrue(Matrix.OwnsObjects);
    Matrix.Add(TObjectList<TTestObject>.Create(True));
    Assert.IsTrue(Matrix[0].OwnsObjects);
    Matrix[0].Add(TTestObject.Create(1));
  finally
    Matrix.Free;
  end;
  Assert.AreEqual<Integer>(1, TTestObject.DestroyedCount);
end;

procedure TMatrixTests.RepeatedAssignmentReleasesOldContent;
var
  Matrix: TObjectMatrix<TTestObject>;
  FirstValues: TArray<TArray<TTestObject>>;
  SecondValues: TArray<TArray<TTestObject>>;
begin
  TTestObject.DestroyedCount := 0;
  FirstValues := [[TTestObject.Create(1), TTestObject.Create(2)]];
  SecondValues := [[TTestObject.Create(3)]];
  Matrix := TObjectMatrix<TTestObject>.Create(FirstValues);
  try
    Matrix.Assign(SecondValues);
    Assert.AreEqual<Integer>(2, TTestObject.DestroyedCount);
    Assert.AreEqual<Integer>(3, Matrix[0][0].Value);
  finally
    Matrix.Free;
    SetLength(FirstValues, 0);
    SetLength(SecondValues, 0);
  end;
  Assert.AreEqual<Integer>(3, TTestObject.DestroyedCount);
end;

procedure TMatrixTests.SupportsEmptyAndJaggedRows;
var
  EmptyMatrix: TMatrix<Integer>;
  JaggedMatrix: TMatrix<Integer>;
  Values: TArray<TArray<Integer>>;
begin
  EmptyMatrix := TMatrix<Integer>.Create([]);
  try
    Values := EmptyMatrix.ToArray;
    Assert.AreEqual<Integer>(0, Length(Values));
  finally
    EmptyMatrix.Free;
  end;

  Values := [[], [1], [2, 3, 4]];
  JaggedMatrix := TMatrix<Integer>.Create(Values);
  try
    Values := JaggedMatrix.ToArray;
    Assert.AreEqual<Integer>(0, Length(Values[0]));
    Assert.AreEqual<Integer>(1, Length(Values[1]));
    Assert.AreEqual<Integer>(3, Length(Values[2]));
  finally
    JaggedMatrix.Free;
  end;
end;

initialization

TDUnitX.RegisterTestFixture(TMatrixTests);

end.
