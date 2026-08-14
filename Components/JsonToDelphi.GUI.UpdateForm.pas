unit JsonToDelphi.GUI.UpdateForm;

interface

uses
  System.Classes,
  Vcl.Controls, Vcl.ExtCtrls, Vcl.Forms, Vcl.StdCtrls,
  JsonToDelphi.GUI.GitHub;

type
  TUpdateForm = class(TForm)
    btnClose: TButton;
    btnOpenRelease: TButton;
    lblVersion: TLabel;
    memReleaseNotes: TMemo;
    pnlButtons: TPanel;
    procedure btnOpenReleaseClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FRelease: TGitHubRelease;
  public
    property NewRelease: TGitHubRelease read FRelease write FRelease;
  end;

implementation

uses
  JsonToDelphi.Runtime.Utils;

{$R *.dfm}

procedure TUpdateForm.btnOpenReleaseClick(Sender: TObject);
begin
  if FRelease.Valid then
    ShellExecute(FRelease.HtmlUrl);
end;

procedure TUpdateForm.FormShow(Sender: TObject);
begin
  if not FRelease.Valid then
    Exit;

  lblVersion.Caption := 'Version ' + FRelease.TagName + ' is available';
  memReleaseNotes.Text := FRelease.Body;
end;

end.
