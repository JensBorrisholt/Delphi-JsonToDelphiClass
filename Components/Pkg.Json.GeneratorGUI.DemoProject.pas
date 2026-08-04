unit Pkg.Json.GeneratorGUI.DemoProject;

interface

type
  TDemoProjectFramework = (dpfBoth, dpfVCL, dpfFMX);

  TDemoProjectGenerator = class
  private
    class procedure ExtractRuntime(const ADestination: string); static;
    class procedure GenerateFrameworkInclude(const ADestination: string;
      AFramework: TDemoProjectFramework); static;
    class procedure ReplaceTokens(const AFileName, AUnitName,
      ARootClassName: string); static;
    class procedure WriteText(const AFileName, AText: string); static;
  public
    class procedure Generate(const ADestination, AUnitName, ARootClassName,
      AJson, ADelphiSource: string); overload; static;
    class procedure Generate(const ADestination, AUnitName, ARootClassName,
      AJson, ADelphiSource: string;
      AFramework: TDemoProjectFramework); overload; static;
  end;

implementation

uses
  System.Classes, System.IOUtils, System.SysUtils, System.Zip;

{$R 'DemoTemplate.res'}

class procedure TDemoProjectGenerator.ExtractRuntime(
  const ADestination: string);
var
  ResourceStream: TResourceStream;
  ZipFile: TZipFile;
begin
  ResourceStream := TResourceStream.Create(HInstance, 'DEMOTEMPLATE',
    'ZIPFILE');
  try
    ZipFile := TZipFile.Create;
    try
      ZipFile.Open(ResourceStream, zmRead);
      ZipFile.ExtractAll(ADestination);
    finally
      ZipFile.Free;
    end;
  finally
    ResourceStream.Free;
  end;
end;

class procedure TDemoProjectGenerator.GenerateFrameworkInclude(
  const ADestination: string; AFramework: TDemoProjectFramework);
var
  FMXDefine: string;
  VCLDefine: string;
begin
  FMXDefine := '{.$DEFINE FMX}';
  VCLDefine := '{.$DEFINE VCL}';
  case AFramework of
    dpfVCL:
      VCLDefine := '{$DEFINE VCL}';
    dpfFMX:
      FMXDefine := '{$DEFINE FMX}';
  end;
  WriteText(IncludeTrailingPathDelimiter(ADestination) + 'FrameWork.inc',
    FMXDefine + sLineBreak +
    VCLDefine + sLineBreak + sLineBreak +
    '{$IF not Defined(VCL) and not Defined(FMX)}' + sLineBreak +
    '  Please define framework, above.' + sLineBreak +
    '{$ENDIF}');
end;

class procedure TDemoProjectGenerator.Generate(const ADestination, AUnitName,
  ARootClassName, AJson, ADelphiSource: string);
begin
  Generate(ADestination, AUnitName, ARootClassName, AJson, ADelphiSource,
    dpfBoth);
end;

class procedure TDemoProjectGenerator.Generate(const ADestination, AUnitName,
  ARootClassName, AJson, ADelphiSource: string;
  AFramework: TDemoProjectFramework);
var
  Destination: string;
begin
  Destination := IncludeTrailingPathDelimiter(ADestination);
  TDirectory.CreateDirectory(Destination);
  ExtractRuntime(Destination);
  GenerateFrameworkInclude(Destination, AFramework);
  WriteText(Destination + AUnitName + '.pas', ADelphiSource);
  WriteText(Destination + 'DemoData.json', AJson);
  ReplaceTokens(Destination + 'Demo Helper\Demo.DemoHelper.pas',
    AUnitName, ARootClassName);
end;

class procedure TDemoProjectGenerator.ReplaceTokens(const AFileName,
  AUnitName, ARootClassName: string);
var
  LegacyClassName: string;
  Text: string;
begin
  LegacyClassName := ARootClassName;
  if (Length(LegacyClassName) > 1) and (LegacyClassName[1] = 'T') then
    Delete(LegacyClassName, 1, 1);
  Text := TFile.ReadAllText(AFileName, TEncoding.UTF8);
  Text := StringReplace(Text, '@@UNIT_NAME@@', AUnitName, [rfReplaceAll]);
  Text := StringReplace(Text, '@@ROOT_CLASS@@', ARootClassName,
    [rfReplaceAll]);
  Text := StringReplace(Text, '@@UnitName@@', AUnitName, [rfReplaceAll]);
  Text := StringReplace(Text, '@@ClassName@@', LegacyClassName,
    [rfReplaceAll]);
  WriteText(AFileName, Text);
end;

class procedure TDemoProjectGenerator.WriteText(const AFileName,
  AText: string);
var
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  try
    Lines.LineBreak := #13#10;
    Lines.Text := AText;
    Lines.SaveToFile(AFileName, TEncoding.UTF8);
  finally
    Lines.Free;
  end;
end;

end.
