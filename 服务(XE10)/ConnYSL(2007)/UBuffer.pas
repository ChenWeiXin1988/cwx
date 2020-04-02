unit UBuffer;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, 
  SyncObjs;

const
  CO_RingBufferDefLen = 100;
  GMBufsize           = 128;

  GDataSendAndRec_One = $5A;    //包头1字节
  GDataSendAndRec_Two = $3C;    //包头2字节
  GHeadLen            = 2;      //包头长度
  GHeaderLen          = 27;      //最少数据包  8个字节
  
type

  TTwoByteRec = packed record
    case integer of
      0: (Data: word);
      1: (Data2: byte;
          Data1: byte; );
  end;
  
//------------------环形缓冲区-------------------------------------------------
//先进先出
  PRBInfo=^TRBInfo;
  TRBInfo=Record
    RTLCS:TRTLCriticalSection;
    HeadIndex:Integer; //指向数据的开头位置
    Position:Integer;  //指向数据的结束位置
    BufferLen:Longint; //缓冲区的长度
    Buffer:Pointer;    //缓冲区指针
  end;

  //缓冲区读取模式，
  TRBReadStyle=(rsCat,rsCopy);
  //环形列表缓冲区 剪切 复制
  TCustomRingBuffer=class
  public
    class function Init(Info:PRBInfo;DefLen:Integer=CO_RingBufferDefLen):Integer;
    class procedure FreeInfo(Info:PRBInfo);
    class function Write(Info:PRBInfo;Data:Pointer;Len:Integer;AutoEnlarge:Boolean=False):Integer;
    class function Read(Info:PRBInfo;Data:Pointer;Len:Integer;ReadStyle:TRBReadStyle=rsCat):Integer;
    class procedure Clear(Info:PRBInfo);
    class function GetDataSize(Info:PRBInfo):Integer;
    class function SetBufferSize(Info:PRBInfo;Len:Integer):Integer;
    class procedure SetBufferByte(Info:PRBInfo;Index:Integer;Value:Byte);
  end;


  //内存环形先进先出缓冲区
  TMemoryRingBuffer=class
  private
    FRBInfo:TRBInfo;
    FAutoEnlarge:Boolean; //T 空间不足够自动扩大缓冲区
    FCl : TCriticalSection;
  public
    constructor Create;overload;
    constructor Create(BufferLen:Integer);overload;
    destructor Destroy; override;
  public
    function Push(Data:Pointer;Len:Integer):Integer; //写入
    function Pop(Data:Pointer;Len:Integer):Integer; //读取并剪切
    function Read(Data:Pointer;Len:Integer):Integer;//仅复制数据
    function GetDataSize:Integer;   //得到数据的长度
    function SetBufferSize(Len:Integer):Integer;  //设置缓冲区的大小
    function GetBufferSize:Integer;  //得到缓冲区的长度
    function GetBufferByte(Index:Integer):Byte;   //得到缓区某一位的值
    procedure SetBufferByte(Index:Integer;Value:Byte);//得到缓区某一位的值
    function GetInfoStr:String;  //得到缓冲区的信息字符串
    function HasNull(Index:Integer):Boolean;//是否有数据
    procedure Clear; //清空缓冲区
  published
    property AutoEnlarge:Boolean read FAutoEnlarge write FAutoEnlarge;
  end;

  
  TMRingBuffer = class(TMemoryRingBuffer)
  public
    function ReadEx(Data:PByte) : Boolean;
    function WriteEx(Data:PByte) : Boolean;
  end;





implementation




{ TCustomRingBuffer }

class procedure TCustomRingBuffer.Clear(Info:PRBInfo);
begin
  EnterCriticalSection(Info.RTLCS);
  Try
    Info.HeadIndex:=-1;
    Info.Position:=-1;
    ZeroMemory(Info.Buffer,Info.BufferLen);
  finally
    LeaveCriticalSection(Info.RTLCS);
  end;
