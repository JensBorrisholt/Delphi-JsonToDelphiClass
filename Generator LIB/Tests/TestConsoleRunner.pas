unit TestConsoleRunner;

interface

uses
  System.SysUtils;

type
  TTestProcedure = procedure;

  TTestCase = record
    Name: string;
    Execute: TTestProcedure;
    class function Create(const AName: string; const AExecute: TTestProcedure): TTestCase; static;
  end;

function RunTests(const ATitle: string; const ATests: TArray<TTestCase>): Integer;

implementation

uses
  System.Diagnostics,
  System.Console;

class function TTestCase.Create(const AName: string; const AExecute: TTestProcedure): TTestCase;
begin
  Result.Name := AName;
  Result.Execute := AExecute;
end;

procedure WriteStatus(const AStatus, AName: string; AElapsedMs: Double; AColor: TConsoleColor);
begin
  Console.ForegroundColor := AColor;
  Console.Write(Format('%-7s', [AStatus]));
  Console.ResetColor;
  Console.WriteLine(Format('%-48s [%9.2f ms]', [AName, AElapsedMs]));
end;

function RunTests(const ATitle: string; const ATests: TArray<TTestCase>): Integer;
var
  Test: TTestCase;
  Stopwatch: TStopwatch;
  TotalStopwatch: TStopwatch;
  Passed: Integer;
  Failed: Integer;
begin
  Passed := 0;
  Failed := 0;
  TotalStopwatch := TStopwatch.StartNew;

  Console.WriteLine(ATitle);
  Console.WriteLine(StringOfChar('-', Length(ATitle)));
  Console.WriteLine;

  for Test in ATests do
  begin
    Stopwatch := TStopwatch.StartNew;
    try
      Test.Execute;
      Stopwatch.Stop;
      Inc(Passed);
      WriteStatus('Passed', Test.Name, Stopwatch.Elapsed.TotalMilliseconds, TConsoleColor.Green);
    except
      on E: Exception do
      begin
        Stopwatch.Stop;
        Inc(Failed);
        WriteStatus('Failed', Test.Name, Stopwatch.Elapsed.TotalMilliseconds, TConsoleColor.Red);
        Console.ForegroundColor := TConsoleColor.DarkRed;
        Console.WriteLine('         ' + E.ClassName + ': ' + E.Message);
        Console.ResetColor;
      end;
    end;
  end;

  TotalStopwatch.Stop;
  Console.WriteLine;
  Console.WriteLine('Summary');
  Console.WriteLine('-------');
  Console.WriteLine(Format('Total:    %d', [Length(ATests)]));

  Console.ForegroundColor := TConsoleColor.Green;
  Console.WriteLine(Format('Passed:   %d', [Passed]));
  Console.ResetColor;

  if Failed > 0 then
    Console.ForegroundColor := TConsoleColor.Red
  else
    Console.ForegroundColor := TConsoleColor.Green;
  Console.WriteLine(Format('Failed:   %d', [Failed]));
  Console.ResetColor;

  Console.WriteLine(Format('Duration: %.2f ms', [TotalStopwatch.Elapsed.TotalMilliseconds]));

  if Failed = 0 then
  begin
    Console.ForegroundColor := TConsoleColor.Green;
    Console.WriteLine;
    Console.WriteLine('Test Run Successful.');
    Console.ResetColor;
  end
  else
  begin
    Console.ForegroundColor := TConsoleColor.Red;
    Console.WriteLine;
    Console.WriteLine('Test Run Failed.');
    Console.ResetColor;
  end;

  Result := Failed;
end;

end.
