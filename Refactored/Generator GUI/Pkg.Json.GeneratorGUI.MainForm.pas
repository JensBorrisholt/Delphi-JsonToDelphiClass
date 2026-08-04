unit Pkg.Json.GeneratorGUI.MainForm;

interface

uses
  System.Classes, System.SysUtils, System.Actions, System.UITypes,
  Vcl.ActnList, Vcl.ComCtrls, Vcl.Controls, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Forms, Vcl.Menus, Vcl.StdCtrls,
  Pkg.Json.GeneratorGUI.GitHub, Pkg.Json.Syntax.Incremental;

type
  TMainForm = class(TForm)
    ActionList: TActionList;
    actConvert: TAction;
    actExit: TAction;
    actFormatJson: TAction;
    actOpen: TAction;
    actSaveAs: TAction;
    actSettings: TAction;
    actClassVisualizer: TAction;
    actBSON: TAction;
    actDelphiUnit: TAction;
    actMinifyJson: TAction;
    actDemoProject: TAction;
    btnConvert: TButton;
    btnFormatJson: TButton;
    edtClassName: TEdit;
    edtUnitName: TEdit;
    lblClassName: TLabel;
    lblInput: TLabel;
    lblOutput: TLabel;
    lblStructure: TLabel;
    lblUnitName: TLabel;
    lblGitHub: TLabel;
    MainMenu: TMainMenu;
    memJson: TRichEdit;
    memOutput: TRichEdit;
    miExit: TMenuItem;
    miFormatJson: TMenuItem;
    miFile: TMenuItem;
    miOpen: TMenuItem;
    miOptions: TMenuItem;
    miSaveAs: TMenuItem;
    miSettings: TMenuItem;
    miView: TMenuItem;
    miVisualizer: TMenuItem;
    miConvert: TMenuItem;
    miBSON: TMenuItem;
    miDelphiUnit: TMenuItem;
    miMinifyJson: TMenuItem;
    miDemoProject: TMenuItem;
    OpenDialog: TOpenDialog;
    pnlNames: TPanel;
    pnlWorkspace: TPanel;
    pnlGitHub: TPanel;
    SaveDialog: TSaveDialog;
    Splitter: TSplitter;
    SplitterTree: TSplitter;
    StatusBar: TStatusBar;
    treeJson: TTreeView;
    procedure actConvertExecute(Sender: TObject);
    procedure actExitExecute(Sender: TObject);
    procedure actFormatJsonExecute(Sender: TObject);
    procedure actOpenExecute(Sender: TObject);
    procedure actSaveAsExecute(Sender: TObject);
    procedure actSettingsExecute(Sender: TObject);
    procedure actClassVisualizerExecute(Sender: TObject);
    procedure actOutputToggleExecute(Sender: TObject);
    procedure ActionListUpdate(Action: TBasicAction; var Handled: Boolean);
    procedure edtClassNameChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure lblGitHubClick(Sender: TObject);
    procedure memJsonChange(Sender: TObject);
  private
    FJsonHighlighter: IIncrementalSyntaxHighlighter;
    FUpdateRequest: IUpdateRequest;
    FRelease: TGitHubRelease;
    FOutputPages: TPageControl;
    FDelphiTab: TTabSheet;
    FBsonTab: TTabSheet;
    FMinifyTab: TTabSheet;
    FBsonOutput: TRichEdit;
    FMinifyOutput: TRichEdit;
    function CreateOutputTab(const ACaption: string; out ATab: TTabSheet): TRichEdit;
    function CurrentOutput(out AExtension: string): TRichEdit;
    procedure ClearOutput;
    function FormatJsonInput(const AShowError: Boolean): Boolean;
    procedure HighlightDelphi;
    procedure SetStatus(const AText: string);
  end;

var
  MainForm: TMainForm;

implementation

uses
  System.IOUtils, Winapi.Messages, Vcl.FileCtrl,
  Pkg.Json.Generator, Pkg.Json.Generator.Errors, Pkg.Json.Generator.Options,
  Pkg.Json.Settings, Pkg.Json.Lib.JSONConverter,
  Pkg.Json.GeneratorGUI.SettingsForm, Pkg.Json.Utils,
  Pkg.Json.GeneratorGUI.UpdateForm, Pkg.Json.GeneratorGUI.Visualizer,
  Pkg.Json.GeneratorGUI.DemoProject,
  Pkg.Json.Syntax.RichEdit,
  Pkg.Json.Syntax.Types;

{$R *.dfm}

procedure TMainForm.ActionListUpdate(Action: TBasicAction; var Handled: Boolean);
begin
  actConvert.Enabled := (Trim(memJson.Text) <> '') and (actDelphiUnit.Checked or actBSON.Checked or actMinifyJson.Checked or actDemoProject.Checked);
  var Extension: string;
  var Editor := CurrentOutput(Extension);
  actSaveAs.Enabled := (Editor <> nil) and (Editor.Text <> '');
