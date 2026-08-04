unit Pkg.Json.GeneratorGUI.SettingsForm;

interface

uses
  System.Classes, System.SysUtils,
  Vcl.ComCtrls, Vcl.Controls, Vcl.ExtCtrls, Vcl.Forms, Vcl.StdCtrls,
  Pkg.Json.Generator.DelphiSettings, Pkg.Json.Generator.CSharpSettings;

type
  TSettingsForm = class(TForm)
  private
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

    procedure BuildForm;
    procedure DelphiPostfixClassNamesClick(Sender: TObject);
    procedure UpdateControls;
    procedure LoadFromSettings(const ADelphiSettings: TDelphiSettings; const ACSharpSettings: TCSharpSettings);
    procedure SaveToSettings(const ADelphiSettings: TDelphiSettings; const ACSharpSettings: TCSharpSettings);
  public
    constructor Create(AOwner: TComponent); override;
    class function Execute(AOwner: TComponent; const ADelphiSettings: TDelphiSettings; const ACSharpSettings: TCSharpSettings): Boolean;
  end;

implementation

{$R *.dfm}

constructor TSettingsForm.Create(AOwner: TComponent);
begin
  inherited;
  BuildForm;
end;

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

procedure TSettingsForm.BuildForm;
var
  TopPos: Integer;
