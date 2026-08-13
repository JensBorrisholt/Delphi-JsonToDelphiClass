unit Tests.Generator.CSharp;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TCSharpSettingsTests = class
  public
    [Test] procedure Defaults;
  end;

  [TestFixture]
  TCSharpNamingTests = class
  public
    [Test] procedure IdentifierSanitizesAndPascalCases;
    [Test] procedure ReservedIdentifierIsEscaped;
    [Test] procedure ClassNamesAreUnique;
    [Test] procedure JsonPropertyAttributeRequiredWhenNameChanges;
  end;

  [TestFixture]
  TCSharpGeneratorTests = class
  public
    [Test] procedure IsValidRecognizesJson;
    [Test] procedure ParseReturnsSelf;
    [Test] procedure GenerateBeforeParseRaises;
    [Test] procedure GeneratesNamespaceAndClass;
    [Test] procedure GeneratesSemanticTypes;
    [Test] procedure GeneratesOneAndTwoDimensionalArrays;
    [Test] procedure NullableValueTypesUseQuestionMark;
    [Test] procedure UriUsesReferenceNullability;
    [Test] procedure RecordsUseInitAccessors;
    [Test] procedure ImmutableClassesUseInitAccessors;
    [Test] procedure ReadonlyListsUseIReadOnlyList;
    [Test] procedure JsonAttributesCanBeForced;
  end;

implementation

uses
  System.SysUtils,
  JsonToDelphi.Generator.CSharp,
  JsonToDelphi.Generator.CSharp.Naming,
  JsonToDelphi.Generator.CSharp.Settings;

procedure TCSharpSettingsTests.Defaults;
var
  Settings: TCSharpSettings;
begin
  Settings := TCSharpSettings.Create;
  try
    Assert.AreEqual('Generated', Settings.NamespaceName);
    Assert.IsTrue(Settings.UsePascalCase);
    Assert.IsFalse(Settings.UseNullableTypes);
    Assert.IsFalse(Settings.AddJsonPropertyNameAttributes);
    Assert.IsFalse(Settings.UseRecords);
    Assert.IsFalse(Settings.GenerateImmutableClasses);
    Assert.IsFalse(Settings.UseReadonlyLists);
  finally
    Settings.Free;
  end;
end;

procedure TCSharpNamingTests.IdentifierSanitizesAndPascalCases;
var
  Naming: TCSharpNaming;
  Settings: TCSharpSettings;
begin
  Settings := TCSharpSettings.Create;
  try
    Naming := TCSharpNaming.Create(Settings);
    try
      Assert.AreEqual('FirstName', Naming.Identifier('first-name'));
    finally
      Naming.Free;
    end;
  finally
    Settings.Free;
  end;
end;

procedure TCSharpNamingTests.ReservedIdentifierIsEscaped;
var
  Naming: TCSharpNaming;
  Settings: TCSharpSettings;
begin
  Settings := TCSharpSettings.Create;
  try
    Settings.UsePascalCase := False;
    Naming := TCSharpNaming.Create(Settings);
    try
      Assert.AreEqual('@class', Naming.Identifier('class'));
    finally
      Naming.Free;
    end;
  finally
    Settings.Free;
  end;
end;

procedure TCSharpNamingTests.ClassNamesAreUnique;
var
  Naming: TCSharpNaming;
  Settings: TCSharpSettings;
begin
  Settings := TCSharpSettings.Create;
  try
    Naming := TCSharpNaming.Create(Settings);
    try
      Assert.AreEqual('Item', Naming.ClassName('item'));
      Assert.AreEqual('Item2', Naming.ClassName('item'));
    finally
      Naming.Free;
    end;
  finally
    Settings.Free;
  end;
end;

procedure TCSharpNamingTests.JsonPropertyAttributeRequiredWhenNameChanges;
var
  Naming: TCSharpNaming;
  Settings: TCSharpSettings;
