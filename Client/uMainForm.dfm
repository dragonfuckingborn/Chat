object MainForm: TMainForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = #1050#1083#1080#1077#1085#1090
  ClientHeight = 313
  ClientWidth = 518
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -24
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  OnClose = FormClose
  OnShow = FormShow
  PixelsPerInch = 144
  TextHeight = 32
  object LbIP: TLabel
    AlignWithMargins = True
    Left = 24
    Top = 24
    Width = 470
    Height = 32
    Margins.Left = 24
    Margins.Top = 24
    Margins.Right = 24
    Margins.Bottom = 0
    Align = alTop
    Caption = #1042#1074#1077#1076#1080#1090#1077' IP '#1072#1076#1088#1077#1089' '#1089#1077#1088#1074#1077#1088#1072':'
    ExplicitWidth = 288
  end
  object LbName: TLabel
    AlignWithMargins = True
    Left = 24
    Top = 132
    Width = 470
    Height = 32
    Margins.Left = 24
    Margins.Top = 24
    Margins.Right = 24
    Margins.Bottom = 0
    Align = alTop
    Caption = #1042#1074#1077#1076#1080#1090#1077' '#1089#1074#1086#1077' '#1080#1084#1103':'
    ExplicitWidth = 203
  end
  object EdtIP: TEdit
    AlignWithMargins = True
    Left = 24
    Top = 68
    Width = 470
    Height = 40
    Margins.Left = 24
    Margins.Top = 12
    Margins.Right = 24
    Margins.Bottom = 0
    Align = alTop
    TabOrder = 0
  end
  object EdtName: TEdit
    AlignWithMargins = True
    Left = 24
    Top = 176
    Width = 470
    Height = 40
    Margins.Left = 24
    Margins.Top = 12
    Margins.Right = 24
    Margins.Bottom = 0
    Align = alTop
    TabOrder = 1
  end
  object BtnConnect: TButton
    Left = 294
    Top = 240
    Width = 200
    Height = 50
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Caption = #1055#1086#1076#1082#1083#1102#1095#1080#1090#1100#1089#1103
    Default = True
    TabOrder = 2
    OnClick = BtnConnectClick
  end
  object IdTCPClient: TIdTCPClient
    ConnectTimeout = 0
    Port = 0
    ReadTimeout = -1
    Left = 11
    Top = 16
  end
end
