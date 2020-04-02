unit UBuffer;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, 
  SyncObjs;

const
  CO_RingBufferDefLen = 100;
  GMBufsize           = 128;

  GDataSendAndRec_One = $5A;    //��ͷ1�ֽ�
  GDataSendAndRec_Two = $3C;    //��ͷ2�ֽ�
  GHeadLen            = 2;      //��ͷ����
  GHeaderLen          = 27;      //�������ݰ�  8���ֽ�
  
type

  TTwoByteRec = packed record
    case integer of
      0: (Data: word);
      1: (Data2: byte;
          Data1: byte; );
  end;
  
//------------------���λ�����-------------------------------------------------
//�Ƚ��ȳ�
  PRBInfo=^TRBInfo;
  TRBInfo=Record
    RTLCS:TRTLCriticalSection;
    HeadIndex:Integer; //ָ�����ݵĿ�ͷλ��
    Position:Integer;  //ָ�����ݵĽ���λ��
    BufferLen:Longint; //�������ĳ���
    Buffer:Pointer;    //������ָ��
  end;

  //��������ȡģʽ��
  TRBReadStyle=(rsCat,rsCopy);
  //�����б����� ���� ����
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


  //�ڴ滷���Ƚ��ȳ�������
  TMemoryRingBuffer=class
  private
    FRBInfo:TRBInfo;
    FAutoEnlarge:Boolean; //T �ռ䲻�㹻�Զ����󻺳���
    FCl : TCriticalSection;
  public
    constructor Create;overload;
    constructor Create(BufferLen:Integer);overload;
    destructor Destroy; override;
  public
    function Push(Data:Pointer;Len:Integer):Integer; //д��
    function Pop(Data:Pointer;Len:Integer):Integer; //��ȡ������
    function Read(Data:Pointer;Len:Integer):Integer;//����������
    function GetDataSize:Integer;   //�õ����ݵĳ���
    function SetBufferSize(Len:Integer):Integer;  //���û������Ĵ�С
    function GetBufferSize:Integer;  //�õ��������ĳ���
    function GetBufferByte(Index:Integer):Byte;   //�õ�����ĳһλ��ֵ
    procedure SetBufferByte(Index:Integer;Value:Byte);//�õ�����ĳһλ��ֵ
    function GetInfoStr:String;  //�õ�����������Ϣ�ַ���
    function HasNull(Index:Integer):Boolean;//�Ƿ�������
    procedure Clear; //��ջ�����
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
//�õ����ݵĳ���
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
//��ȡ���λ������б�
  Result:=0;