begin
  Settings := TCSharpSettings.Create;
  try
    Naming := TCSharpNaming.Create(Settings);
    try
      Assert.IsFalse(Naming.NeedsJsonPropertyNameAttribute('Name', 'Name'));
      Assert.IsTrue(Naming.NeedsJsonPropertyNameAttribute('first_name', 'FirstName'));
    finally
      Naming.Free;
    end;
  finally
    Settings.Free;
  end;
end;

procedure TCSharpGeneratorTests.IsValidRecognizesJson;
var
  Generator: TJsonToCSharpGenerator;
begin
  Generator := TJsonToCSharpGenerator.Create;
  try
    Assert.IsTrue(Generator.IsValid('{"id":1}'));
    Assert.IsFalse(Generator.IsValid('{'));
  finally
    Generator.Free;
  end;
end;

procedure TCSharpGeneratorTests.ParseReturnsSelf;
var
  Generator: TJsonToCSharpGenerator;
begin
  Generator := TJsonToCSharpGenerator.Create;
  try
    Assert.IsTrue(Generator = Generator.Parse('{"id":1}'));
  finally
    Generator.Free;
  end;
end;

procedure TCSharpGeneratorTests.GenerateBeforeParseRaises;
var
  Generator: TJsonToCSharpGenerator;
begin
  Generator := TJsonToCSharpGenerator.Create;
  try
    try
      Generator.GenerateSource;
      Assert.Fail('Expected exception');
    except
      on Exception do
        ;
    end;
  finally
    Generator.Free;
  end;
end;

procedure TCSharpGeneratorTests.GeneratesNamespaceAndClass;
var
  Generator: TJsonToCSharpGenerator;
  Source: string;
begin
  Generator := TJsonToCSharpGenerator.Create;
  try
    Generator.RootClassName := 'Order';
    Generator.Parse('{"id":1,"customer":{"name":"Ada"}}');
    Source := Generator.GenerateSource;
    Assert.IsTrue(Source.Contains('namespace Generated;'));
    Assert.IsTrue(Source.Contains('public sealed class Order'));
    Assert.IsTrue(Source.Contains('public int Id { get; set; }'));
    Assert.IsTrue(Source.Contains('public Customer Customer { get; set; } = new();'));
  finally
    Generator.Free;
  end;
end;

procedure TCSharpGeneratorTests.GeneratesSemanticTypes;
var
  Generator: TJsonToCSharpGenerator;
  Source: string;
begin
  Generator := TJsonToCSharpGenerator.Create;
  try
    Generator.Parse('{"id":"550e8400-e29b-41d4-a716-446655440000","date":"2026-08-05","time":"14:35:27","created":"2026-08-05T14:35:27Z","uri":"https://example.com"}');
    Source := Generator.GenerateSource;
    Assert.IsTrue(Source.Contains('public Guid Id'));
    Assert.IsTrue(Source.Contains('public DateOnly Date'));
    Assert.IsTrue(Source.Contains('public TimeOnly Time'));
    Assert.IsTrue(Source.Contains('public DateTimeOffset Created'));
    Assert.IsTrue(Source.Contains('public Uri Uri'));
  finally
    Generator.Free;
  end;
end;

procedure TCSharpGeneratorTests.GeneratesOneAndTwoDimensionalArrays;
var
  Generator: TJsonToCSharpGenerator;
  Source: string;
begin
  Generator := TJsonToCSharpGenerator.Create;
  try
    Generator.Parse('{"ids":[1,2],"matrix":[[1,2],[3,4]]}');
    Source := Generator.GenerateSource;
    Assert.IsTrue(Source.Contains('List<int> Ids'));
    Assert.IsTrue(Source.Contains('List<List<int>> Matrix'));
  finally
    Generator.Free;
  end;
end;

procedure TCSharpGeneratorTests.NullableValueTypesUseQuestionMark;
var
  Generator: TJsonToCSharpGenerator;
  Settings: TCSharpSettings;
  Source: string;