end;

class procedure TCustomRingBuffer.FreeInfo(Info: PRBInfo);
begin
  EnterCriticalSection(Info.RTLCS);
  Try
    Info.HeadIndex:=-1;
    Info.Position:=-1;
    Info.BufferLen:=0;
    FreeMemory(Info.Buffer);
  finally
    LeaveCriticalSection(Info.RTLCS);
  end;
  DeleteCriticalSection(Info.RTLCS);
end;

class function TCustomRingBuffer.GetDataSize(Info:PRBInfo): Integer;
var
  NullLen:Integer;
begin
//得到数据的长度
  NullLen:=0;
  if (-1=Info.Position)and(Info.Position=Info.HeadIndex) then
    NullLen:=Info.BufferLen
  else
    if (Info.Position>=Info.HeadIndex) then
      NullLen:=((Info.BufferLen-Info.Position-1)+Info.HeadIndex)
    else if (Info.Position<Info.HeadIndex) then
      NullLen:=Info.HeadIndex-Info.Position-1;
  Result:=Info.BufferLen-NullLen;
end;

class function TCustomRingBuffer.Init(Info: PRBInfo;DefLen:Integer=CO_RingBufferDefLen):Integer;
begin
  Result:=0;
  InitializeCriticalSection(Info.RTLCS);
  EnterCriticalSection(Info.RTLCS);
  Try
    Info.HeadIndex:=-1;
    Info.Position:=-1;
    Info.BufferLen:=0;
    Info.Buffer:=GetMemory(DefLen);
    if Assigned(Info.Buffer) then
    begin
      Info.BufferLen:=DefLen;
      ZeroMemory(Info.Buffer,DefLen);
      Result:=DefLen;
    end
  finally
    LeaveCriticalSection(Info.RTLCS);
  end;
end;

class function TCustomRingBuffer.Read(Info: PRBInfo; Data: Pointer;
  Len: Integer;ReadStyle:TRBReadStyle=rsCat): Integer;
var
  DataLen,DataLastLen:Integer;
  P:Pointer;
begin
//读取环形缓冲区列表
  Result:=0;
//检查是否有数据
  if (-1=Info.Position)and(Info.Position=Info.HeadIndex) then
    Exit;
  EnterCriticalSection(Info.RTLCS);
  try
    //缓冲区数据没有成环
    if (Info.Position>=Info.HeadIndex) then
    begin  //检查数据的长度是不是和要求的长度一样
      DataLen:=Info.Position-Info.HeadIndex+1;
      if DataLen>=Len then
        Result:=Len
      else
        Result:=DataLen;
      P:=Pointer(Integer(Info.Buffer)+Info.HeadIndex);
      CopyMemory(Data,P,Result);
      //将读取后的缓冲区空间清空
      if ReadStyle=rsCat then
      begin
        ZeroMemory(P,Result);
        Info.HeadIndex:=Info.HeadIndex+Result;
        if Info.HeadIndex>info.Position then //读完了，缓冲区成为空位置了
        begin
          Info.HeadIndex:=-1;
          Info.Position:=-1;
        end;
      end;
    end
    else if (Info.Position<Info.HeadIndex) then
    begin //缓冲区成环了
      DataLen:=Info.BufferLen-(Info.HeadIndex-Info.Position-1);
      if DataLen>=Len then
        Result:=Len
      else
        Result:=DataLen;
      DataLastLen:=Info.BufferLen-Info.HeadIndex;
      if DataLastLen>=Result then //缓冲区后部的数据长度已经够了
      begin
        P:=Pointer(Integer(Info.Buffer)+Info.HeadIndex);
        CopyMemory(Data,P,Result);
        ZeroMemory(P,Result);
        if ReadStyle=rsCat then
        begin
          Info.HeadIndex:=Info.HeadIndex+Result;
          if Info.HeadIndex>info.BufferLen then
            Info.HeadIndex:=0;
        end;
      end
      else //缓冲区后的数据不足，要将前部的数据也要返回
      begin
        P:=Pointer(Integer(Info.Buffer)+Info.HeadIndex);
        CopyMemory(Data,P,DataLastLen);
        ZeroMemory(P,DataLastLen);
        P:=Pointer(Integer(Data)+DataLastLen);
        CopyMemory(P,Info.Buffer,Result-DataLastLen);
        ZeroMemory(Info.Buffer,Result-DataLastLen);
        if ReadStyle=rsCat then
        begin
          Info.HeadIndex:=Result-DataLastLen;
          if Info.HeadIndex>Info.Position then
          begin
            Info.HeadIndex:=-1;
            Info.Position:=-1;
          end;
        end;
      end;
    
    end;
  finally
    LeaveCriticalSection(Info.RTLCS);
  end;
