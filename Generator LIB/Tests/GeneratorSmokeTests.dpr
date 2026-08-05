program GeneratorSmokeTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  TestConsoleRunner in 'TestConsoleRunner.pas',
  GeneratorSmokeTestCases in 'GeneratorSmokeTestCases.pas';

var
  Failed: Integer;
begin
  Failed := RunTests('Generator Smoke Tests', GetGeneratorSmokeTests);
  if Failed > 0 then
    Halt(1);
end.
