program GeneratorSmokeTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  TestConsoleRunner in 'TestConsoleRunner.pas',
  GeneratorSmokeTestCases in 'GeneratorSmokeTestCases.pas';

var
  Failed: Integer;
begin
  if (ParamCount = 2) and SameText(ParamStr(1), '--write-csharp-matrix') then
  begin
    WriteCSharpMatrixFixture(ParamStr(2));
    Halt(0);
  end;
  Failed := RunTests('Generator Smoke Tests', GetGeneratorSmokeTests);
  if Failed > 0 then
    Halt(1);
end.
