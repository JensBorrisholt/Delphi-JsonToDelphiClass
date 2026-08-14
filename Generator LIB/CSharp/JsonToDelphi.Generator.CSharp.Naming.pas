unit JsonToDelphi.Generator.CSharp.Naming;

interface

uses
  System.Generics.Collections,
  JsonToDelphi.Generator.CSharp.Settings;

type
  TCSharpNaming = class
  private
    FSettings: TCSharpSettings;
    FUsedClassNames: TDictionary<string, Byte>;
    function IsReservedWord(const AValue: string): Boolean;
    function PascalCase(const AValue: string): string;
    function Sanitize(const AValue: string): string;
  public
    constructor Create(const ASettings: TCSharpSettings);
    destructor Destroy; override;
    function ClassName(const AJsonName: string): string;
    function Identifier(const AJsonName: string): string;
    function NeedsJsonPropertyNameAttribute(const AJsonName, ACSharpName: string): Boolean;
  end;

implementation

uses
  System.Character, System.SysUtils;

constructor TCSharpNaming.Create(const ASettings: TCSharpSettings);
begin
  inherited Create;
  FSettings := ASettings;
  FUsedClassNames := TDictionary<string, Byte>.Create;
end;

destructor TCSharpNaming.Destroy;
begin
  FUsedClassNames.Free;
  inherited;
end;

function TCSharpNaming.ClassName(const AJsonName: string): string;
var
  BaseName: string;
  Suffix: Integer;
begin
  BaseName := PascalCase(Sanitize(AJsonName));
  if BaseName = '' then
    BaseName := 'Root';

  Result := BaseName;
  Suffix := 1;
  while FUsedClassNames.ContainsKey(Result.ToLower) do
  begin
    Inc(Suffix);
    Result := BaseName + Suffix.ToString;
  end;

  FUsedClassNames.Add(Result.ToLower, 0);
end;

function TCSharpNaming.Identifier(const AJsonName: string): string;
begin
  Result := Sanitize(AJsonName);
  if FSettings.UsePascalCase then
    Result := PascalCase(Result);

  if Result = '' then
    Result := 'Property';

  if IsReservedWord(Result) then
    Result := '@' + Result;
end;

function TCSharpNaming.IsReservedWord(const AValue: string): Boolean;
const
  ReservedWords: array[0..78] of string = (
    'abstract', 'as', 'base', 'bool', 'break', 'byte', 'case', 'catch', 'char',
    'checked', 'class', 'const', 'continue', 'decimal', 'default', 'delegate',
    'do', 'double', 'else', 'enum', 'event', 'explicit', 'extern', 'false',
    'finally', 'fixed', 'float', 'for', 'foreach', 'goto', 'if', 'implicit',
    'in', 'int', 'interface', 'internal', 'is', 'lock', 'long', 'namespace',
    'new', 'null', 'object', 'operator', 'out', 'override', 'params', 'private',
    'protected', 'public', 'readonly', 'ref', 'return', 'sbyte', 'sealed',
    'short', 'sizeof', 'stackalloc', 'static', 'string', 'struct', 'switch',
    'this', 'throw', 'true', 'try', 'typeof', 'uint', 'ulong', 'unchecked',
    'unsafe', 'ushort', 'using', 'virtual', 'void', 'volatile', 'while',
    'record', 'required');
var
  Word: string;
begin
  for Word in ReservedWords do
    if Word = AValue then
      Exit(True);
  Result := False;
end;

function TCSharpNaming.NeedsJsonPropertyNameAttribute(const AJsonName, ACSharpName: string): Boolean;
var
  Name: string;
begin
  Name := ACSharpName;
  if Name.StartsWith('@') then
    Delete(Name, 1, 1);
  Result := FSettings.AddJsonPropertyNameAttributes or (AJsonName <> Name);
end;

function TCSharpNaming.PascalCase(const AValue: string): string;
var
  Ch: Char;
  UpperNext: Boolean;
begin
  Result := '';
  UpperNext := True;
  for Ch in AValue do
  begin
    if Ch = '_' then
    begin
      UpperNext := True;
      Continue;
    end;

    if UpperNext then
      Result := Result + Ch.ToUpper
    else
      Result := Result + Ch;
    UpperNext := False;
  end;
end;

function TCSharpNaming.Sanitize(const AValue: string): string;
var
  Ch: Char;
begin
  Result := '';
  for Ch in AValue do
    if Ch.IsLetterOrDigit or (Ch = '_') then
      Result := Result + Ch
    else
      Result := Result + '_';

  while Result.StartsWith('_') do
    Delete(Result, 1, 1);

  if (Result <> '') and not (Result[1].IsLetter or (Result[1] = '_')) then
    Result := '_' + Result;
end;

end.
