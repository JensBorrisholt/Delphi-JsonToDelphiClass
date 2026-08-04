unit Pkg.Json.Syntax.CSharp;

interface

uses
  Pkg.Json.Syntax.Highlighter, Pkg.Json.Syntax.Types;

type
  TCSharpSyntaxHighlighter = class(TSyntaxHighlighter)
  private
    class function IsKeyword(const Text: string): Boolean; static;
  protected
    function TokenizeLine(const Text: string; var State: Integer): TSyntaxLine; override;
  end;

implementation

uses
  System.Generics.Collections, System.StrUtils, System.SysUtils;

class function TCSharpSyntaxHighlighter.IsKeyword(const Text: string): Boolean;
begin
  Result := MatchText(Text, [
    'abstract', 'as', 'base', 'bool', 'break', 'byte', 'case', 'catch', 'char',
    'checked', 'class', 'const', 'continue', 'decimal', 'default', 'delegate',
    'do', 'double', 'else', 'enum', 'event', 'explicit', 'extern', 'false',
    'finally', 'fixed', 'float', 'for', 'foreach', 'goto', 'if', 'implicit',
    'in', 'int', 'interface', 'internal', 'is', 'lock', 'long', 'namespace',
    'new', 'null', 'object', 'operator', 'out', 'override', 'params', 'private',
    'protected', 'public', 'readonly', 'record', 'ref', 'return', 'sbyte',
    'sealed', 'short', 'sizeof', 'stackalloc', 'static', 'string', 'struct',
    'switch', 'this', 'throw', 'true', 'try', 'typeof', 'uint', 'ulong',
    'unchecked', 'unsafe', 'ushort', 'using', 'virtual', 'void', 'volatile',
    'while', 'add', 'alias', 'and', 'ascending', 'async', 'await', 'by',
    'descending', 'dynamic', 'equals', 'file', 'from', 'get', 'global', 'group',
    'init', 'into', 'join', 'let', 'managed', 'nameof', 'nint', 'not', 'notnull',
    'nuint', 'on', 'or', 'orderby', 'partial', 'remove', 'required', 'scoped',
    'select', 'set', 'unmanaged', 'value', 'var', 'when', 'where', 'with',
    'yield']);
end;

function TCSharpSyntaxHighlighter.TokenizeLine(const Text: string;
  var State: Integer): TSyntaxLine;
const
  StateNormal = 0;
  StateBlockComment = 1;
  StateVerbatimString = 2;
var
  P, StartP, EndP: PChar;
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

      if State = StateBlockComment then
      begin
        while (P + 1 < EndP) and not ((P^ = '*') and ((P + 1)^ = '/')) do
          Inc(P);
        if P + 1 < EndP then
        begin
          Inc(P, 2);
          State := StateNormal;
        end
        else
          P := EndP;
        AddToken(Tokens, tkComment, StartP, P - StartP);
      end
      else if State = StateVerbatimString then
      begin
        while P < EndP do
          if P^ = '"' then
            if (P + 1 < EndP) and ((P + 1)^ = '"') then
              Inc(P, 2)
            else
            begin
              Inc(P);
              State := StateNormal;
              Break;
            end
          else
            Inc(P);
        AddToken(Tokens, tkString, StartP, P - StartP);
      end
      else if (P + 1 < EndP) and (P^ = '/') and ((P + 1)^ = '/') then
      begin
        AddToken(Tokens, tkComment, P, EndP - P);
        P := EndP;
      end
      else if (P + 1 < EndP) and (P^ = '/') and ((P + 1)^ = '*') then
      begin
        Inc(P, 2);
        while (P + 1 < EndP) and not ((P^ = '*') and ((P + 1)^ = '/')) do
          Inc(P);
        if P + 1 < EndP then
          Inc(P, 2)
        else
        begin
          P := EndP;
          State := StateBlockComment;
        end;
        AddToken(Tokens, tkComment, StartP, P - StartP);
      end
      else if (P + 1 < EndP) and (P^ = '@') and ((P + 1)^ = '"') then
      begin
        Inc(P, 2);
        while P < EndP do
          if P^ = '"' then
            if (P + 1 < EndP) and ((P + 1)^ = '"') then
              Inc(P, 2)
            else
            begin
              Inc(P);
              Break;
            end
          else
            Inc(P);
        if (P = EndP) and ((EndP - StartP < 3) or ((P - 1)^ <> '"')) then
          State := StateVerbatimString;
        AddToken(Tokens, tkString, StartP, P - StartP);
      end
      else if P^ = '"' then
      begin
        Inc(P);
        while P < EndP do
          if P^ = '\' then
          begin
            Inc(P);
            if P < EndP then
              Inc(P);
          end
          else if P^ = '"' then
          begin
            Inc(P);
            Break;
          end
          else
            Inc(P);
        AddToken(Tokens, tkString, StartP, P - StartP);
      end
      else if P^ = '''' then
      begin
        Inc(P);
        while P < EndP do
          if P^ = '\' then
          begin
            Inc(P);
            if P < EndP then
              Inc(P);
          end
          else if P^ = '''' then
          begin
            Inc(P);
            Break;
          end
          else
            Inc(P);
        AddToken(Tokens, tkString, StartP, P - StartP);
      end
      else if IsDigit(P^) then
      begin
        Inc(P);
        while (P < EndP) and CharInSet(P^,
          ['0'..'9', 'A'..'F', 'a'..'f', 'x', 'X', 'b', 'B', '.', '_',
           'e', 'E', '+', '-', 'm', 'M', 'd', 'D', 'f', 'F', 'u', 'U',
           'l', 'L']) do
          Inc(P);
        AddToken(Tokens, tkNumber, StartP, P - StartP);
      end
      else if IsIdentifierStart(P^) then
      begin
        Inc(P);
        while (P < EndP) and IsIdentifierChar(P^) do
          Inc(P);
        SetString(Word, StartP, P - StartP);
        if IsKeyword(Word) then
          AddToken(Tokens, tkKeyword, StartP, P - StartP)
        else
          AddToken(Tokens, tkText, StartP, P - StartP);
      end
      else if IsWhite(P^) then
      begin
        Inc(P);
        while (P < EndP) and IsWhite(P^) do
          Inc(P);
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
