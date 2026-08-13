unit JsonToDelphi.GUI.MainForm;

interface

uses
  System.Classes, System.SysUtils, System.Actions, System.UITypes, System.IOUtils,
  Winapi.Messages, Winapi.Windows,
  Vcl.ActnList, Vcl.ActnMan, Vcl.ComCtrls, Vcl.Controls, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Forms, Vcl.Graphics,
  Vcl.ImgList, Vcl.Ribbon, Vcl.RibbonLunaStyleActnCtrls, Vcl.StdCtrls,
  JsonToDelphi.GUI.GitHub, JsonToDelphi.GUI.Syntax.Incremental,
  JsonToDelphi.Generator.Delphi.Settings, JsonToDelphi.Generator.CSharp.Settings, System.ImageList, Vcl.ToolWin, Vcl.ActnCtrls;

type
  TMainForm = class(TForm)
    ActionList: TActionManager;
    Ribbon: TRibbon;
    RibbonPageHome: TRibbonPage;
    RibbonGroupFile: TRibbonGroup;
    RibbonGroupDelphi: TRibbonGroup;
    RibbonGroupCSharp: TRibbonGroup;
    RibbonGroupJson: TRibbonGroup;
    RibbonGroupGenerate: TRibbonGroup;
    RibbonGroupSettings: TRibbonGroup;
    RibbonGroupPanels: TRibbonGroup;
    SmallImages: TImageList;
    LargeImages: TImageList;
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
    actCSharpSource: TAction;
    actDemoData: TAction;
    edtClassName: TEdit;
    edtUnitName: TEdit;
    lblClassName: TLabel;
    lblInput: TLabel;
    lblOutput: TLabel;
    lblStructure: TLabel;
    lblUnitName: TLabel;
    lblGitHub: TLabel;
    memJson: TRichEdit;
    memOutput: TRichEdit;
    FOutputPages: TPageControl;
    FDelphiTab: TTabSheet;
    FCSharpTab: TTabSheet;
    FBsonTab: TTabSheet;
    FMinifyTab: TTabSheet;
    FCSharpOutput: TRichEdit;
    FBsonOutput: TRichEdit;
    FMinifyOutput: TRichEdit;
    OpenDialog: TOpenDialog;
    pnlNames: TPanel;
    pnlWorkspace: TPanel;
    pnlGitHub: TPanel;
    SaveDialog: TSaveDialog;
    Splitter: TSplitter;
    SplitterTree: TSplitter;
    SplitterDemoData: TSplitter;
    StatusBar: TStatusBar;
    treeJson: TTreeView;
    pnlDemoData: TPanel;
    lblDemoData: TLabel;
    lstDemoData: TListView;
    procedure actConvertExecute(Sender: TObject);
    procedure actExitExecute(Sender: TObject);
    procedure actFormatJsonExecute(Sender: TObject);
    procedure actOpenExecute(Sender: TObject);
    procedure actSaveAsExecute(Sender: TObject);
    procedure actSettingsExecute(Sender: TObject);
    procedure actClassVisualizerExecute(Sender: TObject);
    procedure actDemoDataExecute(Sender: TObject);
    procedure actOutputToggleExecute(Sender: TObject);
    procedure ActionListUpdate(Action: TBasicAction; var Handled: Boolean);
    procedure edtClassNameChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lblGitHubClick(Sender: TObject);
    procedure lstDemoDataSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure memJsonChange(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure SplitterMoved(Sender: TObject);
  private
    FJsonHighlighter: IIncrementalSyntaxHighlighter;
    FUpdateRequest: IUpdateRequest;
    FRelease: TGitHubRelease;
    FDelphiSettings: TDelphiSettings;
    FCSharpSettings: TCSharpSettings;
    function CurrentOutput(out AExtension: string): TRichEdit;
    procedure ClearOutput;
    function FormatJsonInput(const AShowError: Boolean): Boolean;
    procedure HighlightDelphi;
    procedure HighlightCSharp;
    procedure UpdateOutputCaption;
    procedure SetStatus(const AText: string);
    procedure RefreshDemoData;
    procedure RefreshClassVisualizer;
  end;

var
  MainForm: TMainForm;

implementation

uses
  Vcl.FileCtrl,
  JsonToDelphi.Generator.Delphi, JsonToDelphi.Generator.CSharp, JsonToDelphi.Generator.Core.Errors,
  JsonToDelphi.Runtime.JSONConverter,
  JsonToDelphi.GUI.SettingsForm, JsonToDelphi.Runtime.Utils,
  JsonToDelphi.GUI.UpdateForm, JsonToDelphi.GUI.Visualizer,
  JsonToDelphi.GUI.DemoProject, JsonToDelphi.GUI.DemoData,
  JsonToDelphi.GUI.Syntax.RichEdit,
  JsonToDelphi.GUI.Syntax.Types;

{$R *.dfm}

procedure TMainForm.ActionListUpdate(Action: TBasicAction; var Handled: Boolean);
var
  Extension: string;
begin
  actConvert.Enabled := (Trim(memJson.Text) <> '') and (actDelphiUnit.Checked or actCSharpSource.Checked or actBSON.Checked or actMinifyJson.Checked or actDemoProject.Checked);
  var Editor := CurrentOutput(Extension);
  actSaveAs.Enabled := (Editor <> nil) and (Editor.Text <> '');
end;

procedure TMainForm.actConvertExecute(Sender: TObject);
var
  DelphiGenerator: TJsonToDelphiGenerator;
  CSharpGenerator: TJsonToCSharpGenerator;
  DelphiSource: string;
  CSharpSource: string;
  GeneratedSomething: Boolean;
begin
  DelphiGenerator := nil;
  CSharpGenerator := nil;
  DelphiSource := '';
  CSharpSource := '';
  GeneratedSomething := False;

  try
    if actDelphiUnit.Checked or actDemoProject.Checked then
    begin
      DelphiGenerator := TJsonToDelphiGenerator.Create(FDelphiSettings);

      if not DelphiGenerator.IsValid(memJson.Text) then
        raise EConvertError.Create('Input is not valid JSON.');

      DelphiGenerator.RootClassName := Trim(edtClassName.Text);
      DelphiGenerator.DestinationUnitName := Trim(edtUnitName.Text);
      DelphiGenerator.Parse(memJson.Text);
      DelphiSource := DelphiGenerator.GenerateUnit;
      GeneratedSomething := True;
    end;

    if actCSharpSource.Checked then
    begin
      CSharpGenerator := TJsonToCSharpGenerator.Create(FCSharpSettings);

      if not CSharpGenerator.IsValid(memJson.Text) then
        raise EConvertError.Create('Input is not valid JSON.');

      CSharpGenerator.RootClassName := Trim(edtClassName.Text);
      CSharpGenerator.Parse(memJson.Text);


      CSharpSource := CSharpGenerator.GenerateSource;
      GeneratedSomething := True;
    end;

    if actDelphiUnit.Checked then
    begin
      memOutput.Text := DelphiSource;
      HighlightDelphi;
    end;

    if actCSharpSource.Checked then
    begin
      FCSharpOutput.Text := CSharpSource;
      HighlightCSharp;
    end;

    if actBSON.Checked then
      FBsonOutput.Text := TJSONConverter.Json2BsonString(memJson.Text);

    if actMinifyJson.Checked then
      FMinifyOutput.Text := TJSONConverter.MinifyJson(memJson.Text);

    if actDemoProject.Checked then
    begin
      var Destination := '';
      if SelectDirectory('Select destination for the demo project', '', Destination) then
        TDemoProjectGenerator.Generate(Destination, Trim(edtUnitName.Text), DelphiGenerator.GeneratedRootClassName, memJson.Text, DelphiSource);
    end;

    if actDelphiUnit.Checked then
      FOutputPages.ActivePage := FDelphiTab
    else if actCSharpSource.Checked then
      FOutputPages.ActivePage := FCSharpTab
    else if actBSON.Checked then
      FOutputPages.ActivePage := FBsonTab
    else
      FOutputPages.ActivePage := FMinifyTab;

    if GeneratedSomething then
      SetStatus('Selected output formats generated successfully.')
    else
      SetStatus('No output format selected.');
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

  CSharpGenerator.Free;
  DelphiGenerator.Free;
end;

procedure TMainForm.actOutputToggleExecute(Sender: TObject);
begin
  if FOutputPages = nil then
    Exit;

  UpdateOutputCaption;

  FDelphiTab.TabVisible := actDelphiUnit.Checked;
  FCSharpTab.TabVisible := actCSharpSource.Checked;
  FBsonTab.TabVisible := actBSON.Checked;
  FMinifyTab.TabVisible := actMinifyJson.Checked;
end;

procedure TMainForm.actDemoDataExecute(Sender: TObject);
begin
  pnlDemoData.Visible := actDemoData.Checked;
  SplitterDemoData.Visible := actDemoData.Checked;

  if actDemoData.Checked then
    RefreshDemoData;
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

  RefreshClassVisualizer;
end;

procedure TMainForm.actSaveAsExecute(Sender: TObject);
begin
  var Extension: string;
  var Editor := CurrentOutput(Extension);
  if Editor = nil then
    Exit;

  SaveDialog.DefaultExt := Extension;
  SaveDialog.Filter := Format('%s files (*.%s)|*.%s|All files (*.*)|*.*', [UpperCase(Extension), Extension, Extension]);
  SaveDialog.FileName := Trim(edtUnitName.Text) + '.' + Extension;

  if not SaveDialog.Execute then
    Exit;

  TFile.WriteAllText(SaveDialog.FileName, Editor.Text, TEncoding.UTF8);
  SetStatus(Format('Saved %s', [ExtractFileName(SaveDialog.FileName)]));
end;

procedure TMainForm.actSettingsExecute(Sender: TObject);
begin
  if TSettingsForm.Execute(Self, FDelphiSettings, FCSharpSettings) then
  begin
    ClearOutput;
    SetStatus('Generator settings updated.');
  end;
end;

procedure TMainForm.ClearOutput;
begin
  memOutput.Clear;
  if FBsonOutput <> nil then
    FBsonOutput.Clear;

  if FMinifyOutput <> nil then
    FMinifyOutput.Clear;

  if FCSharpOutput <> nil then
    FCSharpOutput.Clear;

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
  else if FOutputPages.ActivePage = FCSharpTab then
  begin
    Result := FCSharpOutput;
    AExtension := 'cs'
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

  if actClassVisualizer.Checked then
    RefreshClassVisualizer;
end;

procedure TMainForm.HighlightCSharp;
begin
  TSyntaxRichEditRenderer.Highlight(FCSharpOutput, slCSharp);
end;

procedure TMainForm.HighlightDelphi;
begin
  TSyntaxRichEditRenderer.Highlight(memOutput, slDelphi);
end;

procedure TMainForm.UpdateOutputCaption;
begin
  if actCSharpSource.Checked and not actDelphiUnit.Checked then
    lblOutput.Caption := 'C# output'
  else if actDelphiUnit.Checked and not actCSharpSource.Checked then
    lblOutput.Caption := 'Delphi output'
  else
    lblOutput.Caption := 'Generated output';
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
  FDelphiSettings := TDelphiSettings.Create;
  FCSharpSettings := TCSharpSettings.Create;
  actOutputToggleExecute(nil);
  edtClassName.Text := 'Root';
  UpdateOutputCaption;
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

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FCSharpSettings.Free;
  FDelphiSettings.Free;
end;

procedure CenterComponent(aCenter: TControl; aCenterOver: TControl);
begin
  aCenter.Left := aCenterOver.Left + ((aCenterOver.Width - aCenter.Width) div 2);
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
  CenterComponent(lblInput, memJson);

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
  SetStatus('Input changed; generate output again.');

  if FJsonHighlighter <> nil then
    FJsonHighlighter.TextChanged;

  RefreshClassVisualizer;
end;

procedure TMainForm.RefreshDemoData;
var
  FileName: string;
  Item: TListItem;
begin
  lstDemoData.Items.BeginUpdate;
  try
    lstDemoData.Items.Clear;
    for FileName in TDemoDataRepository.FileNames do
    begin
      Item := lstDemoData.Items.Add;
      Item.Caption := FileName;
    end;
  finally
    lstDemoData.Items.EndUpdate;
  end;

  if lstDemoData.Items.Count = 0 then
  begin
    SetStatus('The Demo Data directory could not be found or contains no JSON files.');
    Exit;
  end;

  lstDemoData.Items[0].Selected := True;
  lstDemoData.Items[0].Focused := True;
end;

procedure TMainForm.lstDemoDataSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
var
  ChangeHandler: TNotifyEvent;
begin
  if not Selected or (Item = nil) then
    Exit;

  ChangeHandler := memJson.OnChange;
  memJson.OnChange := nil;
  memJson.Lines.BeginUpdate;
  try
    memJson.Text := TDemoDataRepository.Load(Item.Caption);
    if FormatJsonInput(False) then
      SetStatus(Format('Loaded demo data: %s', [Item.Caption]))
    else
      SetStatus(Format('Demo data is not valid JSON: %s', [Item.Caption]));
  finally
    memJson.Lines.EndUpdate;
    memJson.OnChange := ChangeHandler;
  end;

  ClearOutput;
  RefreshClassVisualizer;
end;

procedure TMainForm.RefreshClassVisualizer;
begin
  TJsonSourceVisualizer.Visualize(treeJson, memJson.Text);
  CenterComponent(lblStructure, treeJson);
end;

procedure TMainForm.SetStatus(const AText: string);
begin
  StatusBar.SimpleText := AText;
end;

procedure TMainForm.SplitterMoved(Sender: TObject);
begin
  CenterComponent(lblInput, memJson);
end;

end.
