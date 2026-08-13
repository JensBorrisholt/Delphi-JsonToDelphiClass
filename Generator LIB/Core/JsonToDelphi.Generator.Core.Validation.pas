unit JsonToDelphi.Generator.Core.Validation;

interface

uses
  System.Generics.Collections;

type
  TJsonSourceLocation = record
    Position: Integer;
    Length: Integer;
  end;

  TJsonSourceValidator = class
  public
    class procedure ValidateArrayTypes(const AJson: string); overload; static;
    class procedure ValidateArrayTypes(const AJson: string; ALocations: TDictionary<string, TJsonSourceLocation>); overload; static;
  end;

implementation

uses
  System.Json, System.SysUtils,
  JsonToDelphi.Runtime.JsonValueHelper;

type
  TJsonSourceParser = class
  private
    FPosition: Integer;
    FSource: string;
    FLocations: TDictionary<string, TJsonSourceLocation>;
    function DecodeString(const AStart, ALength: Integer): string;
    function ParseArray(const APath: string; const AStart: Integer): string;
    function ParseObject(const APath: string; const AStart: Integer): string;
    function ParseScalar(const AStart: Integer): string;
    function ParseString: string;
    function ParseValue(const APath: string; out AStart, ALength: Integer): string;
    procedure SkipWhitespace;
    function TypeName(const AType: TJsonType): string;
  public
    constructor Create(const ASource: string; ALocations: TDictionary<string, TJsonSourceLocation>);
    procedure Validate;
  end;

constructor TJsonSourceParser.Create(const ASource: string; ALocations: TDictionary<string, TJsonSourceLocation>);
begin
  inherited Create;
  FSource := ASource;
  FPosition := 1;
  FLocations := ALocations;
end;

function TJsonSourceParser.DecodeString(const AStart, ALength: Integer): string;
var
  Value: TJSONValue;
begin
  Result := '';

  Value := TJSONObject.ParseJSONValue(Copy(FSource, AStart, ALength));
  try
    if Value is TJSONString then
      Result := TJSONString(Value).Value;
  finally
    Value.Free;
  end;
end;

function TJsonSourceParser.ParseArray(const APath: string; const AStart: Integer): string;
var
  Actual, Expected: string;
  Index, ItemLength, ItemStart: Integer;
begin
  Inc(FPosition);
  SkipWhitespace;
  Expected := '';
  Index := 0;

  while (FPosition <= Length(FSource)) and (FSource[FPosition] <> ']') do
  begin
    Actual := ParseValue(Format('%s[%d]', [APath, Index]), ItemStart, ItemLength);
    if Expected = '' then
      Expected := Actual;
    Inc(Index);
    SkipWhitespace;
    if (FPosition <= Length(FSource)) and (FSource[FPosition] = ',') then
    begin
      Inc(FPosition);
      SkipWhitespace;
    end
    else
      Break;
  end;

  if (FPosition <= Length(FSource)) and (FSource[FPosition] = ']') then
    Inc(FPosition);

  Result := 'Array<' + Expected + '>';
end;

function TJsonSourceParser.ParseObject(const APath: string; const AStart: Integer): string;
var
  Key, Path: string;
  KeyLength, KeyStart, ValueLength, ValueStart: Integer;
begin
  Inc(FPosition);
  SkipWhitespace;

  while (FPosition <= Length(FSource)) and (FSource[FPosition] <> '}') do
  begin
    KeyStart := FPosition;
    ParseString;
    KeyLength := FPosition - KeyStart;
    Key := DecodeString(KeyStart, KeyLength);
    SkipWhitespace;
    if (FPosition <= Length(FSource)) and (FSource[FPosition] = ':') then
      Inc(FPosition);
    SkipWhitespace;
    if APath = '$' then
      Path := '$.' + Key
    else
      Path := APath + '.' + Key;
    ParseValue(Path, ValueStart, ValueLength);
    SkipWhitespace;
    if (FPosition <= Length(FSource)) and (FSource[FPosition] = ',') then
    begin
      Inc(FPosition);
      SkipWhitespace;
    end
    else
      Break;
  end;

  if (FPosition <= Length(FSource)) and (FSource[FPosition] = '}') then
    Inc(FPosition);

  Result := 'Object';
