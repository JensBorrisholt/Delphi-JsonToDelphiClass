program JsonToDelphiClass;

{$R 'DemoTemplate.res' '..\Components\DemoTemplate.rc'}
{$R 'JSON_PAS.res' '..\Runtime\JSON_PAS.rc'}

uses
  Vcl.Forms,
  JsonToDelphi.GUI.SettingsForm in 'JsonToDelphi.GUI.SettingsForm.pas' {SettingsForm},
  JsonToDelphi.Runtime.Utils in '..\Runtime\JsonToDelphi.Runtime.Utils.pas',
  JsonToDelphi.GUI.MainForm in 'JsonToDelphi.GUI.MainForm.pas' {MainForm},
  JsonToDelphi.GUI.Syntax.Incremental in 'Syntax\JsonToDelphi.GUI.Syntax.Incremental.pas',
  JsonToDelphi.GUI.Syntax.CSharp in 'Syntax\JsonToDelphi.GUI.Syntax.CSharp.pas',
  JsonToDelphi.GUI.Visualizer in '..\Components\JsonToDelphi.GUI.Visualizer.pas',
  JsonToDelphi.GUI.DemoProject in '..\Components\JsonToDelphi.GUI.DemoProject.pas',
  JsonToDelphi.GUI.DemoData in '..\Components\JsonToDelphi.GUI.DemoData.pas',
  JsonToDelphi.GUI.UpdateForm in '..\Components\JsonToDelphi.GUI.UpdateForm.pas' {UpdateForm},
  JsonToDelphi.GUI.GitHub in '..\Components\JsonToDelphi.GUI.GitHub.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'JSON Class Generator';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
