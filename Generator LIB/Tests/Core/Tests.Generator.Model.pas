unit Tests.Generator.Model;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TGeneratorModelTests = class
  public
    [Test] procedure GeneratorTypeStoresKinds;
    [Test] procedure ArrayDepthReturnsNestedDepth;
    [Test] procedure LeafTypeReturnsInnermostType;
    [Test] procedure FindFieldIsCaseInsensitive;
    [Test] procedure SortFieldsSortsByJsonName;
    [Test] procedure FindClassIsCaseInsensitive;
    [Test] procedure ClearRemovesClassesAndRoot;
    [Test] procedure FieldSourcePositionDefaultsToMinusOne;
  end;

implementation

uses
  JsonToDelphi.Generator.Core.Model;

procedure TGeneratorModelTests.GeneratorTypeStoresKinds;
var
  DataType: TGeneratorType;
begin
  DataType := TGeneratorType.Create(jvkString, svkGuid);
  try
    Assert.IsTrue(DataType.JsonKind = jvkString);
    Assert.IsTrue(DataType.SemanticKind = svkGuid);
    Assert.IsFalse(DataType.Nullable);
  finally
    DataType.Free;
  end;
end;

procedure TGeneratorModelTests.ArrayDepthReturnsNestedDepth;
var
  DataType: TGeneratorType;
begin
  DataType := TGeneratorType.Create(jvkArray);
  try
    DataType.ElementType := TGeneratorType.Create(jvkArray);
    DataType.ElementType.ElementType := TGeneratorType.Create(jvkNumber, svkInteger);
    Assert.AreEqual<Integer>(2, DataType.ArrayDepth);
  finally
    DataType.Free;
  end;
end;

procedure TGeneratorModelTests.LeafTypeReturnsInnermostType;
var
  DataType: TGeneratorType;
begin
  DataType := TGeneratorType.Create(jvkArray);
  try
    DataType.ElementType := TGeneratorType.Create(jvkArray);
    DataType.ElementType.ElementType := TGeneratorType.Create(jvkString, svkDate);
    Assert.IsTrue(DataType.ElementType.ElementType = DataType.LeafType);
  finally
    DataType.Free;
  end;
end;

procedure TGeneratorModelTests.FindFieldIsCaseInsensitive;
var
  GeneratorClass: TGeneratorClass;
  Field: TGeneratorField;
begin
  GeneratorClass := TGeneratorClass.Create;
  try
    Field := TGeneratorField.Create;
    Field.JsonName := 'createdAt';
    GeneratorClass.Fields.Add(Field);
    Assert.IsTrue(Field = GeneratorClass.FindField('CREATEDAT'));
  finally
    GeneratorClass.Free;
  end;
end;

procedure TGeneratorModelTests.SortFieldsSortsByJsonName;
var
  GeneratorClass: TGeneratorClass;
  Field: TGeneratorField;
begin
  GeneratorClass := TGeneratorClass.Create;
  try
    Field := TGeneratorField.Create;
    Field.JsonName := 'zeta';
    GeneratorClass.Fields.Add(Field);
    Field := TGeneratorField.Create;
    Field.JsonName := 'alpha';
    GeneratorClass.Fields.Add(Field);
    GeneratorClass.SortFields;
    Assert.AreEqual('alpha', GeneratorClass.Fields[0].JsonName);
    Assert.AreEqual('zeta', GeneratorClass.Fields[1].JsonName);
  finally
    GeneratorClass.Free;
  end;
end;

procedure TGeneratorModelTests.FindClassIsCaseInsensitive;
var
  Model: TGeneratorModel;
  GeneratorClass: TGeneratorClass;
begin
  Model := TGeneratorModel.Create;
  try
    GeneratorClass := TGeneratorClass.Create;
    GeneratorClass.JsonName := 'Customer';
    Model.Classes.Add(GeneratorClass);
    Assert.IsTrue(GeneratorClass = Model.FindClass('customer'));
  finally
    Model.Free;
  end;
end;

procedure TGeneratorModelTests.ClearRemovesClassesAndRoot;
var
  Model: TGeneratorModel;
  GeneratorClass: TGeneratorClass;
begin
  Model := TGeneratorModel.Create;
  try
    GeneratorClass := TGeneratorClass.Create;
    GeneratorClass.JsonName := 'Root';
    Model.Classes.Add(GeneratorClass);
    Model.RootClass := GeneratorClass;
    Model.Clear;
    Assert.AreEqual<Integer>(0, Model.Classes.Count);
    Assert.IsNull(Model.RootClass);
  finally
    Model.Free;
  end;
end;

procedure TGeneratorModelTests.FieldSourcePositionDefaultsToMinusOne;
var
  Field: TGeneratorField;
begin
  Field := TGeneratorField.Create;
  try
    Assert.AreEqual<Integer>(-1, Field.SourcePosition);
  finally
    Field.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TGeneratorModelTests);

end.
