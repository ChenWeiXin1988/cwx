unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, CPort, Math, UBuffer, qjson;

const
  GBufsize     = 64;

type
  TTwoByteRec = packed record
    case integer of
      0: (Data: Integer);
      1: (Data2: byte;
          Data1: byte; );
  end;

  TFourByteRec = packed record
    case integer of
      0: (Data: Cardinal);
      1: (Data4: byte;
          Data3: byte;
          Data2: byte;
          Data1: byte; );
      2:(DataAry:array[0..3] of byte;);
  end;

  TbufferRec = array[0..GBufsize] of byte;   //64为串口号
  pbufferRec = ^TbufferRec;

  TFrmMain = class(TForm)
    btn6: TButton;
    btn7: TButton;
    btn8: TButton;
    btn9: TButton;
    btn10: TButton;
    mmo1: TMemo;
    btn2: TButton;
    btn3: TButton;
    cbb_COMS: TComboBox;
    btn4: TButton;
    btn1: TButton;
    procedure btn1Click(Sender: TObject);
    procedure btn2Click(Sender: TObject);
    procedure btn3Click(Sender: TObject);
    procedure btn4Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btn9Click(Sender: TObject);
    procedure btn8Click(Sender: TObject);
    procedure btn5Click(Sender: TObject);
    procedure btn6Click(Sender: TObject);
    procedure btn7Click(Sender: TObject);
    procedure btn10Click(Sender: TObject);
    procedure mmo1Change(Sender: TObject);
  private
    Com: TComPort;
    FtmpRbuf, FRbuf, FLastBuf: TbufferRec;
    FMRBuffer:TMRingBuffer;                          //环形缓冲区
  public
    Sno: Integer;
    Cmd: Integer;
    function SenData(const ABuffer:TbufferRec; ALen : Byte):Boolean;
    function BytesToHex(AIn: TbufferRec; Len: Integer): string;

    function CheckSum(ABuff:TbufferRec; iBeg, iEnd: Integer): Byte;//获取校验和 低位优先
  end;

var
  FrmMain: TFrmMain;

implementation
uses uCRC16;

{$R *.dfm}

procedure TFrmMain.btn10Click(Sender: TObject);
var
  fbuffer : TbufferRec;
  iLen : Integer;
  fCrc    : TTwoByteRec;
  fBytes : TBytes;
begin
  iLen := 27;
  setlength(fBytes, iLen);
  FillChar(fbuffer, SizeOf(fbuffer), 0);
  //固定包头
  fbuffer[0] := $5A;
  fbuffer[1] := $3C;
  //长度 BCD码
  fbuffer[2] := $16;
  //命令码
  fbuffer[3] := $03;
  //结果
  fbuffer[4] := $00;
  //保留
  fbuffer[5] := $00;
  //卡号
  fbuffer[6] := $00;
  fbuffer[7] := $00;
  fbuffer[8] := $00;
  fbuffer[9] := $00;
  fbuffer[10] := $00;
  fbuffer[11] := $00;
  fbuffer[12] := $00;
  fbuffer[13] := $12;
  fbuffer[14] := $34;
  fbuffer[15] := $56;
  fbuffer[16] := $78;
  //余额
  fbuffer[17] := $12;
  fbuffer[18] := $34;
  fbuffer[19] := $00;
  fbuffer[20] := $00;
  //消费金额
  fbuffer[21] := $12;
  fbuffer[22] := $34;
  fbuffer[23] := $00;
  fbuffer[24] := $00;
  //校验码
  fbuffer[25]:= CheckSum(fbuffer, 3, 22);
  //尾标
  fbuffer[26] := $DB;
  try
    try
      mmo1.Lines.Add('发送: '+ BytesToHex(fbuffer, iLen));
      if not SenData(fbuffer, iLen) then Exit;
    except
      //
    end;
  finally
    //;
  end;
end;

procedure TFrmMain.btn1Click(Sender: TObject);
var
  fbuffer : TbufferRec;
  iLen : Integer;
  fCrc    : TTwoByteRec;
  fBytes : TBytes;