begin
  Caption := 'Generator settings';
  BorderStyle := bsDialog;
  Position := poOwnerFormCenter;
  ClientWidth := 460;
  ClientHeight := 390;

  FPages := TPageControl.Create(Self);
  FPages.Parent := Self;
  FPages.Align := alClient;

  FDelphiTab := TTabSheet.Create(Self);
  FDelphiTab.PageControl := FPages;
  FDelphiTab.Caption := 'Delphi';

  FCSharpTab := TTabSheet.Create(Self);
  FCSharpTab.PageControl := FPages;
  FCSharpTab.Caption := 'C#';

  FDelphiUsePascalCase := TCheckBox.Create(Self);
  FDelphiUsePascalCase.Parent := FDelphiTab;
  FDelphiUsePascalCase.Left := 20;
  FDelphiUsePascalCase.Top := 20;
  FDelphiUsePascalCase.Width := 300;
  FDelphiUsePascalCase.Caption := 'Use PascalCase identifiers';

  FDelphiAddAttributes := TCheckBox.Create(Self);
  FDelphiAddAttributes.Parent := FDelphiTab;
  FDelphiAddAttributes.Left := 20;
  FDelphiAddAttributes.Top := 52;
  FDelphiAddAttributes.Width := 350;
  FDelphiAddAttributes.Caption := 'Add JSON property attributes';

  FDelphiPostfixClassNames := TCheckBox.Create(Self);
  FDelphiPostfixClassNames.Parent := FDelphiTab;
  FDelphiPostfixClassNames.Left := 20;
  FDelphiPostfixClassNames.Top := 84;
  FDelphiPostfixClassNames.Width := 300;
  FDelphiPostfixClassNames.Caption := 'Postfix generated class names';
  FDelphiPostfixClassNames.OnClick := DelphiPostfixClassNamesClick;

  FDelphiPostfixLabel := TLabel.Create(Self);
  FDelphiPostfixLabel.Parent := FDelphiTab;
  FDelphiPostfixLabel.Left := 44;
  FDelphiPostfixLabel.Top := 116;
  FDelphiPostfixLabel.Caption := 'Postfix';

  FDelphiPostfix := TEdit.Create(Self);
  FDelphiPostfix.Parent := FDelphiTab;
  FDelphiPostfix.Left := 44;
  FDelphiPostfix.Top := 135;
  FDelphiPostfix.Width := 170;

  FDelphiSuppressZeroDate := TCheckBox.Create(Self);
  FDelphiSuppressZeroDate.Parent := FDelphiTab;
  FDelphiSuppressZeroDate.Left := 20;
  FDelphiSuppressZeroDate.Top := 174;
  FDelphiSuppressZeroDate.Width := 350;
  FDelphiSuppressZeroDate.Caption := 'Suppress zero date values';

  TopPos := 20;

  FCSharpNamespaceLabel := TLabel.Create(Self);
  FCSharpNamespaceLabel.Parent := FCSharpTab;
  FCSharpNamespaceLabel.Left := 20;
  FCSharpNamespaceLabel.Top := TopPos;
  FCSharpNamespaceLabel.Caption := 'Namespace';

  FCSharpNamespace := TEdit.Create(Self);
  FCSharpNamespace.Parent := FCSharpTab;
  FCSharpNamespace.Left := 20;
  FCSharpNamespace.Top := TopPos + 19;
  FCSharpNamespace.Width := 300;

  Inc(TopPos, 58);

  FCSharpUsePascalCase := TCheckBox.Create(Self);
  FCSharpUsePascalCase.Parent := FCSharpTab;
  FCSharpUsePascalCase.Left := 20;
  FCSharpUsePascalCase.Top := TopPos;
  FCSharpUsePascalCase.Width := 350;
  FCSharpUsePascalCase.Caption := 'Use PascalCase identifiers';

  Inc(TopPos, 32);

  FCSharpNullableTypes := TCheckBox.Create(Self);
  FCSharpNullableTypes.Parent := FCSharpTab;
  FCSharpNullableTypes.Left := 20;
  FCSharpNullableTypes.Top := TopPos;
  FCSharpNullableTypes.Width := 350;
  FCSharpNullableTypes.Caption := 'Use nullable primitive types';

  Inc(TopPos, 32);

  FCSharpAddAttributes := TCheckBox.Create(Self);
  FCSharpAddAttributes.Parent := FCSharpTab;
  FCSharpAddAttributes.Left := 20;
  FCSharpAddAttributes.Top := TopPos;
  FCSharpAddAttributes.Width := 350;
  FCSharpAddAttributes.Caption := 'Add JsonPropertyName attributes';

  Inc(TopPos, 32);

  FCSharpUseRecords := TCheckBox.Create(Self);
  FCSharpUseRecords.Parent := FCSharpTab;
  FCSharpUseRecords.Left := 20;
  FCSharpUseRecords.Top := TopPos;
  FCSharpUseRecords.Width := 350;
  FCSharpUseRecords.Caption := 'Generate records';

  Inc(TopPos, 32);

  FCSharpImmutable := TCheckBox.Create(Self);
  FCSharpImmutable.Parent := FCSharpTab;
  FCSharpImmutable.Left := 20;
  FCSharpImmutable.Top := TopPos;
  FCSharpImmutable.Width := 350;
  FCSharpImmutable.Caption := 'Generate init-only properties';

  Inc(TopPos, 32);

  FCSharpReadonlyLists := TCheckBox.Create(Self);
  FCSharpReadonlyLists.Parent := FCSharpTab;
  FCSharpReadonlyLists.Left := 20;
  FCSharpReadonlyLists.Top := TopPos;
  FCSharpReadonlyLists.Width := 350;
  FCSharpReadonlyLists.Caption := 'Use IReadOnlyList for arrays';

  FButtonPanel := TPanel.Create(Self);
  FButtonPanel.Parent := Self;
  FButtonPanel.Align := alBottom;
  FButtonPanel.Height := 45;
  FButtonPanel.BevelOuter := bvNone;

  FOKButton := TButton.Create(Self);
  FOKButton.Parent := FButtonPanel;
  FOKButton.Left := ClientWidth - 172;
  FOKButton.Top := 8;
  FOKButton.Width := 75;
  FOKButton.Height := 27;
  FOKButton.Caption := 'OK';
  FOKButton.Default := True;
  FOKButton.ModalResult := mrOK;

  FCancelButton := TButton.Create(Self);
  FCancelButton.Parent := FButtonPanel;
  FCancelButton.Left := ClientWidth - 91;
  FCancelButton.Top := 8;
  FCancelButton.Width := 75;
  FCancelButton.Height := 27;
  FCancelButton.Cancel := True;
  FCancelButton.Caption := 'Cancel';
  FCancelButton.ModalResult := mrCancel;
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
