unit uMainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls, WinSock,
  IdBaseComponent, IdComponent, IdCustomTCPServer, IdTCPServer, IdContext, IniFiles;

type
  TMainForm = class(TForm)
    LbIP: TLabel;
    RchEdtLog: TRichEdit;
    IdTCPServer: TIdTCPServer;
    procedure FormShow(Sender: TObject);
    procedure IdTCPServerExecute(AContext: TIdContext);
    procedure RchEdtLogMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure RchEdtLogChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
    Port:Integer; //����
  end;

  //������ ������ � �������
  TClient=record
    Used:Boolean; //������������ ��� ���
    Name:string; //���
    Busy:Boolean; //�������� ��� ����� ��� ������
    Messages:string; //������� ���������
end;

var
  MainForm: TMainForm;

  Clients: array [1..50] of TClient; //������ ��������

implementation

{$R *.dfm}

Function GetLocalIP:String;
//������� ��������� ���������� IP ������
//https://delphisources.ru/pages/faq/base/get_own_ip.html
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
//������� ���������� ������ ������������  � ������
var
  I:Integer; //�������
begin
  //�� ��������� ������ ���
  Result:=0;
  //�������� �� ��������� �����
  for I := 1 to High(Clients) do
  begin
    //���� �� ������������ �� ����������
    if Clients[I].Used=False then Continue;
    //��������� ����� (���������� ������)
    if AnsiUpperCase(Clients[I].Name)=AnsiUpperCase(Name) then
    begin
      Result:=1; //�������� ��� ������ - ��� ��� ������
      Exit;
    end;
  end;
  //���������
  for I := 1 to High(Clients) do
  begin
    //���� ����� �������� �� ��������
    if Clients[I].Used=False then
    begin
      Clients[I].Name:=Name; //������ ���
      Clients[I].Used:=True; //��������� �� ����� ������
      Clients[I].Busy:=False; //������ ��������
      Clients[I].Messages:=''; //������� ��������� �����
      Exit;
    end;
  end;
  Result:=2; //�������� ��� ������ - ���� ���
end;

Function DeleteClient(Name:string):Boolean;
//������� �������� ������������
var
  I:Integer; //�������
begin
  //�� ��������� False
  Result:=False;
  //���������� ������
  for I := 1 to High(Clients) do
  begin
    //���� ����� �� ������������ �� ����������
    if Clients[I].Used=False then Continue;
    //���� ��� � ������ ������� � ������
    if AnsiUpperCase(Clients[I].Name)=AnsiUpperCase(Name) then
    begin
      Clients[I].Used:=False; //���������, ��� ����� ��������
      Result:=True; //�������
      Exit;
    end;
  end;
end;

Procedure IndySendText(AContext:TIdContext; Text:string);
//��������� �������� ��������� � ���������� �������� �����
var
	StringStream:TStringStream; //����� ������
begin
  //������� ����� ������
  StringStream:=TStringStream.Create;
  //������ � ����� ��� �����
  StringStream.WriteString(Text);
  //��������� ������� � 0
  StringStream.Position:=0;
  //���������� ��� ����� ������
  AContext.Connection.IOHandler.Write(StringStream, StringStream.Size, true);
  //����������� �������
  StringStream.Free;
end;

Function IndyReadText(AContext:TIdContext):string;
//������� ������ ��������� � ���������� �������� �����
var
	StringStream:TStringStream; //����� ������
begin
  //������� ����� ������
	StringStream:=TStringStream.Create;
  //�������� �����
	AContext.Connection.IOHandler.ReadStream(StringStream);
  //��������� ������� � 0
	StringStream.Position:=0;
  //��������� ����� ������� � result
  Result:=StringStream.ReadString(StringStream.Size);
  //����������� �������
	StringStream.Free;
end;

Function GetAllClients:string;
//������� ��������� ������ ��������
var
  I:Integer; //�������
begin
  Result:=''; //�� ��������� �����
  //���������� ������
  for I := 1 to High(Clients) do
  begin
    //���� �� ������������ �� ����������
    if Clients[I].Used=False then Continue;
    //���� ����� �� ����������
    if Clients[I].Busy=True then Continue;
    //��������� � Result ��� �������, ����������� #
    Result:=Result+Clients[I].Name+'#'; //# - �����������
  end;
end;

Function SendMessageClient(Text:string):Boolean;
//������� �������� ���������
var
  User:string; //�������
  I:Integer; //�������
