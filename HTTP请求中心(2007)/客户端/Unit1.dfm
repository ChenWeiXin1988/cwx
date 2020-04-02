object Form21: TForm21
  Left = 0
  Top = 0
  BorderStyle = bsToolWindow
  Caption = #27979#35797'Demo'
  ClientHeight = 405
  ClientWidth = 691
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object btnHeart: TButton
    Left = 144
    Top = 16
    Width = 161
    Height = 65
    Caption = #24515#36339#27979#35797
    TabOrder = 0
    OnClick = btnHeartClick
  end
  object btnServerTime: TButton
    Left = 384
    Top = 16
    Width = 161
    Height = 65
    Caption = #33719#21462#26381#21153#26102#38388
    TabOrder = 1
  end
  object Memo1: TMemo
    Left = 40
    Top = 88
    Width = 601
    Height = 305
    TabOrder = 2
  end
end
