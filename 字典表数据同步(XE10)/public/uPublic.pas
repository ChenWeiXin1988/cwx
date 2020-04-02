unit uPublic;

interface

uses Winapi.Windows, System.SysUtils;

//��ֹ�л����뷨������������     1.3.7.0
procedure ProcessMessage;
//д��־
procedure systemLog(Msg: string);

implementation

//1.3.7.0   ��ֹ�л����뷨������������
procedure ProcessMessage;
var
  Msg: TMsg;
begin
  if PeekMessage(Msg, 0, 0, 0, PM_REMOVE) then
  begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;
end;

procedure systemLog(Msg: string);
var
  F: TextFile;
  FileName: string;
  ExeRoad: string;
begin
  try
    ExeRoad := ExtractFilePath(ParamStr(0));
    if ExeRoad[Length(ExeRoad)] = '\' then
      SetLength(ExeRoad, Length(ExeRoad) - 1);
    if not DirectoryExists(ExeRoad + 'log') then
    begin
      CreateDir(ExeRoad + '\log');
    end;
    FileName := ExeRoad + '\log\DM_Log_' + FormatDateTime('YYYYMMDD', NOW) + '.txt';
    if not FileExists(FileName) then
    begin
      AssignFile(F, FileName);
      ReWrite(F);
    end
    else
      AssignFile(F, FileName);
    Append(F);
    Writeln(F, FormatDateTime('HH:NN:SS.zzz ', Now) + Msg);
    CloseFile(F);
  except
    //�����������е���,��������
    Exit;
  end;
end;

end.
