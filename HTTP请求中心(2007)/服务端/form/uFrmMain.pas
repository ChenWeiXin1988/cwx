unit uFrmMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, uServer;

type
  TfrmMain = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    FServer: TCenterServer;
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

uses uHttpEvent, uPublic, uVar;

{$R *.dfm}

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FServer:= TCenterServer.Create(GAppRunClass.RunPara.iHttpPort);
  FServer.RegHttpProc('cwx.heart', THttpEvent._Heart);
  FServer.RegHttpProc('cwx.servertime', THttpEvent._GetServerTime);
  GURL:= '/gateway.do';
  FServer.Start;
  SystemLog( 'FServer.Started');
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  if Assigned(FServer) then
    FreeAndNil(FServer);
end;

end.
