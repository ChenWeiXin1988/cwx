unit uCRC8;

interface

uses
  SysUtils, Windows;

function GetDataCRC8(const ABlockData:pByte; ALen:Cardinal):Word;

implementation

var
  CRC8Tab : array[0..255] of Byte;  // CRC8快速计算查表
const
  GenPoly8: Byte = $8C;             // 低位先行


///////////////////////////////////////////////////////////
// 8位CRC：按位计算，速度最慢，占用空间最少
// 注：数据流是低位先行，与16位CRC相反
///////////////////////////////////////////////////////////
function CalCRC8(data, crc, genpoly: Byte): Byte;
var i: Integer;
begin
  // 方法1：摘自XMODEM协议, 模仿CRC16计算方法, 但是低位先行
  crc := crc xor data;
  for i:=0 to 7 do
    if (crc and $01) <> 0 then // 只测试最低位
      crc := (crc shr 1) xor genpoly // 最低位为1，移位和异或处理
    else crc := crc shr 1;           // 否则只移位（除2）
  Result := crc;
end;

procedure InitCRC8Tab(genpoly: DWORD);
var i: Integer;
begin
  for i:=0 to 255 do
    CRC8Tab[i] := CalCRC8(i,0,genpoly);
end;

///////////////////////////////////////////////////////////
// 8位CRC：通过查表快速计算，速度快，占用空间多
// 注：数据流是低位先行，与16位CRC相反
// 要预先生成CRC8Tab[256]查表数据
///////////////////////////////////////////////////////////
function QuickCRC8(data, crc: Byte): Word;
begin
  crc := CRC8Tab[crc xor data];
  Result := crc;
end;

function GetDataCRC8(const ABlockData:pByte; ALen:Cardinal):Word;
var
  I: Integer;
  bCRC: Byte;
  sCrc8 : string;
begin
  bCRC:= 0;
  for I := 0 to ALen-1 do
    {$IFDEF CHECKSUM}
    bCRC:= bCRC + PByte(DWORD(ABlockData)+I)^;
    {$ELSE}
    bCRC:= QuickCRC8(PByte(DWORD(ABlockData)+I)^, bCRC);
    {$ENDIF}

//  Result:= bCRC;  //直接返回单字节

  //以下是把单字节变为4位的10进制数字，然后前两位返回到 Word的高字节 后两位返回到 Word的低字节
  sCrc8 := format('%.4d',[bCRC]);  //CRC1
  Result := StrToIntDef(('$' + Copy(sCrc8, 1,2)), 0) * 256 +
            StrToIntDef(('$' + Copy(sCrc8, 3,2)), 0)
end;

initialization
  InitCRC8Tab(GenPoly8);

end.
