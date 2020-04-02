program Demo_YSL;

uses
  Forms,
  ufrmMain in 'frm\ufrmMain.pas' {frmMain},
  uPos_YSL in 'public\uPos_YSL.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
