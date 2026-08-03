unit Pkg.Json.Syntax.RichEdit;

interface

uses
  Vcl.ComCtrls,
  Pkg.Json.Syntax.Types;

type
  TSyntaxRichEditRenderer = class
  private
    class procedure ApplyTokenStyle(const Editor: TRichEdit; const Kind: TSyntaxTokenKind); static;
  public
    class procedure Highlight(const Editor: TRichEdit; const Language: TSyntaxLanguage); static;
  end;

implementation

uses
  System.SysUtils, Vcl.Graphics, Winapi.Messages, Winapi.Windows,
  Pkg.Json.Syntax.Factory;

class procedure TSyntaxRichEditRenderer.ApplyTokenStyle(const Editor: TRichEdit; const Kind: TSyntaxTokenKind);
begin
  Editor.SelAttributes.Style := [];
  case Kind of
    tkKeyword:
      begin
        Editor.SelAttributes.Color := TColor($00CC6600);
        Editor.SelAttributes.Style := [fsBold];
      end;
    tkString:
      Editor.SelAttributes.Color := TColor($002B2BA3);
    tkComment:
      begin
        Editor.SelAttributes.Color := TColor($00008000);
        Editor.SelAttributes.Style := [fsItalic];
      end;
    tkNumber:
      Editor.SelAttributes.Color := TColor($00808000);
    tkSymbol:
      Editor.SelAttributes.Color := clGrayText;
  else
    Editor.SelAttributes.Color := clWindowText;
  end;
end;

class procedure TSyntaxRichEditRenderer.Highlight(const Editor: TRichEdit; const Language: TSyntaxLanguage);
var
  Column, LineIndex, LineStart, SavedLength, SavedStart: Integer;
  Lines: TSyntaxLines;
  Token: TSyntaxToken;
begin
  SavedStart := Editor.SelStart;
  SavedLength := Editor.SelLength;
  Lines := TSyntaxHighlighterFactory.GetHighlighter(Language).Tokenize(Editor.Text);

  SendMessage(Editor.Handle, WM_SETREDRAW, 0, 0);
  Editor.Lines.BeginUpdate;
  try
    for LineIndex := 0 to High(Lines) do
    begin
      LineStart := Editor.Perform(EM_LINEINDEX, LineIndex, 0);
      if LineStart < 0 then
        Break;
      Column := 0;
      for Token in Lines[LineIndex] do
      begin
        Editor.SelStart := LineStart + Column;
        Editor.SelLength := Length(Token.Text);
        ApplyTokenStyle(Editor, Token.Kind);
        Inc(Column, Length(Token.Text));
      end;
    end;
  finally
    Editor.SelStart := SavedStart;
    Editor.SelLength := SavedLength;
    Editor.Lines.EndUpdate;
    SendMessage(Editor.Handle, WM_SETREDRAW, 1, 0);
    Editor.Invalidate;
  end;
end;

end.
