unit Pkg.Json.Generator.Options;

interface

uses
  Pkg.Json.Settings;

type
  TGeneratorOptions = record
    AddJsonPropertyAttributes: Boolean;
    PostFixClassNames: Boolean;
    PostFix: string;
    UsePascalCase: Boolean;
    SuppressZeroDate: Boolean;
    class function FromSettings(const ASettings: TSettings): TGeneratorOptions; static;
    function ClassPostFix: string;
  end;

implementation

class function TGeneratorOptions.FromSettings(const ASettings: TSettings): TGeneratorOptions;
begin
  Result.AddJsonPropertyAttributes := ASettings.AddJsonPropertyAttributes;
  Result.PostFixClassNames := ASettings.PostFixClassNames;
  Result.PostFix := ASettings.PostFix;
  Result.UsePascalCase := ASettings.UsePascalCase;
  Result.SuppressZeroDate := ASettings.SuppressZeroDate;
end;

function TGeneratorOptions.ClassPostFix: string;
begin
  if PostFixClassNames then
    Result := PostFix
  else
    Result := '';
end;

end.
