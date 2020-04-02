unit ufrmMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, RzButton, ExtCtrls, RzPanel, ImgList, RzEdit,
  uPos_YSL, ActnList, qjson;
  
type
  TfrmMain = class(TForm)
    imgl_1: TImageList;
    mmo_Log: TRzMemo;
    actlst1: TActionList;
    act_Open: TAction;
    act_Read: TAction;
    act_Consume: TAction;
    act_Close: TAction;
    Panel1: TPanel;
    btn_Set: TRzBitBtn;
    btn_Close: TRzBitBtn;
    btn_Consume: TRzBitBtn;
    btn_ReadCard: TRzBitBtn;
    grp1: TGroupBox;
    lbl_1: TLabel;
    cbb_Com: TComboBox;
    grp4: TGroupBox;
    Label9: TLabel;
    Label10: TLabel;
    Edit8: TEdit;
    Edit9: TEdit;
    Panel2: TPanel;
    grp5: TGroupBox;
    Label13: TLabel;
    Label16: TLabel;
    Edit13: TEdit;
    Edit16: TEdit;
    RzBitBtn1: TRzBitBtn;
    act_Query: TAction;
    procedure edtM1KeyKeyPress(Sender: TObject; var Key: Char);
    procedure act_OpenExecute(Sender: TObject);
    procedure act_ConsumeExecute(Sender: TObject);
    procedure act_CloseExecute(Sender: TObject);
    procedure btn_ReadCardClick(Sender: TObject);
    procedure act_QueryExecute(Sender: TObject);
  private
    { Private declarations }
    function AddLog(AStr : string):boolean;
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;
  reader: TYSLPos;

implementation

{$R *.dfm}

procedure TfrmMain.act_CloseExecute(Sender: TObject);
begin
  FreeAndNil(reader);
end;

procedure TfrmMain.act_ConsumeExecute(Sender: TObject);
var
  iResult: Integer;
  iFlow: Word;
  cPay, Balance: Currency;
  sErr, cCard: string;
begin
  cCard:= Trim(Edit13.Text);
  iFlow:= StrToInt(Edit9.Text);
  cPay := StrToCurr(Edit8.Text);
  iResult:= reader.Consume(cCard, cPay, iFlow, Balance, sErr);
  if iResult= 0 then
  begin
    Edit16.Text:= Format('%.2f', [balance]);
    AddLog('扣款 - 成功');
  end
  else
    AddLog('扣款 - 失败');
end;

procedure TfrmMain.act_OpenExecute(Sender: TObject);
begin
  reader:= TYSLPos.Create(cbb_Com.ItemIndex+ 1);
end;

procedure TfrmMain.act_QueryExecute(Sender: TObject);
var
  iResult: Integer;
  iFlow: Word;
  cCard, cPay, Balance: Cardinal;
  sErr: string;
begin
//  cCard:= StrToInt(Edit13.Text);
//  iFlow:= StrToInt(Edit9.Text);
//  cPay := StrToInt(Edit8.Text);
//  iResult:= reader.Query(cCard, cPay, iFlow, Balance, sErr);
//  if iResult= 0 then
//  begin
//    Edit16.Text:= Format('%d', [balance]);
//    AddLog('扣款 - 成功');
//  end
//  else
//    AddLog('扣款 - 失败');
end;

procedure TfrmMain.edtM1KeyKeyPress(Sender: TObject; var Key: Char);
begin
  if Not (key in ['0'..'9', #8, 'a'..'f', 'A'..'F']) then
    key := #0
  else if key in ['a'..'f'] then
    key := Char(Ord(key) - 32);
end;

function TfrmMain.AddLog(AStr : string):boolean;
var
  sTmpLog : string;
begin
  mmo_Log.Lines.BeginUpdate;
  try
    if mmo_Log.Lines.Count > 300 then
      mmo_Log.Lines.Clear;
    sTmpLog := format('%s - %s', [formatdatetime('hh:nn:ss.zzz',Now), AStr]);
    mmo_Log.Lines.Insert(0, sTmpLog);
  finally
    mmo_Log.Lines.EndUpdate;
  end;
end;

procedure TfrmMain.btn_ReadCardClick(Sender: TObject);
var
  iResult : Integer;
  Balance: Currency;
  cCard, sErr: string;
begin
  iResult := reader.ReadCard(cCard, Balance, sErr);
  if iResult= 0 then
  begin
    Edit13.Text:= cCard;
    Edit16.Text:= CurrToStr(Balance);
  end
  else
    AddLog('读取个人信息 - 失败');
end;

end.
