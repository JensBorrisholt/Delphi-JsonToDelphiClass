unit Pkg.Json.GeneratorGUI.GitHub;

interface

uses
  System.SysUtils;

const
  ProgramVersion = '3.2';
  ProgramUrl = 'https://github.com/JensBorrisholt/Delphi-JsonToDelphiClass';

type
  TGitHubRelease = class
  public
    TagName: string;
    HtmlUrl: string;
    Body: string;
  end;

  TUpdateCallback = reference to procedure(const ARelease: TGitHubRelease;
    const AError: string);

  TGitHubUpdateService = class
  private
    class function IsNewerVersion(const ATagName: string): Boolean; static;
  public
    class procedure CheckForUpdate(const ACallback: TUpdateCallback); static;
  end;

implementation

uses
  System.Json, System.Net.HttpClient, System.Threading, System.Classes;

class procedure TGitHubUpdateService.CheckForUpdate(
  const ACallback: TUpdateCallback);
const
  UpdateUrl = 'https://api.github.com/repos/JensBorrisholt/Delphi-JsonToDelphiClass/releases/latest';
begin
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
      Release := nil;
      Error := '';
      Client := THTTPClient.Create;
      try
        try
          Client.UserAgent := 'Delphi-JsonToDelphiClass/' + ProgramVersion;
          Response := Client.Get(UpdateUrl);
          if Response.StatusCode <> 200 then
            raise Exception.CreateFmt('GitHub returned HTTP %d',
              [Response.StatusCode]);
          Json := TJSONObject.ParseJSONValue(Response.ContentAsString);
          try
            if not (Json is TJSONObject) then
              raise EConvertError.Create('GitHub returned an invalid response');
            JsonObject := TJSONObject(Json);
            if IsNewerVersion(JsonObject.GetValue<string>('tag_name', '')) then
            begin
              Release := TGitHubRelease.Create;
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
          ACallback(Release, Error);
        end);
    end);
end;

class function TGitHubUpdateService.IsNewerVersion(
  const ATagName: string): Boolean;
var
  CurrentValue, LatestValue: Double;
  LatestText: string;
begin
  LatestText := ATagName.Trim.TrimLeft(['v', 'V']);
  Result := TryStrToFloat(ProgramVersion, CurrentValue,
    TFormatSettings.Invariant) and
    TryStrToFloat(LatestText, LatestValue, TFormatSettings.Invariant) and
    (LatestValue > CurrentValue);
end;

end.