begin
  Result:=False; //�� ��������� False
  //�������� ��� ������������
  User:=Copy(Text, 1, AnsiPos('&', Text)-1);
  //���������� ������
  for I := 1 to High(Clients) do
  begin
    //���� �� ������������ �� �������
    if Clients[I].Used=False then Continue;
    //���� �� ����� �� �������
    if Clients[I].Busy=False then Continue;
    //��������� ��� ������������
    if AnsiUpperCase(User)='�����' then
    begin
      //�������� ���� �������������
      Clients[I].Messages:=Clients[I].Messages+Text+'#';
      Result:=True; //�������
    end else
    begin
      //���������� ������ ��� ������������ � ���� � ���������
      if AnsiUpperCase(Clients[I].Name)=AnsiUpperCase(User) then
      begin
        //������ ��������� � �������
        Clients[I].Messages:=Clients[I].Messages+Text+'#';
        Result:=True; //�������
        Exit;
      end;
    end;
  end;
end;

Function GetMessages(Name:string):string;
//������� ��������� ���������
var
  I:Integer; //�������
begin
  Result:='0'; //�� ��������� ��� ���������
  //���������� ������
  for I := 1 to High(Clients) do
  begin
    //���� �� ������������ �� �������
    if Clients[I].Used=False then Continue;
    //���� �� ����� �� �������
    if Clients[I].Busy=False then Continue;
    //���������� ������ ��� � ������ � ������ �������
    if AnsiUpperCase(Clients[I].Name)=AnsiUpperCase(Name) then
    begin
      //��������� ���������� � Result
      Result:=Clients[I].Messages;
      //������� �������
      Clients[I].Messages:='';
      Exit;
    end;
  end;
end;

Function SetBusyUser(Name:string):Boolean;
//������� ��� ��������� ������� �����
var
  I:Integer; //�������
begin
  Result:=False; //�� ��������� False
  //���������� ������
  for I := 1 to High(Clients) do
  begin
    //���� �� ������������ �� �������
    if Clients[I].Used=False then Continue;
    //���� ��� ����� �� �������
    if Clients[I].Busy=True then Continue;
    //��������� ������ ����� � ������ � �������
    if AnsiUpperCase(Clients[I].Name)=AnsiUpperCase(Name) then
    begin
      Clients[I].Busy:=True; //���������� ������ �����
      Result:=True; //�������
      Exit;
    end;
  end;
end;

Function SetFreeUser(Name:string):Boolean;
//������� ��� ��������� ������� �����
var
  I:Integer; //�������
begin
  Result:=False; //�� ��������� False
  //���������� ������
  for I := 1 to High(Clients) do
  begin
    //���� �� ������������ �� �������
    if Clients[I].Used=False then Continue;
    //���� �������� �� �������
    if Clients[I].Busy=False then Continue;
    //���������� ������ ��� � ������ � ������� ������
    if AnsiUpperCase(Clients[I].Name)=AnsiUpperCase(Name) then
    begin
      Clients[I].Busy:=False; //������������� ������ ��������
      Result:=True; //�������
      Exit;
    end;
  end;
end;

Procedure SendMessageToLog(Text:string; Color:TColor);
//��������� �������� ��������� �� ����� (���)
begin
  //���������� ������� � �����
  MainForm.RchEdtLog.SelStart:=Length(MainForm.RchEdtLog.Text);
  //������ ���� ������
  MainForm.RchEdtLog.SelAttributes.Color:=Color;
  //��������� ������ � ������� � ����
  MainForm.RchEdtLog.Lines.Add('['+DateTimeToStr(Now)+'] '+Text);
  //�������� �������
  HideCaret(MainForm.RchEdtLog.Handle);
end;

//==============================================================================

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
//��������� ������ - ������� - ����� �������
var
 Ini:TIniFile; //��� ���������� ��� ���������� � ������� Ini
begin
  //������� ���������� � ��������� ���� ��� ����������
  Ini:=TIniFile.Create(ExtractFilePath(Application.ExeName)+'Config.ini');
  //��������� ������ �����: ��� ���������� ��� �� ������ �����
  Ini.WriteBool('MainForm', 'WindowState', WindowState=TWindowState.wsMaximized);
  if WindowState<>TWindowState.wsMaximized then
  begin
    //��������� ��������� ����� �� ��� X
    Ini.WriteInteger('MainForm', 'Left', MainForm.Left);
    //��������� ��������� ����� �� ��� Y
    Ini.WriteInteger('MainForm', 'Top', MainForm.Top);
    //��������� ������ �����
    Ini.WriteInteger('MainForm', 'Height', MainForm.Height);
    //��������� ������ �����
    Ini.WriteInteger('MainForm', 'Width', MainForm.Width);
  end;
  //��������� ����
  Ini.WriteInteger('Setting', 'Port', MainForm.Port);
  //����������� �������
  Ini.Free;
end;

procedure TMainForm.FormShow(Sender: TObject);
//��������� ������ - ������� - ��������� �����
var
 Ini:TIniFile; //��� ���������� ��� ���������� � ������� Ini
