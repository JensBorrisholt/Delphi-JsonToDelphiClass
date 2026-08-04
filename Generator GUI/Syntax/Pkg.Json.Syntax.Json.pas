unit Pkg.Json.Syntax.Json;

interface

uses
  Pkg.Json.Syntax.Highlighter, Pkg.Json.Syntax.Types;

type
  TJsonSyntaxHighlighter = class(TSyntaxHighlighter)
  protected
    function TokenizeLine(const Text: string; var State: Integer): TSyntaxLine;
      override;
  end;

implementation

uses
  System.Generics.Collections, System.SysUtils;

function TJsonSyntaxHighlighter.TokenizeLine(const Text: string;
  var State: Integer): TSyntaxLine;
var
  P, StartP, EndP, LookAhead: PChar;
  Tokens: TList<TSyntaxToken>;
  Word: string;
begin
  Tokens := TList<TSyntaxToken>.Create;
  try
    P := PChar(Text);
    EndP := P + Length(Text);
    while P < EndP do
    begin
      StartP := P;
      if P^ = '"' then
      begin
        Inc(P);
        while P < EndP do
          if P^ = '\' then
            Inc(P, 2)
          else if P^ = '"' then
          begin
            Inc(P);
            Break;
          end
          else
            Inc(P);
        LookAhead := P;
        while (LookAhead < EndP) and IsWhite(LookAhead^) do
          Inc(LookAhead);
        if (LookAhead < EndP) and (LookAhead^ = ':') then
          AddToken(Tokens, tkPropertyName, StartP, P - StartP)
        else
          AddToken(Tokens, tkString, StartP, P - StartP);
      end
      else if IsDigit(P^) or (P^ = '-') then
      begin
        Inc(P);
        while (P < EndP) and CharInSet(P^,
          ['0'..'9', '-', '+', '.', 'e', 'E']) do Inc(P);
        AddToken(Tokens, tkNumber, StartP, P - StartP);
      end
      else if IsIdentifierStart(P^) then
      begin
        Inc(P);
        while (P < EndP) and IsIdentifierChar(P^) do Inc(P);
        SetString(Word, StartP, P - StartP);
        if SameText(Word, 'true') or SameText(Word, 'false') or
          SameText(Word, 'null') then
          AddToken(Tokens, tkKeyword, StartP, P - StartP)
        else
          AddToken(Tokens, tkText, StartP, P - StartP);
      end
      else if IsWhite(P^) then
      begin
        Inc(P);
        while (P < EndP) and IsWhite(P^) do Inc(P);
        AddToken(Tokens, tkText, StartP, P - StartP);
      end
      else
      begin
        Inc(P);
        AddToken(Tokens, tkSymbol, StartP, 1);
      end;
    end;
    Result := Tokens.ToArray;
  finally
    Tokens.Free;
  end;
end;

end.
