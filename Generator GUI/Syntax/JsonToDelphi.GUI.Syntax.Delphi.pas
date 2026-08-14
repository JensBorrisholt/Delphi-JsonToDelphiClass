unit JsonToDelphi.GUI.Syntax.Delphi;

interface

uses
  JsonToDelphi.GUI.Syntax.Highlighter, JsonToDelphi.GUI.Syntax.Types;

type
  TDelphiSyntaxHighlighter = class(TSyntaxHighlighter)
  private
    class function IsKeyword(const Text: string): Boolean; static;
  protected
    function TokenizeLine(const Text: string; var State: Integer): TSyntaxLine; override;
  end;

implementation

uses
  System.Generics.Collections, System.StrUtils, System.SysUtils;

class function TDelphiSyntaxHighlighter.IsKeyword(const Text: string): Boolean;
begin
  Result := MatchText(Text, [
    'absolute', 'abstract', 'and', 'array', 'as', 'asm', 'assembler',
    'automated', 'begin', 'case', 'cdecl', 'class', 'const', 'constructor',
    'contains', 'default', 'deprecated', 'destructor', 'dispid',
    'dispinterface', 'div', 'do', 'downto', 'dynamic', 'else', 'end',
    'except', 'experimental', 'export', 'exports', 'external', 'far', 'file',
    'final', 'finalization', 'finally', 'for', 'forward', 'function', 'goto',
    'helper', 'if', 'implementation', 'implements', 'in', 'index', 'inherited',
    'initialization', 'inline', 'interface', 'is', 'label', 'library',
    'local', 'message', 'mod', 'name', 'near', 'nil', 'nodefault', 'not',
    'object', 'of', 'operator', 'or', 'out', 'overload', 'override', 'package',
    'packed', 'pascal', 'platform', 'private', 'procedure', 'program',
    'property', 'protected', 'public', 'published', 'raise', 'read', 'readonly',
    'record', 'reference', 'register', 'reintroduce', 'repeat', 'requires',
    'resident', 'resourcestring', 'safecall', 'sealed', 'set', 'shl', 'shr',
    'stdcall', 'stored', 'static', 'strict', 'then', 'threadvar', 'to', 'try',
    'type', 'unit', 'unsafe', 'until', 'uses', 'var', 'varargs', 'virtual',
    'while', 'winapi', 'with', 'write', 'writeonly', 'xor']);
end;

function TDelphiSyntaxHighlighter.TokenizeLine(const Text: string;
  var State: Integer): TSyntaxLine;
const
  StateNormal = 0;
  StateBraceComment = 1;
  StateParenComment = 2;
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
      if State = StateBraceComment then
      begin
        while (P < EndP) and (P^ <> '}') do Inc(P);
        if P < EndP then begin Inc(P); State := StateNormal end;
        AddToken(Tokens, tkComment, StartP, P - StartP);
      end
      else if State = StateParenComment then
      begin
        while (P + 1 < EndP) and not ((P^ = '*') and ((P + 1)^ = ')')) do Inc(P);
        if P + 1 < EndP then begin Inc(P, 2); State := StateNormal end;
        AddToken(Tokens, tkComment, StartP, P - StartP);
      end
      else if (P + 1 < EndP) and (P^ = '/') and ((P + 1)^ = '/') then
      begin
        AddToken(Tokens, tkComment, P, EndP - P);
        P := EndP;
      end
      else if P^ = '{' then
      begin
        Inc(P);
        while (P < EndP) and (P^ <> '}') do Inc(P);
        if P < EndP then Inc(P) else State := StateBraceComment;
        AddToken(Tokens, tkComment, StartP, P - StartP);
      end
      else if (P + 1 < EndP) and (P^ = '(') and ((P + 1)^ = '*') then
      begin
        Inc(P, 2);
        while (P + 1 < EndP) and not ((P^ = '*') and ((P + 1)^ = ')')) do Inc(P);
        if P + 1 < EndP then Inc(P, 2) else State := StateParenComment;
        AddToken(Tokens, tkComment, StartP, P - StartP);
      end
      else if P^ = '''' then
      begin
        Inc(P);
        while P < EndP do
          if P^ = '''' then
            if (P + 1 < EndP) and ((P + 1)^ = '''') then Inc(P, 2)
            else begin Inc(P); Break end
          else Inc(P);
        AddToken(Tokens, tkString, StartP, P - StartP);
      end
      else if IsDigit(P^) or (P^ = '$') then
      begin
        Inc(P);
        while (P < EndP) and CharInSet(P^,
          ['0'..'9','A'..'F','a'..'f','x','X','.']) do Inc(P);
        AddToken(Tokens, tkNumber, StartP, P - StartP);
      end
      else if IsIdentifierStart(P^) then
      begin
        Inc(P);
        while (P < EndP) and IsIdentifierChar(P^) do Inc(P);
        SetString(Word, StartP, P - StartP);
        if IsKeyword(Word) then
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
