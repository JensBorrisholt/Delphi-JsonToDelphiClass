unit Tests.ConsoleLogger;

interface

uses
  System.Console,
  DUnitX.TestFramework;

type
  TGeneratorConsoleLogger = class(TInterfacedObject, ITestLogger)
  private
    FLastFixture: string;
    procedure WriteResult(const AStatus: string; const AResult: ITestResult; AColor: TConsoleColor);
    procedure WriteErrorDetails(const AError: ITestError);
  protected
    procedure OnTestingStarts(const threadId: TThreadID; testCount, testActiveCount: Cardinal);
    procedure OnStartTestFixture(const threadId: TThreadID; const fixture: ITestFixtureInfo);
    procedure OnSetupFixture(const threadId: TThreadID; const fixture: ITestFixtureInfo);
    procedure OnEndSetupFixture(const threadId: TThreadID; const fixture: ITestFixtureInfo);
    procedure OnBeginTest(const threadId: TThreadID; const Test: ITestInfo);
    procedure OnSetupTest(const threadId: TThreadID; const Test: ITestInfo);
    procedure OnEndSetupTest(const threadId: TThreadID; const Test: ITestInfo);
    procedure OnExecuteTest(const threadId: TThreadID; const Test: ITestInfo);
    procedure OnTestSuccess(const threadId: TThreadID; const Test: ITestResult);
    procedure OnTestError(const threadId: TThreadID; const Error: ITestError);
    procedure OnTestFailure(const threadId: TThreadID; const Failure: ITestError);
    procedure OnTestIgnored(const threadId: TThreadID; const AIgnored: ITestResult);
    procedure OnTestMemoryLeak(const threadId: TThreadID; const Test: ITestResult);
    procedure OnLog(const logType: TLogLevel; const msg: string);
    procedure OnTeardownTest(const threadId: TThreadID; const Test: ITestInfo);
    procedure OnEndTeardownTest(const threadId: TThreadID; const Test: ITestInfo);
    procedure OnEndTest(const threadId: TThreadID; const Test: ITestResult);
    procedure OnTearDownFixture(const threadId: TThreadID; const fixture: ITestFixtureInfo);
    procedure OnEndTearDownFixture(const threadId: TThreadID; const fixture: ITestFixtureInfo);
    procedure OnEndTestFixture(const threadId: TThreadID; const results: IFixtureResult);
    procedure OnTestingEnds(const RunResults: IRunResults);
  end;

implementation

uses
  System.SysUtils;

procedure TGeneratorConsoleLogger.WriteResult(const AStatus: string; const AResult: ITestResult; AColor: TConsoleColor);
var
  Name: string;
begin
  Name := AResult.Test.MethodName;
  if Name = '' then
    Name := AResult.Test.Name;

  Console.ForegroundColor := AColor;
  Console.Write(Format('  %-8s', [AStatus]));
  Console.ResetColor;
  Console.WriteLine(Format('%-52s [%9.2f ms]', [Name, AResult.Duration.TotalMilliseconds]));
end;

procedure TGeneratorConsoleLogger.WriteErrorDetails(const AError: ITestError);
begin
  Console.ForegroundColor := TConsoleColor.DarkRed;
  Console.WriteLine('           ' + AError.ExceptionClass.ClassName + ': ' + AError.ExceptionMessage);
  if AError.IsComparable then
  begin
    Console.WriteLine('           Expected: ' + AError.Expected);
    Console.WriteLine('           Actual:   ' + AError.Actual);
  end;
  Console.ResetColor;
end;

procedure TGeneratorConsoleLogger.OnTestingStarts(const threadId: TThreadID; testCount, testActiveCount: Cardinal);
begin
  Console.WriteLine('Generator LIB Unit Tests');
  Console.WriteLine('------------------------');
  Console.WriteLine;
end;

procedure TGeneratorConsoleLogger.OnStartTestFixture(const threadId: TThreadID; const fixture: ITestFixtureInfo);
begin
  if SameText(FLastFixture, fixture.Name) then
    Exit;

  if FLastFixture <> '' then
    Console.WriteLine;

  FLastFixture := fixture.Name;
  Console.WriteLine(fixture.Name);
end;

procedure TGeneratorConsoleLogger.OnTestSuccess(const threadId: TThreadID; const Test: ITestResult);
begin
  WriteResult('Passed', Test, TConsoleColor.Green);
end;