end;

class procedure TCustomRingBuffer.SetBufferByte(Info: PRBInfo; Index: Integer;
  Value: Byte);
begin
  EnterCriticalSection(Info.RTLCS);
  try
    //检查给定的索引值是否在有效的数据范围内
    PByte(Pointer(Integer(Info.Buffer)+Index))^:=Value;
  finally
    LeaveCriticalSection(Info.RTLCS);
  end;
end;

class function TCustomRingBuffer.SetBufferSize(Info: PRBInfo;
  Len: Integer): Integer;
var
  NewBuffer,P:Pointer;
  DataLen,DataLastLen:Integer;
begin
//重新设置缓冲区空间的大小,返回新的大小
  Result:=Info.BufferLen;
  if (Len=Info.BufferLen)or(Len<=0) then
    Exit;
  EnterCriticalSection(Info.RTLCS);
  try
    //检查是否有数据，如果没有数据，则直接扩大
    if (-1=Info.HeadIndex)and(Info.HeadIndex=Info.Position) then
    begin
      NewBuffer:=GetMemory(Len);
      if Assigned(NewBuffer) then
      begin
        ZeroMemory(NewBuffer,Len);
        FreeMemory(Info.Buffer);
        Info.BufferLen:=Len;
        Info.Buffer:=NewBuffer;
        Result:=Info.BufferLen;
      end;
    end
    else //如果有数据则移动数据
    begin   //没有形成数据环,仅移动数据
      if (Info.Position>=Info.HeadIndex) then
      begin
        NewBuffer:=GetMemory(Len);
        if Assigned(NewBuffer) then
        begin
          ZeroMemory(NewBuffer,Len);
          P:=Pointer(Integer(Info.Buffer)+Info.HeadIndex);
          DataLen:=Info.Position-Info.HeadIndex+1;
          if DataLen<=Len then   //空间够大，可以放得下原有数据
          else  //新的空间比原来的小，只能放部分数据
            DataLen:=Len;
          CopyMemory(NewBuffer,P,DataLen);
          Info.HeadIndex:=0;
          Info.Position:=DataLen-1;
          FreeMemory(Info.Buffer);
          Info.BufferLen:=Len;
          Info.Buffer:=NewBuffer;
          Result:=Info.BufferLen;
        end;
      end
      else //数据已经形成环
      begin
        NewBuffer:=GetMemory(Len);
        if Assigned(NewBuffer) then
        begin
          ZeroMemory(NewBuffer,Len);
          DataLen:=Info.BufferLen-(Info.HeadIndex-Info.Position-1);
          DataLastLen:=Info.BufferLen-Info.HeadIndex+1;
          P:=Pointer(Integer(Info.Buffer)+Info.HeadIndex);
          if DataLastLen<Len then
          begin  //复制完缓冲区的后部分
            CopyMemory(NewBuffer,P,DataLastLen);
            P:=Pointer(Integer(NewBuffer)+DataLastLen);
            if ((Len-DataLastLen)>=Info.HeadIndex+1) then
              DataLen:=Info.HeadIndex+1
            else  //空间不够保存数据,仅能保存部分
              DataLen:=Len-DataLastLen;
            CopyMemory(P,Info.Buffer,DataLen);
            Info.HeadIndex:=0;
            Info.Position:=DataLastLen+DataLen-1;
          end
          else
          begin
            CopyMemory(NewBuffer,P,Len);
            Info.HeadIndex:=0;
            Info.Position:=Len-1;
          end;
          FreeMemory(Info.Buffer);
          Info.BufferLen:=Len;
          Info.Buffer:=NewBuffer;
          Result:=Info.BufferLen
        end;
      end;
    end;
  finally
    LeaveCriticalSection(Info.RTLCS);
  end;
