unit Pkg.Json.Utils;

interface

uses
  System.Classes,
  Winapi.ShellAPI, Winapi.Windows,
  System.Json.Writers, System.Json.Readers, System.SysUtils;

type
  TJsonStringWriter = class(TJsonTextWriter)
  private
    FStrinBuilder: TStringBuilder;
    FStringWriter: TStringWriter;
  public
    constructor Create;
    destructor Destroy; override;
    function ToString: string; override;
  end;

  TJsonStringReader = class(TJsonTextReader)
  public
    constructor Create(const AJson: string);
    destructor Destroy; override;
  end;

procedure ShellExecute(aFileName: string);

function MinifyJson(AJson: string): string;
function PrettyPrint(AJson: string): string;

implementation

uses
  System.Json.Types;

procedure ShellExecute(aFileName: string);
begin
  Winapi.ShellAPI.ShellExecute(0, 'OPEN', PChar(aFileName), '', '', SW_SHOWNORMAL);
end;

function JsonReformat(const AJson: string; Indented: Boolean): string;
var
  JsonWriter: TJsonStringWriter;
  JsonReader: TJsonStringReader;
begin
  JsonReader := TJsonStringReader.Create(AJson);
  JsonWriter := TJsonStringWriter.Create;

  if Indented then
    JsonWriter.Formatting := TJsonFormatting.Indented;

  try
    JsonWriter.WriteToken(JsonReader);
    Result := JsonWriter.ToString;
  finally
    JsonWriter.Free;
    JsonReader.Free;
  end;
end;

function MinifyJson(AJson: string): string;
begin
  Result := JsonReformat(AJson, false);
end;

function PrettyPrint(AJson: string): string;
begin
  Result := JsonReformat(AJson, True);
end;

{ TJsonStringWriter }

constructor TJsonStringWriter.Create;
begin
  FStrinBuilder := TStringBuilder.Create;
  FStringWriter := TStringWriter.Create(FStrinBuilder);
  inherited Create(FStringWriter);
end;

destructor TJsonStringWriter.Destroy;
begin
  FStringWriter.Free;
  FStrinBuilder.Free;
  inherited Destroy;
end;

function TJsonStringWriter.ToString: string;
begin
  Result := FStrinBuilder.ToString;
end;

{ TJsonStringReader }

constructor TJsonStringReader.Create(const AJson: string);
begin
  inherited Create(TStringReader.Create(AJson));
end;

destructor TJsonStringReader.Destroy;
begin
  Reader.Free;
  inherited Destroy;
end;

end.
