unit JsonToDelphi.Runtime.Matrix;

interface

uses
  System.Generics.Collections;

type
  TCustomMatrix<T; TRow: TList<T>, constructor> = class(TObjectList<TRow>)
  type
    TMatrixArray = TArray<TArray<T>>;
  public
    constructor Create(const AValues: TMatrixArray); overload;
    procedure Assign(const AValues: TMatrixArray);
    function ToArray: TMatrixArray; reintroduce;
  end;

  TMatrix<T> = class(TCustomMatrix<T, TList<T>>);

  { Assign transfers ownership of every object in AValues to the matrix. The
    caller must not free those objects or assign objects already owned by this
    matrix. Reassignment frees all previously owned rows and objects. }
  TObjectMatrix<T: class> = class(TCustomMatrix<T, TObjectList<T>>);

implementation

{ TCustomMatrix<T, TRow> }

procedure TCustomMatrix<T, TRow>.Assign(const AValues: TMatrixArray);
var
  Row: TArray<T>;
  RowList: TRow;
begin
  Clear;
  for Row in AValues do
  begin
    RowList := TRow.Create;
    try
      RowList.AddRange(Row);
      Add(RowList);
    except
      RowList.Free;
      raise;
    end;
  end;
end;

constructor TCustomMatrix<T, TRow>.Create(const AValues: TMatrixArray);
begin
  inherited Create;
  Assign(AValues);
end;

function TCustomMatrix<T, TRow>.ToArray: TMatrixArray;
var
  I: Integer;
begin
  SetLength(Result, Count);
  for I := 0 to Count - 1 do
    Result[I] := Items[I].ToArray;
end;

end.