end;

function TJsonSourceParser.ParseScalar(const AStart: Integer): string;
var
  JsonType: TJsonType;
  Value: TJSONValue;
begin
  while (FPosition <= Length(FSource)) and not CharInSet(FSource[FPosition], [',', ']', '}', ' ', #9, #10, #13]) do
    Inc(FPosition);

  Value := TJSONObject.ParseJSONValue(Copy(FSource, AStart, FPosition - AStart));
  try
    if Value = nil then
      Exit('');
    JsonType := TJsonValueHelper.GetJsonType(Value);
    Result := TypeName(JsonType);
  finally
    Value.Free;
  end;
end;

function TJsonSourceParser.ParseString: string;
var
  Start: Integer;
begin
  Start := FPosition;
  Inc(FPosition);
  while FPosition <= Length(FSource) do
    if FSource[FPosition] = '\' then
      Inc(FPosition, 2)
    else if FSource[FPosition] = '"' then
    begin
      Inc(FPosition);
      Break;
    end
    else
      Inc(FPosition);

  Result := DecodeString(Start, FPosition - Start);
end;

function TJsonSourceParser.ParseValue(const APath: string; out AStart, ALength: Integer): string;
var
  Location: TJsonSourceLocation;
  Value: TJSONValue;
begin
  SkipWhitespace;
  AStart := FPosition;

  if FPosition > Length(FSource) then
  begin
    ALength := 0;
    Exit('');
  end;

  case FSource[FPosition] of
    '[':
      Result := ParseArray(APath, AStart);
    '{':
      Result := ParseObject(APath, AStart);
    '"':
      begin
        ParseString;
        Value := TJSONObject.ParseJSONValue(Copy(FSource, AStart, FPosition - AStart));
        try
          if Value = nil then
            Result := ''
          else
            Result := TypeName(TJsonValueHelper.GetJsonType(Value));
        finally
          Value.Free;
        end;
      end;
  else
    Result := ParseScalar(AStart);
  end;
  ALength := FPosition - AStart;

  if FLocations <> nil then
  begin
    Location.Position := AStart - 1;
    Location.Length := ALength;
    FLocations.AddOrSetValue(APath, Location);
  end;
end;

procedure TJsonSourceParser.SkipWhitespace;
begin
  while (FPosition <= Length(FSource)) and CharInSet(FSource[FPosition], [' ', #9, #10, #13]) do
    Inc(FPosition);
end;

function TJsonSourceParser.TypeName(const AType: TJsonType): string;
begin
  case AType of
    jtObject:
      Result := 'Object';
    jtArray:
      Result := 'Array';
    jtString:
      Result := 'string';
    jtTrue, jtFalse:
      Result := 'Boolean';
    jtNumber:
      Result := 'Double';
    jtDateTime:
      Result := 'TDateTime';
    jtBytes:
      Result := 'Byte';
    jtInteger:
      Result := 'Integer';
    jtInteger64:
      Result := 'Int64';
  else
    Result := '';
  end;
end;

procedure TJsonSourceParser.Validate;
var
  ItemLength, ItemStart: Integer;
begin
  ParseValue('$', ItemStart, ItemLength);
end;

class procedure TJsonSourceValidator.ValidateArrayTypes(const AJson: string);
begin
  ValidateArrayTypes(AJson, nil);
end;

class procedure TJsonSourceValidator.ValidateArrayTypes(const AJson: string; ALocations: TDictionary<string, TJsonSourceLocation>);
var
  Parser: TJsonSourceParser;
begin
  if ALocations <> nil then
    ALocations.Clear;
  Parser := TJsonSourceParser.Create(AJson, ALocations);
  try
    Parser.Validate;
  finally
    Parser.Free;
  end;
end;

end.
