unit JsonDoc.JsonDocument;

interface

uses
  System.Classes, System.SysUtils, System.JSON;

type
  EJSONDocument = class(Exception);

  EUnknownJsonValueDescendant = class(EJSONDocument)
    constructor Create;
  end;

  TJSONDocument = class(TComponent)
  private
    FRootValue: TJSONValue;
    FJsonText: string;
    FOnChange: TNotifyEvent;
    procedure SetJsonText(const Value: string);
    procedure SetRootValue(const Value: TJSONValue);
  protected
    procedure FreeRootValue; inline;
    procedure DoOnChange; virtual;
  public
    class function IsSimpleJsonValue(v: TJSONValue): Boolean; inline;
    class function IsValidJsonValueDescendant(aJsonValue: TJSONValue): Boolean; inline;
    class function UnQuote(s: string): string; inline;
    class function StripNonJson(s: string): string; inline;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function ProcessJsonText: Boolean;
    function IsActive: Boolean;
    function EstimatedByteSize: Integer;
    property RootValue: TJSONValue read FRootValue write SetRootValue;
  published
    property JsonText: string read FJsonText write SetJsonText;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

uses
  System.Character;

{ TJSONDocument }

constructor TJSONDocument.Create(AOwner: TComponent);
begin
  inherited;
  FRootValue := nil;
  FJsonText := '';
end;

destructor TJSONDocument.Destroy;
begin
  FreeRootValue;
  inherited;
end;

procedure TJSONDocument.FreeRootValue;
begin
  FreeAndNil(FRootValue);
end;

procedure TJSONDocument.DoOnChange;
begin
  if Assigned(FOnChange) then
    FOnChange(self);
end;

function TJSONDocument.EstimatedByteSize: Integer;
begin
  if IsActive then
    Result := FRootValue.EstimatedByteSize
  else
    Result := 0;
end;

function TJSONDocument.IsActive: Boolean;
begin
  Result := RootValue <> nil;
end;

function TJSONDocument.ProcessJsonText: Boolean;
var
  s: string;
begin
  FreeRootValue;
  s := StripNonJson(JsonText);
  FRootValue := TJSONObject.ParseJSONValue(BytesOf(s), 0);
  Result := IsActive;
  DoOnChange;
end;

procedure TJSONDocument.SetJsonText(const Value: string);
begin
  if FJsonText = Value then
    exit;

  FreeRootValue;
  FJsonText := Value;
  if FJsonText <> '' then
    ProcessJsonText
end;

procedure TJSONDocument.SetRootValue(const Value: TJSONValue);
begin
  if FRootValue <> Value then
  begin
    if FRootValue <> nil then
      FreeRootValue;

    FRootValue := Value;

    if FRootValue <> nil then
      FJsonText := FRootValue.ToString;

    DoOnChange;
  end;
end;

class function TJSONDocument.StripNonJson(s: string): string;
var
  ch: char;
  inString: Boolean;
begin
  Result := '';
  inString := false;
  for ch in s do
  begin
    if ch = '"' then
      inString := not inString;

    if ch.IsWhiteSpace and not inString then
      continue;

    Result := Result + ch;
  end;
end;

class function TJSONDocument.UnQuote(s: string): string;
begin
  Result := Copy(s, 2, Length(s) - 2);
end;

class function TJSONDocument.IsSimpleJsonValue(v: TJSONValue): Boolean;
begin
  Result := (v is TJSONString) or (v is TJSONBool) or (v is TJSONNull);
end;

class function TJSONDocument.IsValidJsonValueDescendant(aJsonValue: TJSONValue): Boolean;
begin
  if IsSimpleJsonValue(aJsonValue) or (aJsonValue is TJSONObject) or (aJsonValue is TJSONArray) then
    exit(true);
  Result := false;
end;

{ EUnknownJsonValueDescendant }

resourcestring
  StrUnknownTJSONValueDescendant = 'Unknown TJSONValue descendant';

constructor EUnknownJsonValueDescendant.Create;
begin
  inherited Create(StrUnknownTJSONValueDescendant);
end;

end.
