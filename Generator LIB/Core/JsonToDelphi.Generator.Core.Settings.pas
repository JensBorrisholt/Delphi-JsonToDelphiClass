unit JsonToDelphi.Generator.Core.Settings;

interface

uses
  JsonToDelphi.Runtime.DTO;

type
  TGeneratorSettings = class(TJsonDTO)
  public
    procedure Load(const aFileName: string);
    procedure Save(const aFileName: string);
  end;

implementation

uses
  System.IOUtils, System.SysUtils;

procedure TGeneratorSettings.Load(const aFileName: string);
begin
  AsJson := TFile.ReadAllText(aFileName, TEncoding.UTF8);
end;

procedure TGeneratorSettings.Save(const aFileName: string);
begin
  TFile.WriteAllText(aFileName, AsJson, TEncoding.UTF8);
end;

end.
