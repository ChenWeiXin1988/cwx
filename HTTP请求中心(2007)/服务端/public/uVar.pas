unit uVar;

interface

uses
  SysUtils, Forms, IniFiles;

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

  //运行参数
  TRunParam = record
    iHttpPort  : Integer;
    iSockPort  : Integer;
  end;

  TAppRunClass = class
  private
    FRunParam : TRunParam;                       //运行参数 从ini文件或数据库中读取
  public
    constructor Create;
    destructor Destroy; override;
    //读取基础数据
    function ReadPara : Boolean;               //读取基础参数
  published
    property RunPara : TRunParam read FRunParam write FRunParam ;
  end;

var
  GAppRunClass: TAppRunClass;

implementation

{ TAppParam }

class function TAppParam.AppName: string;
begin
  Result := ExtractFileName(Application.ExeName);
end;

class function TAppParam.AppPath: string;
begin
  Result := ExtractFilePath(ParamStr(0));
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

{ TAppRunClass }

constructor TAppRunClass.Create;
begin
  //
end;

destructor TAppRunClass.Destroy;
begin

  inherited;
end;

function TAppRunClass.ReadPara: Boolean;
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
      FRunParam.iHttpPort     := sIni.ReadInteger('SYSTEM','iHttpPort',5000);
      FRunParam.iSockPort     := sIni.ReadInteger('SYSTEM','iSockPort',5500);
      Result := True;
    finally
      FreeAndNil(sIni);
    end;
  end;
end;

end.
