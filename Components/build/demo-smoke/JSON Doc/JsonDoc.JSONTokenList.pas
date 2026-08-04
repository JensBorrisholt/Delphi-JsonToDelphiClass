unit JsonDoc.JSONTokenList;

interface

uses
  System.Classes, System.Generics.Collections, System.Json;

type
  TJSONTokenKind = (jsNumber, jsString, jsTrue, jsFalse, jsNull, jsObjectStart, jsObjectEnd, jsArrayStart, jsArrayEnd, jsPairStart, jsPairEnd);

  TJSONTokenList = class
  strict private
  type
    TJSONTokenWrapper = class
      Kind: TJSONTokenKind;
      Content: string;
      constructor Create(aKind: TJSONTokenKind; aContent: string);
    end;

  var
    FItems: TObjectList<TJSONTokenWrapper>;
    function GetItemKind(i: Integer): TJSONTokenKind;
    function GetItemContent(i: Integer): string;
  public
    constructor Create;
    destructor Destroy; override;
    function Add(aKind: TJSONTokenKind; aContent: string): Integer;
    function Count: Integer;
    procedure Clear;
    property ItemKind[Index: Integer]: TJSONTokenKind read GetItemKind;
    property ItemContent[Index: Integer]: string read GetItemContent;
  end;

implementation

{ TJSONTokenList }

constructor TJSONTokenList.Create;
begin
  FItems := TObjectList<TJSONTokenWrapper>.Create;
end;

destructor TJSONTokenList.Destroy;
begin
  FItems.Free;
end;

function TJSONTokenList.Add(aKind: TJSONTokenKind; aContent: string): Integer;
begin
  Result := FItems.Add(TJSONTokenWrapper.Create(aKind, aContent));
end;

procedure TJSONTokenList.Clear;
begin
  FItems.Clear;
end;

function TJSONTokenList.Count: Integer;
begin
  Result := FItems.Count;
end;

function TJSONTokenList.GetItemKind(i: Integer): TJSONTokenKind;
begin
  Result := FItems[i].Kind;
end;

function TJSONTokenList.GetItemContent(i: Integer): string;
begin
  Result := FItems[i].Content;
end;

{ TJSONTokenList.TJSONTokenWrapper }

constructor TJSONTokenList.TJSONTokenWrapper.Create(aKind: TJSONTokenKind; aContent: string);
begin
  Kind := aKind;
  Content := aContent;
end;

end.
