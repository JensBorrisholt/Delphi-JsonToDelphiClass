object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'JSON to Delphi Class'
  ClientHeight = 720
  ClientWidth = 1120
  Color = clBtnFace
  Constraints.MinHeight = 560
  Constraints.MinWidth = 800
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Menu = MainMenu
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object pnlNames: TPanel
    Left = 0
    Top = 0
    Width = 1120
    Height = 57
    Align = alTop
    BevelOuter = bvNone
    Padding.Left = 12
    Padding.Top = 8
    Padding.Right = 12
    Padding.Bottom = 8
    TabOrder = 0
    object lblClassName: TLabel
      Left = 12
      Top = 11
      Width = 86
      Height = 15
      Caption = 'Root class name'
    end
    object lblUnitName: TLabel
      Left = 238
      Top = 11
      Width = 55
      Height = 15
      Caption = 'Unit name'
    end
    object edtClassName: TEdit
      Left = 12
      Top = 28
      Width = 210
      Height = 23
      TabOrder = 0
      OnChange = edtClassNameChange
    end
    object edtUnitName: TEdit
      Left = 238
      Top = 28
      Width = 250
      Height = 23
      TabOrder = 1
    end
    object btnConvert: TButton
      Left = 504
      Top = 22
      Width = 130
      Height = 29
      Action = actConvert
      Default = True
      TabOrder = 2
    end
    object btnFormatJson: TButton
      Left = 650
      Top = 22
      Width = 110
      Height = 29
      Action = actFormatJson
      TabOrder = 3
    end
  end
  object pnlWorkspace: TPanel
    Left = 0
    Top = 57
    Width = 1120
    Height = 614
    Align = alClient
    BevelOuter = bvNone
    Padding.Left = 12
    Padding.Top = 24
    Padding.Right = 12
    Padding.Bottom = 8
    TabOrder = 1
    ExplicitHeight = 640
    object lblInput: TLabel
      Left = 300
      Top = 5
      Width = 59
      Height = 15
      Caption = 'JSON input'
    end
    object lblOutput: TLabel
      Left = 708
      Top = 5
      Width = 73
      Height = 15
      Caption = 'Delphi output'
    end
    object lblStructure: TLabel
      Left = 12
      Top = 5
      Width = 78
      Height = 15
      Caption = 'JSON structure'
      Visible = False
    end
    object Splitter: TSplitter
      Left = 700
      Top = 24
      Width = 8
      Height = 582
      Beveled = True
      ExplicitLeft = 557
      ExplicitHeight = 608
    end
    object SplitterTree: TSplitter
      Left = 292
      Top = 24
      Width = 8
      Height = 582
      Beveled = True
      ExplicitHeight = 608
      Visible = False
    end
    object memJson: TRichEdit
      Left = 300
      Top = 24
      Width = 400
      Height = 582
      Align = alLeft
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Consolas'
      Font.Style = []
      ParentFont = False
      ScrollBars = ssBoth
      TabOrder = 0
      WantTabs = True
      WordWrap = False
      OnChange = memJsonChange
    end
    object treeJson: TTreeView
      Left = 12
      Top = 24
      Width = 280
      Height = 582
      Align = alLeft
      Indent = 19
      ReadOnly = True
      TabOrder = 1
      Visible = False
    end
    object memOutput: TRichEdit
      Left = 708
      Top = 24
      Width = 400
      Height = 582
      Align = alClient
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Consolas'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssBoth
      TabOrder = 2
      WantTabs = True
      WordWrap = False
    end
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 697
    Width = 1120
    Height = 23
    Panels = <>
    SimplePanel = True
  end
  object pnlGitHub: TPanel
    Left = 0
    Top = 671
    Width = 1120
    Height = 26
    Align = alBottom
    BevelOuter = bvNone
    Padding.Left = 12
    TabOrder = 3
    object lblGitHub: TLabel
      Left = 12
      Top = 0
      Width = 38
      Height = 15
      Cursor = crHandPoint
      Align = alClient
      Caption = 'GitHub'
      Layout = tlCenter
      OnClick = lblGitHubClick
    end
  end
  object MainMenu: TMainMenu
    Left = 704
    Top = 8
    object miFile: TMenuItem
      Caption = '&File'
      object miOpen: TMenuItem
        Action = actOpen
      end
      object miSaveAs: TMenuItem
        Action = actSaveAs
      end
      object miExit: TMenuItem
        Action = actExit
      end
    end
    object miOptions: TMenuItem
      Caption = '&Options'
      object miFormatJson: TMenuItem
        Action = actFormatJson
      end
      object miSettings: TMenuItem
        Action = actSettings
      end
    end
    object miView: TMenuItem
      Caption = '&View'
      object miVisualizer: TMenuItem
        Action = actClassVisualizer
        AutoCheck = True
      end
    end
    object miConvert: TMenuItem
      Caption = '&Convert'
      object miDelphiUnit: TMenuItem
        Action = actDelphiUnit
      end
      object miBSON: TMenuItem
        Action = actBSON
      end
      object miMinifyJson: TMenuItem
        Action = actMinifyJson
      end
      object miDemoProject: TMenuItem
        Action = actDemoProject
      end
    end
  end
  object ActionList: TActionList
    OnUpdate = ActionListUpdate
    Left = 744
    Top = 8
    object actOpen: TAction
      Caption = '&Open JSON...'
      ShortCut = 16463
      OnExecute = actOpenExecute
    end
    object actSaveAs: TAction
      Caption = '&Save Delphi unit as...'
      ShortCut = 16467
      OnExecute = actSaveAsExecute
    end
    object actExit: TAction
      Caption = 'E&xit'
      OnExecute = actExitExecute
    end
    object actSettings: TAction
      Caption = '&Generator settings...'
      OnExecute = actSettingsExecute
    end
    object actConvert: TAction
      Caption = '&Generate unit'
      ShortCut = 16500
      OnExecute = actConvertExecute
    end
    object actFormatJson: TAction
      Caption = '&Format JSON'
      ShortCut = 24646
      OnExecute = actFormatJsonExecute
    end
    object actClassVisualizer: TAction
      AutoCheck = True
      Caption = 'Class &Visualizer'
      OnExecute = actClassVisualizerExecute
    end
    object actDelphiUnit: TAction
      AutoCheck = True
      Caption = 'Delphi Unit'
      Checked = True
      OnExecute = actOutputToggleExecute
    end
    object actBSON: TAction
      AutoCheck = True
      Caption = 'BSON'
      OnExecute = actOutputToggleExecute
    end
    object actMinifyJson: TAction
      AutoCheck = True
      Caption = 'Minify JSON'
      OnExecute = actOutputToggleExecute
    end
    object actDemoProject: TAction
      AutoCheck = True
      Caption = 'Demo project'
      OnExecute = actOutputToggleExecute
    end
  end
  object OpenDialog: TOpenDialog
    DefaultExt = 'json'
    Filter = 'JSON files (*.json)|*.json|All files (*.*)|*.*'
    Options = [ofHideReadOnly, ofFileMustExist, ofEnableSizing]
    Left = 784
    Top = 8
  end
  object SaveDialog: TSaveDialog
    DefaultExt = 'pas'
    Filter = 'Delphi units (*.pas)|*.pas|All files (*.*)|*.*'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing]
    Left = 824
    Top = 8
  end
end