//����Ƿ�������
  if (-1=Info.Position)and(Info.Position=Info.HeadIndex) then
    Exit;
  EnterCriticalSection(Info.RTLCS);
  try
    //����������û�гɻ�
    if (Info.Position>=Info.HeadIndex) then
    begin  //������ݵĳ����ǲ��Ǻ�Ҫ��ĳ���һ��
      DataLen:=Info.Position-Info.HeadIndex+1;
      if DataLen>=Len then
        Result:=Len
      else
        Result:=DataLen;
      P:=Pointer(Integer(Info.Buffer)+Info.HeadIndex);
      CopyMemory(Data,P,Result);
      //����ȡ��Ļ������ռ����
      if ReadStyle=rsCat then
      begin
        ZeroMemory(P,Result);
        Info.HeadIndex:=Info.HeadIndex+Result;
        if Info.HeadIndex>info.Position then //�����ˣ���������Ϊ��λ����
        begin
          Info.HeadIndex:=-1;
          Info.Position:=-1;
        end;
      end;
    end
    else if (Info.Position<Info.HeadIndex) then
    begin //�������ɻ���
      DataLen:=Info.BufferLen-(Info.HeadIndex-Info.Position-1);
      if DataLen>=Len then
        Result:=Len
      else
        Result:=DataLen;
      DataLastLen:=Info.BufferLen-Info.HeadIndex;
      if DataLastLen>=Result then //�������󲿵����ݳ����Ѿ�����
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
      else //������������ݲ��㣬Ҫ��ǰ��������ҲҪ����
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
    //������������ֵ�Ƿ�����Ч�����ݷ�Χ��
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
//�������û������ռ�Ĵ�С,�����µĴ�С
  Result:=Info.BufferLen;
  if (Len=Info.BufferLen)or(Len<=0) then
    Exit;
  EnterCriticalSection(Info.RTLCS);
  try
    //����Ƿ������ݣ����û�����ݣ���ֱ������
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
    else //������������ƶ�����
    begin   //û���γ����ݻ�,���ƶ�����
      if (Info.Position>=Info.HeadIndex) then
      begin
        NewBuffer:=GetMemory(Len);
        if Assigned(NewBuffer) then
        begin
          ZeroMemory(NewBuffer,Len);
          P:=Pointer(Integer(Info.Buffer)+Info.HeadIndex);
          DataLen:=Info.Position-Info.HeadIndex+1;
          if DataLen<=Len then   //�ռ乻�󣬿��Էŵ���ԭ������
          else  //�µĿռ��ԭ����С��ֻ�ܷŲ�������
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
      else //�����Ѿ��γɻ�
      begin
        NewBuffer:=GetMemory(Len);
        if Assigned(NewBuffer) then
        begin
          ZeroMemory(NewBuffer,Len);
          DataLen:=Info.BufferLen-(Info.HeadIndex-Info.Position-1);
          DataLastLen:=Info.BufferLen-Info.HeadIndex+1;
          P:=Pointer(Integer(Info.Buffer)+Info.HeadIndex);
          if DataLastLen<Len then
          begin  //�����껺�����ĺ󲿷�
            CopyMemory(NewBuffer,P,DataLastLen);
            P:=Pointer(Integer(NewBuffer)+DataLastLen);
            if ((Len-DataLastLen)>=Info.HeadIndex+1) then
              DataLen:=Info.HeadIndex+1
            else  //�ռ䲻����������,���ܱ��沿��
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
  L,NullLen:Integer; //�ܵĿ����ݵĳ���
  NullLastLen:Integer; //������ǰͷ�Ŀ�λ�ó��Ⱥͺ󲿵Ŀ�λ�õĳ���
  P:Pointer;
  EnlargeLen:Integer;//����Ļ���������
begin
//�����������������

//��黺�����п��пռ䳤��,���пռ�ļ��㷽ʽ������
//1.����������ȫû�����ݣ� -1=HeadIndex=Position
//2.���������в������ݣ���û�гɻ�  Position>=HeadIndex
//3.���������в������ݣ��Ѿ��ɻ�  Position<HeadIndex
  Result:=0;
  EnterCriticalSection(Info.RTLCS);
  try
    NullLen:=0;
    if (-1=Info.Position)and(Info.Position=Info.HeadIndex) then
      NullLen:=Info.BufferLen //��ʽ1
    else if (Info.Position>=Info.HeadIndex) then
      NullLen:=((Info.BufferLen-Info.Position-1)+Info.HeadIndex) //��ʽ2
    else if (Info.Position<Info.HeadIndex) then
      NullLen:=Info.HeadIndex-Info.Position-1;  //��ʽ3

    //�������ݳ���С�ڿռ�ĳ��ȣ����ҿ����Զ�����
    if (Len>=NullLen)and AutoEnlarge then
    begin
      //ע�⣬������չ��Ĵ�С��ָ������չ�Ĵ�С��ͬ,�������µĿռ�û�гɹ�
      //�򻺳����Ĵ�С���Ǳ���ԭ�еĴ�С
      L:=Info.BufferLen;
      EnlargeLen:=TCustomRingBuffer.SetBufferSize(Info,Info.BufferLen*2+Len);
      NullLen:=NullLen+EnlargeLen-L;
    end;

    //û�п��пռ����˳�
    if 0=NullLen then
      Exit;
    //���ػ������п��Է��µ����ݳ���
    if NullLen>=Len then //�������п��Էŵ���ȫ������
      Result:=Len
    else     //��������ֻ�ܷ��²�������
      Result:=NullLen;

    //�������ֲ�ͬ�ķ�ʽ����������
    //��ʽһ
    if (-1=Info.Position)and(Info.Position=Info.HeadIndex) then
    begin //������Ϊ�գ�û������
      CopyMemory(Info.Buffer,Data,Result);
      Info.HeadIndex:=0;
      Info.Position:=Result-1;
    end
    else if (Info.Position>=Info.HeadIndex) then
    begin  //��ʽ�� �������������ݣ���û�гɻ�
      if (Info.HeadIndex=0) then //������ͷλ�û��� 0  ֱ�ӽ����ݷ��ں���
      begin
        P:=Pointer(Integer(Info.Buffer)+Info.Position+1);
        CopyMemory(P,Data,Result);
        Info.Position:=Info.Position+Result;
      end
      else if (Info.Position=Info.BufferLen-1) then //������β������� ֱ�ӽ����ݷ��ڻ�����ǰ��
      begin
        CopyMemory(Info.Buffer,Data,Result);
        Info.Position:=Result-1;
      end
      else //�����������м䲿�������ݣ�ǰ���пռ䣬�����ݿ���Ҫ�ֳ������ִ��
      begin
        //���㻺�����󲿵Ŀռ�
        NullLastLen:=Info.BufferLen-Info.Position-1;
        if NullLastLen>=Len then
        begin  //��������ʣ��ĺ󲿷־Ϳ��Է�������
          P:=Pointer(Integer(Info.Buffer)+Info.Position+1);
          CopyMemory(P,Data,Result);
          Info.Position:=Info.Position+Result;
        end
        else //������ʣ��ĺ󲿷ַŲ���ȫ�����ݣ����ܷ��²���
        begin
          P:=Pointer(Integer(Info.Buffer)+Info.Position+1);
          CopyMemory(P,Data,NullLastLen); //�Ƚ��������ݷ��ڻ������󲿷�
          P:=Pointer(Integer(Data)+NullLastLen); //�ڽ�ʣ������ݷŵ������ǰ��
          CopyMemory(Info.Buffer,P,Result-NullLastLen);
          Info.Position:=Result-NullLastLen-1;
        end;
      end;
    end
    else if (Info.Position<Info.HeadIndex) then
    begin  //��ʽ��
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
  Result:=Format('����ͷ=%d ����β=%d ���ݳ���=%d ����������=%d',[
        FRBInfo.HeadIndex,FRBInfo.Position,GetDataSize,FRBInfo.BufferLen
        ]);
