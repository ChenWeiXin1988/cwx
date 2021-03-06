unit frmMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.Actions, Vcl.ActnList,
  Vcl.StdCtrls, Winapi.ShellAPI;

const
  GExeName = 'SyncServer';
  GServiceName = AnsiString('SyncServer');
  GDisPalyName = AnsiString('无感称重支付系统服务');
  GServiceDes  = AnsiString('无感称重支付系统服务');

type
  TForm1 = class(TForm)
    memo1: TMemo;
    btnQuery: TButton;
    btnCreate: TButton;
    btnStart: TButton;
    btnStop: TButton;
    btnDel: TButton;
    GroupBox1: TGroupBox;
    rbNet: TRadioButton;
    rbSc: TRadioButton;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    EdtExe: TEdit;
    EdtSvr: TEdit;
    procedure btnCreateClick(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure btnQueryClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure btnDelClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure rbClick(Sender: TObject);
  private
    { Private declarations }
    iChecked: Integer;  //0 NET 1 SC
    sExeName: string;   //EXE名称
    sSvrName: string;   //服务名称
  public
    { Public declarations }
    function Check(var sErr: string): Boolean;
  end;

var
  Form1: TForm1;

implementation

uses uServicescontrol;

{$R *.dfm}

procedure TForm1.btnCreateClick(Sender: TObject);
var
  sCmd, sErr: string;
  iRet: Integer;
begin
  if not Check(sErr) then
  begin
    ShowMessage(sErr);
    Exit;
  end;
  case iChecked of
    0: sCmd:= '/c '+ ExtractFilePath(Vcl.Forms.Application.exename)+ sExeName+ ' /install &pause';
    1: sCmd:= '/c sc create '+ sSvrName+ ' binPath= '+ ExtractFilePath(Vcl.Forms.Application.exename)+ sExeName+ ' &pause';
  end;
  shellexecute(handle, nil, 'cmd.exe', pchar(sCmd), nil, sw_normal);
end;

procedure TForm1.btnDelClick(Sender: TObject);
var
  sCmd, sErr: string;
begin
  if not Check(sErr) then
  begin
    ShowMessage(sErr);
    Exit;
  end;
  case iChecked of
    0: sCmd:= '/c '+ ExtractFilePath(Vcl.Forms.Application.exename)+ sExeName+ ' /uninstall &pause';
    1: sCmd:= '/c sc delete '+ sSvrName+ ' &pause';
  end;
  shellexecute(handle, nil, 'cmd.exe', pchar(sCmd), nil, sw_normal);
end;

procedure TForm1.btnQueryClick(Sender: TObject);
var
  sCmd, sErr: string;
begin
  if iChecked= 0 then
  begin
    sErr:= 'NET不支持,退出操作!';
    Exit;
  end;
  if not Check(sErr) then
  begin
    ShowMessage(sErr);
    Exit;
  end;
  sCmd:= '/c sc query '+ sSvrName+ ' &pause';
  shellexecute(handle, nil, 'cmd.exe', pchar(sCmd), nil, sw_normal);
end;

procedure TForm1.btnStartClick(Sender: TObject);
var
  sCmd, sErr: string;
begin
  if not Check(sErr) then
  begin
    ShowMessage(sErr);
    Exit;
  end;
  case iChecked of
    0: sCmd:= '/c net start '+ sSvrName+ ' &pause';
    1: sCmd:= '/c sc start '+ sSvrName+ ' &pause';
  end;
  shellexecute(handle, nil, 'cmd.exe', pchar(sCmd), nil, sw_normal);
end;

procedure TForm1.btnStopClick(Sender: TObject);
var
  sCmd, sErr: string;
begin
  if not Check(sErr) then
  begin
    ShowMessage(sErr);
    Exit;
  end;
  case iChecked of
    0: sCmd:= '/c net stop '+ sSvrName+ ' &pause';
    1: sCmd:= '/c sc stop '+ sSvrName+ ' &pause';
  end;
  shellexecute(handle, nil, 'cmd.exe', pchar(sCmd), nil, sw_normal);
end;

function TForm1.Check(var sErr: string): Boolean;
var
  _ExeName, _SvrName: string;
begin
  Result:= True;
  sErr:= '';
  _ExeName:= Trim(EdtExe.Text);
  _SvrName:= Trim(EdtSvr.Text);
  if _ExeName= '' then
    sErr:= 'EXE名称不能为空!';
  if _SvrName= '' then
    sErr:= sErr+ #13#10+ '服务名称不能为空!';
  if sErr= '' then
    Result:= True;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  iChecked:= 0;
end;

procedure TForm1.rbClick(Sender: TObject);
begin
  if rbNet.Checked then
    iChecked:= 0
  else
    iChecked:= 1;
end;

end.
