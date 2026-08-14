unit JsonToDelphi.Generator.Delphi.Settings;

interface

uses
  JsonToDelphi.Generator.Core.Settings;

type
  TDelphiSettings = class(TGeneratorSettings)
  private
    FAddJsonPropertyAttributes: Boolean;
    FPostFixClassNames: Boolean;
    FPostFix: string;
    FUsePascalCase: Boolean;
    FSuppressZeroDate: Boolean;
  public
    constructor Create; override;
    function ClassPostFix: string;
    property AddJsonPropertyAttributes: Boolean read FAddJsonPropertyAttributes write FAddJsonPropertyAttributes;
    property PostFixClassNames: Boolean read FPostFixClassNames write FPostFixClassNames;
    property PostFix: string read FPostFix write FPostFix;
    property UsePascalCase: Boolean read FUsePascalCase write FUsePascalCase;
    property SuppressZeroDate: Boolean read FSuppressZeroDate write FSuppressZeroDate;
  end;

implementation

constructor TDelphiSettings.Create;
begin
  inherited;
  FAddJsonPropertyAttributes := False;
  FPostFixClassNames := False;
  FPostFix := 'DTO';
  FUsePascalCase := True;
  FSuppressZeroDate := True;
end;

function TDelphiSettings.ClassPostFix: string;
begin
  if PostFixClassNames then
    Result := PostFix
  else
    Result := '';
end;

end.