end;

function TMemoryRingBuffer.HasNull(Index: Integer): Boolean;
begin
//��������λ�õ������Ƿ�Ϊ�գ����Ϊ�շ��� T
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
    SetLength(Arr,GMBufsize);     //���������ݰ������Ϊ64�����Ը���2�������ֽڣ����ٻ����һ����ͷ 0x5A
    Len:=Read(Arr,GMBufsize);     //���ֻ���Ը��Ʒ�ʽ��ȡ������Ӱ�컷�λ������ڵ�����
    if Len > 0 then
    begin
      iErr := 0;
      iRight := 0;
      for i := 0 to Len - 1 do
      begin
        if (Arr[i]   = GDataSendAndRec_One) and
           (Arr[i+1] = GDataSendAndRec_Two) then    //��ͷ
        begin
          iRight := Len - iErr;                     //iRight ��0X5A��ʼ�����ݰ�����
          if i > 0 then  //��һ���ַ����������޳�
          begin
            SetLength(Arr,iErr);
            Len:=Pop(Arr,iErr);                       //ֱ�Ӱ�0x5A��ͷ֮ǰ������ȫ����ȡ,��Բ�λ�������������գ�0x5A��0x5A֮��ı��� �������ȡδ�ɹ�������һ�ν���
            if (Len = 0) or (Len <> iErr) then Exit;  //��ȡ���������δ�ɹ���ֱ���˳�
            goto ReRead;
          end;
          if iRight < GHeaderLen then   //һ�����ݰ�����27�ֽ�
          begin
            Exit;
          end
          else                          //����27��ʱ����Ҫ�жϰ��Ƿ�����������У��
          begin
            iLen := Arr[i+ 2]+ 5;  //�������ݰ��ĳ���
            if iLen > iRight then    //�����Ҫ��ȡ�ĳ��ȱ���Ч���Ȼ������˳����ȴ���һ�δ���
            begin
              Exit;
            end
            else
            begin
              SetLength(Arr,iLen);
              Len:=Pop(Arr,iLen);
              if (Len = 0) or (Len = iErr) then Exit;  //��ȡ���ݷ����쳣��δ��ȡ������û�ж�ȡ���涨���ȵ��ַ���ֱ���˳�
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
