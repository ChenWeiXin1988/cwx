program ControlCenter;

uses
  SvcMgr,
  uService in 'uService.pas' {CenterService: TService},
  uPublic in 'public\uPublic.pas',
  uHttpEvent in 'public\uHttpEvent.pas',
  uServer in 'public\uServer.pas',
  uVar in 'public\uVar.pas',
  uFrmMain in 'form\uFrmMain.pas' {frmMain},
  uAppFactory in 'public\uAppFactory.pas',
  uDelFiles in 'public\uDelFiles.pas';

{$R *.RES}

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
  Application.CreateForm(TCenterService, CenterService);
  Application.Run;
end.
