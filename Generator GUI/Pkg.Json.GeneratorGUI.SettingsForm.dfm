object SettingsForm: TSettingsForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Generator settings'
  ClientHeight = 260
  ClientWidth = 420
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnShow = FormShow
  TextHeight = 15
  object chkUsePascalCase: TCheckBox
    Left = 20
    Top = 20
    Width = 250
    Height = 21
    Caption = 'Use PascalCase identifiers'
    TabOrder = 0
  end
  object chkAddAttributes: TCheckBox
    Left = 20
    Top = 52
    Width = 300
    Height = 21
    Caption = 'Add JSON property attributes'
    TabOrder = 1
  end
  object chkPostfixClassNames: TCheckBox
    Left = 20
    Top = 84
    Width = 250
    Height = 21
    Caption = 'Postfix generated class names'
    TabOrder = 2
    OnClick = chkPostfixClassNamesClick
  end
  object lblPostfix: TLabel
    Left = 44
    Top = 116
    Width = 38
    Height = 15
    Caption = 'Postfix'
  end
  object edtPostfix: TEdit
    Left = 44
    Top = 135
    Width = 170
    Height = 23
    TabOrder = 3
  end
  object chkSuppressZeroDate: TCheckBox
    Left = 20
    Top = 174
    Width = 300
    Height = 21
    Caption = 'Suppress zero date values'
    TabOrder = 4
  end
  object pnlButtons: TPanel
    Left = 0
    Top = 215
    Width = 420
    Height = 45
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 5
    object btnOK: TButton
      Left = 248
      Top = 8
      Width = 75
      Height = 27
      Caption = 'OK'
      Default = True
      TabOrder = 0
      OnClick = btnOKClick
    end
    object btnCancel: TButton
      Left = 329
      Top = 8
      Width = 75
      Height = 27
      Cancel = True
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 1
    end
  end
end
