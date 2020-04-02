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
    memo1.Lines.Add('����ж�سɹ�')
  else
    memo1.Lines.Add('����ж��ʧ��');
  Memo1.Lines.Add('���ж�ط���ʱ�з���-1������Լ��Σ���ǿ�ƽ���������ж�ء�');
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
//    memo1.Lines.Add('error: δ����midas.dll');
//    Exit;
//  end;
//  if ShellExecute(handle, 'open',PChar(fnamePath), nil, nil, SW_SHOWNORMAL) < 32 then
////  if   WinExec(PChar(fname),0) < 31 then
//  begin
//   memo1.Lines.Add('error: Midas.dllע��ʧ��');
//   Exit;
//  end
//  else
//   memo1.Lines.Add('Midas.dllע��ɹ�');
  fnamePath :=  GetCurrentDir +'\ControlCenter.exe';
  if not FileExists(fnamePath) then
  begin
    memo1.Lines.Add('error: ControlCenter.exe');
    Exit;
  end;
  if InstallService('CenterService','CWX����',fnamePath) then
  begin
    memo1.Lines.Add('����װ�ɹ�');
    UpdateDes('CenterService','CWX����');
  end
  else
    memo1.Lines.Add('����װʧ��');
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
   Service := CreateService(SCManager,  //���
                    PChar(ServiceName), //��������
                    PChar(DisplayName), //��ʾ������
                    SERVICE_ALL_ACCESS, //�����������
                    SERVICE_WIN32_OWN_PROCESS or SERVICE_INTERACTIVE_PROCESS, //��������  or SERVICE_WIN32_OWN_PROCESS,//
                    SERVICE_AUTO_START, //�Զ���������
                    SERVICE_ERROR_IGNORE, //���Դ���
                    PChar(FileName),  //�������ļ���
                    nil,  //name of load ordering group (��������) &#39;LocalSystem&#39;
                    nil,  //��ǩ��ʶ��
                    nil,  //�����������
                    nil,  //�ʻ�(��ǰ)
                    nil); //����(��ǰ)

   Args := nil;
   if Service = 0 then exit;
   if StartService(Service, 0, Args) then
     memo1.Lines.Add(DisplayName+' �����Ѿ�����')
   else
     memo1.Lines.Add(DisplayName+' ��������ʧ�ܣ�');
   CloseServiceHandle(Service);
   CloseServiceHandle(SCManager);
  except on E: Exception do
    begin
      CloseServiceHandle(SCManager);
      Memo1.Lines.Add('ʧ��ԭ���ǣ�' + E.Message);
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
   SCManager := OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);//���SC���������
   if SCManager = 0 then Exit;
   try
     Service := OpenService(SCManager, PChar(ServiceName), SERVICE_ALL_ACCESS);

     //�����Ȩ�޴�ָ���������ķ���,�����ؾ��
     ss := ControlService(Service, SERVICE_CONTROL_STOP, ServiceStatus);
     Memo1.Lines.Add('ֹͣ��������' + BoolToStr(ss));

     //����������Ϳ�������,ֹͣ����, ServiceStatus ��������״̬
     ss := DeleteService(Service);
     Memo1.Lines.Add('ж�ط�������' + BoolToStr(ss));
     //��SC ManGer ��ɾ������
     CloseServiceHandle(Service);
     result:=true;
     //�رվ��,�ͷ���Դ
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
