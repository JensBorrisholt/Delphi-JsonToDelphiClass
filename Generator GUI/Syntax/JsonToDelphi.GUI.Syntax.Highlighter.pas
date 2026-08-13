unit JsonToDelphi.GUI.Syntax.Highlighter;

interface

uses
  System.Generics.Collections, System.SysUtils,
  JsonToDelphi.GUI.Syntax.Types;

type
  TSyntaxHighlighter = class abstract
  protected
    class function IsDigit(const C: Char): Boolean; static;
    class function IsIdentifierChar(const C: Char): Boolean; static;
    class function IsIdentifierStart(const C: Char): Boolean; static;
    class function IsWhite(const C: Char): Boolean; static;
    class procedure AddToken(const Tokens: TList<TSyntaxToken>;
      const Kind: TSyntaxTokenKind; const StartP: PChar;
      const Length: Integer); static;
    function TokenizeLine(const Text: string; var State: Integer): TSyntaxLine;
      virtual; abstract;
  public
    function Tokenize(const Text: string): TSyntaxLines;
  end;

implementation

uses
  System.Classes;

class procedure TSyntaxHighlighter.AddToken(const Tokens: TList<TSyntaxToken>;
  const Kind: TSyntaxTokenKind; const StartP: PChar; const Length: Integer);
var
  Token: TSyntaxToken;
begin
  if Length <= 0 then
    Exit;
  Token.Kind := Kind;
  SetString(Token.Text, StartP, Length);
  Tokens.Add(Token);
end;

class function TSyntaxHighlighter.IsDigit(const C: Char): Boolean;
begin
  Result := CharInSet(C, ['0'..'9']);
end;

class function TSyntaxHighlighter.IsIdentifierChar(const C: Char): Boolean;
begin
  Result := IsIdentifierStart(C) or IsDigit(C);
end;

class function TSyntaxHighlighter.IsIdentifierStart(const C: Char): Boolean;
begin
  Result := CharInSet(C, ['A'..'Z', 'a'..'z', '_']);
end;

class function TSyntaxHighlighter.IsWhite(const C: Char): Boolean;
begin
  Result := CharInSet(C, [' ', #9]);
end;

function TSyntaxHighlighter.Tokenize(const Text: string): TSyntaxLines;
var
  I, State: Integer;
  Source: TStringList;
begin
  Source := TStringList.Create;
  try
    Source.Text := Text;
    SetLength(Result, Source.Count);
    State := 0;
    for I := 0 to Source.Count - 1 do
      Result[I] := TokenizeLine(Source[I], State);
  finally
    Source.Free;
  end;
end;

end.
