unit uAppFactory;

interface

uses
  SysUtils, Forms, Windows, DateUtils;

type
  TAppFactory= class
  private
    //
  protected
    function CreateMainForm(var sErr: string): Boolean; virtual;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    function Factory(var sErr: string): Boolean; virtual;
  end;

implementation

uses uVar, uDelFiles, uFrmMain, uPublic;

{ TAppFactory }

constructor TAppFactory.Create;
var
  sPath: string;
  dDateTime: TDateTime;
begin
  GAppRunClass:= TAppRunClass.Create;
  {删除15以前的日志文件}
  try
    dDateTime:= Now- 15;
    sPath:= TFilePath.AppPath+ 'log';
    ListPath(0, sPath, dDateTime, 1);
  except
    //
  end;
end;

function TAppFactory.CreateMainForm(var sErr: string): Boolean;
begin
  Result:= False;
  try
    if not Assigned(frmMain) then
      Application.CreateForm(TfrmMain, frmMain);
    Result:= True;
  except
    on e: Exception do
    begin
      sErr:= 'Err:创建主窗体失败 '+ e.message;
    end;
  end;
end;

destructor TAppFactory.Destroy;
begin
  if Assigned(frmMain) then
    frmMain.Destroy;
  if Assigned(GAppRunClass) then
    FreeAndNil(GAppRunClass);
  inherited;
end;

function TAppFactory.Factory(var sErr: string): Boolean;
begin
  Result:= False;
  while not Result do
  begin
    ProcessMessage;
    if not GAppRunClass.ReadPara then
    begin
      sErr:= '系统参数读取错误, 系统无法正常启动!';
      Sleep(2000);
      Continue;
    end;
    if not CreateMainForm(sErr) then
    begin
      sErr:= '业务窗体创建失败, 系统无法正常启动!';
      Sleep(2000);
      Continue;
    end;
    Result:= True;
  end;
end;

end.
