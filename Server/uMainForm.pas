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
    Port:Integer; //Порт
  end;

  //Запись данных о клиенте
  TClient=record
    Used:Boolean; //Используется или нет
    Name:string; //Имя
    Busy:Boolean; //Свободен или занят для поиска
    Messages:string; //Очередь сообщений
end;

var
  MainForm: TMainForm;

  Clients: array [1..50] of TClient; //Массив клиентов

implementation

{$R *.dfm}

Function GetLocalIP:String;
//Функция получения локального IP адреса
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
//Функция добавления нового пользователя  в список
var
  I:Integer; //счетчик
begin
  //По умолчанию ошибок нет
  Result:=0;
  //Проверка на занятость имени
  for I := 1 to High(Clients) do
  begin
    //Если не используется то игнорируем
    if Clients[I].Used=False then Continue;
    //Сравнение имени (сравниваем КАПСОМ)
    if AnsiUpperCase(Clients[I].Name)=AnsiUpperCase(Name) then
    begin
      Result:=1; //Условный код ошибки - имя уже занято
      Exit;
    end;
  end;
  //Добавляем
  for I := 1 to High(Clients) do
  begin
    //Если место свободно то занимаем
    if Clients[I].Used=False then
    begin
      Clients[I].Name:=Name; //Задаем имя
      Clients[I].Used:=True; //Указываем то место занято
      Clients[I].Busy:=False; //Клиент свободен
      Clients[I].Messages:=''; //Очередь сообщений пуста
      Exit;
    end;
  end;
  Result:=2; //Условный код ошибки - мест нет
end;

Function DeleteClient(Name:string):Boolean;
//Функция удаления пользователя
var
  I:Integer; //счетчик
begin
  //По умолчанию False
  Result:=False;
  //Перебираем список
  for I := 1 to High(Clients) do
  begin
    //Если место не используется то игнорируем
    if Clients[I].Used=False then Continue;
    //Если имя в списке совпало с нужным
    if AnsiUpperCase(Clients[I].Name)=AnsiUpperCase(Name) then
    begin
      Clients[I].Used:=False; //Указываем, что место свободно
      Result:=True; //Успешно
      Exit;
    end;
  end;
end;

Procedure IndySendText(AContext:TIdContext; Text:string);
//Процедура отправки сообщений с поддержкой русского языка
var
	StringStream:TStringStream; //Поток текста
begin
  //Создаем поток текста
  StringStream:=TStringStream.Create;
  //Вносим в поток наш текст
  StringStream.WriteString(Text);
  //Указываем позицию в 0
  StringStream.Position:=0;
  //Отправляем как поток данных
  AContext.Connection.IOHandler.Write(StringStream, StringStream.Size, true);
  //Освобождаем ресурсы
  StringStream.Free;
end;

Function IndyReadText(AContext:TIdContext):string;
//Функция приема сообщений с поддержкой русского языка
var
	StringStream:TStringStream; //Поток текста
begin
  //Создаем поток текста
	StringStream:=TStringStream.Create;
  //Получаем поток
	AContext.Connection.IOHandler.ReadStream(StringStream);
  //Указываем позицию в 0
	StringStream.Position:=0;
  //Полученый поток заносим в result
  Result:=StringStream.ReadString(StringStream.Size);
  //Освобождаем ресурсы
	StringStream.Free;
end;

Function GetAllClients:string;
//Функция получения списка клиентов
var
  I:Integer; //счетчик
begin
  Result:=''; //По умолчанию пусто
  //Перебираем список
  for I := 1 to High(Clients) do
  begin
    //Если не используется то игнорируем
    if Clients[I].Used=False then Continue;
    //Если занят то игнорируем
    if Clients[I].Busy=True then Continue;
    //Добавляем в Result имя клиента, разделитель #
    Result:=Result+Clients[I].Name+'#'; //# - разделитель
  end;
end;

Function SendMessageClient(Text:string):Boolean;
//функция отправки сообщения
var
  User:string; //Адресат
  I:Integer; //Счетчик
begin
  Result:=False; //По умолчанию False
  //Получаем имя пользователя
  User:=Copy(Text, 1, AnsiPos('&', Text)-1);
  //перебираем список
  for I := 1 to High(Clients) do
  begin
    //если не используется то игнорим
    if Clients[I].Used=False then Continue;
    //если не занят то игнорим
    if Clients[I].Busy=False then Continue;
    //проверяем имя пользователя
    if AnsiUpperCase(User)='ОБЩИЙ' then
    begin
      //Отправка всем пользователям
      Clients[I].Messages:=Clients[I].Messages+Text+'#';
      Result:=True; //Успешно
    end else
    begin
      //Сравниваем КАПСОМ имя пользователя в базе с адресатом
      if AnsiUpperCase(Clients[I].Name)=AnsiUpperCase(User) then
      begin
        //ставим сообщение в очередь
        Clients[I].Messages:=Clients[I].Messages+Text+'#';
        Result:=True; //успешно
        Exit;
      end;
    end;
  end;
