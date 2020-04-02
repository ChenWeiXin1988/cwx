unit Unit21;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,SvcMgr,winsvc,Registry;

type
  TForm21 = class(TForm)
    memo1: TMemo;
    btn1: TButton;
    btn2: TButton;
    procedure btn1Click(Sender: TObject);
    procedure btn2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
     function InstallService(ServiceName, DisplayName, FileName: string): boolean;
     function UninstallService(ServiceName: string):boolean;
     function UpdateDes(name,des :string):Boolean;
  end;
var
  Form21: TForm21;

implementation
    uses ShellAPI;
{$R *.dfm}

{ TForm21 }

procedure TForm21.btn1Click(Sender: TObject);
begin
  memo1.Clear;
  if UninstallService('CenterService') then
    memo1.Lines.Add('服务卸载成功')
  else
    memo1.Lines.Add('服务卸载失败');
  Memo1.Lines.Add('如果卸载服务时有返回-1，则多试几次，或强制结束进程再卸载。');
end;

procedure TForm21.btn2Click(Sender: TObject);
var
 fnamePath,ServiceName :string;
begin
  memo1.Clear;
  SetCurrentDir(ExtractFilePath(Forms.Application.exename));
  SetCurrentDir(GetCurrentDir);
//  fnamePath :=  GetCurrentDir +'\midas.dll';
//
//  if not FileExists(fnamePath) then
//  begin
//    memo1.Lines.Add('error: 未发现midas.dll');
//    Exit;
//  end;
//  if ShellExecute(handle, 'open',PChar(fnamePath), nil, nil, SW_SHOWNORMAL) < 32 then
////  if   WinExec(PChar(fname),0) < 31 then
//  begin
//   memo1.Lines.Add('error: Midas.dll注册失败');
//   Exit;
//  end
//  else
//   memo1.Lines.Add('Midas.dll注册成功');
  fnamePath :=  GetCurrentDir +'\ControlCenter.exe';
  if not FileExists(fnamePath) then
  begin
    memo1.Lines.Add('error: ControlCenter.exe');
    Exit;
  end;
  if InstallService('CenterService','CWX服务',fnamePath) then
  begin
    memo1.Lines.Add('服务安装成功');
    UpdateDes('CenterService','CWX服务');
  end
  else
    memo1.Lines.Add('服务安装失败');
end;

function TForm21.InstallService(ServiceName, DisplayName,
  FileName: string): boolean;
var
  SCManager,Service: THandle;
  Args: pchar;
  str :string;
begin
  Result := False;
  SCManager := OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
  if SCManager = 0 then Exit;
  try
   Service := CreateService(SCManager,  //句柄
                    PChar(ServiceName), //服务名称
                    PChar(DisplayName), //显示服务名
                    SERVICE_ALL_ACCESS, //服务访问类型
                    SERVICE_WIN32_OWN_PROCESS or SERVICE_INTERACTIVE_PROCESS, //服务类型  or SERVICE_WIN32_OWN_PROCESS,//
                    SERVICE_AUTO_START, //自动启动服务
                    SERVICE_ERROR_IGNORE, //忽略错误
                    PChar(FileName),  //启动的文件名
                    nil,  //name of load ordering group (载入组名) &#39;LocalSystem&#39;
                    nil,  //标签标识符
                    nil,  //相关性数组名
                    nil,  //帐户(当前)
                    nil); //密码(当前)

   Args := nil;
   if Service = 0 then exit;
   if StartService(Service, 0, Args) then
     memo1.Lines.Add(DisplayName+' 服务已经启动')
   else
     memo1.Lines.Add(DisplayName+' 服务启动失败！');
   CloseServiceHandle(Service);
   CloseServiceHandle(SCManager);
  except on E: Exception do
    begin
      CloseServiceHandle(SCManager);
      Memo1.Lines.Add('失败原因是：' + E.Message);
    end;
  end;
  Result := True;
end;

function TForm21.UninstallService(ServiceName: string): boolean;
var
   SCManager,Service: THandle;
   ServiceStatus: SERVICE_STATUS;
   ss: LongBool;
begin
  Result:=false;
   SCManager := OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);//获得SC管理器句柄
   if SCManager = 0 then Exit;
   try
     Service := OpenService(SCManager, PChar(ServiceName), SERVICE_ALL_ACCESS);

     //以最高权限打开指定服务名的服务,并返回句柄
     ss := ControlService(Service, SERVICE_CONTROL_STOP, ServiceStatus);
     Memo1.Lines.Add('停止服务结果：' + BoolToStr(ss));

     //向服务器发送控制命令,停止工作, ServiceStatus 保存服务的状态
     ss := DeleteService(Service);
     Memo1.Lines.Add('卸载服务结果：' + BoolToStr(ss));
     //从SC ManGer 中删除服务
     CloseServiceHandle(Service);
     result:=true;
     //关闭句柄,释放资源
   finally
     CloseServiceHandle(SCManager);
   end;
end;


function TForm21.UpdateDes(name, des: string): Boolean;
var 
  reg: TRegistry;
begin 
  reg := TRegistry.Create; 
  try
    with reg do begin 
      RootKey := HKEY_LOCAL_MACHINE; 
      if OpenKey('SYSTEM\CurrentControlSet\Services\'+Name,false) then
      begin 
        WriteString('Description',des); 
      end; 
      CloseKey; 
    end; 
  finally 
    reg.Free; 
  end; 
end;

end.
