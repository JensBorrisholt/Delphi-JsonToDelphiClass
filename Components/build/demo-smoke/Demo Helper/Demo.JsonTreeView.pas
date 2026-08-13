unit Demo.JsonTreeView;

interface

{$I ../FrameWork.inc}

uses
  System.Classes,
  System.JSON,
{$IFDEF FMX}
  FMX.Types,
  FMX.TreeView;
{$ENDIF}
{$IFDEF VCL}
  Vcl.ComCtrls,
  Vcl.Controls;
{$ENDIF}

type
{$IFDEF FMX}
  TJsonTreeNode = TTreeViewItem;
{$ENDIF}
{$IFDEF VCL}
  TJsonTreeNode = TTreeNode;
{$ENDIF}

  TJsonTreeView = class(TTreeView)
  private
    FRootValue: TJSONValue;
    FVisibleByteSizes: Boolean;
    FVisibleChildrenCounts: Boolean;
    function AddNode(AParent: TJsonTreeNode; const AText: string): TJsonTreeNode;
    procedure AddValue(AParent: TJsonTreeNode; AValue: TJSONValue; const APrefix: string);
    procedure ExpandAllNodes;
    function ValueInfo(AValue: TJSONValue): string;
  public
    constructor Create(AOwner: TComponent; const AJson: string); reintroduce;
    destructor Destroy; override;
    property VisibleByteSizes: Boolean read FVisibleByteSizes write FVisibleByteSizes;
    property VisibleChildrenCounts: Boolean read FVisibleChildrenCounts write FVisibleChildrenCounts;
  end;

implementation

uses
  System.SysUtils;

function TJsonTreeView.AddNode(AParent: TJsonTreeNode; const AText: string): TJsonTreeNode;
begin
{$IFDEF FMX}
  Result := TTreeViewItem.Create(Self);
  Result.Text := AText;
  if AParent = nil then
    Result.Parent := Self
  else
    Result.Parent := AParent;
{$ENDIF}
{$IFDEF VCL}
  Result := Items.AddChild(AParent, AText);
{$ENDIF}
end;

procedure TJsonTreeView.AddValue(AParent: TJsonTreeNode; AValue: TJSONValue; const APrefix: string);
var
  I: Integer;
  Node: TJsonTreeNode;
  Pair: TJSONPair;
begin
  Node := AddNode(AParent, APrefix + ValueInfo(AValue));
  if AValue is TJSONObject then
    for I := 0 to TJSONObject(AValue).Count - 1 do
    begin
      Pair := TJSONObject(AValue).Pairs[I];
      AddValue(Node, Pair.JSONValue, Pair.JsonString.Value + ' : ');
    end
  else if AValue is TJSONArray then
    for I := 0 to TJSONArray(AValue).Count - 1 do
      AddValue(Node, TJSONArray(AValue).Items[I], '[' + I.ToString + '] ');
end;

constructor TJsonTreeView.Create(AOwner: TComponent; const AJson: string);
begin
  inherited Create(AOwner);
  FVisibleChildrenCounts := True;
  FRootValue := TJSONObject.ParseJSONValue(AJson);
{$IFDEF FMX}
  Parent := AOwner as TFmxObject;
{$ENDIF}
{$IFDEF VCL}
  Parent := AOwner as TWinControl;
{$ENDIF}
  if FRootValue <> nil then
    AddValue(nil, FRootValue, '');
  ExpandAllNodes;
end;

destructor TJsonTreeView.Destroy;
begin
  FRootValue.Free;
  inherited;
end;

procedure TJsonTreeView.ExpandAllNodes;
{$IFDEF FMX}
  procedure ExpandNode(ANode: TTreeViewItem);
  var
    I: Integer;
  begin
    ANode.IsExpanded := True;
    for I := 0 to ANode.Count - 1 do
      ExpandNode(ANode.Items[I]);
  end;
var
  I: Integer;
{$ENDIF}
begin
{$IFDEF FMX}
  for I := 0 to Count - 1 do
    ExpandNode(Items[I]);
{$ENDIF}
{$IFDEF VCL}
  FullExpand;
{$ENDIF}
end;

function TJsonTreeView.ValueInfo(AValue: TJSONValue): string;
var
  Count: Integer;
begin
  if not ((AValue is TJSONObject) or (AValue is TJSONArray)) then
    Exit(AValue.ToString);

  if AValue is TJSONObject then
  begin
    Result := '{}';
    Count := TJSONObject(AValue).Count;
  end
  else
  begin
    Result := '[]';
    Count := TJSONArray(AValue).Count;
  end;

  if VisibleChildrenCounts then
    Result := Result + ' (' + Count.ToString + ')';
  if VisibleByteSizes then
    Result := Result + ' (Size: ' + AValue.EstimatedByteSize.ToString + ' bytes)';
end;

end.
