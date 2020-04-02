program ClientDemo;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form21},
  uVar in 'uVar.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm21, Form21);
  Application.Run;
end.
