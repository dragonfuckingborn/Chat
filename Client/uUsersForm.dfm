object UsersForm: TUsersForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = #1057#1087#1080#1089#1086#1082' '#1087#1086#1083#1100#1079#1086#1074#1072#1090#1077#1083#1077#1081
  ClientHeight = 567
  ClientWidth = 469
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
  object LbUsers: TLabel
    AlignWithMargins = True
    Left = 24
    Top = 24
    Width = 421
    Height = 32
    Margins.Left = 24
    Margins.Top = 24
    Margins.Right = 24
    Margins.Bottom = 0
    Align = alTop
    Caption = #1042#1099#1073#1077#1088#1080#1090#1077' '#1087#1086#1083#1100#1079#1086#1074#1072#1090#1077#1083#1103':'
    ExplicitWidth = 272
  end
  object ListBox: TListBox
    AlignWithMargins = True
    Left = 24
    Top = 68
    Width = 421
    Height = 405
    Margins.Left = 24
    Margins.Top = 12
    Margins.Right = 24
    Margins.Bottom = 0
    Align = alTop
    ItemHeight = 32
    TabOrder = 0
  end
  object BtnOK: TButton
    Left = 295
    Top = 497
    Width = 150
    Height = 50
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Caption = #1054#1050
    Default = True
    TabOrder = 1
    OnClick = BtnOKClick
  end
  object BtnRefresh: TButton
    Left = 112
    Top = 497
    Width = 150
    Height = 50
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Caption = #1054#1073#1085#1086#1074#1080#1090#1100
    TabOrder = 2
    OnClick = BtnRefreshClick
  end
end
