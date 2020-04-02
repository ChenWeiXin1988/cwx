unit uVar;

interface

uses uObj, uThread, uDM_DAC, System.SysUtils, System.IniFiles, Vcl.Forms;

type
  TAppParam= class
  public
    class function AppPath: string;   // 路径
    class function AppName: string;   // 程序名
    class function AppVer: string;    // 版本
  end;

  TFilePath= class(TAppParam)
  public
    class function IniFile: string;
  end;

  TRunParam= record
    sConnectionName: string;          //数据库连接名
    sRemoteUrl: string;               //连接远程服务URL
    iHttpType: Integer;               //0 http(默认) 1 https
  end;

  TAppRunClass= class
  private
    FRunParam: TRunParam;
  public
    FMeals : TMeals;                  //营业时段
    FDBThread: TDatabaseThread;       //数据库处理线程
    FHTTPThread: THttpThread;         //HTTP处理线程
    FCOMThread: TComThread;           //串口处理模块
    FDM    : TDM;                     //数据处理模块
    constructor Create;
    destructor Destroy; override;

    //设置数据库连接
    function InitDBConnection(sCode: string): Boolean;

    //读取ini
    function ReadParam : Boolean;               //读取基础参数

    //缓存
    function InitDBOBJ:Boolean;                 //初始化数据库对象

    //线程类
    function InitThread(asub:boolean):boolean;  //初始化线程
    function DestroyThread:Boolean;             //销毁线程
  published
    property RunParam : TRunParam read FRunParam write FRunParam;
    property dm : TDM read FDM write FDM;
  end;

var
  GAppRunClass : TAppRunClass;

implementation

{ TAppRunClass }

constructor TAppRunClass.Create;
begin
  FMeals:= TMeals.create;
end;

destructor TAppRunClass.Destroy;
begin
  if Assigned(FMeals) then
    FreeAndNil(FMeals);
  if Assigned(FDM) then
    FreeAndNil(FDM);
  inherited;
end;

function TAppRunClass.DestroyThread: Boolean;
begin
  Result := False;
  try
    if Assigned(FDBThread) then
    begin
      FDBThread.Terminate;
      FDBThread.WaitFor;
      FreeAndNil(FDBThread);
    end;
    if Assigned(FHTTPThread) then
    begin
      FHTTPThread.Terminate;
      FHTTPThread.WaitFor;
      FreeAndNil(FHTTPThread);
    end;
    if Assigned(FCOMThread) then
    begin
      FCOMThread.Terminate;
      FCOMThread.WaitFor;
      FreeAndNil(FCOMThread);
    end;
    Result := True;
  finally
    //
  end;
end;

function TAppRunClass.InitDBConnection(sCode: string): Boolean;
begin
  Result:= False;
  try
    FDM:= TDM.Create(nil);
    FDM.FDConnection.ConnectionDefName:= sCode;
    Result:= True;
  except
    on e: Exception do
      Exit;
  end;
end;

function TAppRunClass.InitDBOBJ: Boolean;
begin
  Result := True;
  try
    try
      Result := Result and FMeals.LoadFromDB('');
    finally
      //
    end;
  except
    Result := false;
  end;
end;

function TAppRunClass.InitThread(asub: boolean): boolean;
begin
  Result := false;
  try
    FDBThread := TDatabaseThread.Create();
    FHTTPThread:= THttpThread.Create();
    FCOMThread:= TComThread.Create();
    Result := True;
  except
    //
  end;
end;

function TAppRunClass.ReadParam: Boolean;
var
  sFile : string;
  sIni : TIniFile;
begin
  Result := False;
  sFile := TFilePath.IniFile;
  if FileExists(sFile) then
  begin
    sIni := TIniFile.Create(sFile);
    try
      //数据库连接名
      FRunParam.sConnectionName := sIni.ReadString('Params', 'sConnectionName', '');
      //连接服务URL
      FRunParam.sRemoteUrl      := sIni.ReadString('Params', 'sRemoteUrl', '');
      //HTTP类型 默认0
      FRunParam.iHttpType       := sIni.ReadInteger('Params', 'iHttpType', 0);
      Result := True;
    finally
      FreeAndNil(sIni);
    end;
  end;
end;

{ TAppParam }

class function TAppParam.AppName: string;
begin
  Result := ExtractFileName(Application.ExeName);
end;

class function TAppParam.AppPath: string;
begin
  Result := ExtractFilePath(Application.ExeName);
end;

class function TAppParam.AppVer: string;
begin
  //
end;

{ TFilePath }

class function TFilePath.IniFile: string;
begin
  Result := AppPath + 'System.ini';
end;

end.
