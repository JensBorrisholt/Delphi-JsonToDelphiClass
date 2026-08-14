unit JsonToDelphi.GUI.Syntax.Factory;

interface

uses
  JsonToDelphi.GUI.Syntax.Highlighter, JsonToDelphi.GUI.Syntax.Types;

type
  TSyntaxHighlighterFactory = class
  private
    class var FJson: TSyntaxHighlighter;
    class var FDelphi: TSyntaxHighlighter;
    class var FCSharp: TSyntaxHighlighter;
  public
    class constructor Create;
    class destructor Destroy;
    class function GetHighlighter(const Language: TSyntaxLanguage):
      TSyntaxHighlighter; static;
  end;

implementation

uses
  JsonToDelphi.GUI.Syntax.Delphi, JsonToDelphi.GUI.Syntax.CSharp, JsonToDelphi.GUI.Syntax.Json;

class constructor TSyntaxHighlighterFactory.Create;
begin
  FJson := TJsonSyntaxHighlighter.Create;
  FDelphi := TDelphiSyntaxHighlighter.Create;
  FCSharp := TCSharpSyntaxHighlighter.Create;
end;

class destructor TSyntaxHighlighterFactory.Destroy;
begin
  FCSharp.Free;
  FDelphi.Free;
  FJson.Free;
end;

class function TSyntaxHighlighterFactory.GetHighlighter(
  const Language: TSyntaxLanguage): TSyntaxHighlighter;
begin
  case Language of
    slJson: Result := FJson;
    slDelphi: Result := FDelphi;
    slCSharp: Result := FCSharp;
  else
    Result := FJson;
  end;
end;

end.
