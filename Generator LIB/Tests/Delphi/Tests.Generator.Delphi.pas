unit Tests.Generator.Delphi;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TDelphiSettingsTests = class
  public
    [Test] procedure Defaults;
    [Test] procedure ClassPostFixDisabled;
    [Test] procedure ClassPostFixEnabled;
  end;

  [TestFixture]
  TDelphiNamingTests = class
  public
    [Test] procedure IdentifierSanitizesAndPascalCases;
    [Test] procedure IdentifierGetsFallback;
    [Test] procedure IdentifierStartingWithDigitGetsPrefix;
    [Test] procedure ReservedPropertyNameIsEscaped;
    [Test] procedure ClassNamesAreUnique;
    [Test] procedure JsonNameAttributeRequiredWhenNameChanges;
  end;

  [TestFixture]
  TDelphiGeneratorTests = class
  public
    [Test] procedure IsValidRecognizesJson;
    [Test] procedure ParseReturnsSelf;
    [Test] procedure GenerateRequiresDestinationUnitName;
    [Test] procedure GeneratesObjectGraph;
    [Test] procedure GeneratesPrimitiveRootArray;
    [Test] procedure GeneratesTwoDimensionalArray;
    [Test] procedure GeneratesSemanticTypes;
    [Test] procedure IncludesUriUnitOnlyWhenNeeded;
    [Test] procedure SuppressZeroDateCanBeDisabled;
    [Test] procedure JsonAttributesCanBeForced;
    [Test] procedure ClassPostFixIsApplied;
  end;

implementation

uses
  System.SysUtils,
  JsonToDelphi.Generator.Delphi,
  JsonToDelphi.Generator.Delphi.Naming,
  JsonToDelphi.Generator.Delphi.Settings;

procedure TDelphiSettingsTests.Defaults;
var
  Settings: TDelphiSettings;
begin
  Settings := TDelphiSettings.Create;
  try
    Assert.IsFalse(Settings.AddJsonPropertyAttributes);
    Assert.IsFalse(Settings.PostFixClassNames);
    Assert.AreEqual('DTO', Settings.PostFix);
    Assert.IsTrue(Settings.UsePascalCase);
    Assert.IsTrue(Settings.SuppressZeroDate);
  finally
    Settings.Free;
  end;
end;

procedure TDelphiSettingsTests.ClassPostFixDisabled;
var
  Settings: TDelphiSettings;
begin
  Settings := TDelphiSettings.Create;
  try
    Assert.AreEqual('', Settings.ClassPostFix);
  finally
    Settings.Free;
  end;
end;

procedure TDelphiSettingsTests.ClassPostFixEnabled;
var
  Settings: TDelphiSettings;
begin
  Settings := TDelphiSettings.Create;
  try
    Settings.PostFixClassNames := True;
    Settings.PostFix := 'Dto';
    Assert.AreEqual('Dto', Settings.ClassPostFix);
  finally
    Settings.Free;
  end;
end;

procedure TDelphiNamingTests.IdentifierSanitizesAndPascalCases;
var
  Naming: TDelphiNaming;
  Settings: TDelphiSettings;
begin
  Settings := TDelphiSettings.Create;
  try
    Naming := TDelphiNaming.Create(Settings);
    try
      Assert.AreEqual('FirstName', Naming.Identifier('first-name'));
    finally
      Naming.Free;
    end;
  finally
    Settings.Free;
  end;
end;

procedure TDelphiNamingTests.IdentifierGetsFallback;
var
  Naming: TDelphiNaming;
  Settings: TDelphiSettings;
begin
  Settings := TDelphiSettings.Create;
  try
    Naming := TDelphiNaming.Create(Settings);
    try
      Assert.AreEqual('Property', Naming.Identifier('---'));
    finally
      Naming.Free;
    end;
  finally
    Settings.Free;
  end;
end;

procedure TDelphiNamingTests.IdentifierStartingWithDigitGetsPrefix;
var
  Naming: TDelphiNaming;
  Settings: TDelphiSettings;
begin
  Settings := TDelphiSettings.Create;
  try
    Naming := TDelphiNaming.Create(Settings);
    try
      Assert.AreEqual('_123Name', Naming.Identifier('123_name'));
    finally
      Naming.Free;
    end;
  finally
    Settings.Free;
  end;
