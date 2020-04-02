unit uPos_YSL;

interface

uses
  Windows, SysUtils, qjson, IniFiles, Classes, Dialogs;



const
  External_YSL_POS_DLL = 'ConnYSL.dll';


  function YSL_OpenPort(ComPort: Byte): Boolean; stdcall
    ; external External_YSL_POS_DLL;
  function YSL_ClosePort: Boolean; stdcall
    ; external External_YSL_POS_DLL;
  function YSL_ReadCard(var cCard: string; var Balance: Currency): Byte; stdcall
    ; external External_YSL_POS_DLL;
  function YSL_Consume(cCard: string; cPay: Currency; iFlow: Byte; var Balance: Currency): Byte; stdcall
    ; external External_YSL_POS_DLL;
  function YSL_Query(cCard: string; cPay: Currency; iFlow: Byte; var Balance: Currency): Byte; stdcall
    ; external External_YSL_POS_DLL;
    
type
  Opr_Cmd= (order_Read, order_Pay, order_Query);

  TFourLong = packed record
  case integer of
    0 : (iCardinal : Cardinal);
    1 : (i4 : byte;
         i3 : byte;
         i2 : byte;
         i1 : byte);
  end;

  TYSLPos = class(TObject)
  private
    Opr       : Opr_Cmd;
  protected
    function OpenPort(AComPort:Byte): Boolean;
    procedure ClosePort;
    function change(iIn:integer; Opr: Opr_Cmd): string;
  public
    constructor Create(AComPort: Word);
    destructor Destroy; override;
    //0x01 读卡
    function ReadCard(var cCard: string; var Balance: Currency; var sErr: string): Byte;
    //0x02 消费
    function Consume(cCard: string; cPay: Currency; iFlow: Byte; var Balance: Currency; var sErr: string): Byte;
    //0x03 交易确认
    function Query(cCard: string; cPay: Currency; iFlow: Byte; var Balance: Cardinal; var sErr: string): Byte;
  end;

implementation

{ TBSJKReader }

function TYSLPos.change(iIn: integer; Opr: Opr_Cmd): string;
begin
  case Opr of
    order_Read: begin
      case iIn of
        0:    Result:= '成功';
        1:    Result:= '无效';
        2:    Result:= '无效';
        4:    Result:= '无卡';
        5:    Result:= '卡禁用';
        6:    Result:= '需要验证密码';
        10:   Result:= '卡已损坏';
        105:  Result:= '设备不可用';
      end;
    end;
    order_Pay: begin
      case iIn of
        0:    Result:= '成功';
        1:    Result:= '支付失败';
        3:    Result:= '消费限额';
        4:    Result:= '交易未决';
        5:    Result:= '卡禁用';
        6:    Result:= '需要密码';
        10:   Result:= '卡损坏';
        14:   Result:= '余额不足';
        105:  Result:= '设备不可用';
        111:  Result:= '设备结算区已满，需要同步';
      end;
    end;
    order_Query: begin
      case iIn of
        0:    Result:= '交易成功入账';
        1:    Result:= '交易失败';
      end;
    end;
  end;
end;

procedure TYSLPos.ClosePort;
begin
  YSL_ClosePort;
end;

function TYSLPos.Consume(cCard: string; cPay: Currency; iFlow: Byte;
  var Balance: Currency; var sErr: string): Byte;
begin
  sErr := '';
  try
    Result:= YSL_Consume(cCard, cPay, iFlow, Balance);
  finally
    sErr := change(Result, order_Pay);
  end;
end;

constructor TYSLPos.Create(AComPort: Word);
begin
  OpenPort(AComPort);
end;

destructor TYSLPos.Destroy;
begin
  ClosePort;
  inherited;
end;

function TYSLPos.OpenPort(AComPort:Byte): Boolean;
var
  I, iErrCode: Integer;
begin
  Result:= False;
  if AComPort=0 then Exit;
  Result := YSL_OpenPort(AComPort);
end;

function TYSLPos.Query(cCard: string; cPay: Currency; iFlow: Byte;
  var Balance: Cardinal; var sErr: string): Byte;
begin
  sErr := '';
  try
//    Result:= YSL_Consume(cCard, cPay, iFlow, Balance);
  finally
    sErr := change(Result, order_Query);
  end;
end;

function TYSLPos.ReadCard(var cCard: string; var Balance: Currency; var sErr: string): Byte;
begin
  sErr := '';
  try
    Result := YSL_ReadCard(cCard, Balance);
  finally
    sErr := change(Result, order_Read);
  end;
end;

end.
