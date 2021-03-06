library ConnYSL;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

uses
  SysUtils,
  Classes,
  unt_objects in 'unt_objects.pas',
  UBuffer in 'UBuffer.pas',
  uCRC8 in 'uCRC8.pas',
  InterfaceDll in 'InterfaceDll.pas';

{$R *.res}
exports
  YSL_OpenPort,         //打开端口
  YSL_ClosePort,        //关闭端口
  YSL_ReadCard,         //0x01 读卡
  YSL_Consume,          //0x02 消费
  YSL_ConsumeEx,        //0x02 消费 交易未决
  YSL_Query;            //0x03 交易确认

begin
end.
