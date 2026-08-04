unit JsonDoc.JSONAncestorHelper;

interface

uses
  System.JSON;

type
  TJSONValueHelper = class helper for TJSONValue
  public
    function ElementCount: Integer;
  end;

implementation

{ TJSONValueHelper }

function TJSONValueHelper.ElementCount: Integer;
begin
  if Self is TJSONObject then
    Exit(TJSONObject(Self).Count);

  if Self is TJSONArray then
    Exit(TJSONArray(Self).Count);

  Exit(-1);
end;

end.