begin
  iLen := 27;
  setlength(fBytes, iLen);
  FillChar(fbuffer, SizeOf(fbuffer), 0);
  //固定包头
  fbuffer[0] := $5A;
  fbuffer[1] := $3C;
  //长度 BCD码
  fbuffer[2] := $16;
  //命令码
  fbuffer[3] := $01;
  //结果
  fbuffer[4] := $05;
  //保留
  fbuffer[5] := $00;
  //卡号
  fbuffer[6] := $00;
  fbuffer[7] := $00;
  fbuffer[8] := $00;
  fbuffer[9] := $00;
  fbuffer[10] := $00;
  fbuffer[11] := $00;
  fbuffer[12] := $00;
  fbuffer[13] := $12;
  fbuffer[14] := $34;
  fbuffer[15] := $56;
  fbuffer[16] := $78;
  //余额
  fbuffer[17] := $12;
  fbuffer[18] := $34;
  fbuffer[19] := $00;
  fbuffer[20] := $00;
  //无意义
  fbuffer[21] := $00;
  fbuffer[22] := $00;
  fbuffer[23] := $00;
  fbuffer[24] := $00;
  //校验码
  fbuffer[25]:= CheckSum(fbuffer, 3, 22);
  //尾标
  fbuffer[26] := $DB;
  try
    try
      mmo1.Lines.Add('发送: '+ BytesToHex(fbuffer, iLen+ 2));
      if not SenData(fbuffer, iLen+ 2) then Exit;
    except
      //
    end;
  finally
    //;
  end;
end;

procedure TFrmMain.btn2Click(Sender: TObject);
var
  fbuffer : TbufferRec;
  iLen : Integer;
  fCrc    : TTwoByteRec;
  fBytes : TBytes;
begin
  iLen := 27;
  setlength(fBytes, iLen);
  FillChar(fbuffer, SizeOf(fbuffer), 0);
  //固定包头
  fbuffer[0] := $5A;
  fbuffer[1] := $3C;
  //长度 BCD码
  fbuffer[2] := $16;
  //命令码
  fbuffer[3] := $02;
  //结果
  fbuffer[4] := $06;
  //保留
  fbuffer[5] := $00;
  //卡号
  fbuffer[6] := $00;
  fbuffer[7] := $00;
  fbuffer[8] := $00;
  fbuffer[9] := $00;
  fbuffer[10] := $00;
  fbuffer[11] := $00;
  fbuffer[12] := $00;
  fbuffer[13] := $12;
  fbuffer[14] := $34;
  fbuffer[15] := $56;
  fbuffer[16] := $78;
  //余额
  fbuffer[17] := $12;
  fbuffer[18] := $34;
  fbuffer[19] := $00;
  fbuffer[20] := $00;
  //消费金额
  fbuffer[21] := $12;
  fbuffer[22] := $34;
  fbuffer[23] := $00;
  fbuffer[24] := $00;
  //校验码
  fbuffer[25]:= CheckSum(fbuffer, 3, 22);
  //尾标
  fbuffer[26] := $DB;
  try
    try
      mmo1.Lines.Add('发送: '+ BytesToHex(fbuffer, iLen));
      if not SenData(fbuffer, iLen) then Exit;
    except
      //
    end;
  finally
    //;
  end;
end;

procedure TFrmMain.btn3Click(Sender: TObject);
var
  fbuffer : TbufferRec;
  iLen : Integer;
  fCrc    : TTwoByteRec;
  fBytes : TBytes;
begin
  iLen := 27;
  setlength(fBytes, iLen);
  FillChar(fbuffer, SizeOf(fbuffer), 0);
  //固定包头
  fbuffer[0] := $5A;
  fbuffer[1] := $3C;
  //长度 BCD码
  fbuffer[2] := $16;
  //命令码
  fbuffer[3] := $03;
  //结果
  fbuffer[4] := $01;
  //保留
  fbuffer[5] := $00;
  //卡号
  fbuffer[6] := $00;
  fbuffer[7] := $00;
  fbuffer[8] := $00;
  fbuffer[9] := $00;
  fbuffer[10] := $00;
  fbuffer[11] := $00;
  fbuffer[12] := $00;
  fbuffer[13] := $12;
  fbuffer[14] := $34;
  fbuffer[15] := $56;
  fbuffer[16] := $78;
  //余额
  fbuffer[17] := $12;
  fbuffer[18] := $34;
  fbuffer[19] := $00;
  fbuffer[20] := $00;
  //消费金额
  fbuffer[21] := $12;
  fbuffer[22] := $34;
  fbuffer[23] := $00;
  fbuffer[24] := $00;
  //校验码
  fbuffer[25]:= CheckSum(fbuffer, 3, 22);
  //尾标
  fbuffer[26] := $DB;
  try
    try
      mmo1.Lines.Add('发送: '+ BytesToHex(fbuffer, iLen));
      if not SenData(fbuffer, iLen) then Exit;
    except
      //
    end;
  finally
    //;
  end;
