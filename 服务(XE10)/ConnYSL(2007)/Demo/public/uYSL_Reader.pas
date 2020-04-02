unit uYSL_Reader;

interface

uses
  Windows, SysUtils, qjson, IniFiles, Classes, Dialogs;

const
  External_YSL_POS_DLL = 'ConnYSL.dll';

  function YSL_OpenPort(ComPort: Byte): Boolean; stdcall
    ; external External_YSL_POS_DLL;
  function YSL_ClosePort: Boolean; stdcall
    ; external External_YSL_POS_DLL;
  function YSL_ReadCard(var cCard, Balance: Cardinal): Byte; stdcall
    ; external External_YSL_POS_DLL;
  function YSL_Consume(cCard, cPay: Cardinal; iFlow: Byte; var Balance: Cardinal): Byte; stdcall
    ; external External_YSL_POS_DLL;
  function YSL_Query(cCard, cPay: Cardinal; iFlow: Byte; var Balance: Cardinal): Byte; stdcall
    ; external External_YSL_POS_DLL;
type
  TFourLong = packed record
  case integer of
    0 : (iCardinal : Cardinal);
    1 : (i4 : byte;
         i3 : byte;
         i2 : byte;
         i1 : byte);
  end;

  TYSLReader = class(TObject)
  private
    //
  protected
    function OpenPort(AComPort:Byte): Boolean;
    procedure ClosePort;
    function change(iIn:integer): string;
  public
    constructor Create(AComPort: Word);
    destructor Destroy; override;
    //0x01 读卡
    function ReadCard(var cCard, Balance: Cardinal; var sErr: string): Byte;
    //0x02 消费
    function Consume(cCard, cPay: Cardinal; iFlow: Byte; var Balance: Cardinal; var sErr: string): Byte;
    //0x03 交易确认
    function Query(cCard, cPay: Cardinal; iFlow: Byte; var Balance: Cardinal; var sErr: string): Byte;
  end;

implementation

{ TBSJKReader }

function TYSLReader.change(iIn: integer): string;
begin
  //
end;

procedure TYSLReader.ClosePort;
begin
  YSL_ClosePort;
end;

function TYSLReader.Consume(cCard, cPay: Cardinal; iFlow: Byte;
  var Balance: Cardinal; var sErr: string): Byte;
begin
  sErr := '';
  try
    Result:= YSL_Consume(cCard, cPay, iFlow, Balance);
  finally
    sErr := change(Result);
  end;
end;

constructor TYSLReader.Create(AComPort: Word);
begin
  OpenPort(AComPort);
end;

destructor TYSLReader.Destroy;
begin
  ClosePort;
  inherited;
end;

function TYSLReader.OpenPort(AComPort:Byte): Boolean;
var
  I, iErrCode: Integer;
begin
  Result:= False;
  if AComPort=0 then Exit;
  Result := YSL_OpenPort(AComPort);
end;

function TYSLReader.Query(cCard, cPay: Cardinal; iFlow: Byte;
  var Balance: Cardinal; var sErr: string): Byte;
begin
  sErr := '';
  try
    Result:= YSL_Consume(cCard, cPay, iFlow, Balance);
  finally
    sErr := change(Result);
  end;
end;

function TYSLReader.ReadCard(var cCard, Balance: Cardinal; var sErr: string): Byte;
begin
  sErr := '';
  try
    Result := YSL_ReadCard(cCard, Balance);
  finally
    sErr := change(Result);
  end;
end;

end.
