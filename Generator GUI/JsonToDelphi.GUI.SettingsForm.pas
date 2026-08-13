unit JsonToDelphi.GUI.SettingsForm;

interface

uses
  System.Classes, System.SysUtils,
  Vcl.ComCtrls, Vcl.Controls, Vcl.ExtCtrls, Vcl.Forms, Vcl.StdCtrls,
  JsonToDelphi.Generator.Delphi.Settings, JsonToDelphi.Generator.CSharp.Settings;

type
  TSettingsForm = class(TForm)
    FPages: TPageControl;
    FDelphiTab: TTabSheet;
    FCSharpTab: TTabSheet;
    FButtonPanel: TPanel;
    FOKButton: TButton;
    FCancelButton: TButton;
    FDelphiUsePascalCase: TCheckBox;
    FDelphiAddAttributes: TCheckBox;
    FDelphiPostfixClassNames: TCheckBox;
    FDelphiPostfixLabel: TLabel;
    FDelphiPostfix: TEdit;
    FDelphiSuppressZeroDate: TCheckBox;
    FCSharpNamespaceLabel: TLabel;
    FCSharpNamespace: TEdit;
    FCSharpUsePascalCase: TCheckBox;
    FCSharpNullableTypes: TCheckBox;
    FCSharpAddAttributes: TCheckBox;
    FCSharpUseRecords: TCheckBox;
    FCSharpImmutable: TCheckBox;
    FCSharpReadonlyLists: TCheckBox;
    procedure DelphiPostfixClassNamesClick(Sender: TObject);
  private
    procedure UpdateControls;
    procedure LoadFromSettings(const ADelphiSettings: TDelphiSettings; const ACSharpSettings: TCSharpSettings);
    procedure SaveToSettings(const ADelphiSettings: TDelphiSettings; const ACSharpSettings: TCSharpSettings);
  public
    class function Execute(AOwner: TComponent; const ADelphiSettings: TDelphiSettings; const ACSharpSettings: TCSharpSettings): Boolean;
  end;

implementation

{$R *.dfm}


class function TSettingsForm.Execute(AOwner: TComponent; const ADelphiSettings: TDelphiSettings; const ACSharpSettings: TCSharpSettings): Boolean;
begin
  with TSettingsForm.Create(AOwner) do
    try
      LoadFromSettings(ADelphiSettings, ACSharpSettings);
      Result := ShowModal = mrOK;
      if Result then
        SaveToSettings(ADelphiSettings, ACSharpSettings);
    finally
      Free;
    end;
end;

procedure TSettingsForm.DelphiPostfixClassNamesClick(Sender: TObject);
begin
  UpdateControls;
end;

procedure TSettingsForm.LoadFromSettings(const ADelphiSettings: TDelphiSettings; const ACSharpSettings: TCSharpSettings);
begin
  FDelphiUsePascalCase.Checked := ADelphiSettings.UsePascalCase;
  FDelphiAddAttributes.Checked := ADelphiSettings.AddJsonPropertyAttributes;
  FDelphiPostfixClassNames.Checked := ADelphiSettings.PostFixClassNames;
  FDelphiPostfix.Text := ADelphiSettings.PostFix;
  FDelphiSuppressZeroDate.Checked := ADelphiSettings.SuppressZeroDate;

  FCSharpNamespace.Text := ACSharpSettings.NamespaceName;
  FCSharpUsePascalCase.Checked := ACSharpSettings.UsePascalCase;
  FCSharpNullableTypes.Checked := ACSharpSettings.UseNullableTypes;
  FCSharpAddAttributes.Checked := ACSharpSettings.AddJsonPropertyNameAttributes;
  FCSharpUseRecords.Checked := ACSharpSettings.UseRecords;
  FCSharpImmutable.Checked := ACSharpSettings.GenerateImmutableClasses;
  FCSharpReadonlyLists.Checked := ACSharpSettings.UseReadonlyLists;

  UpdateControls;
end;

procedure TSettingsForm.SaveToSettings(const ADelphiSettings: TDelphiSettings; const ACSharpSettings: TCSharpSettings);
begin
  ADelphiSettings.UsePascalCase := FDelphiUsePascalCase.Checked;
  ADelphiSettings.AddJsonPropertyAttributes := FDelphiAddAttributes.Checked;
  ADelphiSettings.PostFixClassNames := FDelphiPostfixClassNames.Checked;
  ADelphiSettings.PostFix := Trim(FDelphiPostfix.Text);
  ADelphiSettings.SuppressZeroDate := FDelphiSuppressZeroDate.Checked;

  ACSharpSettings.NamespaceName := Trim(FCSharpNamespace.Text);
  ACSharpSettings.UsePascalCase := FCSharpUsePascalCase.Checked;
  ACSharpSettings.UseNullableTypes := FCSharpNullableTypes.Checked;
  ACSharpSettings.AddJsonPropertyNameAttributes := FCSharpAddAttributes.Checked;
  ACSharpSettings.UseRecords := FCSharpUseRecords.Checked;
  ACSharpSettings.GenerateImmutableClasses := FCSharpImmutable.Checked;
  ACSharpSettings.UseReadonlyLists := FCSharpReadonlyLists.Checked;
end;

procedure TSettingsForm.UpdateControls;
begin
  FDelphiPostfixLabel.Enabled := FDelphiPostfixClassNames.Checked;
  FDelphiPostfix.Enabled := FDelphiPostfixClassNames.Checked;
end;

end.