end;

procedure TMainForm.actConvertExecute(Sender: TObject);
begin
  var Options := TGeneratorOptions.FromSettings(TSettings.Instance);
  var Generator := TJsonToDelphiGenerator.Create(Options);

  try
    if not Generator.IsValid(memJson.Text) then
      raise EConvertError.Create('Input is not valid JSON.');

    Generator.RootClassName := Trim(edtClassName.Text);
    Generator.DestinationUnitName := Trim(edtUnitName.Text);
    Generator.Parse(memJson.Text);
    TJsonModelVisualizer.Visualize(treeJson, Generator.Model);

    var DelphiSource := '';
    if actDelphiUnit.Checked or actDemoProject.Checked then
      DelphiSource := Generator.GenerateUnit;

    if actDelphiUnit.Checked then
    begin
      memOutput.Text := DelphiSource;
      HighlightDelphi;
    end;

    if actBSON.Checked then
      FBsonOutput.Text := TJSONConverter.Json2BsonString(memJson.Text);

    if actMinifyJson.Checked then
      FMinifyOutput.Text := TJSONConverter.MinifyJson(memJson.Text);

    if actDemoProject.Checked then
    begin
      var
      Destination := '';
      if SelectDirectory('Select destination for the demo project', '', Destination) then
        TDemoProjectGenerator.Generate(Destination, Trim(edtUnitName.Text), Generator.GeneratedRootClassName, memJson.Text, DelphiSource);
    end;

    if actDelphiUnit.Checked then
      FOutputPages.ActivePage := FDelphiTab
    else if actBSON.Checked then
      FOutputPages.ActivePage := FBsonTab
    else
      FOutputPages.ActivePage := FMinifyTab;

    SetStatus('Selected output formats generated successfully.');
  except
    on E: EJsonGenerator do
    begin
      ClearOutput;
      SetStatus(E.Message);

      if E.JsonPath <> '' then
      begin
        memJson.SetFocus;
        memJson.SelStart := E.Position;
        memJson.SelLength := E.SelectionLength;
        memJson.Perform(EM_SCROLLCARET, 0, 0);
      end;
      MessageDlg(E.Message, mtError, [mbOK], 0);
    end;
    on E: Exception do
    begin
      ClearOutput;
      SetStatus('Generation failed.');
      MessageDlg(E.Message, mtError, [mbOK], 0);
    end;
  end;
  Generator.Free;
end;

procedure TMainForm.actOutputToggleExecute(Sender: TObject);
begin
  if FOutputPages = nil then
    Exit;
  FDelphiTab.TabVisible := actDelphiUnit.Checked;
  FBsonTab.TabVisible := actBSON.Checked;
  FMinifyTab.TabVisible := actMinifyJson.Checked;
end;

