unit GeneratorSmokeTestsGui.MainForm;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  System.Diagnostics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.ComCtrls,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  GeneratorSmokeTestCases;

type
  TSmokeTestsForm = class(TForm)
    BottomPanel: TPanel;
    RunButton: TButton;
    SummaryLabel: TLabel;
    TestList: TListView;
    procedure FormShow(Sender: TObject);
    procedure RunButtonClick(Sender: TObject);
  private
    FHasRun: Boolean;
    procedure RunTests;
    procedure AddResult(const ATestName, AStatus, ADetails: string; ADurationMs: Double);
    procedure UpdateSummary(ATotal, APassed, AFailed: Integer; ADurationMs: Double);
  end;

var
  SmokeTestsForm: TSmokeTestsForm;

implementation

{$R *.dfm}

procedure TSmokeTestsForm.AddResult(const ATestName, AStatus, ADetails: string; ADurationMs: Double);
var
  Item: TListItem;
begin
  Item := TestList.Items.Add;
  Item.Caption := ATestName;
  Item.SubItems.Add(AStatus);
  Item.SubItems.Add(Format('%.2f ms', [ADurationMs]));
  Item.SubItems.Add(ADetails);
end;

procedure TSmokeTestsForm.FormShow(Sender: TObject);
begin
  if FHasRun then
    Exit;

  FHasRun := True;
  RunTests;
end;

procedure TSmokeTestsForm.RunButtonClick(Sender: TObject);
begin
  RunTests;
end;

procedure TSmokeTestsForm.RunTests;
var
  Test: TTestCase;
  Tests: TArray<TTestCase>;
  Stopwatch: TStopwatch;
  TotalStopwatch: TStopwatch;
  Passed: Integer;
  Failed: Integer;
begin
  RunButton.Enabled := False;
  TestList.Items.BeginUpdate;
  try
    TestList.Items.Clear;
    SummaryLabel.Caption := 'Kører tests...';
  finally
    TestList.Items.EndUpdate;
  end;
  Application.ProcessMessages;

  Passed := 0;
  Failed := 0;
  Tests := GetGeneratorSmokeTests;
  TotalStopwatch := TStopwatch.StartNew;

  for Test in Tests do
  begin
    Stopwatch := TStopwatch.StartNew;
    try
      Test.Execute;
      Stopwatch.Stop;
      Inc(Passed);
      AddResult(Test.Name, 'Passed', '', Stopwatch.Elapsed.TotalMilliseconds);
    except
      on E: Exception do
      begin
        Stopwatch.Stop;
        Inc(Failed);
        AddResult(Test.Name, 'Failed', E.ClassName + ': ' + E.Message, Stopwatch.Elapsed.TotalMilliseconds);
      end;
    end;
    Application.ProcessMessages;
  end;

  TotalStopwatch.Stop;
  UpdateSummary(Length(Tests), Passed, Failed, TotalStopwatch.Elapsed.TotalMilliseconds);
  RunButton.Enabled := True;
end;

procedure TSmokeTestsForm.UpdateSummary(ATotal, APassed, AFailed: Integer; ADurationMs: Double);
begin
  SummaryLabel.Caption := Format('Total: %d    Passed: %d    Failed: %d    Duration: %.2f ms',
    [ATotal, APassed, AFailed, ADurationMs]);
end;

end.
