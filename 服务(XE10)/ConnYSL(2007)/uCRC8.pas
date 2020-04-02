unit uCRC8;

interface

uses
  SysUtils, Windows;

function GetDataCRC8(const ABlockData:pByte; ALen:Cardinal):Word;

implementation

var
  CRC8Tab : array[0..255] of Byte;  // CRC8���ټ�����
const
  GenPoly8: Byte = $8C;             // ��λ����


///////////////////////////////////////////////////////////
// 8λCRC����λ���㣬�ٶ�������ռ�ÿռ�����
// ע���������ǵ�λ���У���16λCRC�෴
///////////////////////////////////////////////////////////
function CalCRC8(data, crc, genpoly: Byte): Byte;
var i: Integer;
begin
  // ����1��ժ��XMODEMЭ��, ģ��CRC16���㷽��, ���ǵ�λ����
  crc := crc xor data;
  for i:=0 to 7 do
    if (crc and $01) <> 0 then // ֻ�������λ
      crc := (crc shr 1) xor genpoly // ���λΪ1����λ�������
    else crc := crc shr 1;           // ����ֻ��λ����2��
  Result := crc;
end;

procedure InitCRC8Tab(genpoly: DWORD);
var i: Integer;
begin
  for i:=0 to 255 do
    CRC8Tab[i] := CalCRC8(i,0,genpoly);
end;

///////////////////////////////////////////////////////////
// 8λCRC��ͨ�������ټ��㣬�ٶȿ죬ռ�ÿռ��
// ע���������ǵ�λ���У���16λCRC�෴
// ҪԤ������CRC8Tab[256]�������
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

//  Result:= bCRC;  //ֱ�ӷ��ص��ֽ�

  //�����ǰѵ��ֽڱ�Ϊ4λ��10�������֣�Ȼ��ǰ��λ���ص� Word�ĸ��ֽ� ����λ���ص� Word�ĵ��ֽ�
  sCrc8 := format('%.4d',[bCRC]);  //CRC1
  Result := StrToIntDef(('$' + Copy(sCrc8, 1,2)), 0) * 256 +
            StrToIntDef(('$' + Copy(sCrc8, 3,2)), 0)
end;

initialization
  InitCRC8Tab(GenPoly8);

end.
