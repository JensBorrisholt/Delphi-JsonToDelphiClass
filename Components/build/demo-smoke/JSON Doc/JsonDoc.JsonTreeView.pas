unit JsonDoc.JsonTreeView;

interface

{$I ../FrameWork.inc}

uses
  System.Classes, System.Json, System.Generics.Collections,
{$IFDEF FMX}
  FMX.Types, FMX.TreeView, JsonDoc.TreeViewHelper,
{$IFEND}
{$IFDEF VCL}
  Vcl.ComCtrls, Vcl.Controls,
{$IFEND}
  JsonDoc.JSONValueHelper, JsonDoc.JsonDocument;

type
{$IFDEF FMX}
  TParent = TFmxObject;
{$IFEND}
{$IFDEF VCL}
  TParent = TWinControl;
{$IFEND}

  TJSONTreeView = class(TTreeView)
  private
    FJSONDocument: TJSONDocument;
    FVisibleChildrenCounts: Boolean;
    FVisibleByteSizes: Boolean;
    function InfoText(aObject: TJSONValue): string;
    function DoAddChild(aParent: TTreeNode; const aText: string): TTreeNode; inline;
    procedure DoAddBranch(aNode: TTreeNode; aJsonValue: TJSONValue; aPrefix: string);
    function HasActiveDocument: Boolean;
    procedure SetJSONDocument(const aValue: TJSONDocument);
    procedure SetVisibleChildrenCounts(const aValue: Boolean);
    procedure SetVisibleByteSizes(const aValue: Boolean);
    procedure ProcessElement(aNode: TTreeNode; aJSONArray: TJSONArray; aPrefix: string; aIndex: Integer);
    procedure ProcessPair(aNode: TTreeNode; aJSONObject: TJSONObject; aIndex: Integer);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); overload; override;
    constructor Create(AOwner: TComponent; aJsonText: string); reintroduce; overload;
    procedure ClearAll;
    procedure LoadJson;
  published
    property JsonDocument: TJSONDocument read FJSONDocument write SetJSONDocument;
    property VisibleChildrenCounts: Boolean read FVisibleChildrenCounts write SetVisibleChildrenCounts;
    property VisibleByteSizes: Boolean read FVisibleByteSizes write SetVisibleByteSizes;
  end;

implementation

uses
  System.SysUtils, System.StrUtils;

{ TJSONTreeView }

procedure TJSONTreeView.ClearAll;
begin
{$IFDEF VCL}Items.{$IFEND}Clear;
end;

constructor TJSONTreeView.Create(AOwner: TComponent);
begin
  inherited;
  FVisibleChildrenCounts := True;
  FVisibleByteSizes := False;
end;

constructor TJSONTreeView.Create(AOwner: TComponent; aJsonText: string);
var
  Document: TJSONDocument;
begin
  inherited Create(AOwner);
{$IFDEF VCL}
  if AOwner is TParent then
    Parent := AOwner as TParent;
{$IFEND};

  FVisibleChildrenCounts := True;
  FVisibleByteSizes := False;
  Document := TJSONDocument.Create(Self);
  Document.JsonText := aJsonText;
  JsonDocument := Document;
end;

procedure TJSONTreeView.DoAddBranch(aNode: TTreeNode; aJsonValue: TJSONValue; aPrefix: string);
var
  TreeNode: TTreeNode;
  ElementCount: Integer;
  i: Integer;
begin
  if not TJSONDocument.IsValidJsonValueDescendant(aJsonValue) then
    exit;

  TreeNode := DoAddChild(aNode, aPrefix + InfoText(aJsonValue));
  ElementCount := aJsonValue.ElementCount;

  if aJsonValue is TJSONObject then
    for i := 0 to ElementCount - 1 do
      ProcessPair(TreeNode, TJSONObject(aJsonValue), i);

  if aJsonValue is TJSONArray then
    for i := 0 to ElementCount - 1 do
      ProcessElement(TreeNode, TJSONArray(aJsonValue), Copy(aPrefix, 1, length(aPrefix) - 3), i);
end;

function TJSONTreeView.DoAddChild(aParent: TTreeNode; const aText: string): TTreeNode;
begin
  Result := {$IFDEF VCL}Items.{$IFEND}AddChild(aParent, aText);
end;

function TJSONTreeView.HasActiveDocument: Boolean;
begin
  Result := (FJSONDocument <> nil) and (FJSONDocument.IsActive);
end;

function TJSONTreeView.InfoText(aObject: TJSONValue): string;
begin
  if TJSONDocument.IsSimpleJsonValue(aObject) then
    exit(aObject.ToString);

  if aObject is TJSONArray then
    Result := '[]'
  else
    Result := '{}';

  if VisibleChildrenCounts then
    Result := Result + ' (' + IntToStr(aObject.ElementCount) + ')';

  if VisibleByteSizes then
    Result := Result + ' (Size: ' + IntToStr(aObject.EstimatedByteSize) + ' bytes)';
end;

procedure TJSONTreeView.LoadJson;
begin
  ClearAll;

  if not HasActiveDocument then
    exit;

  DoAddBranch(nil, JsonDocument.RootValue, '');
  FullExpand;
end;

procedure TJSONTreeView.ProcessPair(aNode: TTreeNode; aJSONObject: TJSONObject; aIndex: Integer);
var
  s: string;
begin
  s := TJSONDocument.UnQuote(aJSONObject.Pairs[aIndex].JsonString.ToString) + ' : ';
  DoAddBranch(aNode, aJSONObject.Pairs[aIndex].JSONValue, s);
end;

procedure TJSONTreeView.ProcessElement(aNode: TTreeNode; aJSONArray: TJSONArray; aPrefix: string; aIndex: Integer);
var
  s: string;
begin
  s := aPrefix + '[' + IntToStr(aIndex) + '] ';
  DoAddBranch(aNode, aJSONArray.Items[aIndex], s);
end;

procedure TJSONTreeView.SetJSONDocument(const aValue: TJSONDocument);
begin
  if FJSONDocument = aValue then
    exit;

  FJSONDocument := aValue;
  ClearAll;

  if HasActiveDocument then
    LoadJson;
end;

procedure TJSONTreeView.SetVisibleByteSizes(const aValue: Boolean);
begin
  if FVisibleByteSizes = aValue then
    exit;

  FVisibleByteSizes := aValue;
  LoadJson;
end;

procedure TJSONTreeView.SetVisibleChildrenCounts(const aValue: Boolean);
begin
  if FVisibleChildrenCounts = aValue then
    exit;

  FVisibleChildrenCounts := aValue;
  LoadJson;
end;

procedure TJSONTreeView.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;
  if Operation <> opRemove then
    exit;

  if FJSONDocument = nil then
    exit;

  if AComponent = FJSONDocument then
  begin
    FJSONDocument := nil;
    ClearAll;
  end;
end;

end.
