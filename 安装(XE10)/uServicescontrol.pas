unit uServicescontrol;

interface
  uses Windows,Messages,SysUtils,Winsvc,Dialogs;

  function  CreateServices(Const SvrName,FilePath:String):Boolean;
  function  DeleteServices(Const SvrName: String):Boolean;
  function  StartServices(Const  SvrName:String):Boolean;
  function  StopServices(Const  SvrName:String):Boolean;
  function  QueryServiceStatu(Const SvrName:   String):String;


  implementation


  //��������
function StartServices(Const   SvrName:   String):   Boolean;
var
  a,b:SC_HANDLE;
  c:PChar;
begin
  Result:=False;
  a:=OpenSCManager(nil,nil,SC_MANAGER_ALL_ACCESS);
  if a <=0 then  Exit;
  b:=OpenService(a,PChar(SvrName),SERVICE_ALL_ACCESS);
  if b <=0  then  Exit;
  try
    Result:=StartService(b,0,c);
    CloseServiceHandle(b);
    CloseServiceHandle(a);
  except
    CloseServiceHandle(b);
    CloseServiceHandle(a);
    Exit;
  end;
end;


  //ֹͣ����
function   StopServices(Const   SvrName:   String):   Boolean;
var
  a,b:   SC_HANDLE;
  d:   TServiceStatus;
begin
  Result := False;
  a :=OpenSCManager(nil,nil,SC_MANAGER_ALL_ACCESS);
  if a <=0 then Exit;
  b:=OpenService(a,PChar(SvrName),SERVICE_ALL_ACCESS);
  if b <=0  then  Exit;
  try
    Result:=ControlService(b,SERVICE_CONTROL_STOP,d);
    CloseServiceHandle(a);
    CloseServiceHandle(b);
  except
    CloseServiceHandle(a);
    CloseServiceHandle(b);
    Exit;
  end;
end;


  //��ѯ��ǰ�����״̬
function  QueryServiceStatu(Const   SvrName:   String):   String;
var
  a,b:   SC_HANDLE;
  d:   TServiceStatus;
begin
  Result := 'δ��װ';
  a := OpenSCManager(nil,nil,SC_MANAGER_ALL_ACCESS);
  if a <=0 then  Exit;
  b := OpenService(a,PChar(SvrName),SERVICE_ALL_ACCESS);
  if  b  <= 0  then  Exit;
  try
    QueryServiceStatus(b,d);
    if   d.dwCurrentState      =   SERVICE_RUNNING   then
      Result   :=   '����'         //Run
    else   if   d.dwCurrentState      =   SERVICE_RUNNING   then
      Result   :=   'Wait'         //Runing
    else   if   d.dwCurrentState      =   SERVICE_START_PENDING then
      Result   :=   'Wait'         //Pause
    else   if   d.dwCurrentState      =   SERVICE_STOP_PENDING      then
      Result   :=   'ֹͣ'         //Pause
    else   if   d.dwCurrentState      =   SERVICE_PAUSED   then
      Result   :=   '��ͣ'         //Pause
    else   if   d.dwCurrentState      =   SERVICE_STOPPED   then
      Result   :=   'ֹͣ'      //Stop
    else   if   d.dwCurrentState      =   SERVICE_CONTINUE_PENDING      then
      Result   :=   'Wait'         //Pause
    else   if   d.dwCurrentState      =   SERVICE_PAUSE_PENDING   then
      Result   :=   'Wait';         //Pause
    CloseServiceHandle(a);
    CloseServiceHandle(b);
  except
    CloseServiceHandle(a);
    CloseServiceHandle(b);
    Exit;
  end;
end;


{��������}
function  CreateServices(Const SvrName,FilePath:   String):   Boolean;
var
  a,b:SC_HANDLE;
begin
  Result:=False;
  if  FilePath   =''   then   Exit;
  a   :=   OpenSCManager(nil,nil,SC_MANAGER_CREATE_SERVICE);
  if   a   <=   0   then   Exit;
  try
    b   :=   CreateService(a,
                           PChar(SvrName),
                           PChar(SvrName),
                           SERVICE_ALL_ACCESS,
                           SERVICE_INTERACTIVE_PROCESS   or   SERVICE_WIN32_OWN_PROCESS,
                           SERVICE_AUTO_START,SERVICE_ERROR_NORMAL,
                           PChar(FilePath),
                           nil,
                           nil,
                           nil,
                           nil,
                           nil);
    if   b   <=   0   then   begin
      ShowMessage(   SysErrorMessage(   GetlastError   ));
      Exit;
    end;
    CloseServiceHandle(a);
    CloseServiceHandle(b);
    Result   :=   True;
  except
    CloseServiceHandle(a);
    CloseServiceHandle(b);
    Exit;
  end;
end;


{ж�ط���}
function   DeleteServices(Const   SvrName:   String):   Boolean;
var
  a,b:SC_HANDLE;
begin
  Result:=False;
  a := OpenSCManager(nil,nil,SC_MANAGER_ALL_ACCESS);
  if a <= 0 then  Exit;
  b :=OpenService(a,PChar(SvrName),STANDARD_RIGHTS_REQUIRED);
  if b <= 0 then Exit;
  try
    Result := DeleteService(b);
    if not Result then
    ShowMessage(SysErrorMessage(GetlastError));
    CloseServiceHandle(b);
    CloseServiceHandle(a);
  except
    CloseServiceHandle(b);
    CloseServiceHandle(a);
    Exit;
  end;
end;
end.

