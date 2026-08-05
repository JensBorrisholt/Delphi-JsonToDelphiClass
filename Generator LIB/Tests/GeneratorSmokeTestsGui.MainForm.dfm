object SmokeTestsForm: TSmokeTestsForm
  Left = 0
  Top = 0
  Caption = 'Generator Smoke Tests'
  ClientHeight = 520
  ClientWidth = 980
  Position = poScreenCenter
  OnShow = FormShow
  TextHeight = 15
  object TestList: TListView
    Left = 0
    Top = 0
    Width = 980
    Height = 472
    Align = alClient
    Columns = <
      item
        Caption = 'Test'
        Width = 330
      end
      item
        Caption = 'Status'
        Width = 90
      end
      item
        Alignment = taRightJustify
        Caption = 'Duration'
        Width = 100
      end
      item
        Caption = 'Details'
        Width = 420
      end>
    ReadOnly = True
    RowSelect = True
    TabOrder = 0
    ViewStyle = vsReport
  end
  object BottomPanel: TPanel
    Left = 0
    Top = 472
    Width = 980
    Height = 48
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object SummaryLabel: TLabel
      Left = 16
      Top = 17
      Width = 81
      Height = 15
      Caption = 'Ikke kørt endnu'
    end
    object RunButton: TButton
      Left = 864
      Top = 10
      Width = 100
      Height = 29
      Anchors = [akTop, akRight]
      Caption = 'Run Tests'
      TabOrder = 0
      OnClick = RunButtonClick
    end
  end
end
