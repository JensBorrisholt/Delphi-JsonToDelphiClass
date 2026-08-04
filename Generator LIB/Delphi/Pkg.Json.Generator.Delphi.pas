unit Pkg.Json.Generator.Delphi;

interface

uses
  Pkg.Json.Generator.Model, Pkg.Json.Generator.DelphiSettings;

type
  TJsonToDelphiGenerator = class
  private
    FJson: string;
    FModel: TGeneratorModel;
    FOptions: TDelphiSettings;
    FOwnsOptions: Boolean;
    FRootClassName: string;
    FDestinationUnitName: string;
  public
    constructor Create(const AOptions: TDelphiSettings); overload;
    constructor Create; overload;
    destructor Destroy; override;
    function GeneratedRootClassName: string;
    function GenerateUnit: string;
    function IsValid(const AJson: string): Boolean;
    function Parse(const AJson: string): TJsonToDelphiGenerator;
    property Json: string read FJson;
    property Model: TGeneratorModel read FModel;
    property RootClassName: string read FRootClassName write FRootClassName;
    property DestinationUnitName: string read FDestinationUnitName write FDestinationUnitName;
  end;

implementation

uses
  System.Json, System.SysUtils,
  Pkg.Json.Generator.Builder, Pkg.Json.Generator.DelphiWriter;

constructor TJsonToDelphiGenerator.Create;
begin
  inherited Create;
  FOptions := TDelphiSettings.Create;
  FOwnsOptions := True;
  FModel := TGeneratorModel.Create;
  FRootClassName := 'Root';
  FDestinationUnitName := 'Root';
end;

constructor TJsonToDelphiGenerator.Create(const AOptions: TDelphiSettings);
begin
  inherited Create;
  if AOptions = nil then
    raise EArgumentNilException.Create('AOptions');

  FOptions := AOptions;
  FOwnsOptions := False;
  FModel := TGeneratorModel.Create;
  FRootClassName := 'Root';
  FDestinationUnitName := 'Root';
end;

destructor TJsonToDelphiGenerator.Destroy;
begin
  FModel.Free;
  if FOwnsOptions then
    FOptions.Free;
  inherited;
end;

function TJsonToDelphiGenerator.GenerateUnit: string;
var
  Writer: TDelphiUnitWriter;
begin
  if FDestinationUnitName.Trim = '' then
    raise EArgumentException.Create('DestinationUnitName must be provided');

  Writer := TDelphiUnitWriter.Create(FOptions);
  try
    Result := Writer.WriteUnit(FModel, FDestinationUnitName);
  finally
    Writer.Free;
  end;
end;

function TJsonToDelphiGenerator.GeneratedRootClassName: string;
var
  Writer: TDelphiUnitWriter;
begin
  if FModel.RootClass = nil then
    raise Exception.Create('No model has been built');

  Writer := TDelphiUnitWriter.Create(FOptions);
  try
    Result := Writer.GeneratedClassName(FModel, FModel.RootClass);
  finally
    Writer.Free;
  end;
end;

function TJsonToDelphiGenerator.IsValid(const AJson: string): Boolean;
var
  Value: TJSONValue;
begin
  Value := TJSONObject.ParseJSONValue(AJson);
  Result := Value <> nil;
  Value.Free;
end;

function TJsonToDelphiGenerator.Parse(const AJson: string): TJsonToDelphiGenerator;
var
  Builder: TJsonModelBuilder;
begin
  Builder := TJsonModelBuilder.Create(FModel);
  try
    Builder.Build(AJson, FRootClassName);
    FJson := AJson;
  finally
    Builder.Free;
  end;
  Result := Self;
end;

end.
