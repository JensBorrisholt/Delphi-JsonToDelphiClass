unit Pkg.Json.Generator.Naming;

interface

uses
  System.Generics.Collections,
  Pkg.Json.Generator.Options;

type
  TDelphiNaming = class
  private
    FOptions: TGeneratorOptions;
    FUsedClassNames: TDictionary<string, Byte>;
    function CapitalizeParts(const Value: string): string;
    function IsReservedWord(const Value: string): Boolean;
  public
    constructor Create(const AOptions: TGeneratorOptions);
    destructor Destroy; override;
    function ClassName(const AJsonName: string): string;
    function Identifier(const AJsonName: string): string;
    function NeedsJsonNameAttribute(const AJsonName, ADelphiName: string): Boolean;
    function PropertyName(const AName: string): string;
  end;

implementation

uses
  System.Character, System.Classes, System.SysUtils,
  Pkg.Json.ReservedWords;

constructor TDelphiNaming.Create(const AOptions: TGeneratorOptions);
begin
  inherited Create;
  FOptions := AOptions;
  FUsedClassNames := TDictionary<string, Byte>.Create;
end;

destructor TDelphiNaming.Destroy;
begin
  FUsedClassNames.Free;
  inherited;
end;

function TDelphiNaming.CapitalizeParts(const Value: string): string;
var
  I: Integer;
  Part: string;
  Parts: TStringList;
begin
  Parts := TStringList.Create;
  try
    ExtractStrings(['_'], [], PChar(Value), Parts);
    Result := '';
    for I := 0 to Parts.Count - 1 do
    begin
      Part := Parts[I];
      if Part <> '' then
      begin
        Part[1] := Part[1].ToUpper;
        if FOptions.UsePascalCase then
          Result := Result + Part
        else if Result = '' then
          Result := Part
        else
          Result := Result + '_' + Part;
      end;
    end;
  finally
    Parts.Free;
  end;
end;

function TDelphiNaming.Identifier(const AJsonName: string): string;
var
  Ch: Char;
  Sanitized: string;
begin
  Sanitized := '';
  for Ch in AJsonName do
    if Ch.IsLetterOrDigit then
      Sanitized := Sanitized + Ch
    else
      Sanitized := Sanitized + '_';
  while Sanitized.StartsWith('_') do
    Delete(Sanitized, 1, 1);
  Result := CapitalizeParts(Sanitized);
  if Result = '' then
    Result := 'Property';
  if not Result[1].IsLetter then
    Result := '_' + Result;
end;

function TDelphiNaming.ClassName(const AJsonName: string): string;
var
  BaseName: string;
  Suffix: Integer;
begin
  BaseName := 'T' + Identifier(AJsonName) + FOptions.ClassPostFix;
  Result := BaseName;
  Suffix := 0;
  while FUsedClassNames.ContainsKey(Result.ToLower) do
  begin
    Inc(Suffix);
    Result := BaseName + Chr(Ord('A') + Suffix - 1);
  end;
  FUsedClassNames.Add(Result.ToLower, 0);
end;

function TDelphiNaming.IsReservedWord(const Value: string): Boolean;
begin
  Result := ReservedWords.IndexOf(Value.ToLower) >= 0;
end;

function TDelphiNaming.NeedsJsonNameAttribute(const AJsonName, ADelphiName: string): Boolean;
begin
  Result := FOptions.AddJsonPropertyAttributes or not SameText(AJsonName, ADelphiName);
end;

function TDelphiNaming.PropertyName(const AName: string): string;
begin
  if IsReservedWord(AName) then
    Result := '&' + AName
  else
    Result := AName;
end;

end.
