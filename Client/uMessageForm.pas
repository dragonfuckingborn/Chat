unit uMessageForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls;

type
  TMessageForm = class(TForm)
    RchEdt: TRichEdit;
    Pnl: TPanel;
    EdtText: TEdit;
    BtnSend: TButton;
    Tmr: TTimer;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure BtnSendClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure TmrTimer(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    UserName:string;
    WaitResult:Boolean;
  end;

var
  MessageForm: TMessageForm;

implementation

{$R *.dfm}

uses uUsersForm, uMainForm;

Procedure SentTextToRichEdit(From:string; Text:string);
begin
  MessageForm.RchEdt.SelStart:=Length(MessageForm.RchEdt.Text);
  MessageForm.RchEdt.Lines.Add(From+' ('+DateTimeToStr(Now)+')');
  MessageForm.RchEdt.SelAttributes.Color:=clBlack;
  MessageForm.RchEdt.SelAttributes.Bold:=False;
  MessageForm.RchEdt.Lines.Add(Text);
  MessageForm.RchEdt.Lines.Add('');
end;

Procedure GetNewMessages;
var
  Text:string;
  ToText, FromText:string;
begin
  IndySendText('@'+MainForm.EdtName.Text);
  Text:=IndyReadText;
  if Text<>'0' then
  begin
    while Text<>'' do
    begin
      ToText:=AnsiUpperCase(Copy(Text, 1, AnsiPos('&', Text)-1));
      Delete(Text, 1, AnsiPos('&', Text));
      FromText:=Copy(Text, 1, AnsiPos('&', Text)-1);
      Delete(Text, 1, AnsiPos('&', Text));
      if (ToText='ОБЩИЙ') or (ToText=AnsiUpperCase(MainForm.EdtName.Text)) then
      begin
        if AnsiUpperCase(FromText)<>AnsiUpperCase(MainForm.EdtName.Text) then
        begin
          SentTextToRichEdit(FromText, Copy(Text, 1, AnsiPos('#', Text)-1));
        end;
      end;
      Delete(Text, 1, AnsiPos('#', Text));
    end;
  end;
end;

procedure TMessageForm.BtnSendClick(Sender: TObject);
begin
  while WaitResult=True do Sleep(100);
  WaitResult:=True;
  IndySendText('='+UserName+'&'+MainForm.EdtName.Text+'&'+EdtText.Text);
  if IndyReadText='0' then
  begin
    SentTextToRichEdit(MainForm.EdtName.Text, EdtText.Text);
    EdtText.Clear;
  end else
  begin
    ShowMessage('Ошибка отправки сообщения');
  end;
  WaitResult:=False;
end;

procedure TMessageForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Tmr.Enabled:=False;
  UsersForm.Show;
end;

procedure TMessageForm.FormCreate(Sender: TObject);
begin
  WaitResult:=False;
end;

procedure TMessageForm.FormShow(Sender: TObject);
begin
  RchEdt.Clear;
  Tmr.Enabled:=True;
end;

procedure TMessageForm.TmrTimer(Sender: TObject);
begin
  if WaitResult=True then Exit;
  WaitResult:=True;
  GetNewMessages;
  WaitResult:=False;
end;

end.
