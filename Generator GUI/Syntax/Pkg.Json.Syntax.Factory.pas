unit Pkg.Json.Syntax.Factory;

interface

uses
  Pkg.Json.Syntax.Highlighter, Pkg.Json.Syntax.Types;

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
  Pkg.Json.Syntax.Delphi, Pkg.Json.Syntax.CSharp, Pkg.Json.Syntax.Json;

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
