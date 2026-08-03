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
  System.SysUtils,
  Pkg.Json.JsonValueHelper;

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
    if (Field.Kind in [gfObject, gfArray]) and
       (Field.FieldClass <> nil) and
       ((Field.Kind = gfObject) or (Field.ContainedType = jtObject)) then
      AddClass(ATree, Node, Field.FieldClass, ADepth + 1);
  end;
end;

class function TJsonModelVisualizer.FieldTypeName(
  const AField: TGeneratorField): string;

  function JsonTypeName(const AType: TJsonType): string;
  begin
    case AType of
      jtObject: Result := 'object';
      jtArray: Result := 'array';
      jtString: Result := 'string';
      jtTrue, jtFalse: Result := 'Boolean';
      jtNumber: Result := 'Double';
      jtDateTime: Result := 'TDateTime';
      jtBytes: Result := 'Byte';
      jtInteger: Result := 'Integer';
      jtInteger64: Result := 'Int64';
    else
      Result := 'unknown';
    end;
  end;

begin
  case AField.Kind of
    gfObject: Result := AField.FieldClass.Name;
    gfArray:
      if AField.ContainedType = jtObject then
        Result := 'TObjectList<' + AField.FieldClass.Name + '>'
      else
        Result := 'TList<' + JsonTypeName(AField.ContainedType) + '>';
  else
    Result := JsonTypeName(AField.ValueType);
  end;
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
    Root := ATree.Items.Add(nil, AModel.RootClass.Name);
    AddClass(ATree, Root, AModel.RootClass, 0);
    Root.Expand(False);
  finally
    ATree.Items.EndUpdate;
  end;
end;

end.