end;

procedure TDelphiNamingTests.ReservedPropertyNameIsEscaped;
var
  Naming: TDelphiNaming;
  Settings: TDelphiSettings;
begin
  Settings := TDelphiSettings.Create;
  try
    Naming := TDelphiNaming.Create(Settings);
    try
      Assert.AreEqual('&type', Naming.PropertyName('type'));
    finally
      Naming.Free;
    end;
  finally
    Settings.Free;
  end;
end;

procedure TDelphiNamingTests.ClassNamesAreUnique;
var
  Naming: TDelphiNaming;
  Settings: TDelphiSettings;
begin
  Settings := TDelphiSettings.Create;
  try
    Naming := TDelphiNaming.Create(Settings);
    try
      Assert.AreEqual('TItem', Naming.ClassName('item'));
      Assert.AreEqual('TItemA', Naming.ClassName('item'));
    finally
      Naming.Free;
    end;
  finally
    Settings.Free;
  end;
end;

procedure TDelphiNamingTests.JsonNameAttributeRequiredWhenNameChanges;
var
  Naming: TDelphiNaming;
  Settings: TDelphiSettings;
begin
  Settings := TDelphiSettings.Create;
  try
    Naming := TDelphiNaming.Create(Settings);
    try
      Assert.IsFalse(Naming.NeedsJsonNameAttribute('Name', 'Name'));
      Assert.IsTrue(Naming.NeedsJsonNameAttribute('first_name', 'FirstName'));
    finally
      Naming.Free;
    end;
  finally
    Settings.Free;
  end;
end;

procedure TDelphiGeneratorTests.IsValidRecognizesJson;
var
  Generator: TJsonToDelphiGenerator;
begin
  Generator := TJsonToDelphiGenerator.Create;
  try
    Assert.IsTrue(Generator.IsValid('{"id":1}'));
    Assert.IsFalse(Generator.IsValid('{'));
  finally
    Generator.Free;
  end;
end;

procedure TDelphiGeneratorTests.ParseReturnsSelf;
var
  Generator: TJsonToDelphiGenerator;
begin
  Generator := TJsonToDelphiGenerator.Create;
  try
    Assert.IsTrue(Generator = Generator.Parse('{"id":1}'));
  finally
    Generator.Free;
  end;
end;

procedure TDelphiGeneratorTests.GenerateRequiresDestinationUnitName;
var
  Generator: TJsonToDelphiGenerator;
begin
  Generator := TJsonToDelphiGenerator.Create;
  try
    Generator.Parse('{"id":1}');
    Generator.DestinationUnitName := '';
    try
      Generator.GenerateUnit;
      Assert.Fail('Expected EArgumentException');
    except
      on EArgumentException do
        ;
    end;
  finally
    Generator.Free;
  end;
end;

procedure TDelphiGeneratorTests.GeneratesObjectGraph;
var
  Generator: TJsonToDelphiGenerator;
  Source: string;
begin
  Generator := TJsonToDelphiGenerator.Create;
  try
    Generator.RootClassName := 'Order';
    Generator.DestinationUnitName := 'OrderDTO';
    Generator.Parse('{"id":1,"customer":{"name":"Ada"},"lines":[{"sku":"A"},{"sku":"B"}]}');
    Source := Generator.GenerateUnit;
    Assert.IsTrue(Source.Contains('unit OrderDTO;'));
    Assert.IsTrue(Source.Contains('TOrder = class(TJsonDTO)'));
    Assert.IsTrue(Source.Contains('property Lines: TObjectList<TLines>'));
  finally
    Generator.Free;
  end;
end;

procedure TDelphiGeneratorTests.GeneratesPrimitiveRootArray;
var
  Generator: TJsonToDelphiGenerator;
begin
  Generator := TJsonToDelphiGenerator.Create;
  try
    Generator.Parse('[1,2,3]');
    Assert.IsTrue(Generator.GenerateUnit.Contains('property Items: TList<Integer>'));
  finally
    Generator.Free;
  end;
end;

procedure TDelphiGeneratorTests.GeneratesTwoDimensionalArray;
var
  Generator: TJsonToDelphiGenerator;
  Source: string;
