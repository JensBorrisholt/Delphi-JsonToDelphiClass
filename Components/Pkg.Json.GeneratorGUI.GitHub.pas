unit Pkg.Json.GeneratorGUI.GitHub;

interface

uses
  System.SysUtils;

const
  ProgramVersion = '4.2';
  ProgramUrl = 'https://github.com/JensBorrisholt/Delphi-JsonToDelphiClass';

type
  TGitHubRelease = record
    TagName: string;
    HtmlUrl: string;
    Body: string;
    function Valid: Boolean;
  end;

  TUpdateCallback = reference to procedure(const ARelease: TGitHubRelease; const AError: string);

  IUpdateRequest = interface
    ['{74669AEF-6D10-4B01-9450-55D74F10535A}']
    procedure Cancel;
  end;

  TGitHubUpdateService = class
  private
    class function IsNewerVersion(const ATagName: string): Boolean; static;
  public
    class function CheckForUpdate(const ACallback: TUpdateCallback): IUpdateRequest; static;
  end;

implementation

uses
  System.Json, System.Net.HttpClient, System.Threading, System.Classes, System.SyncObjs;

type
  IUpdateState = interface
    ['{DA22CD19-8BB0-44F1-A6A2-B562902DF9BD}']
    function Canceled: Boolean;
    procedure Cancel;
  end;

  TUpdateState = class(TInterfacedObject, IUpdateState)
  private
    FCanceled: Integer;
  public
    function Canceled: Boolean;
    procedure Cancel;
  end;

  TUpdateRequest = class(TInterfacedObject, IUpdateRequest)
  private
    FState: IUpdateState;
  public
    constructor Create(const AState: IUpdateState);
    destructor Destroy; override;
    procedure Cancel;
  end;

class function TGitHubUpdateService.CheckForUpdate(const ACallback: TUpdateCallback): IUpdateRequest;
const
  UpdateUrl = 'https://api.github.com/repos/JensBorrisholt/Delphi-JsonToDelphiClass/releases/latest';
var
  State: IUpdateState;
begin
  State := TUpdateState.Create;
  Result := TUpdateRequest.Create(State);
  TTask.Run(
    procedure
    var
      Client: THTTPClient;
      Error: string;
      Json: TJSONValue;
      JsonObject: TJSONObject;
      Release: TGitHubRelease;
      Response: IHTTPResponse;
    begin
      Error := '';
      Client := THTTPClient.Create;
      try
        try
          Client.UserAgent := 'Delphi-JsonToDelphiClass/' + ProgramVersion;
          Response := Client.Get(UpdateUrl);
          if Response.StatusCode <> 200 then
            raise Exception.CreateFmt('GitHub returned HTTP %d', [Response.StatusCode]);
          Json := TJSONObject.ParseJSONValue(Response.ContentAsString);
          try
            if not(Json is TJSONObject) then
              raise EConvertError.Create('GitHub returned an invalid response');

            JsonObject := TJSONObject(Json);

            if IsNewerVersion(JsonObject.GetValue<string>('tag_name', '')) then
            begin
              Release.TagName := JsonObject.GetValue<string>('tag_name', '');
              Release.HtmlUrl := JsonObject.GetValue<string>('html_url', ProgramUrl);
              Release.Body := JsonObject.GetValue<string>('body', '');
            end;
          finally
            Json.Free;
          end;
        except
          on E: Exception do
            Error := E.Message;
        end;
      finally
        Client.Free;
      end;
      TThread.ForceQueue(nil,
        procedure
        begin
          if not State.Canceled then
            ACallback(Release, Error);
        end);
    end);
end;

procedure TUpdateState.Cancel;
begin
  TInterlocked.Exchange(FCanceled, 1);
end;

function TUpdateState.Canceled: Boolean;
begin
  Result := TInterlocked.CompareExchange(FCanceled, 0, 0) <> 0;
end;

constructor TUpdateRequest.Create(const AState: IUpdateState);
begin
  inherited Create;
  FState := AState;
end;

destructor TUpdateRequest.Destroy;
begin
  Cancel;
  inherited;
end;

procedure TUpdateRequest.Cancel;
begin
  if FState <> nil then
    FState.Cancel;
end;

class function TGitHubUpdateService.IsNewerVersion(const ATagName: string): Boolean;
var
  CurrentValue, LatestValue: Double;
  LatestText: string;
begin
  LatestText := ATagName.Trim.TrimLeft(['v', 'V']);
  Result := TryStrToFloat(ProgramVersion, CurrentValue, TFormatSettings.Invariant) and TryStrToFloat(LatestText, LatestValue, TFormatSettings.Invariant) and (LatestValue > CurrentValue);
end;

{ TGitHubRelease }

function TGitHubRelease.Valid: Boolean;
begin
  Result := HtmlUrl <> '';
end;

end.