procedure TMainForm.actExitExecute(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.actFormatJsonExecute(Sender: TObject);
begin
  FormatJsonInput(True);
end;

procedure TMainForm.actOpenExecute(Sender: TObject);
var
  ChangeHandler: TNotifyEvent;
begin
  if not OpenDialog.Execute then
    Exit;

  ChangeHandler := memJson.OnChange;
  memJson.OnChange := nil;
  memJson.Lines.BeginUpdate;
  try
    memJson.Lines.LoadFromFile(OpenDialog.FileName, TEncoding.UTF8);
    if FormatJsonInput(False) then
      SetStatus(Format('Loaded and formatted %s', [ExtractFileName(OpenDialog.FileName)]))
    else
    begin
      SetStatus('The opened file does not contain valid JSON.');
      MessageDlg('The file was opened, but it does not contain valid JSON.', mtWarning, [mbOK], 0);
    end;

  finally
    memJson.Lines.EndUpdate;
    memJson.OnChange := ChangeHandler;
  end;
end;

procedure TMainForm.actSaveAsExecute(Sender: TObject);
begin
  var Extension: string;
  var Editor := CurrentOutput(Extension);
  if Editor = nil then
    Exit;

  SaveDialog.DefaultExt := Extension;
  SaveDialog.FileName := Trim(edtUnitName.Text) + '.' + Extension;

  if not SaveDialog.Execute then
    Exit;

  TFile.WriteAllText(SaveDialog.FileName, Editor.Text, TEncoding.UTF8);
  SetStatus(Format('Saved %s', [ExtractFileName(SaveDialog.FileName)]));
end;

procedure TMainForm.actSettingsExecute(Sender: TObject);
begin
  with TSettingsForm.Create(Self) do
    try
      ShowModal;
    finally
      Free;
    end;
end;

procedure TMainForm.ClearOutput;
begin
  memOutput.Clear;
  if FBsonOutput <> nil then
    FBsonOutput.Clear;

  if FMinifyOutput <> nil then
    FMinifyOutput.Clear;

  treeJson.Items.Clear;
end;

function TMainForm.CreateOutputTab(const ACaption: string; out ATab: TTabSheet): TRichEdit;
begin
  ATab := TTabSheet.Create(Self);
  ATab.PageControl := FOutputPages;
  ATab.Caption := ACaption;
  Result := TRichEdit.Create(Self);
  Result.Parent := ATab;
  Result.Align := alClient;
  Result.ReadOnly := True;
  Result.ScrollBars := ssBoth;
  Result.WordWrap := False;
  Result.Font.Assign(memOutput.Font);
end;

function TMainForm.CurrentOutput(out AExtension: string): TRichEdit;
begin
  Result := nil;
  AExtension := '';
  if FOutputPages = nil then
    Exit;

 if FOutputPages.ActivePage = FDelphiTab then
  begin
    Result := memOutput;
    AExtension := 'pas'
  end
  else if FOutputPages.ActivePage = FBsonTab then
  begin
    Result := FBsonOutput;
    AExtension := 'bson'
  end
  else if FOutputPages.ActivePage = FMinifyTab then
  begin
    Result := FMinifyOutput;
    AExtension := 'json'
  end;
end;

procedure TMainForm.actClassVisualizerExecute(Sender: TObject);
begin
  treeJson.Visible := actClassVisualizer.Checked;
  SplitterTree.Visible := actClassVisualizer.Checked;
  lblStructure.Visible := actClassVisualizer.Checked;
end;

procedure TMainForm.HighlightDelphi;
begin
  TSyntaxRichEditRenderer.Highlight(memOutput, slDelphi);
end;

function TMainForm.FormatJsonInput(const AShowError: Boolean): Boolean;
begin
  Result := False;
  try
    memJson.Text := PrettyPrint(memJson.Text);
    memJson.SelStart := 0;
    memJson.SelLength := 0;
    SetStatus('JSON formatted successfully.');
    FJsonHighlighter.HighlightAll;
    Result := True;
  except
    on E: Exception do
    begin
      SetStatus('JSON formatting failed.');
      if AShowError then
        MessageDlg('The input is not valid JSON.' + sLineBreak + sLineBreak + E.Message, mtError, [mbOK], 0);
    end;
  end;
end;

procedure TMainForm.edtClassNameChange(Sender: TObject);
begin
  edtUnitName.Text := Trim(edtClassName.Text) + 'U';
  ClearOutput;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FJsonHighlighter := TIncrementalSyntaxHighlighter.Create(memJson, slJson);
  FOutputPages := TPageControl.Create(Self);
  FOutputPages.Parent := pnlWorkspace;
  FOutputPages.Align := alClient;
  FDelphiTab := TTabSheet.Create(Self);
  FDelphiTab.PageControl := FOutputPages;
  FDelphiTab.Caption := 'Delphi Unit';
  memOutput.Parent := FDelphiTab;
  memOutput.Align := alClient;
  FBsonOutput := CreateOutputTab('BSON', FBsonTab);
  FMinifyOutput := CreateOutputTab('Minify JSON', FMinifyTab);
  actOutputToggleExecute(nil);
  edtClassName.Text := 'Root';
  SetStatus('Paste JSON or open a JSON file to begin.');
  lblGitHub.Caption := 'Checking GitHub for updates...';

  FUpdateRequest := TGitHubUpdateService.CheckForUpdate(
    procedure(const ARelease: TGitHubRelease; const AError: string)
    begin
      FRelease := ARelease;
      if AError <> '' then
        lblGitHub.Caption := 'GitHub update check failed: ' + AError
      else if FRelease.Valid then
        lblGitHub.Caption := 'Version ' + FRelease.TagName + ' is available — click to view'
      else
        lblGitHub.Caption := 'Version ' + ProgramVersion + ' is up to date — view project on GitHub';
    end);
end;

procedure TMainForm.lblGitHubClick(Sender: TObject);
begin
  if not FRelease.Valid then
    ShellExecute(ProgramUrl)
  else
    with TUpdateForm.Create(Self) do
      try
        NewRelease := FRelease;
        ShowModal;
      finally
        Free;
      end;
end;

procedure TMainForm.memJsonChange(Sender: TObject);
begin
  ClearOutput;
  SetStatus('Input changed; generate the unit again.');

  if FJsonHighlighter <> nil then
    FJsonHighlighter.TextChanged;
end;

procedure TMainForm.SetStatus(const AText: string);
begin
  StatusBar.SimpleText := AText;
end;

end.