end;

class function TCustomRingBuffer.Write(Info: PRBInfo; Data: Pointer;
  Len: Integer;AutoEnlarge:Boolean=False): Integer;
var
  L,NullLen:Integer; //总的空数据的长度
  NullLastLen:Integer; //缓冲区前头的空位置长度和后部的空位置的长度
  P:Pointer;
  EnlargeLen:Integer;//扩大的缓冲区长度
begin
//给缓冲区中添加数据

//检查缓冲区中空闲空间长度,空闲空间的计算方式有三种
//1.缓冲区中完全没有数据， -1=HeadIndex=Position
//2.缓冲区中有部分数据，但没有成环  Position>=HeadIndex
//3.缓冲区中有部分数据，已经成环  Position<HeadIndex
  Result:=0;
  EnterCriticalSection(Info.RTLCS);
  try
    NullLen:=0;
    if (-1=Info.Position)and(Info.Position=Info.HeadIndex) then
      NullLen:=Info.BufferLen //方式1
    else if (Info.Position>=Info.HeadIndex) then
      NullLen:=((Info.BufferLen-Info.Position-1)+Info.HeadIndex) //方式2
    else if (Info.Position<Info.HeadIndex) then
      NullLen:=Info.HeadIndex-Info.Position-1;  //方式3

    //数据数据长度小于空间的长度，并且可以自动扩大
    if (Len>=NullLen)and AutoEnlarge then
    begin
      //注意，可能扩展后的大小和指定想扩展的大小不同,如申请新的空间没有成功
      //则缓冲区的大小还是保持原有的大小
      L:=Info.BufferLen;
      EnlargeLen:=TCustomRingBuffer.SetBufferSize(Info,Info.BufferLen*2+Len);
      NullLen:=NullLen+EnlargeLen-L;
    end;

    //没有空闲空间则退出
    if 0=NullLen then
      Exit;
    //返回缓冲区中可以放下的数据长度
    if NullLen>=Len then //缓冲区中可以放得下全部数据
      Result:=Len
    else     //缓冲区中只能放下部分数据
      Result:=NullLen;

    //根据三种不同的方式来复制数据
    //方式一
    if (-1=Info.Position)and(Info.Position=Info.HeadIndex) then
    begin //缓冲区为空，没有数据
      CopyMemory(Info.Buffer,Data,Result);
      Info.HeadIndex:=0;
      Info.Position:=Result-1;
    end
    else if (Info.Position>=Info.HeadIndex) then
    begin  //方式二 缓冲区中有数据，但没有成环
      if (Info.HeadIndex=0) then //缓冲区头位置还是 0  直接将数据放在后面
      begin
        P:=Pointer(Integer(Info.Buffer)+Info.Position+1);
        CopyMemory(P,Data,Result);
        Info.Position:=Info.Position+Result;
      end
      else if (Info.Position=Info.BufferLen-1) then //缓冲区尾部在最后， 直接将数据放在缓冲区前面
      begin
        CopyMemory(Info.Buffer,Data,Result);
        Info.Position:=Result-1;
      end
      else //缓冲区仅是中间部分有数据，前后都有空间，新数据可能要分成两部分存放
      begin
        //计算缓冲区后部的空间
        NullLastLen:=Info.BufferLen-Info.Position-1;
        if NullLastLen>=Len then
        begin  //缓冲区中剩余的后部分就可以放下数据
          P:=Pointer(Integer(Info.Buffer)+Info.Position+1);
          CopyMemory(P,Data,Result);
          Info.Position:=Info.Position+Result;
        end
        else //缓冲区剩余的后部分放不下全部数据，仅能放下部分
        begin
          P:=Pointer(Integer(Info.Buffer)+Info.Position+1);
          CopyMemory(P,Data,NullLastLen); //先将部分数据放在缓冲区后部分
          P:=Pointer(Integer(Data)+NullLastLen); //在将剩余的数据放到缓冲的前面
          CopyMemory(Info.Buffer,P,Result-NullLastLen);
          Info.Position:=Result-NullLastLen-1;
        end;
      end;
    end
    else if (Info.Position<Info.HeadIndex) then
    begin  //方式三
      P:=Pointer(Integer(Info.Buffer)+Info.Position+1);
      CopyMemory(P,Data,Result);
      Info.Position:=Info.Position+Result;
    end;
  finally
    LeaveCriticalSection(Info.RTLCS);
  end;
