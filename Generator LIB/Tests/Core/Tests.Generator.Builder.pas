unit Tests.Generator.Builder;

interface

uses
  DUnitX.TestFramework,
  JsonToDelphi.Generator.Core.Model;

type
  [TestFixture]
  TGeneratorBuilderTests = class
  private
    procedure AssertSemanticKind(const AJson, AFieldName: string; AExpected: TSemanticValueKind);
  public
    [Test] procedure BuildsObjectRoot;
    [Test] procedure BuildsPrimitiveRootArray;
    [Test] procedure RejectsScalarRoot;
    [Test] procedure RejectsEmptyJson;
    [Test] procedure RejectsEmptyRootClassName;
    [Test] procedure InfersPrimitiveKinds;
    [Test] procedure InfersGuid;
    [Test] procedure InfersDate;
    [Test] procedure InfersTime;
    [Test] procedure InfersDateTime;
    [Test] procedure InfersUri;
    [Test] procedure KeepsRelativeUriAsString;
    [Test] procedure MarksNullAsNullable;
    [Test] procedure BuildsOneDimensionalArray;
    [Test] procedure BuildsTwoDimensionalArray;
    [Test] procedure RejectsMoreThanTwoDimensions;
    [Test] procedure MarksMissingObjectMembersOptional;
    [Test] procedure RetainsSourcePathAndRange;
  end;

implementation

uses
  System.SysUtils,
  JsonToDelphi.Generator.Core.Builder,
  JsonToDelphi.Generator.Core.Errors;

procedure TGeneratorBuilderTests.AssertSemanticKind(const AJson, AFieldName: string; AExpected: TSemanticValueKind);
var
  Builder: TJsonModelBuilder;
  Model: TGeneratorModel;
begin
  Model := TGeneratorModel.Create;
  try
    Builder := TJsonModelBuilder.Create(Model);
    try
      Builder.Build(AJson, 'Root');
      Assert.IsTrue(AExpected = Model.RootClass.FindField(AFieldName).DataType.SemanticKind);
    finally
      Builder.Free;
    end;
  finally
    Model.Free;
  end;
end;

procedure TGeneratorBuilderTests.BuildsObjectRoot;
var
  Builder: TJsonModelBuilder;
  Model: TGeneratorModel;
begin
  Model := TGeneratorModel.Create;
  try
    Builder := TJsonModelBuilder.Create(Model);
    try
      Builder.Build('{"id":1}', 'Order');
      Assert.IsNotNull(Model.RootClass);
      Assert.AreEqual('Order', Model.RootClass.JsonName);
      Assert.AreEqual<Integer>(1, Model.RootClass.Fields.Count);
    finally
      Builder.Free;
    end;
  finally
    Model.Free;
  end;
end;

procedure TGeneratorBuilderTests.BuildsPrimitiveRootArray;
var
  Builder: TJsonModelBuilder;
  Model: TGeneratorModel;
  Field: TGeneratorField;
begin
  Model := TGeneratorModel.Create;
  try
    Builder := TJsonModelBuilder.Create(Model);
    try
      Builder.Build('[1,2,3]', 'Root');
      Field := Model.RootClass.FindField('Items');
      Assert.IsNotNull(Field);
      Assert.AreEqual<Integer>(1, Field.DataType.ArrayDepth);
      Assert.IsTrue(Field.DataType.LeafType.SemanticKind = svkInteger);
    finally
      Builder.Free;
    end;
  finally
    Model.Free;
  end;
end;

procedure TGeneratorBuilderTests.RejectsScalarRoot;
var
  Builder: TJsonModelBuilder;
  Model: TGeneratorModel;
begin
  Model := TGeneratorModel.Create;
  try
    Builder := TJsonModelBuilder.Create(Model);
    try
      try
        Builder.Build('42', 'Root');
        Assert.Fail('Expected EJsonGenerator');
      except
        on EJsonGenerator do
          ;
      end;
    finally
      Builder.Free;
    end;
  finally
    Model.Free;
  end;
end;

procedure TGeneratorBuilderTests.RejectsEmptyJson;
var
  Builder: TJsonModelBuilder;
  Model: TGeneratorModel;
begin
  Model := TGeneratorModel.Create;
  try
    Builder := TJsonModelBuilder.Create(Model);
    try
      try
        Builder.Build('', 'Root');
        Assert.Fail('Expected EJsonGenerator');
      except
        on EJsonGenerator do
          ;
      end;
    finally
      Builder.Free;
    end;
  finally
    Model.Free;
  end;
end;

procedure TGeneratorBuilderTests.RejectsEmptyRootClassName;
var
  Builder: TJsonModelBuilder;
  Model: TGeneratorModel;
begin
  Model := TGeneratorModel.Create;
  try
    Builder := TJsonModelBuilder.Create(Model);
    try
      try
        Builder.Build('{}', '');
        Assert.Fail('Expected EJsonGenerator');
      except
        on EJsonGenerator do
          ;
      end;
    finally
      Builder.Free;
    end;
  finally
    Model.Free;
  end;
end;

procedure TGeneratorBuilderTests.InfersPrimitiveKinds;
var
  Builder: TJsonModelBuilder;
  Model: TGeneratorModel;
