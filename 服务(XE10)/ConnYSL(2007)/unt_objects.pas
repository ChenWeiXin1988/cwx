unit unt_objects;

interface

uses
  Windows, CPort, UBuffer, SysUtils, Classes, Math, qjson;

const
  GBufsize     = 64;

type
  TbufferRec = array[0..GBufsize] of byte;   //64为串口号
  pbufferRec = ^TbufferRec;
  
  TSendMessRec = packed record
    RevState  : Word;
    abuf      : TbufferRec;
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

  TTwoByteRec = packed record
    case integer of
      0: (Data: word);
      1: (Data2: byte;
          Data1: byte; );
  end;

  //上次接收状态
  TRevState = record
    isHead : boolean;
    FEnd : boolean; // 是否接收完
    nCount : byte; //  还剩多少
    PBuffer : array[0..GBufsize] of byte;
  end;

  TCOMPos= class(TObject)
  private
    FTimeOut      : Word;
    FEvent        : THandle;
    FLock         : TRTLCriticalSection;
    FComPort      : TComPort;
    FBaudRate     : DWord;
    FRevState     : TRevState;
    FTmpRbuf      : TBufferRec;
    FRbuf         : TBufferRec;
    FLastBuf      : TBufferRec;
    FLastPosition : Word;
    FSendRec      : TSendMessRec;
    FMRBuffer     : TMRingBuffer;
    procedure Lock;
    procedure UnLock;
    procedure RecvEvent(Sender: TObject; Count: integer);
    function ValidateSum(ABuff:TbufferRec): Boolean; //校验是否通过
    function SendData(const ABuffer: TbufferRec; ALen: Byte): Boolean;
    function AddString(param: string; len: Byte; c: Char): string;
    procedure systemLog(Msg: string);
  published
    property Event: THandle read FEvent;
  public
    property BaudRate: DWORD read FBaudRate write FBaudRate;
    property ComPort: TComPort read FComPort;

    constructor Create();
    destructor Destroy; override;
    function OpenPort(AComPort: Byte): Boolean;
    function ClosePort: Boolean;

    function ReadCard(var cCard: string; var Balance: Currency): Byte;                  //0x01 读卡
    function Consume(cCard: string; cPay: Currency; iFlow: Byte; var Balance, cPayEx: Currency): Byte;//0x02 消费
    function ConsumeEx(cCard: string; cPay: Currency; iFlow: Byte; var Balance, cPayEx: Currency): Byte;//0x02 消费交易未决等结果
    function Query(cCard: string; cPay: Currency; iFlow: Byte; var Balance, cPayEx: Currency): Byte;  //0x03 交易确认

    function CheckSum(ABuff:TbufferRec; iBeg, iEnd: Integer): Byte;//获取校验和 低位优先
  end;  

implementation

uses uCRC8;

{ TCOMPos }

function TCOMPos.ValidateSum(ABuff: TBufferRec): Boolean;
var
  i, iLen, sum: Integer;
begin
  Result:= False;
  iLen:= 27;
  sum:= 0;
  for I := 3 to (iLen- 3) do
    sum:= sum+ ABuff[i];
  sum:= sum mod 256;
  if sum= ABuff[iLen- 2] then
    Result:= True;
end;

function TCOMPos.AddString(param: string; len: Byte; c: Char): string;
var
  str: string;
begin
  str:= param;
  try
    while Length(str)< len do
      str:= c+ str;
  finally
    Result:= str;
  end;
end;

function TCOMPos.CheckSum(ABuff: TbufferRec; iBeg, iEnd: Integer): Byte;
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

function TCOMPos.ClosePort: Boolean;
begin
  FComPort.Close;
  FreeAndNil(FMRBuffer);
end;