end;

Function GetMessages(Name:string):string;
//Функция получения сообщений
var
  I:Integer; //счетчик
begin
  Result:='0'; //по умолчанию нет сообщений
  //перебираем список
  for I := 1 to High(Clients) do
  begin
    //если не используется то игнорим
    if Clients[I].Used=False then Continue;
    //если не занят то игнорим
    if Clients[I].Busy=False then Continue;
    //сравниваем КАПСОМ имя в списке с именем запроса
    if AnsiUpperCase(Clients[I].Name)=AnsiUpperCase(Name) then
    begin
      //Сообщения отправляем в Result
      Result:=Clients[I].Messages;
      //Очищаем очередь
      Clients[I].Messages:='';
      Exit;
    end;
  end;
end;

Function SetBusyUser(Name:string):Boolean;
//Функция для установки статуса Занят
var
  I:Integer; //счетчик
begin
  Result:=False; //по умолчанию False
  //перебираем список
  for I := 1 to High(Clients) do
  begin
    //если не используется то игнорим
    if Clients[I].Used=False then Continue;
    //если уже занят то игнорим
    if Clients[I].Busy=True then Continue;
    //Сравнение КАПСОМ имени в списке с искомым
    if AnsiUpperCase(Clients[I].Name)=AnsiUpperCase(Name) then
    begin
      Clients[I].Busy:=True; //Установили статус Занят
      Result:=True; //Успешно
      Exit;
    end;
  end;
end;

Function SetFreeUser(Name:string):Boolean;
//Функция для установки статуса Занят
var
  I:Integer; //счетчик
begin
  Result:=False; //по умолчанию False
  //перебираем список
  for I := 1 to High(Clients) do
  begin
    //если не используется то игнорим
    if Clients[I].Used=False then Continue;
    //если свободен то игнорим
    if Clients[I].Busy=False then Continue;
    //Сравниваем КАПСОМ имя в списке с искомым именем
    if AnsiUpperCase(Clients[I].Name)=AnsiUpperCase(Name) then
    begin
      Clients[I].Busy:=False; //Устанавливаем статус Свободен
      Result:=True; //Успешно
      Exit;
    end;
  end;
end;

Procedure SendMessageToLog(Text:string; Color:TColor);
//Процедура отправки сообщения на экран (лог)
begin
  //Перемещаем каретку в конец
  MainForm.RchEdtLog.SelStart:=Length(MainForm.RchEdtLog.Text);
  //задаем цвет текста
  MainForm.RchEdtLog.SelAttributes.Color:=Color;
  //добавляем строку с текстом и дату
  MainForm.RchEdtLog.Lines.Add('['+DateTimeToStr(Now)+'] '+Text);
  //скрываем каретку
  HideCaret(MainForm.RchEdtLog.Handle);
end;

//==============================================================================

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
//Процедура класса - событие - форма закрыта
var
 Ini:TIniFile; //тип переменной для сохранения в формате Ini
begin
  //Создаем переменную и указываем путь для сохранения
  Ini:=TIniFile.Create(ExtractFilePath(Application.ExeName)+'Config.ini');
  //Сохраняем статус формы: или нормальная или на полный экран
  Ini.WriteBool('MainForm', 'WindowState', WindowState=TWindowState.wsMaximized);
  if WindowState<>TWindowState.wsMaximized then
  begin
    //Сохраняем положение формы по оси X
    Ini.WriteInteger('MainForm', 'Left', MainForm.Left);
    //Сохраняем положение формы по оси Y
    Ini.WriteInteger('MainForm', 'Top', MainForm.Top);
    //Сохраняем высоту формы
    Ini.WriteInteger('MainForm', 'Height', MainForm.Height);
    //Сохраняем ширину формы
    Ini.WriteInteger('MainForm', 'Width', MainForm.Width);
  end;
  //Сохранили порт
  Ini.WriteInteger('Setting', 'Port', MainForm.Port);
  //Освобождаем ресурсы
  Ini.Free;
end;

procedure TMainForm.FormShow(Sender: TObject);
//Процедура класса - событие - появление формы
var
 Ini:TIniFile; //тип переменной для сохранения в формате Ini
