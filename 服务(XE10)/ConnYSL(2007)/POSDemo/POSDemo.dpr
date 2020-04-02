program POSDemo;

uses
  Forms,
  Unit1 in 'Unit1.pas' {FrmMain},
  uCRC16 in 'uCRC16.pas',
  UBuffer in 'UBuffer.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
