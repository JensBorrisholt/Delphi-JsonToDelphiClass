unit Pkg.Json.Generator.Errors;

interface

uses
  System.SysUtils;

type
  EJsonGenerator = class(Exception)
  private
    FJsonPath: string;
    FPosition: Integer;
    FSelectionLength: Integer;
  public
    constructor CreateAt(const AMessage, AJsonPath: string; const APosition, ASelectionLength: Integer);
    property JsonPath: string read FJsonPath;
    property Position: Integer read FPosition;
    property SelectionLength: Integer read FSelectionLength;
  end;

implementation

constructor EJsonGenerator.CreateAt(const AMessage, AJsonPath: string; const APosition, ASelectionLength: Integer);
begin
  inherited Create(AMessage);
  FJsonPath := AJsonPath;
  FPosition := APosition;
  FSelectionLength := ASelectionLength;
end;

end.
