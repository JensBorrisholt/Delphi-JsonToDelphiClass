unit JsonToDelphi.Runtime.Matrix;

interface

uses
  System.Generics.Collections;

type
  TMatrix<T> = class(TObjectList<TList<T>>)
  public
    constructor Create; overload;
    constructor Create(const AValues: TArray<TArray<T>>); overload;
    procedure Assign(const AValues: TArray<TArray<T>>);
    function ToArray: TArray<TArray<T>>; reintroduce;
  end;

  { Assign transfers ownership of every object in AValues to the matrix. The
    caller must not free those objects or assign objects already owned by this
    matrix. Reassignment frees all previously owned rows and objects. }
  TObjectMatrix<T: class> = class(TObjectList<TObjectList<T>>)
  public
    constructor Create; overload;
    constructor Create(const AValues: TArray<TArray<T>>); overload;
    procedure Assign(const AValues: TArray<TArray<T>>);
    function ToArray: TArray<TArray<T>>; reintroduce;
  end;

implementation

{ TMatrix<T> }

procedure TMatrix<T>.Assign(const AValues: TArray<TArray<T>>);
var
  Row: TArray<T>;
  RowList: TList<T>;
begin
  Clear;
  for Row in AValues do
  begin
    RowList := TList<T>.Create;
    try
      RowList.AddRange(Row);
      Add(RowList);
    except
      RowList.Free;
      raise;
    end;
  end;
end;

constructor TMatrix<T>.Create;
begin
  inherited Create(True);
end;

constructor TMatrix<T>.Create(const AValues: TArray<TArray<T>>);
begin
  Create;
  Assign(AValues);
end;

function TMatrix<T>.ToArray: TArray<TArray<T>>;
var
  I: Integer;
begin
  SetLength(Result, Count);
  for I := 0 to Count - 1 do
    Result[I] := Items[I].ToArray;
end;

{ TObjectMatrix<T> }

procedure TObjectMatrix<T>.Assign(const AValues: TArray<TArray<T>>);
var
  Row: TArray<T>;
  RowList: TObjectList<T>;
begin
  Clear;
  for Row in AValues do
  begin
    RowList := TObjectList<T>.Create(True);
    try
      RowList.AddRange(Row);
      Add(RowList);
    except
      RowList.Free;
      raise;
    end;
  end;
end;

constructor TObjectMatrix<T>.Create;
begin
  inherited Create(True);
end;

constructor TObjectMatrix<T>.Create(const AValues: TArray<TArray<T>>);
begin
  Create;
  Assign(AValues);
end;

function TObjectMatrix<T>.ToArray: TArray<TArray<T>>;
var
  I: Integer;
begin
  SetLength(Result, Count);
  for I := 0 to Count - 1 do
    Result[I] := Items[I].ToArray;
end;

end.
