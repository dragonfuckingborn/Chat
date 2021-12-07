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
    Port:Integer; //Номер порта
  end;

//Объявляем публичные процедуры для других юнитов
Procedure IndySendText(Text:string);
Function IndyReadText:string;

Const
  SeparatorOne=#1;
  SeparatorTwo=#2;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses uUsersForm;

Function FindErrorConnect:Boolean;
//функция проверки соединения с сервером
begin
  Result:=False; //по умолчанию False
  //проверка наличия соединения
  if MainForm.IdTCPClient.Connected=False then
  begin
    Result:=True; //Есть ошибка
    //Показываем сообщение
    ShowMessage('Потеря соединения с сервером. Работа программы не возможна.');
    //Закрываем главную форму (и приложение в целом)
    MainForm.Close;
  end;
end;

Procedure IndySendText(Text:string);
//функция отправки сообщения с поддержкой русского языка
var
	StringStream:TStringStream; //текстовый поток
begin
  //проверяем наличие соединения, в противном случае выходим
  if FindErrorConnect=True then Exit;
  //создаем поток
  StringStream:=TStringStream.Create;
  //загружаем переменную в поток
  StringStream.WriteString(Text);
  //устанавливаем позицию в 0
  StringStream.Position:=0;
  //отсылаем поток
  MainForm.IdTCPClient.IOHandler.Write(StringStream, StringStream.Size, true);
  //освобождаем ресурсы
  StringStream.Free;
end;

Function IndyReadText:string;
//функция приема сообщений с поддержкой русского языка
var
	StringStream:TStringStream; //текстовый поток
begin
  //проверяем наличие соединения, в противном случае выходим
  if FindErrorConnect=True then Exit;
  //создаем поток
	StringStream:=TStringStream.Create;
  //получаем поток от сервера
	MainForm.IdTCPClient.IOHandler.ReadStream(StringStream);
  //устанавливаем позицию в 0
	StringStream.Position:=0;
  //загружаем поток в переменную Result
  Result:=StringStream.ReadString(StringStream.Size);
  //освобождаем ресурсы
	StringStream.Free;
end;

//==============================================================================

procedure TMainForm.BtnConnectClick(Sender: TObject);
//Процедура класса - событие - нажатие кнопки Подключиться
var
  ErrorStr:string; //Переменная для хранения ошибки
begin
  //если пользователь не ввел IP то уведомляем
  if EdtIP.Text='' then
  begin
    //выводим сообщение
    ShowMessage('Введите IP');
    //Фокус переводим на это поле
    EdtIP.SetFocus;
    Exit;
  end;
  //если пользователь не ввел имя то уведомляем
  if EdtName.Text='' then
  begin
    //выводим сообщение
    ShowMessage('Введите имя');
    //фокус переводим на это поле
    EdtName.SetFocus;
    Exit;
  end;
  //сравнение КАПСОМ - если имя равно Общий, то это недопустимо
  if AnsiUpperCase(EdtName.Text)='ОБЩИЙ' then
  begin
    //выводим сообщение
    ShowMessage('Это имя зарезервировано');
    //фокус переводим на это поле
    EdtName.SetFocus;
    Exit;
  end;
  //Выключаем кнопку на время соединения
  BtnConnect.Enabled:=False;
  //позволяем системе выполнить учередь сообщений (в том числе перерисовать экран)
  Application.ProcessMessages; 
  //Задаем IP для подключения
  IdTCPClient.Host:=EdtIP.Text;
  //Указываем потр для подключения
  IdTCPClient.Port:=MainForm.Port;
  //Подключаемся
  try //Перехватываем ошибки
    IdTCPClient.Connect;
  Except
    //Если есть ошибки подключения то выходим
    ShowMessage('Ошибка подключения');
    //Включаем назад кнопку
    BtnConnect.Enabled:=True;
    Exit;
  end;
  //Отправляем запрос на регистрацию имени
  IndySendText('+'+EdtName.Text);
  //Получаем ответ от сервера
  ErrorStr:=IndyReadText;
  //Обрабатываем ошибки
  if ErrorStr='1' then //Дублирование имени
  begin
    //Выводим сообщение
    ShowMessage('Это имя уже занято');
    //включаем кнопку
    BtnConnect.Enabled:=True;
    //отключаемся от сервера
    IdTCPClient.Disconnect;
    Exit;
  end;
  if ErrorStr='2' then //Максимальное число клиентов достигнуто
  begin
    //выводим сообщение
    ShowMessage('Сервер перегружен');
    //включаем кнопку
    BtnConnect.Enabled:=True;
    //отключаемся от сервера
    IdTCPClient.Disconnect;
    Exit;
  end;
  //Скрыли текущую форму
  MainForm.Hide;
  //Показали форму с пользователями в модальном режиме
  UsersForm.Show;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
//Процедура класса - событие - закрытие формы
var
  Ini:TIniFile; //тип переменной для сохранения в формате Ini
begin
  //если есть соединенние с сервером, то
  if IdTCPClient.Connected=True then
  begin
    //Уведомляем сервер об отключении
    IndySendText('-'+EdtName.Text);
    //Получаем ответ от сервера
    if IndyReadText<>'0' then ShowMessage('Ошибка соединения');
    //Отключаемся
    IdTCPClient.Disconnect;
  end;

  //Сохраняем настройки
  //Создаем переменную и указываем путь для сохранения
  Ini:=TIniFile.Create(ExtractFilePath(Application.ExeName)+'Config.ini');
  //сохраняем IP
  Ini.WriteString('Setting', 'IP', EdtIP.Text);
  //Сохраняем имя
  Ini.WriteString('Setting', 'Name', EdtName.Text);
  //сохраняем порт
  Ini.WriteInteger('Setting', 'Port', MainForm.Port);
  //Освобождаем ресурсы
  Ini.Free;
end;

procedure TMainForm.FormShow(Sender: TObject);
//Процедура класса - событие - показ формы
var
 Ini:TIniFile; //тип переменной для сохранения в формате Ini
begin
  //Загружаем настройки
  //Создаем переменную и указываем путь для загрузки
  Ini:=TIniFile.Create(ExtractFilePath(Application.ExeName)+'Config.ini');
  //загружаем IP
  EdtIP.Text:=Ini.ReadString('Setting', 'IP', '');
  //Загружаем имя
  EdtName.Text:=Ini.ReadString('Setting', 'Name', '');
  //Загружаем порт
  MainForm.Port:=Ini.ReadInteger('Setting', 'Port', 1234);
  //Освобождаем ресурсы
  Ini.Free;
end;

end.
