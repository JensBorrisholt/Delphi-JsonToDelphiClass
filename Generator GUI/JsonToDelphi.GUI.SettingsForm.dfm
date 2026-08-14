object SettingsForm: TSettingsForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Generator settings'
  ClientHeight = 390
  ClientWidth = 460
  Position = poOwnerFormCenter
  object FPages: TPageControl
    Left = 0
    Top = 0
    Width = 460
    Height = 345
    ActivePage = FDelphiTab
    Align = alClient
    TabOrder = 0
    object FDelphiTab: TTabSheet
      Caption = 'Delphi'
      object FDelphiUsePascalCase: TCheckBox
        Left = 20
        Top = 20
        Width = 300
        Height = 17
        Caption = 'Use PascalCase identifiers'
        TabOrder = 0
      end
      object FDelphiAddAttributes: TCheckBox
        Left = 20
        Top = 52
        Width = 350
        Height = 17
        Caption = 'Add JSON property attributes'
        TabOrder = 1
      end
      object FDelphiPostfixClassNames: TCheckBox
        Left = 20
        Top = 84
        Width = 300
        Height = 17
        Caption = 'Postfix generated class names'
        TabOrder = 2
        OnClick = DelphiPostfixClassNamesClick
      end
      object FDelphiPostfixLabel: TLabel
        Left = 44
        Top = 116
        Width = 38
        Height = 15
        Caption = 'Postfix'
      end
      object FDelphiPostfix: TEdit
        Left = 44
        Top = 135
        Width = 170
        Height = 23
        TabOrder = 3
      end
      object FDelphiSuppressZeroDate: TCheckBox
        Left = 20
        Top = 174
        Width = 350
        Height = 17
        Caption = 'Suppress zero date values'
        TabOrder = 4
      end
    end
    object FCSharpTab: TTabSheet
      Caption = 'C#'
      ImageIndex = 1
      object FCSharpNamespaceLabel: TLabel
        Left = 20
        Top = 20
        Width = 63
        Height = 15
        Caption = 'Namespace'
      end
      object FCSharpNamespace: TEdit
        Left = 20
        Top = 39
        Width = 300
        Height = 23
        TabOrder = 0
      end
      object FCSharpUsePascalCase: TCheckBox
        Left = 20
        Top = 78
        Width = 350
        Height = 17
        Caption = 'Use PascalCase identifiers'
        TabOrder = 1
      end
      object FCSharpNullableTypes: TCheckBox
        Left = 20
        Top = 110
        Width = 350
        Height = 17
        Caption = 'Use nullable primitive types'
        TabOrder = 2
      end
      object FCSharpAddAttributes: TCheckBox
        Left = 20
        Top = 142
        Width = 350
        Height = 17
        Caption = 'Add JsonPropertyName attributes'
        TabOrder = 3
      end
      object FCSharpUseRecords: TCheckBox
        Left = 20
        Top = 174
        Width = 350
        Height = 17
        Caption = 'Generate records'
        TabOrder = 4
      end
      object FCSharpImmutable: TCheckBox
        Left = 20
        Top = 206
        Width = 350
        Height = 17
        Caption = 'Generate init-only properties'
        TabOrder = 5
      end
      object FCSharpReadonlyLists: TCheckBox
        Left = 20
        Top = 238
        Width = 350
        Height = 17
        Caption = 'Use IReadOnlyList for arrays'
        TabOrder = 6
      end
    end
  end
  object FButtonPanel: TPanel
    Left = 0
    Top = 345
    Width = 460
    Height = 45
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object FOKButton: TButton
      Left = 288
      Top = 8
      Width = 75
      Height = 27
      Caption = 'OK'
      Default = True
      ModalResult = 1
      TabOrder = 0
    end
    object FCancelButton: TButton
      Left = 369
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
