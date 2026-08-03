object UpdateForm: TUpdateForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Update available'
  ClientHeight = 420
  ClientWidth = 620
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnShow = FormShow
  TextHeight = 15
  object lblVersion: TLabel
    Left = 16
    Top = 16
    Width = 150
    Height = 20
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Segoe UI Semibold'
    Font.Style = []
    ParentFont = False
  end
  object memReleaseNotes: TMemo
    Left = 16
    Top = 48
    Width = 588
    Height = 316
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object pnlButtons: TPanel
    Left = 0
    Top = 375
    Width = 620
    Height = 45
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnOpenRelease: TButton
      Left = 386
      Top = 8
      Width = 120
      Height = 27
      Caption = 'Open on GitHub'
      TabOrder = 0
      OnClick = btnOpenReleaseClick
    end
    object btnClose: TButton
      Left = 512
      Top = 8
      Width = 92
      Height = 27
      Cancel = True
      Caption = 'Close'
      ModalResult = 2
      TabOrder = 1
    end
  end
end
