program JsonToDelphiClass;

uses
  Vcl.Forms,
  Pkg.Json.GeneratorGUI.SettingsForm in 'Pkg.Json.GeneratorGUI.SettingsForm.pas' {SettingsForm},
  Pkg.Json.Utils in '..\Lib\Pkg.Json.Utils.pas',
  Pkg.Json.GeneratorGUI.MainForm in 'Pkg.Json.GeneratorGUI.MainForm.pas' {MainForm},
  Pkg.Json.Syntax.Incremental in 'Syntax\Pkg.Json.Syntax.Incremental.pas',
  Pkg.Json.Syntax.CSharp in 'Syntax\Pkg.Json.Syntax.CSharp.pas',
  Pkg.Json.GeneratorGUI.Visualizer in '..\Components\Pkg.Json.GeneratorGUI.Visualizer.pas',
  Pkg.Json.GeneratorGUI.DemoProject in '..\Components\Pkg.Json.GeneratorGUI.DemoProject.pas',
  Pkg.Json.GeneratorGUI.DemoData in '..\Components\Pkg.Json.GeneratorGUI.DemoData.pas',
  Pkg.Json.GeneratorGUI.UpdateForm in '..\Components\Pkg.Json.GeneratorGUI.UpdateForm.pas' {UpdateForm},
  Pkg.Json.GeneratorGUI.GitHub in '..\Components\Pkg.Json.GeneratorGUI.GitHub.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'JSON Class Generator';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