begin
  //Создаем переменную и указываем путь для загрузки
  Ini:=TIniFile.Create(ExtractFilePath(Application.ExeName)+'Config.ini');
  //Загружаем положение формы по оси X
  MainForm.Left:=Ini.ReadInteger('MainForm', 'Left', MainForm.Left);
  //Загружаем положение формы по оси Y
  MainForm.Top:=Ini.ReadInteger('MainForm', 'Top', MainForm.Top);
  //Загружаем высоту формы
  MainForm.Height:=Ini.ReadInteger('MainForm', 'Height', MainForm.Height);
  //Загружаем ширину формы
  MainForm.Width:=Ini.ReadInteger('MainForm', 'Width', MainForm.Width);
  //Загружаем статус формы: или нормальная или на полный экран
  if Ini.ReadBool('MainForm', 'WindowState', False)=True then
    WindowState:=TWindowState.wsMaximized else
      WindowState:=TWindowState.wsNormal;
  //Загрузили порт
  MainForm.Port:=Ini.ReadInteger('Setting', 'Port', 1234);
  //Освобождаем ресурсы
  Ini.Free;

  //Получили свой IP для отображения
  LbIP.Caption:=GetLocalIP;
  //Задали порт
  IdTCPServer.DefaultPort:=MainForm.Port;
  //Активировали сервер
  IdTCPServer.Active:=True;
  //Вывели сообщение
  SendMessageToLog('Сервер запущен, ожидание подключений...', clBlue);
  //Скрыть каретку - украшение интерфейса
  HideCaret(RchEdtLog.Handle);
end;

procedure TMainForm.IdTCPServerExecute(AContext: TIdContext);
//Процедура класса - событие - на сервер пришла информация от клиента
var
  Text:string; //хранение текста от клиента
  Code:Integer;  //хранение кодов ответов от функций
begin
  //Получили текст
  Text:=IndyReadText(AContext);

  //Обрабатываем служебные команды (первый символ)
  if Text[1]='+' then //плюс - запрос на добавление нового клиента
  begin
    //Удаляем служебный символ
    Delete(Text, 1, 1);
    //Добавляем нового клиента и получаем код ошибки
    Code:=AddClient(Text);
    //Отправляем ответ
    IndySendText(AContext, IntToStr(Code));
    //Если ошибок нет то пишем лог
    if Code=0 then
    begin
      //Пишем лог
      SendMessageToLog('Клиент '+Text+' подключен', clGreen)
    end;
  end;

  if Text[1]='-' then //минус - запрос на удаление клиента
  begin
    //Удаляем служебный символ
    Delete(Text, 1, 1);
    //удаляем клиента
    if DeleteClient(Text)=True then
    begin
      //Успешно
      IndySendText(AContext, '0');
      //Пишем лог
      SendMessageToLog('Клиент '+Text+' отключен', clRed);
    end else
    begin
      //Ошибка
      IndySendText(AContext, '10');
      //Пишем лог
      SendMessageToLog('Клиент '+Text+' не отключен', clRed)
    end;
  end;

  if Text[1]='*' then //звездочка - запрос на список клиентов
  begin
    //Выдали список активных клиентов
    //формат: User1#User2#User3 разделитель #
    IndySendText(AContext, GetAllClients);
  end;

  if Text[1]='=' then //равно - постановка сообщения в очередь
  begin
    //Удаляем служебный символ
    Delete(Text, 1, 1);
    //Ставим сообщение в очередь и отправляем ответ с результатом: 0 - успешно, 1 - ошибка
    if SendMessageClient(Text)=True then IndySendText(AContext, '0') else
      IndySendText(AContext, '1');
  end;

  if Text[1]='@' then //собака - получить все сообщения
  begin
    //Удаляем служебный символ
    Delete(Text, 1, 1);
    //Отправляем сообщения при наличии
    //будет отправлено либо "0" либо сообщения с разделителем #
    IndySendText(AContext, GetMessages(Text));
  end;

  if Text[1]='?' then //вопрос - установить статус занят
  begin
    //Удаляем служебный символ
    Delete(Text, 1, 1);
    //Устанавливаем статус и отправляем ответ: 0 - успешно, 1 - ошибка
    if SetBusyUser(Text)=True then IndySendText(AContext, '0') else
      IndySendText(AContext, '1');
  end;

  if Text[1]='!' then //восклицание - снять статус занят
  begin
    //Удаляем служебный символ
    Delete(Text, 1, 1);
    //Устанавливаем статус и отправляем ответ: 0 - успешно, 1 - ошибка
    if SetFreeUser(Text)=True then IndySendText(AContext, '0') else
      IndySendText(AContext, '1');
  end;
end;

procedure TMainForm.RchEdtLogChange(Sender: TObject);
//Процедура класса - событие - изменение текста в richedit
begin
  //Скролл вниз - украшение интерфейса
  SendMessage(RchEdtLog.handle, WM_VSCROLL, SB_BOTTOM, 0);
  //Скрыть каретку - украшение интерфейса
  HideCaret(RchEdtLog.Handle);
end;

procedure TMainForm.RchEdtLogMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
//Процедура класса - событие - отпускание мыши в richedit
begin
  //Скрыть каретку - украшение интерфейса
  HideCaret(RchEdtLog.Handle);
end;

end.
