unit Pkg.Json.Syntax.Factory;

interface

uses
  Pkg.Json.Syntax.Highlighter, Pkg.Json.Syntax.Types;

type
  TSyntaxHighlighterFactory = class
  private
    class var FJson: TSyntaxHighlighter;
    class var FDelphi: TSyntaxHighlighter;
  public
    class constructor Create;
    class destructor Destroy;
    class function GetHighlighter(const Language: TSyntaxLanguage):
      TSyntaxHighlighter; static;
  end;

implementation

uses
  Pkg.Json.Syntax.Delphi, Pkg.Json.Syntax.Json;

class constructor TSyntaxHighlighterFactory.Create;
begin
  FJson := TJsonSyntaxHighlighter.Create;
  FDelphi := TDelphiSyntaxHighlighter.Create;
end;

class destructor TSyntaxHighlighterFactory.Destroy;
begin
  FDelphi.Free;
  FJson.Free;
end;

class function TSyntaxHighlighterFactory.GetHighlighter(
  const Language: TSyntaxLanguage): TSyntaxHighlighter;
begin
  case Language of
    slJson: Result := FJson;
    slDelphi: Result := FDelphi;
  else
    Result := FJson;
  end;
end;

end.
