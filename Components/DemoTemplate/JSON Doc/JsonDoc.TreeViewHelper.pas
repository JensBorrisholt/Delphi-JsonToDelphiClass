unit JsonDoc.TreeViewHelper;

interface

{$I ../FrameWork.inc}
{$IFNDEF FMX}
  Only include this unit in a FMX project
{$IFEND}
  uses FMX.TreeView, FMX.Types;

Type
  TTreeNode = TTreeViewItem;

  TFMXTreeViewHelper = class helper for TTreeView
  public
    function AddChild(Parent: TTreeViewItem; const S: string): TTreeViewItem;
    Procedure ExpandChidren(aItem: TTreeViewItem);
    procedure FullExpand;
  end;

implementation
uses
  System.Classes;

{ TFMXTreeViewHelper }

function TFMXTreeViewHelper.AddChild(Parent: TTreeViewItem; const S: string): TTreeViewItem;
begin
  Result := TTreeViewItem.Create(Self);
  Result.Text := S;
  if Parent = nil then
    Result.Parent := Self
  else
    Result.Parent := Parent;
end;

procedure TFMXTreeViewHelper.ExpandChidren(aItem: TTreeViewItem);
Var
  i: Integer;
  Item: TTreeViewItem;
begin
  for i := 0 to aItem.Count - 1 do
  begin
    Item := aItem[i];
    Item.IsExpanded := True;
    if Item.Count > 0 then
      ExpandChidren(Item);
  end;
end;

procedure TFMXTreeViewHelper.FullExpand;
var
  i: Integer;
  Item: TTreeViewItem;
begin
  BeginUpdate;

  for i := 0 to Count - 1 do
  begin
    Item := Items[i];
    Item.IsExpanded := True;
    if Item.Count > 0 then
      ExpandChidren(Item);
  end;

  EndUpdate;
end;

end.
