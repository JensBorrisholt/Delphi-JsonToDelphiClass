program GeneratorLibTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Console,
  DUnitX.TestFramework,
  Tests.ConsoleLogger in 'Runner\Tests.ConsoleLogger.pas',
  Tests.Generator.Core in 'Core\Tests.Generator.Core.pas',
  Tests.Generator.Model in 'Core\Tests.Generator.Model.pas',
  Tests.Generator.Validation in 'Core\Tests.Generator.Validation.pas',
  Tests.Generator.Builder in 'Core\Tests.Generator.Builder.pas',
  Tests.Generator.Delphi in 'Delphi\Tests.Generator.Delphi.pas',
  Tests.Generator.CSharp in 'CSharp\Tests.Generator.CSharp.pas';

var
  Runner: ITestRunner;
  Results: IRunResults;
begin
  TDUnitX.Options.HideBanner := True;
  TDUnitX.CheckCommandLine;
  Runner := TDUnitX.CreateRunner;
  Runner.UseRTTI := True;
  Runner.AddLogger(TGeneratorConsoleLogger.Create);
  Results := Runner.Execute;
  if not Results.AllPassed then
    ExitCode := EXIT_ERRORS;
  Console.ReadLine;
end.