end;

procedure TFrmMain.btn4Click(Sender: TObject);
var
  fbuffer : TbufferRec;
  iLen : Integer;
  fCrc    : TTwoByteRec;
  fBytes : TBytes;
begin
  iLen := 8;            //需要进行CRC16处理的长度
  setlength(fBytes, iLen);
  FillChar(fbuffer, SizeOf(fbuffer), 0);
  //固定包头
  fbuffer[0] := $EE;
  //长度 BCD码
  fbuffer[1] := $08;
  //通讯序号
  fbuffer[2] := Sno;
  //命令码
  fbuffer[3] := Cmd;
  //版本
  fbuffer[4] := $00;
  fbuffer[5] := $01;
  //响应代码
  fbuffer[6] := $90;
  fbuffer[7] := $00;
  //CRC
  move(fbuffer[0], fBytes[0], iLen);
  fCrc.Data := CRC(fBytes);
  fbuffer[8] := fCrc.Data1; //CRC1
  fbuffer[9] := fCrc.Data2; //CRC2
  //
  try
    try
      mmo1.Lines.Add('发送: '+ BytesToHex(fbuffer, iLen+ 2));
      if not SenData(fbuffer, iLen+ 2) then Exit;
    except
      //
    end;
  finally
    //;
  end;
end;

procedure TFrmMain.btn5Click(Sender: TObject);
var
  fbuffer : TbufferRec;
  iLen : Integer;
  fCrc    : TFourByteRec;
  fBytes : TBytes;
begin
  iLen := 4;            //需要进行CRC16处理的长度
  setlength(fBytes, iLen);
  FillChar(fbuffer, SizeOf(fbuffer), 0);
  fCrc.Data := 183354;
  fbuffer[0] := fCrc.Data1; //CRC1
  fbuffer[1] := fCrc.Data2; //CRC2
  fbuffer[2] := fCrc.Data3; //CRC1
  fbuffer[3] := fCrc.Data4; //CRC2
  //
  try
    try
      mmo1.Lines.Add('发送: '+ BytesToHex(fbuffer, iLen+ 2));
      if not SenData(fbuffer, iLen+ 2) then Exit;
    except
      //
    end;
  finally
    //;
  end;
end;

procedure TFrmMain.btn6Click(Sender: TObject);
var
  fbuffer : TbufferRec;
  iLen : Integer;
  fCrc    : TTwoByteRec;
  fBytes : TBytes;
begin
  iLen := 27;
  setlength(fBytes, iLen);
  FillChar(fbuffer, SizeOf(fbuffer), 0);
  //固定包头
  fbuffer[0] := $5A;
  fbuffer[1] := $3C;
  //长度 BCD码
  fbuffer[2] := $16;
  //命令码
  fbuffer[3] := $01;
  //结果
  fbuffer[4] := $00;
  //保留
  fbuffer[5] := $00;
  //卡号
  fbuffer[6] := $00;
  fbuffer[7] := $00;
  fbuffer[8] := $00;
  fbuffer[9] := $00;
  fbuffer[10] := $00;
  fbuffer[11] := $00;
  fbuffer[12] := $00;
  fbuffer[13] := $12;
  fbuffer[14] := $34;
  fbuffer[15] := $56;
  fbuffer[16] := $78;
  //余额
  fbuffer[17] := $12;
  fbuffer[18] := $34;
  fbuffer[19] := $00;
  fbuffer[20] := $00;
  //无意义
  fbuffer[21] := $00;
  fbuffer[22] := $00;
  fbuffer[23] := $00;
  fbuffer[24] := $00;
  //校验码
  fbuffer[25]:= CheckSum(fbuffer, 3, 22);
  //尾标
  fbuffer[26] := $DB;
  try
    try
      mmo1.Lines.Add('发送: '+ BytesToHex(fbuffer, iLen));
      if not SenData(fbuffer, iLen) then Exit;
    except
      //
    end;
  finally
    //;
  end;
