program GeneratorSmokeTestsGui;

uses
  Vcl.Forms,
  GeneratorSmokeTestsGui.MainForm in 'GeneratorSmokeTestsGui.MainForm.pas' {SmokeTestsForm},
  GeneratorSmokeTestCases in 'GeneratorSmokeTestCases.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Generator Smoke Tests';
  Application.CreateForm(TSmokeTestsForm, SmokeTestsForm);
  Application.Run;
end.
