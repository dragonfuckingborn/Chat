unit uMainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls, WinSock,
  IdBaseComponent, IdComponent, IdCustomTCPServer, IdTCPServer, IdContext;

type
  TMainForm = class(TForm)
    LbIP: TLabel;
    RchEdtLog: TRichEdit;
    IdTCPServer: TIdTCPServer;
    procedure FormShow(Sender: TObject);
    procedure IdTCPServerExecute(AContext: TIdContext);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  TClient=record
    Used:Boolean;
    Name:string;
    Messages:string;
end;

var
  MainForm: TMainForm;

  Clients: array [1..50] of TClient;

implementation

{$R *.dfm}

Function GetLocalIP:String;
const
  WSVer=$101;
var
  wsaData:TWSAData;
  P:PHostEnt;
  Buf: array [0..127] of Char;
begin
  Result:='';
  if WSAStartup(WSVer, wsaData)=0 then
  begin
    if GetHostName(@Buf, 128)=0 then
    begin
      P:=GetHostByName(@Buf);
      if P<>nil then Result:=iNet_ntoa(PInAddr(p^.h_addr_list^)^);
    end;
    WSACleanup;
  end;
end;

Function AddClient(Name:string):Integer;
var
  I:Integer;
begin
  Result:=0;
  for I := 1 to High(Clients) do
  begin
    if Clients[I].Used=False then Continue;
    if AnsiUpperCase(Clients[I].Name)=AnsiUpperCase(Name) then
    begin
      Result:=1;
      Exit;
    end;
  end;

  //Добавляем
  for I := 1 to High(Clients) do
  begin
    if Clients[I].Used=False then
    begin
      Clients[I].Name:=Name;
      Clients[I].Used:=True;
      Clients[I].Messages:='';
      Exit;
    end;
  end;
  Result:=2;
end;

Function DeleteClient(Name:string):Boolean;
var
  I:Integer;
begin
  Result:=False;
  for I := 1 to High(Clients) do
  begin
    if Clients[I].Used=False then Continue;
    if AnsiUpperCase(Clients[I].Name)=AnsiUpperCase(Name) then
    begin
      Clients[I].Used:=False;
      Result:=True;
      Exit;
    end;
  end;
end;

Procedure IndySendText(AContext:TIdContext; Text:string);
var
	StringStream:TStringStream;
begin
  StringStream:=TStringStream.Create;
  StringStream.WriteString(Text);
  StringStream.Position:=0;
  AContext.Connection.IOHandler.Write(StringStream, StringStream.Size, true);
  StringStream.Free;
end;

Function IndyReadText(AContext:TIdContext):string;
var
	StringStream:TStringStream;
begin
	StringStream:=TStringStream.Create;
	AContext.Connection.IOHandler.ReadStream(StringStream);
	StringStream.Position:=0;
  Result:=StringStream.ReadString(StringStream.Size);
	StringStream.Free;
end;

Function GetAllClients:string;
var
  I:Integer;
begin
  Result:='';
  for I := 1 to High(Clients) do
  begin
    if Clients[I].Used=False then Continue;
    Result:=Result+Clients[I].Name+'#';
  end;
end;

Function SendMessageClient(Text:string):Boolean;
var
  User:string;
  I:Integer;
begin
  Result:=False;
  User:=Copy(Text, 1, AnsiPos('&', Text)-1);
  for I := 1 to High(Clients) do
  begin
    if Clients[I].Used=False then Continue;
    if AnsiUpperCase(User)='ОБЩИЙ' then
    begin
      Clients[I].Messages:=Clients[I].Messages+Text+'#';
      Result:=True;
    end else
    begin
      if AnsiUpperCase(Clients[I].Name)=AnsiUpperCase(User) then
      begin
        Clients[I].Messages:=Clients[I].Messages+Text+'#';
        Result:=True;
        Exit;
      end;
    end;
  end;
end;

Function GetMessages(Name:string):string;
var
  I:Integer;
begin
  Result:='0';
  for I := 1 to High(Clients) do
  begin
    if Clients[I].Used=False then Continue;
    if AnsiUpperCase(Clients[I].Name)=AnsiUpperCase(Name) then
    begin
      Result:=Clients[I].Messages;
      Clients[I].Messages:='';
      Exit;
    end;
  end;
end;

Procedure SendMessageToLog(Text:string);
begin
  MainForm.RchEdtLog.SelStart:=Length(MainForm.RchEdtLog.Text);
  MainForm.RchEdtLog.Lines.Add('['+DateTimeToStr(Now)+'] '+Text);
end;


procedure TMainForm.FormShow(Sender: TObject);
begin
  LbIP.Caption:=GetLocalIP;
  IdTCPServer.DefaultPort:=1234;
  IdTCPServer.Active:=True;
  HideCaret(RchEdtLog.Handle);
end;

procedure TMainForm.IdTCPServerExecute(AContext: TIdContext);
var
  Text:string;
  Code:Integer;
begin
  Text:=IndyReadText(AContext);

  if Text[1]='+' then
  begin
    Delete(Text, 1, 1);
    Code:=AddClient(Text);
    IndySendText(AContext, IntToStr(Code));
    if Code=0 then
    begin
      SendMessageToLog('Клиент '+Text+' подключен')
    end;
  end;

  if Text[1]='-' then
  begin
    Delete(Text, 1, 1);
    if DeleteClient(Text)=True then
    begin
      IndySendText(AContext, '0');
      SendMessageToLog('Клиент '+Text+' отключен');
    end else
    begin
      IndySendText(AContext, '10');
      SendMessageToLog('Клиент '+Text+' не отключен')
    end;
  end;

  if Text[1]='*' then
  begin
    IndySendText(AContext, GetAllClients);
  end;

  if Text[1]='=' then
  begin
    Delete(Text, 1, 1);
    if SendMessageClient(Text)=True then IndySendText(AContext, '0') else
      IndySendText(AContext, '1');
  end;

  if Text[1]='@' then
  begin
    Delete(Text, 1, 1);
    IndySendText(AContext, GetMessages(Text));
  end;
end;

end.
