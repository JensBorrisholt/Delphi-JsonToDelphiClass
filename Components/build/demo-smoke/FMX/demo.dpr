program demo;

uses
  System.StartUpCopy,
  FMX.Forms,
  MainU in 'MainU.pas' {FormMain},
  Demo.DemoHelper in '..\Demo Helper\Demo.DemoHelper.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