begin
  Generator := TJsonToDelphiGenerator.Create;
  try
    Generator.Parse('[[1,2],[3,4]]');
    Source := Generator.GenerateUnit;
    Assert.IsTrue(Source.Contains('FItemsArray: TArray<TArray<Integer>>;'));
    Assert.IsTrue(Source.Contains('property Items: TObjectList<TList<Integer>>'));
    Assert.IsTrue(Source.Contains('RefreshArray2D<Integer>'));
  finally
    Generator.Free;
  end;
end;

procedure TDelphiGeneratorTests.GeneratesSemanticTypes;
var
  Generator: TJsonToDelphiGenerator;
  Source: string;
begin
  Generator := TJsonToDelphiGenerator.Create;
  try
    Generator.Parse('{"id":"550e8400-e29b-41d4-a716-446655440000","date":"2026-08-05","time":"14:35:27","created":"2026-08-05T14:35:27Z","uri":"https://example.com"}');
    Source := Generator.GenerateUnit;
    Assert.IsTrue(Source.Contains('FId: TGUID;'));
    Assert.IsTrue(Source.Contains('FDate: TDate;'));
    Assert.IsTrue(Source.Contains('FTime: TTime;'));
    Assert.IsTrue(Source.Contains('FCreated: TDateTime;'));
    Assert.IsTrue(Source.Contains('FUri: TURI;'));
  finally
    Generator.Free;
  end;
end;

procedure TDelphiGeneratorTests.IncludesUriUnitOnlyWhenNeeded;
var
  Generator: TJsonToDelphiGenerator;
  Source: string;
begin
  Generator := TJsonToDelphiGenerator.Create;
  try
    Generator.Parse('{"uri":"https://example.com"}');
    Source := Generator.GenerateUnit;
    Assert.IsTrue(Source.Contains('System.Net.URLClient'));
    Generator.Parse('{"name":"Ada"}');
    Source := Generator.GenerateUnit;
    Assert.IsFalse(Source.Contains('System.Net.URLClient'));
  finally
    Generator.Free;
  end;
end;

procedure TDelphiGeneratorTests.SuppressZeroDateCanBeDisabled;
var
  Generator: TJsonToDelphiGenerator;
  Settings: TDelphiSettings;
begin
  Settings := TDelphiSettings.Create;
  try
    Settings.SuppressZeroDate := False;
    Generator := TJsonToDelphiGenerator.Create(Settings);
    try
      Generator.Parse('{"date":"2026-08-05"}');
      Assert.IsFalse(Generator.GenerateUnit.Contains('SuppressZero'));
    finally
      Generator.Free;
    end;
  finally
    Settings.Free;
  end;
end;

procedure TDelphiGeneratorTests.JsonAttributesCanBeForced;
var
  Generator: TJsonToDelphiGenerator;
  Settings: TDelphiSettings;
begin
  Settings := TDelphiSettings.Create;
  try
    Settings.AddJsonPropertyAttributes := True;
    Generator := TJsonToDelphiGenerator.Create(Settings);
    try
      Generator.Parse('{"Name":"Ada"}');
      Assert.IsTrue(Generator.GenerateUnit.Contains('[JSONName(''Name'')]'));
    finally
      Generator.Free;
    end;
  finally
    Settings.Free;
  end;
end;

procedure TDelphiGeneratorTests.ClassPostFixIsApplied;
var
  Generator: TJsonToDelphiGenerator;
  Settings: TDelphiSettings;
begin
  Settings := TDelphiSettings.Create;
  try
    Settings.PostFixClassNames := True;
    Settings.PostFix := 'DTO';
    Generator := TJsonToDelphiGenerator.Create(Settings);
    try
      Generator.RootClassName := 'Order';
      Generator.Parse('{"id":1}');
      Assert.AreEqual('TOrderDTO', Generator.GeneratedRootClassName);
    finally
      Generator.Free;
    end;
  finally
    Settings.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TDelphiSettingsTests);
  TDUnitX.RegisterTestFixture(TDelphiNamingTests);
  TDUnitX.RegisterTestFixture(TDelphiGeneratorTests);

end.
