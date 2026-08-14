unit JsonToDelphi.Generator.CSharp;

interface

uses
  JsonToDelphi.Generator.Core.Model,
  JsonToDelphi.Generator.CSharp.Settings;

type
  TJsonToCSharpGenerator = class
  private
    FJson: string;
    FModel: TGeneratorModel;
    FRootClassName: string;
    FSettings: TCSharpSettings;
    FOwnsSettings: Boolean;
  public
    constructor Create; overload;
    constructor Create(const ASettings: TCSharpSettings); overload;
    destructor Destroy; override;
    function GeneratedRootClassName: string;
    function GenerateSource: string;
    function IsValid(const AJson: string): Boolean;
    function Parse(const AJson: string): TJsonToCSharpGenerator;
    property Json: string read FJson;
    property Model: TGeneratorModel read FModel;
    property RootClassName: string read FRootClassName write FRootClassName;
  end;

implementation

uses
  System.Json, System.SysUtils,
  JsonToDelphi.Generator.Core.Builder,
  JsonToDelphi.Generator.CSharp.Writer;

constructor TJsonToCSharpGenerator.Create;
begin
  inherited Create;
  FSettings := TCSharpSettings.Create;
  FOwnsSettings := True;
  FModel := TGeneratorModel.Create;
  FRootClassName := 'Root';
end;

constructor TJsonToCSharpGenerator.Create(const ASettings: TCSharpSettings);
begin
  inherited Create;
  if ASettings = nil then
    raise EArgumentNilException.Create('ASettings');

  FSettings := ASettings;
  FOwnsSettings := False;
  FModel := TGeneratorModel.Create;
  FRootClassName := 'Root';
end;

destructor TJsonToCSharpGenerator.Destroy;
begin
  FModel.Free;
  if FOwnsSettings then
    FSettings.Free;
  inherited;
end;

function TJsonToCSharpGenerator.GeneratedRootClassName: string;
var
  Writer: TCSharpWriter;
begin
  if FModel.RootClass = nil then
    raise Exception.Create('No model has been built');

  Writer := TCSharpWriter.Create(FSettings);
  try
    Result := Writer.GeneratedClassName(FModel, FModel.RootClass);
  finally
    Writer.Free;
  end;
end;

function TJsonToCSharpGenerator.GenerateSource: string;
var
  Writer: TCSharpWriter;
begin
  if FModel.RootClass = nil then
    raise Exception.Create('No model has been built');

  Writer := TCSharpWriter.Create(FSettings);
  try
    Result := Writer.WriteSource(FModel);
  finally
    Writer.Free;
  end;
end;

function TJsonToCSharpGenerator.IsValid(const AJson: string): Boolean;
var
  Value: TJSONValue;
begin
  Value := TJSONObject.ParseJSONValue(AJson);
  Result := Value <> nil;
  Value.Free;
end;

function TJsonToCSharpGenerator.Parse(const AJson: string): TJsonToCSharpGenerator;
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