procedure TGeneratorConsoleLogger.OnTestFailure(const threadId: TThreadID; const Failure: ITestError);
begin
  WriteResult('Failed', Failure, TConsoleColor.Red);
  WriteErrorDetails(Failure);
end;

procedure TGeneratorConsoleLogger.OnTestError(const threadId: TThreadID; const Error: ITestError);
begin
  WriteResult('Error', Error, TConsoleColor.Red);
  WriteErrorDetails(Error);
end;

procedure TGeneratorConsoleLogger.OnTestIgnored(const threadId: TThreadID; const AIgnored: ITestResult);
begin
  WriteResult('Ignored', AIgnored, TConsoleColor.Yellow);
  if AIgnored.Message <> '' then
    Console.WriteLine('           ' + AIgnored.Message);
end;

procedure TGeneratorConsoleLogger.OnTestMemoryLeak(const threadId: TThreadID; const Test: ITestResult);
begin
  WriteResult('Leaked', Test, TConsoleColor.Magenta);
  if Test.Message <> '' then
    Console.WriteLine('           ' + Test.Message);
end;

procedure TGeneratorConsoleLogger.OnTestingEnds(const RunResults: IRunResults);
var
  Failed: Integer;
begin
  Failed := RunResults.FailureCount + RunResults.ErrorCount + RunResults.MemoryLeakCount;

  Console.WriteLine;
  Console.WriteLine('Summary');
  Console.WriteLine('-------');
  Console.WriteLine(Format('Total:    %d', [RunResults.TestCount]));

  Console.ForegroundColor := TConsoleColor.Green;
  Console.WriteLine(Format('Passed:   %d', [RunResults.PassCount]));
  Console.ResetColor;

  if Failed > 0 then
    Console.ForegroundColor := TConsoleColor.Red
  else
    Console.ForegroundColor := TConsoleColor.Green;
  Console.WriteLine(Format('Failed:   %d', [Failed]));
  Console.ResetColor;

  if RunResults.IgnoredCount > 0 then
  begin
    Console.ForegroundColor := TConsoleColor.Yellow;
    Console.WriteLine(Format('Ignored:  %d', [RunResults.IgnoredCount]));
    Console.ResetColor;
  end;

  Console.WriteLine(Format('Duration: %.2f ms', [RunResults.Duration.TotalMilliseconds]));
  Console.WriteLine;

  if RunResults.AllPassed then
  begin
    Console.ForegroundColor := TConsoleColor.Green;
    Console.WriteLine('Test Run Successful.');
  end
  else
  begin
    Console.ForegroundColor := TConsoleColor.Red;
    Console.WriteLine('Test Run Failed.');
  end;
  Console.ResetColor;
end;

procedure TGeneratorConsoleLogger.OnSetupFixture(const threadId: TThreadID; const fixture: ITestFixtureInfo);
begin
end;

procedure TGeneratorConsoleLogger.OnEndSetupFixture(const threadId: TThreadID; const fixture: ITestFixtureInfo);
begin
end;

procedure TGeneratorConsoleLogger.OnBeginTest(const threadId: TThreadID; const Test: ITestInfo);
begin
end;

procedure TGeneratorConsoleLogger.OnSetupTest(const threadId: TThreadID; const Test: ITestInfo);
begin
end;

procedure TGeneratorConsoleLogger.OnEndSetupTest(const threadId: TThreadID; const Test: ITestInfo);
begin
end;

procedure TGeneratorConsoleLogger.OnExecuteTest(const threadId: TThreadID; const Test: ITestInfo);
begin
end;

procedure TGeneratorConsoleLogger.OnLog(const logType: TLogLevel; const msg: string);
begin
  Console.WriteLine('           ' + msg);
end;

procedure TGeneratorConsoleLogger.OnTeardownTest(const threadId: TThreadID; const Test: ITestInfo);
begin
end;

procedure TGeneratorConsoleLogger.OnEndTeardownTest(const threadId: TThreadID; const Test: ITestInfo);
begin
end;

procedure TGeneratorConsoleLogger.OnEndTest(const threadId: TThreadID; const Test: ITestResult);
begin
end;

procedure TGeneratorConsoleLogger.OnTearDownFixture(const threadId: TThreadID; const fixture: ITestFixtureInfo);
begin
end;

procedure TGeneratorConsoleLogger.OnEndTearDownFixture(const threadId: TThreadID; const fixture: ITestFixtureInfo);
begin
end;

procedure TGeneratorConsoleLogger.OnEndTestFixture(const threadId: TThreadID; const results: IFixtureResult);
begin
end;

end.