end;

 { TMemoryRingBuffer }

procedure TMemoryRingBuffer.Clear;
begin
  FCl.Enter;
  try
    TCustomRingBuffer.Clear(@FRBInfo);
  finally
    FCl.Leave;
  end;
end;

constructor TMemoryRingBuffer.Create;
begin
  inherited;
  FAutoEnlarge:=False;
  TCustomRingBuffer.Init(@FRBInfo);
  if FCl = nil then
    FCl := TCriticalSection.Create;
end;

constructor TMemoryRingBuffer.Create(BufferLen: Integer);
begin
  inherited Create;
  FAutoEnlarge:=False;
  TCustomRingBuffer.Init(@FRBInfo,BufferLen);
  if FCl = nil then
    FCl := TCriticalSection.Create;  
end;

destructor TMemoryRingBuffer.Destroy;
begin
  TCustomRingBuffer.FreeInfo(@FRBInfo);
  if FCl <> nil then
    FreeAndNil(FCl);
  inherited;
end;

function TMemoryRingBuffer.GetBufferByte(Index: Integer): Byte;
begin
  Result:=PByte(Pointer(Integer(FRBInfo.Buffer)+Index))^;
end;

function TMemoryRingBuffer.GetBufferSize: Integer;
begin
  Result:=FRBInfo.BufferLen;
end;

function TMemoryRingBuffer.GetDataSize: Integer;
begin
  FCl.Enter;
  try
    Result:=TCustomRingBuffer.GetDataSize(@FRBInfo);
  finally
    FCl.Leave;
  end;
end;

function TMemoryRingBuffer.GetInfoStr: String;
begin
  Result:=Format('数据头=%d 数据尾=%d 数据长度=%d 缓冲区长度=%d',[
        FRBInfo.HeadIndex,FRBInfo.Position,GetDataSize,FRBInfo.BufferLen
        ]);
end;

function TMemoryRingBuffer.HasNull(Index: Integer): Boolean;
begin
//检查给定的位置的数据是否为空，如果为空返回 T
 // Result:=True;
 // Result:=odd(Index);
//  Exit;

  if (-1=FRBInfo.Position)and(FRBInfo.Position=FRBInfo.HeadIndex) then
    Result:=True
  else if (FRBInfo.Position>=FRBInfo.HeadIndex)and((Index<FRBInfo.HeadIndex)or(Index>FRBInfo.Position)) then
    Result:=True
  else if (FRBInfo.Position<FRBInfo.HeadIndex)and(Index>FRBInfo.Position)and(Index<FRBInfo.HeadIndex) then
    Result:=True
  else
    Result:=False;

