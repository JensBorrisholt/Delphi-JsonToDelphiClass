unit JsonToDelphi.GUI.Visualizer;

interface

uses
  System.Generics.Collections, Vcl.ComCtrls;

type
  TJsonSourceVisualizer = class
  private
    class procedure AddValue(const ATree: TTreeView; const AParent: TTreeNode; const APrefix: string; const AValue: TObject); static;
  public
    class procedure Visualize(const ATree: TTreeView; const AJson: string); static;
  end;

implementation

uses
  System.JSON, System.SysUtils;

class procedure TJsonSourceVisualizer.AddValue(const ATree: TTreeView; const AParent: TTreeNode; const APrefix: string; const AValue: TObject);
var
  JsonValue: TJSONValue;
  JsonObject: TJSONObject;
  JsonArray: TJSONArray;
  Node: TTreeNode;
  I: Integer;
  Text: string;
begin
  JsonValue := AValue as TJSONValue;

  if JsonValue is TJSONObject then
  begin
    JsonObject := TJSONObject(JsonValue);
    Text := Format('{} (%d)', [JsonObject.Count]);
    Node := ATree.Items.AddChild(AParent, APrefix + Text);

    for I := 0 to JsonObject.Count - 1 do
      AddValue(ATree, Node, JsonObject.Pairs[I].JsonString.Value + ' : ', JsonObject.Pairs[I].JsonValue);

    Exit;
  end;

  if JsonValue is TJSONArray then
  begin
    JsonArray := TJSONArray(JsonValue);
    Text := Format('[] (%d)', [JsonArray.Count]);
    Node := ATree.Items.AddChild(AParent, APrefix + Text);

    for I := 0 to JsonArray.Count - 1 do
      AddValue(ATree, Node, Format('[%d] ', [I]), JsonArray.Items[I]);

    Exit;
  end;

  ATree.Items.AddChild(AParent, APrefix + JsonValue.ToJSON);
end;

class procedure TJsonSourceVisualizer.Visualize(const ATree: TTreeView; const AJson: string);
var
  JsonValue: TJSONValue;
begin
  ATree.Items.BeginUpdate;
  try
    ATree.Items.Clear;

    if Trim(AJson) = '' then
      Exit;

    JsonValue := TJSONObject.ParseJSONValue(AJson);
    try
      if JsonValue = nil then
        Exit;

      AddValue(ATree, nil, '', JsonValue);
      ATree.FullExpand;
    finally
      JsonValue.Free;
    end;
  finally
    ATree.Items.EndUpdate;
  end;
end;

end.
