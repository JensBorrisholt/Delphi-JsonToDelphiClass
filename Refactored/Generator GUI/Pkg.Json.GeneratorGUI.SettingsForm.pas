unit Pkg.Json.GeneratorGUI.SettingsForm;

interface

uses
  System.Classes, System.SysUtils,
  Vcl.Controls, Vcl.ExtCtrls, Vcl.Forms, Vcl.StdCtrls;

type
  TSettingsForm = class(TForm)
    btnCancel: TButton;
    btnOK: TButton;
    chkAddAttributes: TCheckBox;
    chkPostfixClassNames: TCheckBox;
    chkSuppressZeroDate: TCheckBox;
    chkUsePascalCase: TCheckBox;
    edtPostfix: TEdit;
    lblPostfix: TLabel;
    pnlButtons: TPanel;
    procedure chkPostfixClassNamesClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
  private
    procedure UpdateControls;
  end;

implementation

uses
  Pkg.Json.Settings;

{$R *.dfm}

procedure TSettingsForm.btnOKClick(Sender: TObject);
begin
  TSettings.Instance.AddJsonPropertyAttributes := chkAddAttributes.Checked;
  TSettings.Instance.UsePascalCase := chkUsePascalCase.Checked;
  TSettings.Instance.PostFixClassNames := chkPostfixClassNames.Checked;
  TSettings.Instance.PostFix := Trim(edtPostfix.Text);
  TSettings.Instance.SuppressZeroDate := chkSuppressZeroDate.Checked;
  ModalResult := mrOK;
end;

procedure TSettingsForm.chkPostfixClassNamesClick(Sender: TObject);
begin
  UpdateControls;
end;

procedure TSettingsForm.FormShow(Sender: TObject);
begin
  chkAddAttributes.Checked := TSettings.Instance.AddJsonPropertyAttributes;
  chkUsePascalCase.Checked := TSettings.Instance.UsePascalCase;
  chkPostfixClassNames.Checked := TSettings.Instance.PostFixClassNames;
  edtPostfix.Text := TSettings.Instance.PostFix;
  chkSuppressZeroDate.Checked := TSettings.Instance.SuppressZeroDate;
  UpdateControls;
end;

procedure TSettingsForm.UpdateControls;
begin
  lblPostfix.Enabled := chkPostfixClassNames.Checked;
  edtPostfix.Enabled := chkPostfixClassNames.Checked;
end;

end.