end;

function TMemoryRingBuffer.Pop(Data: Pointer; Len: Integer): Integer;
begin
  FCl.Enter;
  try
    Result:=TCustomRingBuffer.Read(@FRBInfo,Data,Len,rsCat);
  finally
    FCl.Leave;
  end;
end;

function TMemoryRingBuffer.Push(Data: Pointer; Len: Integer): Integer;
begin
  FCl.Enter;
  try
    Result:=TCustomRingBuffer.Write(@FRBInfo,Data,Len,FAutoEnlarge);
  finally
    FCl.Leave;
  end;
end;

function TMemoryRingBuffer.Read(Data: Pointer; Len: Integer): Integer;
begin
  FCl.Enter;
  try
    Result:=TCustomRingBuffer.Read(@FRBInfo,Data,Len,rsCopy);
  finally
    FCl.Leave;
  end;
end;

procedure TMemoryRingBuffer.SetBufferByte(Index: Integer; Value: Byte);
begin
  TCustomRingBuffer. SetBufferByte(@FRBInfo,Index,Value);
end;

function TMemoryRingBuffer.SetBufferSize(Len: Integer): Integer;
begin
  Result:=TCustomRingBuffer.SetBufferSize(@FRBInfo,Len);
end;

{ TMRingBuffer }

function TMRingBuffer.ReadEx(Data: PByte): Boolean;
var
  Arr:array of Byte;
  Len, LenD:Integer;
  i :Integer;
  iErr, iRight, iLen : Word;
  fTwo : TTwoByteRec;
label ReRead;
begin
  Result := False;
  try
  ReRead:
    SetLength(Arr,GMBufsize);     //程序中数据包最长长度为64，所以复制2被长度字节，至少会出现一个包头 0x5A
    Len:=Read(Arr,GMBufsize);     //这个只是以复制方式读取，并不影响环形缓冲区内的数据
    if Len > 0 then
    begin
      iErr := 0;
      iRight := 0;
      for i := 0 to Len - 1 do
      begin
        if (Arr[i]   = GDataSendAndRec_One) and
           (Arr[i+1] = GDataSendAndRec_Two) then    //包头
        begin
          iRight := Len - iErr;                     //iRight 从0X5A开始的数据包长度
          if i > 0 then  //第一个字符就是则不用剔除
          begin
            SetLength(Arr,iErr);
            Len:=Pop(Arr,iErr);                       //直接把0x5A包头之前的数据全部读取,将圆形缓冲区内数据清空，0x5A及0x5A之后的保留 ，如果读取未成功，则下一次进行
            if (Len = 0) or (Len <> iErr) then Exit;  //读取并清空数据未成功，直接退出
            goto ReRead;
          end;
          if iRight < GHeaderLen then   //一个数据包至少27字节
          begin
            Exit;
          end
          else                          //大于27个时候，需要判断包是否完整，包括校验
          begin
            iLen := Arr[i+ 2]+ 5;  //整个数据包的长度
            if iLen > iRight then    //如果需要读取的长度比有效长度还短则退出，等待下一次处理
            begin
              Exit;
            end
            else
            begin
              SetLength(Arr,iLen);
              Len:=Pop(Arr,iLen);
              if (Len = 0) or (Len = iErr) then Exit;  //读取数据发生异常，未读取，或者没有读取到规定长度的字符，直接退出
                move(Arr[0],Data^,iLen);
                Result := True;
            end;
          end;
        end
        else
        begin
          Inc(iErr);
        end;
      end;
    end;
  finally
    SetLength(Arr,0);
  end;
end;

function TMRingBuffer.WriteEx(Data: PByte): Boolean;
var
  iLen, iWLen : Integer;
begin
  Result := False;
  try
    iLen := High(Data^);
    iWLen := Push(Data,iLen);
    if (iWLen = iLen) then
    Result := True;
  except
  end;  
end;

end.
