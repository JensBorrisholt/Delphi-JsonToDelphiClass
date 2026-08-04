unit Pkg.Json.Syntax.Types;

interface

type
  TSyntaxTokenKind = (tkText, tkKeyword, tkPropertyName, tkString, tkComment,
    tkNumber, tkSymbol);

  TSyntaxToken = record
    Kind: TSyntaxTokenKind;
    Text: string;
  end;

  TSyntaxLine = TArray<TSyntaxToken>;
  TSyntaxLines = TArray<TSyntaxLine>;

  TSyntaxLanguage = (slJson, slDelphi);

implementation

end.