function TCOMPos.Consume(cCard: string; cPay: Currency; iFlow: Byte; var Balance, cPayEx: Currency): Byte;
var
  fBytes: TBytes;
  PBytes: PByte;
  iLen: Integer;
  fbuffer : TbufferRec;
  AFOUR : TFourByteRec;
  function BytesToHex(AIn: TbufferRec): string;
  var
    i: integer;
  begin
    Result := '';
    for I := 0 to High(AIn) do
    begin
      Result := Result + format('%s', [IntToHex(AIn[I], 2)]);
    end;
  end;
begin
  Result:= 1;                                            //默认失败
  iLen:= 21;
  setlength(fBytes, iLen);
  PBytes := @fBytes[0];
  FillChar(fbuffer, SizeOf(fbuffer), 0);
  //头部
  fbuffer[0]:= $5A;
  fbuffer[1]:= $3C;
  //长度
  fbuffer[2]:= $12;
  //命令
  fbuffer[3]:= $02;
  //流水
  fbuffer[4]:= iFlow;
  //保留
  fbuffer[5]:= $00;
  //卡号
  fbuffer[6] := StrToIntDef('$'+ Copy(cCard, 1, 2), 0);
  fbuffer[7] := StrToIntDef('$'+ Copy(cCard, 3, 2), 0);
  fbuffer[8] := StrToIntDef('$'+ Copy(cCard, 5, 2), 0);
  fbuffer[9] := StrToIntDef('$'+ Copy(cCard, 7, 2), 0);
  fbuffer[10]:= StrToIntDef('$'+ Copy(cCard, 9, 2), 0);
  fbuffer[11]:= StrToIntDef('$'+ Copy(cCard, 11, 2), 0);
  fbuffer[12]:= StrToIntDef('$'+ Copy(cCard, 13, 2), 0);
  fbuffer[13]:= StrToIntDef('$'+ Copy(cCard, 15, 2), 0);
  fbuffer[14]:= StrToIntDef('$'+ Copy(cCard, 17, 2), 0);
  fbuffer[15]:= StrToIntDef('$'+ Copy(cCard, 19, 2), 0);
  fbuffer[16]:= StrToIntDef('$'+ Copy(cCard, 21, 2), 0);
  //消费金额
  AFOUR.Data := Trunc(cPay* 100);
  fbuffer[17]:= AFOUR.Data4;
  fbuffer[18]:= AFOUR.Data3;
  fbuffer[19]:= AFOUR.Data2;
  fbuffer[20]:= AFOUR.Data1;
  //校验码
  fbuffer[21]:= CheckSum(fbuffer, 3, 20);
  //尾部
  fbuffer[22]:= $DB;
  Lock;
  try
    try
      ResetEvent(FEvent);
      if not SendData(fbuffer, iLen+ 2) then Exit;
      if WaitForSingleObject(FEvent,FTimeOut)=WAIT_OBJECT_0 then
      begin
        systemLog(FormatDateTime('hh:mm:ss', Now)+ '-'+ BytesToHex(FSEndRec.abuf));
        result := FSEndRec.RevState ;  //0成功 其他失败
        if (result = 0) and
           (StrToIntDef(IntToHex(FSEndRec.abuf[3],2), 00) = $02) then
        begin
          //消费后余额
          AFOUR.Data4 := FSEndRec.abuf[17];
          AFOUR.Data3 := FSEndRec.abuf[18];
          AFOUR.Data2 := FSEndRec.abuf[19];
          AFOUR.Data1 := FSEndRec.abuf[20];
          Balance:= AFOUR.Data/100;
          //实际消费额
          AFOUR.Data4 := FSEndRec.abuf[21];
          AFOUR.Data3 := FSEndRec.abuf[22];
          AFOUR.Data2 := FSEndRec.abuf[23];
          AFOUR.Data1 := FSEndRec.abuf[24];
          cPayEx:= AFOUR.Data/100;
        end;
        ResetEvent(FEvent);
      end;
    except
      //
    end;
  finally
    UnLock;
  end;
end;

