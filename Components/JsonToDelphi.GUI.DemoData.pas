unit JsonToDelphi.GUI.DemoData;

interface

uses
  System.SysUtils;

type
  TDemoDataRepository = class
  private
    class function FindDirectoryFrom(const AStartDirectory: string): string; static;
  public
    class function Directory: string; static;
    class function FileNames: TArray<string>; static;
    class function Load(const AFileName: string): string; static;
  end;

implementation

uses
  System.Classes, System.IOUtils;

class function TDemoDataRepository.Directory: string;
begin
  Result := FindDirectoryFrom(TPath.GetDirectoryName(ParamStr(0)));
  if Result = '' then
    Result := FindDirectoryFrom(GetCurrentDir);
end;

class function TDemoDataRepository.FileNames: TArray<string>;
var
  DemoDirectory: string;
  FileName: string;
  Files: TStringList;
begin
  DemoDirectory := Directory;
  if DemoDirectory = '' then
    Exit(nil);

  Files := TStringList.Create;
  try
    for FileName in TDirectory.GetFiles(DemoDirectory, '*.json') do
      Files.Add(TPath.GetFileName(FileName));

    Files.Sort;
    Result := Files.ToStringArray;
  finally
    Files.Free;
  end;
end;

class function TDemoDataRepository.FindDirectoryFrom(const AStartDirectory: string): string;
var
  CurrentDirectory: string;
  DemoDirectory: string;
  ParentDirectory: string;
begin
  Result := '';
  CurrentDirectory := AStartDirectory;

  while CurrentDirectory <> '' do
  begin
    DemoDirectory := TPath.Combine(CurrentDirectory, 'Demo Data');
    if TDirectory.Exists(DemoDirectory) then
      Exit(DemoDirectory);

    ParentDirectory := TPath.GetDirectoryName(CurrentDirectory);
    if SameText(ParentDirectory, CurrentDirectory) then
      Exit;

    CurrentDirectory := ParentDirectory;
  end;
end;

class function TDemoDataRepository.Load(const AFileName: string): string;
var
  DemoDirectory: string;
  FileName: string;
begin
  FileName := TPath.GetFileName(AFileName);
  if not SameText(FileName, AFileName) then
    raise EArgumentException.Create('Invalid demo data file name.');

  DemoDirectory := Directory;
  if DemoDirectory = '' then
    raise EFileNotFoundException.Create('The Demo Data directory could not be found.');

  FileName := TPath.Combine(DemoDirectory, FileName);
  if not TFile.Exists(FileName) then
    raise EFileNotFoundException.CreateFmt('Demo data file not found: %s', [AFileName]);

  Result := TFile.ReadAllText(FileName, TEncoding.UTF8);
end;

end.
