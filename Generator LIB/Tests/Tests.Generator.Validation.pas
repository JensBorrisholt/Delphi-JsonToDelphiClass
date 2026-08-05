unit Tests.Generator.Validation;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TGeneratorValidationTests = class
  public
    [Test] procedure AcceptsHomogeneousArrays;
    [Test] procedure AcceptsIntegerInt64Promotion;
    [Test] procedure AcceptsNumericPromotionToDouble;
    [Test] procedure RejectsMixedScalarArrayTypes;
    [Test] procedure ReportsNestedConflictPathAndRange;
    [Test] procedure CollectsSourceLocations;
  end;

implementation

uses
  System.Generics.Collections,
  System.SysUtils,
  Pkg.Json.Generator.Errors,
  Pkg.Json.Generator.Validation;

procedure TGeneratorValidationTests.AcceptsHomogeneousArrays;
begin
  TJsonSourceValidator.ValidateArrayTypes('{"values":[1,2,3]}');
end;

procedure TGeneratorValidationTests.AcceptsIntegerInt64Promotion;
begin
  TJsonSourceValidator.ValidateArrayTypes('[1,2147483648]');
end;

procedure TGeneratorValidationTests.AcceptsNumericPromotionToDouble;
begin
  TJsonSourceValidator.ValidateArrayTypes('[1,2.5,2147483648]');
end;

procedure TGeneratorValidationTests.RejectsMixedScalarArrayTypes;
begin
  try
    TJsonSourceValidator.ValidateArrayTypes('[1,"2"]');
    Assert.Fail('Expected EJsonGenerator');
  except
    on EJsonGenerator do
      ;
  end;
end;

procedure TGeneratorValidationTests.ReportsNestedConflictPathAndRange;
const
  Json = '[[1,2],["3","4"]]';
begin
  try
    TJsonSourceValidator.ValidateArrayTypes(Json);
    Assert.Fail('Expected EJsonGenerator');
  except
    on E: EJsonGenerator do
    begin
      Assert.AreEqual('$[1]', E.JsonPath);
      Assert.AreEqual('["3","4"]', Copy(Json, E.Position + 1, E.SelectionLength));
      Assert.IsTrue(E.Message.Contains('expected Integer, found string'));
    end;
  end;
end;

procedure TGeneratorValidationTests.CollectsSourceLocations;
var
  Locations: TDictionary<string, TJsonSourceLocation>;
  Location: TJsonSourceLocation;
begin
  Locations := TDictionary<string, TJsonSourceLocation>.Create;
  try
    TJsonSourceValidator.ValidateArrayTypes('{"customer":{"name":"Ada"},"ids":[1,2]}', Locations);
    Assert.IsTrue(Locations.TryGetValue('$.customer', Location));
    Assert.IsTrue(Location.Position >= 0);
    Assert.IsTrue(Location.Length > 0);
    Assert.IsTrue(Locations.ContainsKey('$.customer.name'));
    Assert.IsTrue(Locations.ContainsKey('$.ids'));
  finally
    Locations.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TGeneratorValidationTests);

end.