function TCOMPos.ConsumeEx(cCard: string; cPay: Currency; iFlow: Byte;
  var Balance, cPayEx: Currency): Byte;
var
  fBytes: TBytes;
  PBytes: PByte;
  iLen: Integer;
  fbuffer : TbufferRec;
  AFOUR : TFourByteRec;
begin
  Result:= 99;                                            //默认失败
  Lock;
  try
    ResetEvent(FEvent);
    if (FSEndRec.abuf[0]<> $5A)
      or (FSEndRec.abuf[1]<>$3C)
      or (FSEndRec.abuf[3]<>$02) then Exit;
      
    result := FSEndRec.RevState ;  //0成功 其他失败
    if result = 0 then
    begin
      //消费后余额
      AFOUR.Data4 := FSEndRec.abuf[17];
      AFOUR.Data3 := FSEndRec.abuf[18];
      AFOUR.Data2 := FSEndRec.abuf[19];
      AFOUR.Data1 := FSEndRec.abuf[20];
      Balance:= AFOUR.Data/100;
      //实际消费额
      AFOUR.Data4 := FSEndRec.abuf[21];
      AFOUR.Data3 := FSEndRec.abuf[22];
      AFOUR.Data2 := FSEndRec.abuf[23];
      AFOUR.Data1 := FSEndRec.abuf[24];
      cPayEx:= AFOUR.Data/100;
    end;
    ResetEvent(FEvent);
  finally
    UnLock;
  end;
end;

constructor TCOMPos.Create;
begin
  InitializeCriticalSection(FLock);
  Fevent := CreateEvent(nil,true,false,nil);
  FRevState.FEnd := true;
  FRevState.nCount := 0;
  Fillchar(FRevState.PBuffer, sizeof(FRevState.PBuffer), 0);
  FComPort := TComPort.Create(nil);
  FComPort.OnRxChar := RecvEvent;
  FComPort.SyncMethod := smNone;
  FComPort.Events := [evRxChar, evError, evCTS];
  FComPort.BaudRate := br19200;
  FComPort.EventThreadPriority := tpHigher;
  FComPort.Buffer.InputSize := 4096;
  FComPort.Buffer.OutputSize := 1024;
  FillChar(FLastBuf, SizeOf(FLastBuf), 0);
  FLastPosition := 0;
  FMRBuffer := TMRingBuffer.Create;
  FTimeOut := 2000;
end;

destructor TCOMPos.Destroy;
begin
  FreeAndNil(FComPort);
  DeleteCriticalSection(FLock);
  inherited;
end;

procedure TCOMPos.Lock;
begin
  EnterCriticalSection(FLock);
end;

function TCOMPos.OpenPort(AComPort: Byte): Boolean;
begin
  Result := False;
  try
    if not FComPort.Connected then
    begin
      FComPort.Port := 'COM'+intToStr(AComPort);
      FComPort.Open;
      Result := True;
    end;
  except
    Result := False;
  end;
end;

function TCOMPos.Query(cCard: string; cPay: Currency; iFlow: Byte; var Balance, cPayEx: Currency): Byte;
var                
  fBytes: TBytes;
  PBytes: PByte;
  iLen: Integer;
  fbuffer : TbufferRec;
  AFOUR : TFourByteRec;
