unit uDelFiles;

interface

uses Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,  StdCtrls;

  const UM_LOG  = WM_USER + 1;   //日志记录

  function ListPath(iHandle:Thandle; sPath:string;dDate:TDateTime;OperType:byte=0):Integer;
  function GetFilesTime(sFilename: String; Timetype: Integer): TDateTime;

implementation

function ListPath(iHandle:Thandle; sPath:string;dDate:TDateTime;OperType:byte):Integer;
var
  r:TsearchRec;  
  ret:integer;  
  ds,d1,d2,d3:string;  
  cdt,chkd:Tdatetime;
  sStr : string;
  tcount : integer;
begin
  Result := -1;
  tcount := 0;
  if not OperType in [0,1] then Exit;

  ret:=findfirst(sPath+'\'+'*.*',faanyfile,r);
  while ret=0 do
  begin
    if r.attr=fadirectory then
    begin  
      if (r.name<>'.') and (r.Name<>'..') then  
      begin  
        //logs.lines.add('正在进入目录:'+r.name+'进行文件检查....');  
        ListPath(iHandle, sPath+'\'+r.name,dDate);
      end;  
    end  
    else
    begin  
       ds  := sPath+'\'+r.name;
       cdt := GetFilesTime(ds, 0);
       chkd:= dDate;
  
       d1:=datetimetostr(cdt);
       d2:=datetimetostr(GetFilesTime(ds, 1));
       d3:=datetimetostr(GetFilesTime(ds, 2));
  
       if cdt<chkd then  
       begin  
         case OperType of     //操作类型
           0: begin   //预览
             sStr := format('%.4d<%s>-Create[%s]Edit[%s]Access[%s]',[tcount + 1,
                                                                r.name,          //路径[%s]
                                                               d1,
                                                               d2,
                                                               d3]);
           end;
           1: begin   //执行操作
             sStr := format('%.4d<%s>-Create[%s]Edit[%s]Access[%s]',[tcount + 1,
                                                                r.name,     //路径[%s]  ds
                                                               d1,
                                                               d2,
                                                               d3]);
             deletefile(ds);
           end;
         end;
         if iHandle <> 0 then
         PostMessage(iHandle, UM_LOG, 0, Integer(sStr));
         tcount := tcount+1;
       end;

    end;
    application.ProcessMessages;
    ret:=findnext(r);
  end;
  findclose(r);
  Result := tcount;
end;
  
function GetFilesTime(sFilename: String; Timetype: Integer): TDateTime;
var  
  ffd: TWin32FindData;  
  dft: DWord;  
  lft, Time: TFileTime;  
  sHandle: THandle;  
begin  
  sHandle:= Windows.FindFirstFile(PChar(sFileName), ffd);  
  if (sHandle <>INVALID_HANDLE_VALUE) then  
    begin
      case Timetype of  
        0: Time:= ffd.ftCreationTime;       //创建时间
        1: Time:= ffd.ftLastWriteTime;      //最后修改时间
        2: Time:= ffd.ftLastAccessTime;     //最后访问时间
      end;
    Windows.FindClose(sHandle);  
    FileTimeToLocalFileTime(Time, lft);  
    FileTimeToDosDateTime(lft, LongRec(dft).HI, LongRec(dft).Lo);  
    Result:= FileDateToDateTime(dft);  
  end else Result:= 0;  
end;  

end.
