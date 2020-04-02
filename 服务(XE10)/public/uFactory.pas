unit uFactory;

interface

uses System.SysUtils, Vcl.Forms;

type
  TAppFactory = class
  private
    //
  protected
    function CreateMainForm(var sErr: string) : boolean; virtual;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    function Factory(var sErr: string) : Boolean; virtual;
  end;

implementation

uses uVar, uFrmMain, uPublic;

{ TAppFactory }

constructor TAppFactory.Create;
begin
  GAppRunClass := TAppRunClass.Create;
end;

function TAppFactory.CreateMainForm(var sErr: string): boolean;
begin
  try
    Application.CreateForm(TFormMain,FormMain);
    result := true;
  except
    sErr := 'Err:����������ʧ��';
  end;
end;

destructor TAppFactory.Destroy;
begin
  try
    if GAppRunClass <> nil then
    begin
      GAppRunClass.DestroyThread;
      FreeAndNil(GAppRunClass);
    end;
  finally

  end;
  inherited;
end;

function TAppFactory.Factory(var sErr: string): Boolean;
begin
  Result := False;
  while not Result do
  begin
    ProcessMessage;
    if not GAppRunClass.ReadParam then
    begin
      sErr :='Params Read Error!';
      Sleep(2000);
      Continue;
    end;
    if not GAppRunClass.InitDBConnection(GAppRunClass.RunParam.sConnectionName) then
    begin
      sErr :='Database Connect Error!';
      Sleep(2000);
      Continue;
    end;
    if not GAppRunClass.InitDBOBJ then
    begin
      sErr := 'Cache Data Error!';
      Sleep(2000);
      Continue;
    end;
    if not GAppRunClass.InitThread(False) then
    begin
      sErr := 'Threads Start Error!';
      Sleep(2000);
      Continue;
    end;
    Result := True;
  end;
end;

end.