begin
  Model := TGeneratorModel.Create;
  try
    Builder := TJsonModelBuilder.Create(Model);
    try
      Builder.Build('{"text":"x","enabled":true,"small":1,"large":2147483648,"ratio":1.5}', 'Root');
      Assert.IsTrue(Model.RootClass.FindField('text').DataType.SemanticKind = svkString);
      Assert.IsTrue(Model.RootClass.FindField('enabled').DataType.SemanticKind = svkBoolean);
      Assert.IsTrue(Model.RootClass.FindField('small').DataType.SemanticKind = svkInteger);
      Assert.IsTrue(Model.RootClass.FindField('large').DataType.SemanticKind = svkInteger64);
      Assert.IsTrue(Model.RootClass.FindField('ratio').DataType.SemanticKind = svkFloat);
    finally
      Builder.Free;
    end;
  finally
    Model.Free;
  end;
end;

procedure TGeneratorBuilderTests.InfersGuid;
begin
  AssertSemanticKind('{"value":"550e8400-e29b-41d4-a716-446655440000"}', 'value', svkGuid);
end;

procedure TGeneratorBuilderTests.InfersDate;
begin
  AssertSemanticKind('{"value":"2026-08-05"}', 'value', svkDate);
end;

procedure TGeneratorBuilderTests.InfersTime;
begin
  AssertSemanticKind('{"value":"14:35:27.125"}', 'value', svkTime);
end;

procedure TGeneratorBuilderTests.InfersDateTime;
begin
  AssertSemanticKind('{"value":"2026-08-05T14:35:27Z"}', 'value', svkDateTime);
end;

procedure TGeneratorBuilderTests.InfersUri;
begin
  AssertSemanticKind('{"value":"https://example.com/test"}', 'value', svkUri);
end;

procedure TGeneratorBuilderTests.KeepsRelativeUriAsString;
begin
  AssertSemanticKind('{"value":"/customer/42"}', 'value', svkString);
end;

procedure TGeneratorBuilderTests.MarksNullAsNullable;
var
  Builder: TJsonModelBuilder;
  Model: TGeneratorModel;
  Field: TGeneratorField;
begin
  Model := TGeneratorModel.Create;
  try
    Builder := TJsonModelBuilder.Create(Model);
    try
      Builder.Build('{"value":null}', 'Root');
      Field := Model.RootClass.FindField('value');
      Assert.IsTrue(Field.DataType.Nullable);
      Assert.IsTrue(Field.DataType.JsonKind = jvkNull);
    finally
      Builder.Free;
    end;
  finally
    Model.Free;
  end;
end;

procedure TGeneratorBuilderTests.BuildsOneDimensionalArray;
var
  Builder: TJsonModelBuilder;
  Model: TGeneratorModel;
  Field: TGeneratorField;
begin
  Model := TGeneratorModel.Create;
  try
    Builder := TJsonModelBuilder.Create(Model);
    try
      Builder.Build('{"dates":["2026-08-01","2026-08-02"]}', 'Root');
      Field := Model.RootClass.FindField('dates');
      Assert.AreEqual<Integer>(1, Field.DataType.ArrayDepth);
      Assert.IsTrue(Field.DataType.LeafType.SemanticKind = svkDate);
    finally
      Builder.Free;
    end;
  finally
    Model.Free;
  end;
end;

procedure TGeneratorBuilderTests.BuildsTwoDimensionalArray;
var
  Builder: TJsonModelBuilder;
  Model: TGeneratorModel;
  Field: TGeneratorField;
begin
  Model := TGeneratorModel.Create;
  try
    Builder := TJsonModelBuilder.Create(Model);
    try
      Builder.Build('{"matrix":[[1,2],[3,4]]}', 'Root');
      Field := Model.RootClass.FindField('matrix');
      Assert.AreEqual<Integer>(2, Field.DataType.ArrayDepth);
      Assert.IsTrue(Field.DataType.LeafType.SemanticKind = svkInteger);
    finally
      Builder.Free;
    end;
  finally
    Model.Free;
  end;
end;

procedure TGeneratorBuilderTests.RejectsMoreThanTwoDimensions;
var
  Builder: TJsonModelBuilder;
  Model: TGeneratorModel;
begin
  Model := TGeneratorModel.Create;
  try
    Builder := TJsonModelBuilder.Create(Model);
    try
      try
        Builder.Build('{"matrix":[[[1]]]}', 'Root');
        Assert.Fail('Expected EJsonGenerator');
      except
        on EJsonGenerator do
          ;
      end;
    finally
      Builder.Free;
    end;
  finally
    Model.Free;
  end;
end;

procedure TGeneratorBuilderTests.MarksMissingObjectMembersOptional;
var
  Builder: TJsonModelBuilder;
  Model: TGeneratorModel;
  Rows: TGeneratorClass;
begin
  Model := TGeneratorModel.Create;
  try
    Builder := TJsonModelBuilder.Create(Model);
    try
      Builder.Build('{"rows":[{"a":1},{"b":2}]}', 'Root');
      Rows := Model.FindClass('rows');
      Assert.IsNotNull(Rows);
      Assert.IsTrue(Rows.FindField('a').IsOptional);
      Assert.IsTrue(Rows.FindField('b').IsOptional);
    finally
      Builder.Free;
    end;
  finally
    Model.Free;
  end;
end;

procedure TGeneratorBuilderTests.RetainsSourcePathAndRange;
var
  Builder: TJsonModelBuilder;
  Model: TGeneratorModel;
  Field: TGeneratorField;
begin
  Model := TGeneratorModel.Create;
  try
    Builder := TJsonModelBuilder.Create(Model);
    try
      Builder.Build('{"maybe":null}', 'Root');
      Field := Model.RootClass.FindField('maybe');
      Assert.AreEqual('$.maybe', Field.JsonPath);
      Assert.IsTrue(Field.SourcePosition >= 0);
      Assert.AreEqual<Integer>(4, Field.SourceLength);
    finally
      Builder.Free;
    end;
  finally
    Model.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TGeneratorBuilderTests);

end.
