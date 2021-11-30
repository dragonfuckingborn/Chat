object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = #1057#1077#1088#1074#1077#1088
  ClientHeight = 344
  ClientWidth = 578
  Color = clBtnFace
  Constraints.MinHeight = 400
  Constraints.MinWidth = 600
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -24
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  OnShow = FormShow
  PixelsPerInch = 144
  TextHeight = 32
  object LbIP: TLabel
    AlignWithMargins = True
    Left = 12
    Top = 24
    Width = 554
    Height = 38
    Margins.Left = 12
    Margins.Top = 24
    Margins.Right = 12
    Margins.Bottom = 0
    Align = alTop
    Alignment = taCenter
    Caption = 'IP'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -28
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
    ExplicitWidth = 26
  end
  object RchEdtLog: TRichEdit
    AlignWithMargins = True
    Left = 12
    Top = 86
    Width = 554
    Height = 246
    Margins.Left = 12
    Margins.Top = 24
    Margins.Right = 12
    Margins.Bottom = 12
    TabStop = False
    Align = alClient
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -24
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 0
    OnChange = RchEdtLogChange
    OnEnter = RchEdtLogChange
    OnMouseDown = RchEdtLogMouseDown
    OnMouseUp = RchEdtLogMouseDown
  end
  object IdTCPServer: TIdTCPServer
    Bindings = <>
    DefaultPort = 0
    OnExecute = IdTCPServerExecute
    Left = 40
    Top = 16
  end
end
