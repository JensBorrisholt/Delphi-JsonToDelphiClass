unit Pkg.Json.GeneratorGUI.UpdateForm;

interface

uses
  System.Classes,
  Vcl.Controls, Vcl.ExtCtrls, Vcl.Forms, Vcl.StdCtrls,
  Pkg.Json.GeneratorGUI.GitHub;

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
  Pkg.Json.Utils;

{$R *.dfm}

procedure TUpdateForm.btnOpenReleaseClick(Sender: TObject);
begin
  if FRelease <> nil then
    ShellExecute(FRelease.HtmlUrl);
end;

procedure TUpdateForm.FormShow(Sender: TObject);
begin
  if FRelease = nil then
    Exit;
  lblVersion.Caption := 'Version ' + FRelease.TagName + ' is available';
  memReleaseNotes.Text := FRelease.Body;
end;

end.