begin
  Result:= 4;                                            //默认没有读取到卡片
  iLen:= 21;
  setlength(fBytes, iLen);
  PBytes := @fBytes[0];
  FillChar(fbuffer, SizeOf(fbuffer), 0);
  //头部
  fbuffer[0]:= $5A;
  fbuffer[1]:= $3C;
  //长度
  fbuffer[2]:= $12;
  //命令
  fbuffer[3]:= $03;
  //流水
  fbuffer[4]:= iFlow;
  //
  fbuffer[5]:= $00;
  //卡号
  fbuffer[6] := StrToIntDef('$'+ Copy(cCard, 1, 2), 0);
  fbuffer[7] := StrToIntDef('$'+ Copy(cCard, 3, 2), 0);
  fbuffer[8] := StrToIntDef('$'+ Copy(cCard, 5, 2), 0);
  fbuffer[9] := StrToIntDef('$'+ Copy(cCard, 7, 2), 0);
  fbuffer[10]:= StrToIntDef('$'+ Copy(cCard, 9, 2), 0);
  fbuffer[11]:= StrToIntDef('$'+ Copy(cCard, 11, 2), 0);
  fbuffer[12]:= StrToIntDef('$'+ Copy(cCard, 13, 2), 0);
  fbuffer[13]:= StrToIntDef('$'+ Copy(cCard, 15, 2), 0);
  fbuffer[14]:= StrToIntDef('$'+ Copy(cCard, 17, 2), 0);
  fbuffer[15]:= StrToIntDef('$'+ Copy(cCard, 19, 2), 0);
  fbuffer[16]:= StrToIntDef('$'+ Copy(cCard, 21, 2), 0);
  //消费金额
  AFOUR.Data := Round(cPay* 100);
  fbuffer[17]:= AFOUR.Data4;
  fbuffer[18]:= AFOUR.Data3;
  fbuffer[19]:= AFOUR.Data2;
  fbuffer[20]:= AFOUR.Data1;
  //校验码
  fbuffer[21]:= CheckSum(fbuffer, 3, 20);
  //尾部
  fbuffer[22]:= $DB;
  Lock;
  try
    try
      ResetEvent(FEvent);
      if not SendData(fbuffer, iLen+ 2) then Exit;
      if WaitForSingleObject(FEvent,10000)=WAIT_OBJECT_0 then         {交易查询指令=10秒}
      begin
        result := FSEndRec.RevState ;  //0成功 其他失败
        if (result = 0) and
           (StrToIntDef(IntToHex(FSEndRec.abuf[3],2), 00) = $03) then
        begin
          //消费后余额
          AFOUR.Data4 := FSEndRec.abuf[17];
          AFOUR.Data3 := FSEndRec.abuf[18];
          AFOUR.Data2 := FSEndRec.abuf[19];
          AFOUR.Data1 := FSEndRec.abuf[20];
          Balance:= AFOUR.Data/100;
          //实际消费额
          AFOUR.Data4 := FSEndRec.abuf[21];
          AFOUR.Data3 := FSEndRec.abuf[22];
          AFOUR.Data2 := FSEndRec.abuf[23];
          AFOUR.Data1 := FSEndRec.abuf[24];
          cPayEx:= AFOUR.Data/100;
        end;
        ResetEvent(FEvent);
      end;
    except
      //
    end;
  finally
    UnLock;
  end;
end;

function TCOMPos.ReadCard(var cCard: string; var Balance: Currency): Byte;
var
  fBytes: TBytes;
  PBytes: PByte;
  iLen: Integer;
  fbuffer : TbufferRec;
  AFOUR : TFourByteRec;
