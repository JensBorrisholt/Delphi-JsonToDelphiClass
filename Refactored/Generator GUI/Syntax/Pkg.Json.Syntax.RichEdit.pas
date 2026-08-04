unit Pkg.Json.Syntax.RichEdit;

interface

uses
  Vcl.ComCtrls,
  Pkg.Json.Syntax.Types;

type
  TSyntaxRichEditRenderer = class
  private
    class procedure ApplyTokenStyle(const Editor: TRichEdit;
      const AStart, ALength: Integer; const Kind: TSyntaxTokenKind); static;
  public
    class procedure Highlight(const Editor: TRichEdit; const Language: TSyntaxLanguage); static;
    class procedure HighlightLine(const Editor: TRichEdit;
      const Language: TSyntaxLanguage; const LineIndex: Integer); static;
  end;

implementation

uses
  System.SysUtils, Vcl.Graphics, Winapi.Messages, Winapi.RichEdit,
  Winapi.Windows,
  Pkg.Json.Syntax.Factory;

class procedure TSyntaxRichEditRenderer.ApplyTokenStyle(const Editor: TRichEdit;
  const AStart, ALength: Integer; const Kind: TSyntaxTokenKind);
var
  CharFormat: TCharFormat2;
  CharRange: TCharRange;
begin
  FillChar(CharFormat, SizeOf(CharFormat), 0);
  CharFormat.cbSize := SizeOf(CharFormat);
  CharFormat.dwMask := CFM_COLOR or CFM_BOLD or CFM_ITALIC;
  CharFormat.crTextColor := ColorToRGB(clWindowText);
  case Kind of
    tkKeyword:
      begin
        CharFormat.crTextColor := ColorToRGB(TColor($00CC6600));
        CharFormat.dwEffects := CFE_BOLD;
      end;
    tkPropertyName:
      CharFormat.crTextColor := ColorToRGB(TColor($00FF0080));
    tkString:
      CharFormat.crTextColor := ColorToRGB(TColor($002B2BA3));
    tkComment:
      begin
        CharFormat.crTextColor := ColorToRGB(TColor($00008000));
        CharFormat.dwEffects := CFE_ITALIC;
      end;
    tkNumber:
      CharFormat.crTextColor := ColorToRGB(TColor($000080FF));
    tkSymbol:
      CharFormat.crTextColor := ColorToRGB(clWindowText);
  end;

  CharRange.cpMin := AStart;
  if ALength < 0 then
    CharRange.cpMax := -1
  else
    CharRange.cpMax := AStart + ALength;
  SendMessage(Editor.Handle, EM_EXSETSEL, 0, LPARAM(@CharRange));
  SendMessage(Editor.Handle, EM_SETCHARFORMAT, SCF_SELECTION,
    LPARAM(@CharFormat));
end;

class procedure TSyntaxRichEditRenderer.Highlight(const Editor: TRichEdit; const Language: TSyntaxLanguage);
var
  Column, LineIndex, LineStart, SavedLength, SavedStart: Integer;
  Lines: TSyntaxLines;
  SavedEventMask: NativeInt;
  Token: TSyntaxToken;
begin
  SavedStart := Editor.SelStart;
  SavedLength := Editor.SelLength;
  Lines := TSyntaxHighlighterFactory.GetHighlighter(Language).Tokenize(Editor.Text);

  SendMessage(Editor.Handle, WM_SETREDRAW, 0, 0);
  SavedEventMask := Editor.Perform(EM_SETEVENTMASK, 0, 0);
  Editor.Lines.BeginUpdate;
  try
    { Reset the complete document once. Most tokens use the default style, so
      only coloured tokens need individual RichEdit formatting operations. }
    ApplyTokenStyle(Editor, 0, -1, tkText);

    for LineIndex := 0 to High(Lines) do
    begin
      LineStart := Editor.Perform(EM_LINEINDEX, LineIndex, 0);
      if LineStart < 0 then
        Break;
      Column := 0;
      for Token in Lines[LineIndex] do
      begin
        if not (Token.Kind in [tkText, tkSymbol]) then
        begin
          ApplyTokenStyle(Editor, LineStart + Column, Length(Token.Text),
            Token.Kind);
        end;
        Inc(Column, Length(Token.Text));
      end;
    end;
  finally
    Editor.SelStart := SavedStart;
    Editor.SelLength := SavedLength;
    Editor.Lines.EndUpdate;
    Editor.Perform(EM_SETEVENTMASK, 0, SavedEventMask);
    SendMessage(Editor.Handle, WM_SETREDRAW, 1, 0);
    Editor.Invalidate;
  end;
end;

class procedure TSyntaxRichEditRenderer.HighlightLine(const Editor: TRichEdit;
  const Language: TSyntaxLanguage; const LineIndex: Integer);
var
  Column, LineLength, LineStart, SavedLength, SavedStart: Integer;
  Lines: TSyntaxLines;
  SavedEventMask: NativeInt;
  Token: TSyntaxToken;
begin
  if (LineIndex < 0) or (LineIndex >= Editor.Lines.Count) then
    Exit;
  SavedStart := Editor.SelStart;
  SavedLength := Editor.SelLength;
  Lines := TSyntaxHighlighterFactory.GetHighlighter(Language).Tokenize(
    Editor.Lines[LineIndex]);
  LineStart := Editor.Perform(EM_LINEINDEX, LineIndex, 0);
  LineLength := Length(Editor.Lines[LineIndex]);
  SendMessage(Editor.Handle, WM_SETREDRAW, 0, 0);
  SavedEventMask := Editor.Perform(EM_SETEVENTMASK, 0, 0);
  try
    ApplyTokenStyle(Editor, LineStart, LineLength, tkText);
    if Length(Lines) > 0 then
    begin
      Column := 0;
      for Token in Lines[0] do
      begin
        if not (Token.Kind in [tkText, tkSymbol]) then
          ApplyTokenStyle(Editor, LineStart + Column, Length(Token.Text),
            Token.Kind);
        Inc(Column, Length(Token.Text));
      end;
    end;
  finally
    Editor.SelStart := SavedStart;
    Editor.SelLength := SavedLength;
    Editor.Perform(EM_SETEVENTMASK, 0, SavedEventMask);
    SendMessage(Editor.Handle, WM_SETREDRAW, 1, 0);
    Editor.Invalidate;
  end;
end;

end.