end;

procedure TFrmMain.btn7Click(Sender: TObject);
var
  fbuffer : TbufferRec;
  iLen : Integer;
  fCrc    : TTwoByteRec;
  fBytes : TBytes;
begin
  iLen := 27;
  setlength(fBytes, iLen);
  FillChar(fbuffer, SizeOf(fbuffer), 0);
  //固定包头
  fbuffer[0] := $5A;
  fbuffer[1] := $3C;
  //长度 BCD码
  fbuffer[2] := $16;
  //命令码
  fbuffer[3] := $02;
  //结果
  fbuffer[4] := $00;
  //保留
  fbuffer[5] := $00;
  //卡号
  fbuffer[6] := $00;
  fbuffer[7] := $00;
  fbuffer[8] := $00;
  fbuffer[9] := $00;
  fbuffer[10] := $00;
  fbuffer[11] := $00;
  fbuffer[12] := $00;
  fbuffer[13] := $12;
  fbuffer[14] := $34;
  fbuffer[15] := $56;
  fbuffer[16] := $78;
  //余额
  fbuffer[17] := $12;
  fbuffer[18] := $34;
  fbuffer[19] := $00;
  fbuffer[20] := $00;
  //消费金额
  fbuffer[21] := $12;
  fbuffer[22] := $34;
  fbuffer[23] := $00;
  fbuffer[24] := $00;
  //校验码
  fbuffer[25]:= CheckSum(fbuffer, 3, 22);
  //尾标
  fbuffer[26] := $DB;
  try
    try
      mmo1.Lines.Add('发送: '+ BytesToHex(fbuffer, iLen));
      if not SenData(fbuffer, iLen) then Exit;
    except
      //
    end;
  finally
    //;
  end;
end;

procedure TFrmMain.btn8Click(Sender: TObject);
begin
  if Com.Connected then
    Com.Close;
end;

procedure TFrmMain.btn9Click(Sender: TObject);
begin
  if not Com.Connected then
  begin
    Com.Port:= 'COM2';
    Com.BaudRate := br9600;
    Com.Open;
  end;
end;

function TFrmMain.BytesToHex(AIn: TbufferRec; Len: Integer): string;
var
  i: integer;
begin
  Result := '';
  for I := 0 to Len- 1 do
  begin
    Result := Result + format('%s ', [IntToHex(AIn[I], 2)]);
  end;
end;

function TFrmMain.CheckSum(ABuff: TbufferRec; iBeg, iEnd: Integer): Byte;
var
  i, sum: Integer;
begin
  Result:= 0;
  sum:= 0;
  for I := iBeg to iEnd do
    sum:= sum+ ABuff[i];
  sum:= sum mod 256;
  Result:= sum;
end;

procedure TFrmMain.FormCreate(Sender: TObject);
begin
  Com := TComPort.Create(nil);
  Com.SyncMethod := smNone;
  Com.BaudRate := br9600;
  Com.EventThreadPriority := tpHigher;
  Com.Buffer.InputSize := 4096;
  Com.Buffer.OutputSize := 1024;
  Sno:= -1;
end;

procedure TFrmMain.mmo1Change(Sender: TObject);
begin
  if mmo1.Lines.Count> 100 then
    mmo1.Lines.Clear;
end;

function TFrmMain.SenData(const ABuffer: TbufferRec; ALen: Byte): Boolean;
var
  sSend : string;
  I, iRes : Integer;
begin
  Result := False;
  if ALen <= 0 then Exit;
  if Com = nil then Exit;
  if not Com.Connected then Exit;
  try
    iRes := Com.Write(ABuffer, ALen);
    Result := True;
  finally
  end;
end;

end.
