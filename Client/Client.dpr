program Client;

uses
  Vcl.Forms,
  uMainForm in 'uMainForm.pas' {MainForm},
  uUsersForm in 'uUsersForm.pas' {UsersForm},
  uMessageForm in 'uMessageForm.pas' {MessageForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TUsersForm, UsersForm);
  Application.CreateForm(TMessageForm, MessageForm);
  Application.Run;
end.