begin
  Result:= 4;                                            //默认没有读取到卡片
  iLen:= 21;
  setlength(fBytes, iLen);
  PBytes := @fBytes[0];
  FillChar(fbuffer, SizeOf(fbuffer), 0);
  //头部
  fbuffer[0]:= $5A;
  fbuffer[1]:= $3C;
  //长度
  fbuffer[2]:= $12;
  //命令
  fbuffer[3]:= $01;
  //校验码
  fbuffer[21]:= CheckSum(fbuffer, 3, 20);
  //
  fbuffer[22]:= $DB;
  Lock;
  try
    try
      ResetEvent(FEvent);
      if not SendData(fbuffer, iLen+ 2) then Exit;
      if WaitForSingleObject(FEvent,FTimeOut)=WAIT_OBJECT_0 then
      begin
        result := FSEndRec.RevState ;  //0成功 其他失败
        if (result = 0) and
           (StrToIntDef(IntToHex(FSEndRec.abuf[3],2), 00) = $01) then
        begin
          //卡号
          cCard:= inttohex(FSEndRec.abuf[6],2)+ inttohex(FSEndRec.abuf[7],2)
            + inttohex(FSEndRec.abuf[8],2) + inttohex(FSEndRec.abuf[9],2)
            + inttohex(FSEndRec.abuf[10],2)+ inttohex(FSEndRec.abuf[11],2)
            + inttohex(FSEndRec.abuf[12],2)+ inttohex(FSEndRec.abuf[13],2)
            + inttohex(FSEndRec.abuf[14],2)+ inttohex(FSEndRec.abuf[15],2)
            + inttohex(FSEndRec.abuf[16],2);
          //金额
          AFOUR.Data4 := FSEndRec.abuf[17];
          AFOUR.Data3 := FSEndRec.abuf[18];
          AFOUR.Data2 := FSEndRec.abuf[19];
          AFOUR.Data1 := FSEndRec.abuf[20];
          Balance:= AFOUR.Data/ 100;
        end;
        ResetEvent(FEvent);
      end;
    except
      //
    end;
  finally
    UnLock;
  end;
end;

procedure TCOMPos.RecvEvent(Sender: TObject; Count: integer);
var
  iLen : Integer;
  pRec : pbufferRec;
  fbyte : PByte;
  ATwo : TTwoByteRec;
  bLoop : Boolean;
begin
  FillChar(FRbuf, SizeOf(FRbuf), 0);
  pRec := @FRbuf;
  iLen := Min(Count, GBufsize);
  FComPort.Read(FRbuf, iLen);
  if FMRBuffer <> nil then
    FMRBuffer.Push(pRec, iLen);
  fbyte := @FRbuf[0];
  bLoop := True;
  while bLoop do
  begin
    if FMRBuffer.ReadEx(fbyte) then
    begin
      if not ValidateSum(FRbuf) then Continue;
      move(FRbuf[0],FSendRec.abuf[0],GBufsize+1) ;
      FSEndRec.RevState := StrToIntDef(IntToHex(FSendRec.abuf[4],2), 99);
      SetEvent(FEvent);
    end
    else
    begin
      bLoop := False;
    end;
  end;
end;

function TCOMPos.SendData(const ABuffer: TbufferRec; ALen: Byte): Boolean;
var
  sSend : string;
  I, iRes : Integer;
begin
  Result := False;
  if ALen <= 0 then Exit;
  if FComPort = nil then Exit;
  if not FComPort.Connected then Exit;
  {$IFDEF DEBUG}
  {$ENDIF}
  try
    iRes := FComPort.Write(ABuffer, ALen);
    Result := True;
  finally
  end;
end;

procedure TCOMPos.systemLog(Msg: string);
var
  F: TextFile;
  FileName: string;
  ExeRoad: string;
begin
  try
    ExeRoad := ExtractFilePath(ParamStr(0));
    if ExeRoad[Length(ExeRoad)] = '\' then
      SetLength(ExeRoad, Length(ExeRoad) - 1);
    if not DirectoryExists(ExeRoad + '\TXLog') then
    begin
      CreateDir(ExeRoad + '\TXLog');
    end;
    FileName := ExeRoad + '\TXLog\YSL-' + FormatDateTime('YYMMDD', NOW) + '.txt';
    if not FileExists(FileName) then
    begin
      AssignFile(F, FileName);
      ReWrite(F);
    end
    else
      AssignFile(F, FileName);
    Append(F);
    Writeln(F, FormatDateTime('HH:NN:SS', Now) + Msg);
    Writeln(F, '');
    CloseFile(F);
  except
    //可能在事务中调用,避免意外
  end;
end;

procedure TCOMPos.UnLock;
begin
  LeaveCriticalSection(FLock);
end;

end.
