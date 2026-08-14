unit Tests.Generator.Core;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TGeneratorErrorTests = class
  public
    [Test] procedure CreateAtStoresLocation;
  end;

  [TestFixture]
  TGeneratorSettingsTests = class
  public
    [Test] procedure DelphiSettingsCanBeSavedAndLoaded;
    [Test] procedure CSharpSettingsCanBeSavedAndLoaded;
  end;

implementation

uses
  System.IOUtils,
  JsonToDelphi.Generator.Core.Errors,
  JsonToDelphi.Generator.Delphi.Settings,
  JsonToDelphi.Generator.CSharp.Settings;

procedure TGeneratorErrorTests.CreateAtStoresLocation;
var
  Error: EJsonGenerator;
begin
  Error := EJsonGenerator.CreateAt('Type conflict', '$.items[1]', 12, 7);
  try
    Assert.AreEqual('Type conflict', Error.Message);
    Assert.AreEqual('$.items[1]', Error.JsonPath);
    Assert.AreEqual<Integer>(12, Error.Position);
    Assert.AreEqual<Integer>(7, Error.SelectionLength);
  finally
    Error.Free;
  end;
end;

procedure TGeneratorSettingsTests.DelphiSettingsCanBeSavedAndLoaded;
var
  FileName: string;
  Loaded: TDelphiSettings;
  Settings: TDelphiSettings;
begin
  FileName := TPath.GetTempFileName;
  Settings := TDelphiSettings.Create;
  try
    Settings.AddJsonPropertyAttributes := True;
    Settings.PostFixClassNames := True;
    Settings.PostFix := 'Model';
    Settings.UsePascalCase := False;
    Settings.SuppressZeroDate := False;
    Settings.Save(FileName);

    Loaded := TDelphiSettings.Create;
    try
      Loaded.Load(FileName);
      Assert.IsTrue(Loaded.AddJsonPropertyAttributes);
      Assert.IsTrue(Loaded.PostFixClassNames);
      Assert.AreEqual('Model', Loaded.PostFix);
      Assert.IsFalse(Loaded.UsePascalCase);
      Assert.IsFalse(Loaded.SuppressZeroDate);
    finally
      Loaded.Free;
    end;
  finally
    Settings.Free;
    TFile.Delete(FileName);
  end;
end;

procedure TGeneratorSettingsTests.CSharpSettingsCanBeSavedAndLoaded;
var
  FileName: string;
  Loaded: TCSharpSettings;
  Settings: TCSharpSettings;
begin
  FileName := TPath.GetTempFileName;
  Settings := TCSharpSettings.Create;
  try
    Settings.NamespaceName := 'Acme.Generated';
    Settings.UsePascalCase := False;
    Settings.UseNullableTypes := True;
    Settings.AddJsonPropertyNameAttributes := True;
    Settings.UseRecords := True;
    Settings.GenerateImmutableClasses := True;
    Settings.UseReadonlyLists := True;
    Settings.Save(FileName);

    Loaded := TCSharpSettings.Create;
    try
      Loaded.Load(FileName);
      Assert.AreEqual('Acme.Generated', Loaded.NamespaceName);
      Assert.IsFalse(Loaded.UsePascalCase);
      Assert.IsTrue(Loaded.UseNullableTypes);
      Assert.IsTrue(Loaded.AddJsonPropertyNameAttributes);
      Assert.IsTrue(Loaded.UseRecords);
      Assert.IsTrue(Loaded.GenerateImmutableClasses);
      Assert.IsTrue(Loaded.UseReadonlyLists);
    finally
      Loaded.Free;
    end;
  finally
    Settings.Free;
    TFile.Delete(FileName);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TGeneratorErrorTests);
  TDUnitX.RegisterTestFixture(TGeneratorSettingsTests);

end.
