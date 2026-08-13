unit JsonToDelphi.Generator.Core.TypeUnification;

interface

uses
  JsonToDelphi.Generator.Core.Model;

type
  TGeneratorTypeUnifier = class
  private
    class function CloneType(AType: TGeneratorType): TGeneratorType; static;
    class function IsNumeric(AKind: TSemanticValueKind): Boolean; static;
    class procedure MergeObjectClasses(ATarget, AObserved: TGeneratorClass;
      const AJsonPath: string; APosition, ASelectionLength: Integer); static;
    class function NumericKind(ALeft, ARight: TSemanticValueKind): TSemanticValueKind; static;
    class function TypeName(AType: TGeneratorType): string; static;
    class procedure RaiseConflict(ALeft, ARight: TGeneratorType; const AJsonPath: string; APosition, ASelectionLength: Integer); static;
  public
    // Merges AObserved into ATarget and always consumes AObserved.
    class procedure Merge(var ATarget: TGeneratorType; AObserved: TGeneratorType; const AJsonPath: string; APosition: Integer = -1; ASelectionLength: Integer = 0); static;
  end;

implementation

uses
  System.SysUtils,
  JsonToDelphi.Generator.Core.Errors;

class function TGeneratorTypeUnifier.CloneType(AType: TGeneratorType): TGeneratorType;
begin
  if AType = nil then
    Exit(nil);

  Result := TGeneratorType.Create(AType.JsonKind, AType.SemanticKind);
  Result.Nullable := AType.Nullable;
  Result.ObjectClass := AType.ObjectClass;
  Result.ElementType := CloneType(AType.ElementType);
end;

class function TGeneratorTypeUnifier.IsNumeric(AKind: TSemanticValueKind): Boolean;
begin
  Result := AKind in [svkInteger, svkInteger64, svkFloat];
end;

class function TGeneratorTypeUnifier.NumericKind(ALeft, ARight: TSemanticValueKind): TSemanticValueKind;
begin
  if (ALeft = svkFloat) or (ARight = svkFloat) then
    Exit(svkFloat);

  if (ALeft = svkInteger64) or (ARight = svkInteger64) then
    Exit(svkInteger64);

  Result := svkInteger;
end;

class procedure TGeneratorTypeUnifier.MergeObjectClasses(ATarget,
  AObserved: TGeneratorClass; const AJsonPath: string; APosition,
  ASelectionLength: Integer);
var
  ClonedField: TGeneratorField;
  Field: TGeneratorField;
  FieldPath: string;
  ObservedField: TGeneratorField;
  TargetType: TGeneratorType;
begin
  if (ATarget = nil) or (AObserved = nil) or (ATarget = AObserved) then
    Exit;

  for Field in ATarget.Fields do
    if AObserved.FindField(Field.JsonName) = nil then
      Field.IsOptional := True;

  for ObservedField in AObserved.Fields do
  begin
    Field := ATarget.FindField(ObservedField.JsonName);
    if Field = nil then
    begin
      ClonedField := TGeneratorField.Create;
      ClonedField.JsonName := ObservedField.JsonName;
      ClonedField.JsonPath := ObservedField.JsonPath;
      ClonedField.SourcePosition := ObservedField.SourcePosition;
      ClonedField.SourceLength := ObservedField.SourceLength;
      ClonedField.IsOptional := True;
      ClonedField.DataType := CloneType(ObservedField.DataType);
      ATarget.Fields.Add(ClonedField);
      Continue;
    end;

    Field.IsOptional := Field.IsOptional or ObservedField.IsOptional;
    FieldPath := Field.JsonPath;
    if FieldPath = '' then
      FieldPath := AJsonPath + '.' + Field.JsonName;
    TargetType := Field.ExtractDataType;
    try
      Merge(TargetType, CloneType(ObservedField.DataType), FieldPath,
        APosition, ASelectionLength);
      Field.DataType := TargetType;
      TargetType := nil;
    finally
      TargetType.Free;
    end;
  end;
end;

