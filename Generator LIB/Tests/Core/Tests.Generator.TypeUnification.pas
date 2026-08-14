unit Tests.Generator.TypeUnification;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TGeneratorTypeUnificationTests = class
  public
    [Test] procedure PromotesIntegerToInt64InBothOrders;
    [Test] procedure PromotesNumericTypesToFloat;
    [Test] procedure MakesConcreteTypeNullableInBothOrders;
    [Test] procedure MergesArrayElementTypesRecursively;
    [Test] procedure MergesObjectStructures;
    [Test] procedure WidensDifferentStringSemanticsToString;
    [Test] procedure ReportsIncompatibleTypeAtSourceLocation;
  end;

implementation

uses
  JsonToDelphi.Generator.Core.Errors,
  JsonToDelphi.Generator.Core.Model,
  JsonToDelphi.Generator.Core.TypeUnification;

function NewType(AJsonKind: TJsonValueKind; ASemanticKind: TSemanticValueKind): TGeneratorType;
begin
  Result := TGeneratorType.Create(AJsonKind, ASemanticKind);
end;

function NewArray(AElementType: TGeneratorType): TGeneratorType;
begin
  Result := TGeneratorType.Create(jvkArray);
  Result.ElementType := AElementType;
end;

procedure AddField(AClass: TGeneratorClass; const AName: string;
  ADataType: TGeneratorType);
var
  Field: TGeneratorField;
begin
  Field := TGeneratorField.Create;
  Field.JsonName := AName;
  Field.JsonPath := '$.' + AName;
  Field.DataType := ADataType;
  AClass.Fields.Add(Field);
end;

procedure TGeneratorTypeUnificationTests.PromotesIntegerToInt64InBothOrders;
var
  DataType: TGeneratorType;
begin
  DataType := NewType(jvkNumber, svkInteger);
  try
    TGeneratorTypeUnifier.Merge(DataType, NewType(jvkNumber, svkInteger64), '$.value');
    Assert.IsTrue(DataType.SemanticKind = svkInteger64);
  finally
    DataType.Free;
  end;

  DataType := NewType(jvkNumber, svkInteger64);
  try
    TGeneratorTypeUnifier.Merge(DataType, NewType(jvkNumber, svkInteger), '$.value');
    Assert.IsTrue(DataType.SemanticKind = svkInteger64);
  finally
    DataType.Free;
  end;
end;

procedure TGeneratorTypeUnificationTests.PromotesNumericTypesToFloat;
var
  DataType: TGeneratorType;
begin
  DataType := NewType(jvkNumber, svkInteger);
  try
    TGeneratorTypeUnifier.Merge(DataType, NewType(jvkNumber, svkFloat), '$.value');
    Assert.IsTrue(DataType.SemanticKind = svkFloat);
  finally
    DataType.Free;
  end;
end;

procedure TGeneratorTypeUnificationTests.MakesConcreteTypeNullableInBothOrders;
var
  DataType: TGeneratorType;
  NullType: TGeneratorType;
begin
  DataType := NewType(jvkNumber, svkInteger);
  try
    NullType := NewType(jvkNull, svkUnknown);
    NullType.Nullable := True;
    TGeneratorTypeUnifier.Merge(DataType, NullType, '$.value');
    Assert.IsTrue(DataType.Nullable);
    Assert.IsTrue(DataType.SemanticKind = svkInteger);
  finally
    DataType.Free;
  end;

  DataType := NewType(jvkNull, svkUnknown);
  DataType.Nullable := True;
  try
    TGeneratorTypeUnifier.Merge(DataType, NewType(jvkNumber, svkInteger), '$.value');
    Assert.IsTrue(DataType.Nullable);
    Assert.IsTrue(DataType.SemanticKind = svkInteger);
  finally
    DataType.Free;
  end;
end;

procedure TGeneratorTypeUnificationTests.MergesArrayElementTypesRecursively;
var
  DataType: TGeneratorType;
begin
  DataType := NewArray(NewArray(NewType(jvkNumber, svkInteger)));
  try
    TGeneratorTypeUnifier.Merge(DataType,
      NewArray(NewArray(NewType(jvkNumber, svkFloat))), '$.matrix');
    Assert.IsTrue(DataType.LeafType.SemanticKind = svkFloat);
  finally
    DataType.Free;
  end;
end;

procedure TGeneratorTypeUnificationTests.MergesObjectStructures;
var
  LeftClass: TGeneratorClass;
  LeftType: TGeneratorType;
  RightClass: TGeneratorClass;
  RightType: TGeneratorType;
begin
  LeftClass := TGeneratorClass.Create;
  RightClass := TGeneratorClass.Create;
  LeftType := NewType(jvkObject, svkObject);
  try
    LeftType.ObjectClass := LeftClass;
    AddField(LeftClass, 'id', NewType(jvkNumber, svkInteger));
    AddField(LeftClass, 'name', NewType(jvkString, svkString));

    RightType := NewType(jvkObject, svkObject);
    RightType.ObjectClass := RightClass;
    AddField(RightClass, 'id', NewType(jvkNumber, svkInteger64));
    AddField(RightClass, 'active', NewType(jvkBoolean, svkBoolean));

    TGeneratorTypeUnifier.Merge(LeftType, RightType, '$.person');
    Assert.IsTrue(LeftClass.FindField('id').DataType.SemanticKind = svkInteger64);
    Assert.IsTrue(LeftClass.FindField('name').IsOptional);
    Assert.IsTrue(LeftClass.FindField('active').IsOptional);
  finally
    LeftType.Free;
    LeftClass.Free;
    RightClass.Free;
  end;
end;

procedure TGeneratorTypeUnificationTests.WidensDifferentStringSemanticsToString;
var
  DataType: TGeneratorType;
begin
  DataType := NewType(jvkString, svkDate);
  try
    TGeneratorTypeUnifier.Merge(DataType, NewType(jvkString, svkString), '$.value');
    Assert.IsTrue(DataType.SemanticKind = svkString);
  finally
    DataType.Free;
  end;
end;

procedure TGeneratorTypeUnificationTests.ReportsIncompatibleTypeAtSourceLocation;
var
  DataType: TGeneratorType;
begin
  DataType := NewType(jvkNumber, svkInteger);
  try
    try
      TGeneratorTypeUnifier.Merge(DataType, NewType(jvkString, svkString), '$[1]', 3, 3);
      Assert.Fail('Expected EJsonGenerator');
    except
      on E: EJsonGenerator do
      begin
        Assert.AreEqual('$[1]', E.JsonPath);
        Assert.AreEqual<Integer>(3, E.Position);
        Assert.AreEqual<Integer>(3, E.SelectionLength);
      end;
    end;
  finally
    DataType.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TGeneratorTypeUnificationTests);

end.
