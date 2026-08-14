unit JsonToDelphi.Generator.CSharp.Settings;

interface

uses
  JsonToDelphi.Generator.Core.Settings;

type
  TCSharpSettings = class(TGeneratorSettings)
  private
    FNamespaceName: string;
    FUsePascalCase: Boolean;
    FUseNullableTypes: Boolean;
    FAddJsonPropertyNameAttributes: Boolean;
    FUseRecords: Boolean;
    FGenerateImmutableClasses: Boolean;
    FUseReadonlyLists: Boolean;
  public
    constructor Create; override;
    property NamespaceName: string read FNamespaceName write FNamespaceName;
    property UsePascalCase: Boolean read FUsePascalCase write FUsePascalCase;
    property UseNullableTypes: Boolean read FUseNullableTypes write FUseNullableTypes;
    property AddJsonPropertyNameAttributes: Boolean read FAddJsonPropertyNameAttributes write FAddJsonPropertyNameAttributes;
    property UseRecords: Boolean read FUseRecords write FUseRecords;
    property GenerateImmutableClasses: Boolean read FGenerateImmutableClasses write FGenerateImmutableClasses;
    property UseReadonlyLists: Boolean read FUseReadonlyLists write FUseReadonlyLists;
  end;

implementation

constructor TCSharpSettings.Create;
begin
  inherited;
  FNamespaceName := 'Generated';
  FUsePascalCase := True;
  FUseNullableTypes := False;
  FAddJsonPropertyNameAttributes := False;
  FUseRecords := False;
  FGenerateImmutableClasses := False;
  FUseReadonlyLists := False;
end;

end.