class function TGeneratorTypeUnifier.TypeName(AType: TGeneratorType): string;
begin
  if AType = nil then
    Exit('unknown');

  case AType.JsonKind of
    jvkNull:
      Result := 'null';
    jvkObject:
      Result := 'object';
    jvkArray:
      Result := 'array';
    jvkString:
      Result := 'string';
    jvkBoolean:
      Result := 'boolean';
    jvkNumber:
      case AType.SemanticKind of
        svkInteger:
          Result := 'Integer';
        svkInteger64:
          Result := 'Int64';
        svkFloat:
          Result := 'Float';
      else
        Result := 'number';
      end;
  else
    Result := 'unknown';
  end;
end;

class procedure TGeneratorTypeUnifier.RaiseConflict(ALeft, ARight: TGeneratorType; const AJsonPath: string; APosition, ASelectionLength: Integer);
begin
  raise EJsonGenerator.CreateAt(Format('Type conflict at %s: expected %s, found %s',
    [AJsonPath, TypeName(ALeft), TypeName(ARight)]), AJsonPath, APosition, ASelectionLength);
end;

class procedure TGeneratorTypeUnifier.Merge(var ATarget: TGeneratorType; AObserved: TGeneratorType; const AJsonPath: string; APosition, ASelectionLength: Integer);
var
  ObservedElement: TGeneratorType;
  TargetElement: TGeneratorType;
begin
  if AObserved = nil then
    Exit;

  if ATarget = nil then
  begin
    ATarget := AObserved;
    Exit;
  end;

  try
    if AObserved.JsonKind in [jvkNull, jvkUnknown] then
    begin
      ATarget.Nullable := ATarget.Nullable or AObserved.Nullable or (AObserved.JsonKind = jvkNull);
      Exit;
    end;

    if ATarget.JsonKind in [jvkNull, jvkUnknown] then
    begin
      AObserved.Nullable := AObserved.Nullable or ATarget.Nullable or (ATarget.JsonKind = jvkNull);
      ATarget.Free;
      ATarget := AObserved;
      AObserved := nil;
      Exit;
    end;

    ATarget.Nullable := ATarget.Nullable or AObserved.Nullable;

    if (ATarget.JsonKind = jvkNumber) and (AObserved.JsonKind = jvkNumber) and IsNumeric(ATarget.SemanticKind) and IsNumeric(AObserved.SemanticKind) then
    begin
      ATarget.SemanticKind := NumericKind(ATarget.SemanticKind, AObserved.SemanticKind);
      Exit;
    end;

    if (ATarget.JsonKind = jvkString) and (AObserved.JsonKind = jvkString) then
    begin
      if ATarget.SemanticKind <> AObserved.SemanticKind then
        ATarget.SemanticKind := svkString;
      Exit;
    end;

    if (ATarget.JsonKind = jvkArray) and (AObserved.JsonKind = jvkArray) then
    begin
      ObservedElement := AObserved.ExtractElementType;
      if ATarget.ElementType = nil then
        ATarget.ElementType := ObservedElement
      else
      begin
        TargetElement := ATarget.ExtractElementType;
        Merge(TargetElement, ObservedElement, AJsonPath, APosition, ASelectionLength);
        ATarget.ElementType := TargetElement;
      end;
      Exit;
    end;

    if (ATarget.JsonKind = jvkObject) and (AObserved.JsonKind = jvkObject) then
    begin
      if ATarget.ObjectClass = nil then
        ATarget.ObjectClass := AObserved.ObjectClass
      else if (AObserved.ObjectClass <> nil) then
        MergeObjectClasses(ATarget.ObjectClass, AObserved.ObjectClass,
          AJsonPath, APosition, ASelectionLength);
      Exit;
    end;

    if (ATarget.JsonKind = AObserved.JsonKind) and (ATarget.SemanticKind = AObserved.SemanticKind) then
      Exit;

    RaiseConflict(ATarget, AObserved, AJsonPath, APosition, ASelectionLength);
  finally
    AObserved.Free;
  end;
end;

end.
