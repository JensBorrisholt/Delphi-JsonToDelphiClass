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
    [Test] procedure AcceptsMixedScalarArrayTypes;
    [Test] procedure CollectsNestedSourceLocations;
    [Test] procedure CollectsSourceLocations;
  end;

implementation

uses
  System.Generics.Collections,
  System.SysUtils,
  JsonToDelphi.Generator.Core.Errors,
  JsonToDelphi.Generator.Core.Validation;

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

procedure TGeneratorValidationTests.AcceptsMixedScalarArrayTypes;
begin
  TJsonSourceValidator.ValidateArrayTypes('[1,"2"]');
end;

procedure TGeneratorValidationTests.CollectsNestedSourceLocations;
const
  Json = '[[1,2],["3","4"]]';
var
  Location: TJsonSourceLocation;
  Locations: TDictionary<string, TJsonSourceLocation>;
begin
  Locations := TDictionary<string, TJsonSourceLocation>.Create;
  try
    TJsonSourceValidator.ValidateArrayTypes(Json, Locations);
    Assert.IsTrue(Locations.TryGetValue('$[1]', Location));
    Assert.AreEqual('["3","4"]', Copy(Json, Location.Position + 1, Location.Length));
  finally
    Locations.Free;
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
