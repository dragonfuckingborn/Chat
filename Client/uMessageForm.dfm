object MessageForm: TMessageForm
  Left = 0
  Top = 0
  Caption = #1063#1072#1090
  ClientHeight = 499
  ClientWidth = 778
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -24
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  OnClose = FormClose
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 144
  TextHeight = 32
  object RchEdt: TRichEdit
    AlignWithMargins = True
    Left = 12
    Top = 12
    Width = 754
    Height = 423
    Margins.Left = 12
    Margins.Top = 12
    Margins.Right = 12
    Margins.Bottom = 12
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
  end
  object Pnl: TPanel
    AlignWithMargins = True
    Left = 12
    Top = 447
    Width = 754
    Height = 40
    Margins.Left = 12
    Margins.Top = 0
    Margins.Right = 12
    Margins.Bottom = 12
    Align = alBottom
    BevelOuter = bvNone
    ShowCaption = False
    TabOrder = 1
    object EdtText: TEdit
      AlignWithMargins = True
      Left = 0
      Top = 0
      Width = 606
      Height = 40
      Margins.Left = 0
      Margins.Top = 0
      Margins.Right = 12
      Margins.Bottom = 0
      Align = alClient
      TabOrder = 0
    end
    object BtnSend: TButton
      Left = 618
      Top = 0
      Width = 136
      Height = 40
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Align = alRight
      Caption = #1054#1090#1087#1088#1072#1074#1080#1090#1100
      TabOrder = 1
      OnClick = BtnSendClick
    end
  end
  object Tmr: TTimer
    Enabled = False
    Interval = 500
    OnTimer = TmrTimer
    Left = 56
    Top = 32
  end
end
