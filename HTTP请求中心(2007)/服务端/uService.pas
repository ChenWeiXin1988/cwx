unit uService;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, SvcMgr, Dialogs,
  uAppFactory;

type
  TCenterService = class(TService)
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
    procedure ServiceExecute(Sender: TService);
  private
    { Private declarations }
  public
    function GetServiceController: TServiceController; override;
    { Public declarations }
  end;

var
  CenterService: TCenterService;
  AppFactory: TAppFactory;

implementation

uses uPublic, uFrmMain, uVar;

{$R *.DFM}

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  CenterService.Controller(CtrlCode);
end;

function TCenterService.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TCenterService.ServiceExecute(Sender: TService);
begin
  while not Terminated do
  begin
    systemLog('ServiceExecute');
    Sleep(5000);
  end;
end;

procedure TCenterService.ServiceStart(Sender: TService; var Started: Boolean);
var
  sErr: string;
begin
  AppFactory:= TAppFactory.Create;
  AppFactory.Factory(sErr);
  Started:= True;
  systemLog('ServiceStart');
end;

procedure TCenterService.ServiceStop(Sender: TService; var Stopped: Boolean);
begin
  if Assigned(AppFactory) then
    FreeAndNil(AppFactory);
  Stopped:= True;
  systemLog('ServiceStop');
end;

end.
