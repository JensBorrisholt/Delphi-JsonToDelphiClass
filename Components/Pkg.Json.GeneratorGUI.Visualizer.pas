unit Pkg.Json.GeneratorGUI.Visualizer;

interface

uses
  Vcl.ComCtrls,
  Pkg.Json.Generator.Model;

type
  TJsonModelVisualizer = class
  private
    class function FieldTypeName(const AField: TGeneratorField): string; static;
    class procedure AddClass(const ATree: TTreeView; const AParent: TTreeNode;
      const AClass: TGeneratorClass; const ADepth: Integer); static;
  public
    class procedure Visualize(const ATree: TTreeView;
      const AModel: TGeneratorModel); static;
  end;

implementation

uses
  System.SysUtils;

class procedure TJsonModelVisualizer.AddClass(const ATree: TTreeView;
  const AParent: TTreeNode; const AClass: TGeneratorClass;
  const ADepth: Integer);
var
  Field: TGeneratorField;
  Node: TTreeNode;
begin
  if (AClass = nil) or (ADepth > 32) then
    Exit;
  for Field in AClass.Fields do
  begin
    Node := ATree.Items.AddChild(AParent,
      Format('%s: %s', [Field.JsonName, FieldTypeName(Field)]));
    if (Field.DataType <> nil) and
       (Field.DataType.LeafType <> nil) and
       (Field.DataType.LeafType.SemanticKind = svkObject) then
      AddClass(ATree, Node, Field.DataType.LeafType.ObjectClass,
        ADepth + 1);
  end;
end;

class function TJsonModelVisualizer.FieldTypeName(
  const AField: TGeneratorField): string;

  function SemanticTypeName(const AType: TGeneratorType): string;
  begin
    if AType = nil then
      Exit('unknown');
    if AType.JsonKind = jvkArray then
      Exit('array<' + SemanticTypeName(AType.ElementType) + '>');
    case AType.SemanticKind of
      svkObject: Result := 'object';
      svkString: Result := 'string';
      svkBoolean: Result := 'boolean';
      svkInteger: Result := 'integer';
      svkInteger64: Result := 'integer64';
      svkFloat: Result := 'number';
      svkDateTime: Result := 'date-time';
      svkBytes: Result := 'byte';
    else
      Result := 'unknown';
    end;
  end;

begin
  Result := SemanticTypeName(AField.DataType);
  if AField.IsOptional then
    Result := Result + ' (optional)';
  if (AField.DataType <> nil) and AField.DataType.Nullable then
    Result := Result + ' (nullable)';
end;

class procedure TJsonModelVisualizer.Visualize(const ATree: TTreeView;
  const AModel: TGeneratorModel);
var
  Root: TTreeNode;
begin
  ATree.Items.BeginUpdate;
  try
    ATree.Items.Clear;
    if (AModel = nil) or (AModel.RootClass = nil) then
      Exit;
    Root := ATree.Items.Add(nil, AModel.RootClass.JsonName);
    AddClass(ATree, Root, AModel.RootClass, 0);
    Root.Expand(False);
  finally
    ATree.Items.EndUpdate;
  end;
end;

end.