begin
  //������� ���������� � ��������� ���� ��� ��������
  Ini:=TIniFile.Create(ExtractFilePath(Application.ExeName)+'Config.ini');
  //��������� ��������� ����� �� ��� X
  MainForm.Left:=Ini.ReadInteger('MainForm', 'Left', MainForm.Left);
  //��������� ��������� ����� �� ��� Y
  MainForm.Top:=Ini.ReadInteger('MainForm', 'Top', MainForm.Top);
  //��������� ������ �����
  MainForm.Height:=Ini.ReadInteger('MainForm', 'Height', MainForm.Height);
  //��������� ������ �����
  MainForm.Width:=Ini.ReadInteger('MainForm', 'Width', MainForm.Width);
  //��������� ������ �����: ��� ���������� ��� �� ������ �����
  if Ini.ReadBool('MainForm', 'WindowState', False)=True then
    WindowState:=TWindowState.wsMaximized else
      WindowState:=TWindowState.wsNormal;
  //��������� ����
  MainForm.Port:=Ini.ReadInteger('Setting', 'Port', 1234);
  //����������� �������
  Ini.Free;

  //�������� ���� IP ��� �����������
  LbIP.Caption:=GetLocalIP;
  //������ ����
  IdTCPServer.DefaultPort:=MainForm.Port;
  //������������ ������
  IdTCPServer.Active:=True;
  //������ ���������
  SendMessageToLog('������ �������, �������� �����������...', clBlue);
  //������ ������� - ��������� ����������
  HideCaret(RchEdtLog.Handle);
end;

procedure TMainForm.IdTCPServerExecute(AContext: TIdContext);
//��������� ������ - ������� - �� ������ ������ ���������� �� �������
var
  Text:string; //�������� ������ �� �������
  Code:Integer;  //�������� ����� ������� �� �������
begin
  //�������� �����
  Text:=IndyReadText(AContext);

  //������������ ��������� ������� (������ ������)
  if Text[1]='+' then //���� - ������ �� ���������� ������ �������
  begin
    //������� ��������� ������
    Delete(Text, 1, 1);
    //��������� ������ ������� � �������� ��� ������
    Code:=AddClient(Text);
    //���������� �����
    IndySendText(AContext, IntToStr(Code));
    //���� ������ ��� �� ����� ���
    if Code=0 then
    begin
      //����� ���
      SendMessageToLog('������ '+Text+' ���������', clGreen)
    end;
  end;

  if Text[1]='-' then //����� - ������ �� �������� �������
  begin
    //������� ��������� ������
    Delete(Text, 1, 1);
    //������� �������
    if DeleteClient(Text)=True then
    begin
      //�������
      IndySendText(AContext, '0');
      //����� ���
      SendMessageToLog('������ '+Text+' ��������', clRed);
    end else
    begin
      //������
      IndySendText(AContext, '10');
      //����� ���
      SendMessageToLog('������ '+Text+' �� ��������', clRed)
    end;
  end;

  if Text[1]='*' then //��������� - ������ �� ������ ��������
  begin
    //������ ������ �������� ��������
    //������: User1#User2#User3 ����������� #
    IndySendText(AContext, GetAllClients);
  end;

  if Text[1]='=' then //����� - ���������� ��������� � �������
  begin
    //������� ��������� ������
    Delete(Text, 1, 1);
    //������ ��������� � ������� � ���������� ����� � �����������: 0 - �������, 1 - ������
    if SendMessageClient(Text)=True then IndySendText(AContext, '0') else
      IndySendText(AContext, '1');
  end;

  if Text[1]='@' then //������ - �������� ��� ���������
  begin
    //������� ��������� ������
    Delete(Text, 1, 1);
    //���������� ��������� ��� �������
    //����� ���������� ���� "0" ���� ��������� � ������������ #
    IndySendText(AContext, GetMessages(Text));
  end;

  if Text[1]='?' then //������ - ���������� ������ �����
  begin
    //������� ��������� ������
    Delete(Text, 1, 1);
    //������������� ������ � ���������� �����: 0 - �������, 1 - ������
    if SetBusyUser(Text)=True then IndySendText(AContext, '0') else
      IndySendText(AContext, '1');
  end;

  if Text[1]='!' then //����������� - ����� ������ �����
  begin
    //������� ��������� ������
    Delete(Text, 1, 1);
    //������������� ������ � ���������� �����: 0 - �������, 1 - ������
    if SetFreeUser(Text)=True then IndySendText(AContext, '0') else
      IndySendText(AContext, '1');
  end;
end;

procedure TMainForm.RchEdtLogChange(Sender: TObject);
//��������� ������ - ������� - ��������� ������ � richedit
begin
  //������ ���� - ��������� ����������
  SendMessage(RchEdtLog.handle, WM_VSCROLL, SB_BOTTOM, 0);
  //������ ������� - ��������� ����������
  HideCaret(RchEdtLog.Handle);
end;

procedure TMainForm.RchEdtLogMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
//��������� ������ - ������� - ���������� ���� � richedit
begin
  //������ ������� - ��������� ����������
  HideCaret(RchEdtLog.Handle);
end;

end.
