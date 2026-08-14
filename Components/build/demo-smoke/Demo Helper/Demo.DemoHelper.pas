unit Demo.DemoHelper;

interface

{$I ../FrameWork.inc}

uses
  System.Classes, System.SysUtils,
{$IFDEF FMX}
  FMX.Controls, FMX.Types, FMX.Forms,
{$IFEND}
{$IFDEF VCL}
  Vcl.Controls, Vcl.Forms,
{$IFEND}
  Demo.JsonTreeView;

Type
{$IFDEF FMX}
  TParent = TFmxObject;
{$IFEND}
{$IFDEF VCL}
  TParent = TWinControl;
{$IFEND}

  TDemoCreator = class
  public
    class procedure Construct(aTarget: TParent);
  end;

implementation

uses
  System.Threading,
  RootU;

class procedure TDemoCreator.Construct(aTarget: TParent);
  function GetObject: TRoot;
  begin
    Result := TRoot.Create;
    with TStringList.Create do
      try
        LoadFromFile('../../DemoData.json');
        Result.AsJson := Text;
      finally
        Free;
      end;
  end;

var
  Root: TRoot;
begin
  Root := GetObject;
  with TJsonTreeView.Create(aTarget, Root.AsJson) do
  begin
{$IFDEF FMX}
    Parent := aTarget;
    Align := TAlignLayout.Client;
{$IFEND}
{$IFDEF VCL}
    Align := alClient;
{$IFEND}
    VisibleChildrenCounts := True;
    VisibleByteSizes := False;
  end;

  Root.Free;
end;

initialization

TTask.Run(
  procedure
  begin
    while not Assigned(Application) do
      TThread.Sleep(50);

    while not Assigned(Application.MainForm) do
      TThread.Sleep(50);

    while not Application.MainForm.Visible do
      TThread.Sleep(50);

    TThread.Synchronize(nil,
        procedure
        begin
          TDemoCreator.Construct(Application.MainForm);
        end)
  end);
end.
