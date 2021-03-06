program SyncServer;

uses
  Vcl.SvcMgr,
  uServices in 'uServices.pas' {Sync_Server: TService},
  uDM_DAC in 'FireDAC\uDM_DAC.pas' {DM: TDataModule},
  uThread in 'thread\uThread.pas',
  uFactory in 'public\uFactory.pas',
  uVar in 'public\uVar.pas',
  uObj in 'uObj\uObj.pas',
  uFrmMain in 'forms\uFrmMain.pas' {FormMain},
  uPublic in 'public\uPublic.pas',
  uSQL in 'public\uSQL.pas',
  uPos_YSL in 'com\uPos_YSL.pas';

{$R *.RES}

var
  sErr: string;

begin
  // Windows 2003 Server requires StartServiceCtrlDispatcher to be
  // called before CoRegisterClassObject, which can be called indirectly
  // by Application.Initialize. TServiceApplication.DelayInitialize allows
  // Application.Initialize to be called from TService.Main (after
  // StartServiceCtrlDispatcher has been called).
  //
  // Delayed initialization of the Application object may affect
  // events which then occur prior to initialization, such as
  // TService.OnCreate. It is only recommended if the ServiceApplication
  // registers a class object with OLE and is intended for use with
  // Windows 2003 Server.
  //
  // Application.DelayInitialize := True;
  //
  if not Application.DelayInitialize or Application.Installing then
    Application.Initialize;
  {$IFNDEF DEBUG}
  Application.CreateForm(TSync_Server, Sync_Server);
  Application.Run;
  {$ELSE}
//  AppFactory := TAppFactory.Create;
//  if AppFactory.Factory(sErr) then
//    Application.CreateForm(TFormMain, FormMain);
//  Application.Run;
//  AppFactory.Destroy;
  {$ENDIF}
end.
