unit uMessageForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, IniFiles;

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
    procedure EdtTextKeyPress(Sender: TObject; var Key: Char);
    procedure EdtTextKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure RchEdtChange(Sender: TObject);
    procedure RchEdtMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
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

Procedure SentTextToRichEdit(From:string; Text:string; Color:TColor);
begin
  MessageForm.RchEdt.SelStart:=Length(MessageForm.RchEdt.Text);
  MessageForm.RchEdt.SelAttributes.Color:=Color;
  MessageForm.RchEdt.SelAttributes.Bold:=True;
  MessageForm.RchEdt.Lines.Add(From+' ('+DateTimeToStr(Now)+')');
  MessageForm.RchEdt.SelAttributes.Color:=clBlack;
  MessageForm.RchEdt.SelAttributes.Bold:=False;
  MessageForm.RchEdt.Lines.Add(Text);
  MessageForm.RchEdt.Lines.Add('');
  HideCaret(MessageForm.RchEdt.Handle);
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
          SentTextToRichEdit(FromText, Copy(Text, 1, AnsiPos('#', Text)-1), clRed);
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
     SentTextToRichEdit(MainForm.EdtName.Text, EdtText.Text, clBlue);
       EdtText.Clear;
  end else
  begin
        ShowMessage('Ошибка отправки сообщения');
  end;
  WaitResult:=False;
end;

procedure TMessageForm.EdtTextKeyPress(Sender: TObject; var Key: Char);
begin
    if Key='#' then Key:=#0;
  if Key='&' then Key:=#0;
end;

procedure TMessageForm.EdtTextKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
    if Key=VK_RETURN then BtnSend.Click;
end;
procedure TMessageForm.FormClose(Sender: TObject; var Action: TCloseAction);
var
 Ini:TIniFile;
begin
  Ini:=TIniFile.Create(ExtractFilePath(Application.ExeName)+'Config.ini');
  Ini.WriteBool('MessageForm', 'WindowState', WindowState=TWindowState.wsMaximized);
  if WindowState<>TWindowState.wsMaximized then
  begin
    Ini.WriteInteger('MessageForm', 'Left', MessageForm.Left);
    Ini.WriteInteger('MessageForm', 'Top', MessageForm.Top);
    Ini.WriteInteger('MessageForm', 'Height', MessageForm.Height);
    Ini.WriteInteger('MessageForm', 'Width', MessageForm.Width);
  end;
  Ini.Free;
  Tmr.Enabled:=False;
  while WaitResult=True do Sleep(100);
  IndySendText('!'+MainForm.EdtName.Text);
  if IndyReadText<>'0' then
  begin
    ShowMessage('Ошибка завершения диалога');
  end;
  UsersForm.Show;
end;

procedure TMessageForm.FormCreate(Sender: TObject);
begin
  WaitResult:=False;
end;

procedure TMessageForm.FormShow(Sender: TObject);
var
 Ini:TIniFile;
begin
  Ini:=TIniFile.Create(ExtractFilePath(Application.ExeName)+'Config.ini');
  MessageForm.Left:=Ini.ReadInteger('MessageForm', 'Left', MessageForm.Left);
  MessageForm.Top:=Ini.ReadInteger('MessageForm', 'Top', MessageForm.Top);
  MessageForm.Height:=Ini.ReadInteger('MessageForm', 'Height', MessageForm.Height);
  MessageForm.Width:=Ini.ReadInteger('MessageForm', 'Width', MessageForm.Width);
  if Ini.ReadBool('MessageForm', 'WindowState', False)=True then
    WindowState:=TWindowState.wsMaximized else
      WindowState:=TWindowState.wsNormal;
  Ini.Free;
  RchEdt.Clear;
  Tmr.Enabled:=True;
end;

procedure TMessageForm.RchEdtChange(Sender: TObject);
begin
  SendMessage(RchEdt.handle, WM_VSCROLL, SB_BOTTOM, 0);
  HideCaret(MessageForm.RchEdt.Handle);
end;

procedure TMessageForm.RchEdtMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  HideCaret(MessageForm.RchEdt.Handle);
end;

procedure TMessageForm.TmrTimer(Sender: TObject);
begin
  if WaitResult=True then Exit;
  WaitResult:=True;
  GetNewMessages;
  WaitResult:=False;
end;

end.
