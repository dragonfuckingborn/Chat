unit uMainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, IdBaseComponent,
  IdComponent, IdTCPConnection, IdTCPClient, IniFiles;

type
  TMainForm = class(TForm)
    LbIP: TLabel;
    EdtIP: TEdit;
    LbName: TLabel;
    EdtName: TEdit;
    BtnConnect: TButton;
    IdTCPClient: TIdTCPClient;
    procedure BtnConnectClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    Port:Integer;
  end;

Procedure IndySendText(Text:string);
Function IndyReadText:string;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses uUsersForm;

Function FindErrorConnect:Boolean;
begin
  Result:=False;
  if MainForm.IdTCPClient.Connected=False then
  begin
    Result:=True;
    ShowMessage('Потеря соединения с сервером. Работа программы не возможна.');
    MainForm.Close;
  end;
end;

Procedure IndySendText(Text:string);
var
	StringStream:TStringStream;
begin
  if FindErrorConnect=True then Exit;
    StringStream:=TStringStream.Create;
    StringStream.WriteString(Text);
    StringStream.Position:=0;
  MainForm.IdTCPClient.IOHandler.Write(StringStream, StringStream.Size, true);
    StringStream.Free;
end;

Function IndyReadText:string;
var
	StringStream:TStringStream;
begin
  if FindErrorConnect=True then Exit;
	StringStream:=TStringStream.Create;
	MainForm.IdTCPClient.IOHandler.ReadStream(StringStream);
	StringStream.Position:=0;
  Result:=StringStream.ReadString(StringStream.Size);
	StringStream.Free;
end;


procedure TMainForm.BtnConnectClick(Sender: TObject);
var
  ErrorStr:string;
begin
  if EdtIP.Text='' then
  begin
    ShowMessage('Введите IP');
    EdtIP.SetFocus;
    Exit;
  end;
  if EdtName.Text='' then
  begin
    ShowMessage('Введите имя');
    EdtName.SetFocus;
    Exit;
  end;
  if AnsiUpperCase(EdtName.Text)='ОБЩИЙ' then
  begin
    ShowMessage('Это имя зарезервировано');
    EdtName.SetFocus;
    Exit;
  end;
  BtnConnect.Enabled:=False;
  Application.ProcessMessages;
  IdTCPClient.Host:=EdtIP.Text;
  IdTCPClient.Port:=MainForm.Port;
  try
    IdTCPClient.Connect;
  Except
    ShowMessage('Ошибка подключения');
    BtnConnect.Enabled:=True;
    Exit;
  end;
  IndySendText('+'+EdtName.Text);
  ErrorStr:=IndyReadText;
  if ErrorStr='1' then
  begin
     ShowMessage('Это имя уже занято');
        BtnConnect.Enabled:=True;
       IdTCPClient.Disconnect;
    Exit;
  end;
  if ErrorStr='2' then
  begin
    ShowMessage('Сервер перегружен');
    BtnConnect.Enabled:=True;
    IdTCPClient.Disconnect;
    Exit;
  end;
  MainForm.Hide;
  UsersForm.Show;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
var
  Ini:TIniFile;
begin
  if IdTCPClient.Connected=True then
  begin
    IndySendText('-'+EdtName.Text);
      if IndyReadText<>'0' then ShowMessage('Ошибка соединения');
        IdTCPClient.Disconnect;
  end;
  Ini:=TIniFile.Create(ExtractFilePath(Application.ExeName)+'Config.ini');
  Ini.WriteString('Setting', 'IP', EdtIP.Text);
  Ini.WriteString('Setting', 'Name', EdtName.Text);
  Ini.WriteInteger('Setting', 'Port', MainForm.Port);
  Ini.Free;
end;

procedure TMainForm.FormShow(Sender: TObject);
var
 Ini:TIniFile;
begin
  Ini:=TIniFile.Create(ExtractFilePath(Application.ExeName)+'Config.ini');
    EdtIP.Text:=Ini.ReadString('Setting', 'IP', '');
     EdtName.Text:=Ini.ReadString('Setting', 'Name', '');
  MainForm.Port:=Ini.ReadInteger('Setting', 'Port', 1234);
   Ini.Free;
end;

end.