begin
  Settings := TCSharpSettings.Create;
  try
    Settings.UseNullableTypes := True;
    Generator := TJsonToCSharpGenerator.Create(Settings);
    try
      Generator.Parse('{"id":"550e8400-e29b-41d4-a716-446655440000","date":"2026-08-05","time":"14:35:27"}');
      Source := Generator.GenerateSource;
      Assert.IsTrue(Source.Contains('Guid? Id'));
      Assert.IsTrue(Source.Contains('DateOnly? Date'));
      Assert.IsTrue(Source.Contains('TimeOnly? Time'));
    finally
      Generator.Free;
    end;
  finally
    Settings.Free;
  end;
end;

procedure TCSharpGeneratorTests.UriUsesReferenceNullability;
var
  Generator: TJsonToCSharpGenerator;
  Settings: TCSharpSettings;
  Source: string;
begin
  Settings := TCSharpSettings.Create;
  try
    Settings.UseNullableTypes := True;
    Generator := TJsonToCSharpGenerator.Create(Settings);
    try
      Generator.Parse('{"uri":"https://example.com"}');
      Source := Generator.GenerateSource;
      Assert.IsTrue(Source.Contains('public Uri Uri'));
      Assert.IsFalse(Source.Contains('Uri? Uri'));
    finally
      Generator.Free;
    end;
  finally
    Settings.Free;
  end;
end;

procedure TCSharpGeneratorTests.RecordsUseInitAccessors;
var
  Generator: TJsonToCSharpGenerator;
  Settings: TCSharpSettings;
  Source: string;
begin
  Settings := TCSharpSettings.Create;
  try
    Settings.UseRecords := True;
    Generator := TJsonToCSharpGenerator.Create(Settings);
    try
      Generator.Parse('{"name":"Ada"}');
      Source := Generator.GenerateSource;
      Assert.IsTrue(Source.Contains('public sealed record Root'));
      Assert.IsTrue(Source.Contains('{ get; init; }'));
    finally
      Generator.Free;
    end;
  finally
    Settings.Free;
  end;
end;

procedure TCSharpGeneratorTests.ImmutableClassesUseInitAccessors;
var
  Generator: TJsonToCSharpGenerator;
  Settings: TCSharpSettings;
  Source: string;
begin
  Settings := TCSharpSettings.Create;
  try
    Settings.GenerateImmutableClasses := True;
    Generator := TJsonToCSharpGenerator.Create(Settings);
    try
      Generator.Parse('{"name":"Ada"}');
      Source := Generator.GenerateSource;
      Assert.IsTrue(Source.Contains('public sealed class Root'));
      Assert.IsTrue(Source.Contains('{ get; init; }'));
    finally
      Generator.Free;
    end;
  finally
    Settings.Free;
  end;
end;

procedure TCSharpGeneratorTests.ReadonlyListsUseIReadOnlyList;
var
  Generator: TJsonToCSharpGenerator;
  Settings: TCSharpSettings;
  Source: string;
begin
  Settings := TCSharpSettings.Create;
  try
    Settings.UseReadonlyLists := True;
    Generator := TJsonToCSharpGenerator.Create(Settings);
    try
      Generator.Parse('{"ids":[1,2]}');
      Source := Generator.GenerateSource;
      Assert.IsTrue(Source.Contains('IReadOnlyList<int> Ids'));
    finally
      Generator.Free;
    end;
  finally
    Settings.Free;
  end;
end;

procedure TCSharpGeneratorTests.JsonAttributesCanBeForced;
var
  Generator: TJsonToCSharpGenerator;
  Settings: TCSharpSettings;
  Source: string;
begin
  Settings := TCSharpSettings.Create;
  try
    Settings.AddJsonPropertyNameAttributes := True;
    Generator := TJsonToCSharpGenerator.Create(Settings);
    try
      Generator.Parse('{"Name":"Ada"}');
      Source := Generator.GenerateSource;
      Assert.IsTrue(Source.Contains('[JsonPropertyName("Name")]'));
    finally
      Generator.Free;
    end;
  finally
    Settings.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TCSharpSettingsTests);
  TDUnitX.RegisterTestFixture(TCSharpNamingTests);
  TDUnitX.RegisterTestFixture(TCSharpGeneratorTests);

end.
