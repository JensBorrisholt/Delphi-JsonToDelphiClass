program Demo;

uses
  Vcl.Forms,
  Demo.DemoHelper in '..\Demo Helper\Demo.DemoHelper.pas',
  FormMain in 'FormMain.pas' {MainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
