unit Pkg.Json.Syntax.Incremental;

interface

uses
  Vcl.ComCtrls,
  Pkg.Json.Syntax.Types;

type
  IIncrementalSyntaxHighlighter = interface
    ['{49CD8C83-0A77-455E-A8B7-783ED4FA59DE}']
    procedure HighlightAll;
    procedure TextChanged;
  end;

  TIncrementalSyntaxHighlighter = class(TInterfacedObject, IIncrementalSyntaxHighlighter)
  private
    FEditor: TRichEdit;
    FLanguage: TSyntaxLanguage;
    FLastLength: Integer;
    FLastLineCount: Integer;
    procedure RememberDocument;
  protected
    procedure HighlightAll;
    procedure TextChanged;
  public
    constructor Create(const AEditor: TRichEdit; const ALanguage: TSyntaxLanguage);
  end;

implementation

uses
  System.SysUtils, Winapi.Messages,
  Pkg.Json.Syntax.RichEdit;

constructor TIncrementalSyntaxHighlighter.Create(const AEditor: TRichEdit; const ALanguage: TSyntaxLanguage);
begin
  inherited Create;
  FEditor := AEditor;
  FLanguage := ALanguage;
  RememberDocument;
end;

procedure TIncrementalSyntaxHighlighter.HighlightAll;
begin
  if FEditor.Text <> '' then
    TSyntaxRichEditRenderer.Highlight(FEditor, FLanguage);

  RememberDocument;
end;

procedure TIncrementalSyntaxHighlighter.RememberDocument;
begin
  FLastLength := Length(FEditor.Text);
  FLastLineCount := FEditor.Lines.Count;
end;

procedure TIncrementalSyntaxHighlighter.TextChanged;
var
  CurrentLength, CurrentLine, CurrentLineCount: Integer;
begin
  CurrentLength := Length(FEditor.Text);
  CurrentLineCount := FEditor.Lines.Count;

  if FEditor.Text = '' then
  begin
    RememberDocument;
    Exit;
  end;

  if (Abs(CurrentLength - FLastLength) > 1) or (CurrentLineCount <> FLastLineCount) then
    TSyntaxRichEditRenderer.Highlight(FEditor, FLanguage)
  else
  begin
    CurrentLine := FEditor.Perform(EM_LINEFROMCHAR, FEditor.SelStart, 0);
    TSyntaxRichEditRenderer.HighlightLine(FEditor, FLanguage, CurrentLine);
  end;

  RememberDocument;
end;

end.
