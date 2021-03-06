unit uServices;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.SvcMgr, Vcl.Dialogs, uFactory;

type
  TSync_Server = class(TService)
    procedure ServiceAfterInstall(Sender: TService);
    procedure ServiceAfterUninstall(Sender: TService);
    procedure ServiceBeforeInstall(Sender: TService);
    procedure ServiceBeforeUninstall(Sender: TService);
    procedure ServiceContinue(Sender: TService; var Continued: Boolean);
    procedure ServiceCreate(Sender: TObject);
    procedure ServiceExecute(Sender: TService);
    procedure ServicePause(Sender: TService; var Paused: Boolean);
    procedure ServiceShutdown(Sender: TService);
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
    procedure ServiceDestroy(Sender: TObject);
  private
    { Private declarations }
  public
    function GetServiceController: TServiceController; override;
    { Public declarations }
  end;

var
  Sync_Server: TSync_Server;
  AppFactory: TAppFactory;

implementation

uses uDM_DAC, uPublic, uFrmMain, uVar;

{$R *.dfm}

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  Sync_Server.Controller(CtrlCode);
end;

function TSync_Server.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TSync_Server.ServiceAfterInstall(Sender: TService);
begin
  //安装服务之后调用的方法；
  systemLog('ServiceAfterInstall');
end;

procedure TSync_Server.ServiceAfterUninstall(Sender: TService);
begin
  //服务卸载之后调用的方法；
  systemLog('ServiceAfterUninstall');
end;

procedure TSync_Server.ServiceBeforeInstall(Sender: TService);
begin
  //服务安装之前调用的方法
  systemLog('ServiceBeforeInstall');
end;

procedure TSync_Server.ServiceBeforeUninstall(Sender: TService);
begin
  //服务卸载之前调用的方法；
  systemLog('ServiceBeforeUninstall');
end;

procedure TSync_Server.ServiceContinue(Sender: TService;
  var Continued: Boolean);
begin
  //服务暂停继续调用的方法；
  systemLog('ServiceContinue');
end;

procedure TSync_Server.ServiceCreate(Sender: TObject);
begin
  //
  systemLog('ServiceCreate');
end;

procedure TSync_Server.ServiceDestroy(Sender: TObject);
begin
  //
  systemLog('ServiceDestroy');
end;

//执行服务开始调用的方法
procedure TSync_Server.ServiceExecute(Sender: TService);
begin
  while not Terminated do
  begin
    systemLog('ServiceExecute');
    ServiceThread.ProcessRequests(False);
    Sleep(1000);
  end;
end;

procedure TSync_Server.ServicePause(Sender: TService; var Paused: Boolean);
begin
  //暂停时调用的方法
end;

procedure TSync_Server.ServiceShutdown(Sender: TService);
begin
  //关闭时调用的方法；
end;

//启动服务调用的方法
procedure TSync_Server.ServiceStart(Sender: TService; var Started: Boolean);
var
  sErr: string;
begin
  AppFactory:= TAppFactory.Create;
  if not AppFactory.Factory(sErr) then
    systemLog(sErr);
  Started:= True;
end;

//停止服务调用的方法
procedure TSync_Server.ServiceStop(Sender: TService; var Stopped: Boolean);
begin
  Stopped:= True;
  if Assigned(FormMain) then
    FormMain.Destroy;
  if Assigned(AppFactory) then
    AppFactory.Destroy;
end;

end.
