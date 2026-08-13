unit JsonToDelphi.GUI.Async;

interface

uses
  System.Classes;

type
  IAsyncDebouncer = interface
    ['{698DF9B2-9DA3-4C88-A84F-A42209CF0D18}']
    procedure Cancel;
    function GetPending: Boolean;
    procedure Schedule(const ADelay: Cardinal; const ACallback: TThreadProcedure);
    property Pending: Boolean read GetPending;
  end;

  TAsyncDebouncer = class(TInterfacedObject, IAsyncDebouncer)
  private
    FCallback: TThreadProcedure;
    FTimer: TObject;
    procedure TimerTimer(Sender: TObject);
  protected
    procedure Cancel;
    function GetPending: Boolean;
    procedure Schedule(const ADelay: Cardinal; const ACallback: TThreadProcedure);
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  Vcl.ExtCtrls;

constructor TAsyncDebouncer.Create;
var
  Timer: TTimer;
begin
  inherited Create;
  Timer := TTimer.Create(nil);
  Timer.Enabled := False;
  Timer.OnTimer := TimerTimer;
  FTimer := Timer;
end;

destructor TAsyncDebouncer.Destroy;
begin
  Cancel;
  FTimer.Free;
  inherited;
end;

procedure TAsyncDebouncer.Cancel;
begin
  TTimer(FTimer).Enabled := False;
  FCallback := nil;
end;

function TAsyncDebouncer.GetPending: Boolean;
begin
  Result := TTimer(FTimer).Enabled;
end;

procedure TAsyncDebouncer.Schedule(const ADelay: Cardinal;
  const ACallback: TThreadProcedure);
begin
  TTimer(FTimer).Enabled := False;
  FCallback := ACallback;
  TTimer(FTimer).Interval := ADelay;
  TTimer(FTimer).Enabled := Assigned(FCallback);
end;

procedure TAsyncDebouncer.TimerTimer(Sender: TObject);
var
  Callback: TThreadProcedure;
begin
  TTimer(FTimer).Enabled := False;
  Callback := FCallback;
  FCallback := nil;
  if Assigned(Callback) then
    Callback();
end;

end.
