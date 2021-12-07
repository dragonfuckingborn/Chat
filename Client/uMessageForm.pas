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
    procedure EdtTextKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure RchEdtChange(Sender: TObject);
    procedure RchEdtMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    { Private declarations }
  public
    { Public declarations }
    UserName:string; //Имя с кем общаемся
    WaitResult:Boolean; //Ожидание ответа от сервера
  end;

var
  MessageForm: TMessageForm;

implementation

{$R *.dfm}

uses uUsersForm, uMainForm;

Procedure SentTextToRichEdit(From:string; Text:string; Color:TColor);
//Процедура для добавления текста в richedit
begin
  //Перемещаем каретку в конец
  MessageForm.RchEdt.SelStart:=Length(MessageForm.RchEdt.Text);
  //задаем цвет текста для имени и даты
  MessageForm.RchEdt.SelAttributes.Color:=Color;
  //Шрифт будет жирным
  MessageForm.RchEdt.SelAttributes.Bold:=True;
  //добавляем строку
  MessageForm.RchEdt.Lines.Add(From+' ('+DateTimeToStr(Now)+')');
  //Для текста выбираем черный цвет
  MessageForm.RchEdt.SelAttributes.Color:=clBlack;
  //Шрифт обычный
  MessageForm.RchEdt.SelAttributes.Bold:=False;
  //Добавляем текст
  MessageForm.RchEdt.Lines.Add(Text);
  //Добавляем пустую строку для разделения
  MessageForm.RchEdt.Lines.Add('');
  //скрываем каретку - украшение интерфейса
  HideCaret(MessageForm.RchEdt.Handle);
end;

Procedure GetNewMessages;
// Процедура запроса новых сообщений
var
  Text:string; //Текст сообщения
  ToText, FromText:string; //кому сообщение и от кого
begin
  //Запрос сообщений с сервера
  IndySendText('@'+MainForm.EdtName.Text);
  //Получили сообщения
  Text:=IndyReadText;
  //Если сообщения есть (не равны 0)
  if Text<>'0' then
  begin
    //Сообщения хранятся в очереди
    while Text<>'' do
    begin
      //Извлекаем Кому
      ToText:=AnsiUpperCase(Copy(Text, 1, AnsiPos(SeparatorTwo, Text)-1));
      Delete(Text, 1, AnsiPos(SeparatorTwo, Text));
      //Извлекаем От кого, разделитель
      FromText:=Copy(Text, 1, AnsiPos(SeparatorTwo, Text)-1);
      Delete(Text, 1, AnsiPos(SeparatorTwo, Text));
      //Если Кому=общий или Кому=имя клиента то
      if (ToText='ОБЩИЙ') or (ToText=AnsiUpperCase(MainForm.EdtName.Text)) then
      begin
        //Если От кого не равно Кому то
        if AnsiUpperCase(FromText)<>AnsiUpperCase(MainForm.EdtName.Text) then
        begin
          //Отправляем собщение на экран, цвет красный
          SentTextToRichEdit(FromText, Copy(Text, 1, AnsiPos(SeparatorOne, Text)-1), clRed);
        end;
      end;
      //Удаляем сообщение из очереди
      Delete(Text, 1, AnsiPos(SeparatorOne, Text));
    end;
  end;
end;

//==============================================================================

procedure TMessageForm.BtnSendClick(Sender: TObject);
//Процедура класса - событие - кнопка нажата
begin
  //Отправка сообщения
  //Если кто то ждет ответа от сервера, то ждем освобождения канала
  while WaitResult=True do Sleep(100);
  //Блокируем канал для своих нужд
  WaitResult:=True;
  //Отправляем сообщение на сервер
  IndySendText('='+UserName+SeparatorTwo+MainForm.EdtName.Text+SeparatorTwo+
    EdtText.Text);
  //Если успешно (0 - ошибок нет)
  if IndyReadText='0' then
  begin
    //Отображаем сообщение на экране, цвет синий
    SentTextToRichEdit(MainForm.EdtName.Text, EdtText.Text, clBlue);
    //Очищаем поле ввода
    EdtText.Clear;
  end else
  begin
    //Выводим сообщение об ошибке
    ShowMessage('Ошибка отправки сообщения');
  end;
  //Освобождаем канал
  WaitResult:=False;
end;

procedure TMessageForm.EdtTextKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
//Процедура класса - событие - нажатие клавиши в поле ввода
begin
  //Если нажатая клавиша Enter то отправляем сообщение путем нажатия кнопки
  if Key=VK_RETURN then BtnSend.Click;
end;

procedure TMessageForm.FormClose(Sender: TObject; var Action: TCloseAction);
//Процедура класса - событие - закрытие формы
var
 Ini:TIniFile; //тип переменной для сохранения в формате Ini
begin
  //Создаем переменную и указываем путь для сохранения
  Ini:=TIniFile.Create(ExtractFilePath(Application.ExeName)+'Config.ini');
  //Сохраняем статус формы: или нормальная или на полный экран
  Ini.WriteBool('MessageForm', 'WindowState', WindowState=TWindowState.wsMaximized);
  //Если экран не равен максмальному, то сохраняем
  if WindowState<>TWindowState.wsMaximized then
  begin
    //Сохраняем положение формы по оси X
    Ini.WriteInteger('MessageForm', 'Left', MessageForm.Left);
    //Сохраняем положение формы по оси Y
    Ini.WriteInteger('MessageForm', 'Top', MessageForm.Top);
    //Сохраняем высоту формы
    Ini.WriteInteger('MessageForm', 'Height', MessageForm.Height);
    //Сохраняем ширину формы
    Ini.WriteInteger('MessageForm', 'Width', MessageForm.Width);
  end;
  //Освобождаем ресурсы
  Ini.Free;
  //таймер выключаем
  Tmr.Enabled:=False;
  //если он еще выполняется, то ждем
  while WaitResult=True do Sleep(100);
  //Уведомляем сервер о завершении диалога
  IndySendText('!'+MainForm.EdtName.Text);
  //если ошибка то
  if IndyReadText<>'0' then
  begin
    //уведомляем
    ShowMessage('Ошибка завершения диалога');
  end;
  //Возвращаемся назад
  UsersForm.Show;
end;

procedure TMessageForm.FormCreate(Sender: TObject);
//Процедура класса - событие - создание формы
begin
  //Задаем умолчания - канал свободен
  WaitResult:=False;
end;

procedure TMessageForm.FormShow(Sender: TObject);
//Процедура класса - событие - показ формы
var
 Ini:TIniFile; //тип переменной для сохранения в формате Ini
begin
  //Создаем переменную и указываем путь для загрузки
  Ini:=TIniFile.Create(ExtractFilePath(Application.ExeName)+'Config.ini');
  //Загружаем положение формы по оси X
  MessageForm.Left:=Ini.ReadInteger('MessageForm', 'Left', MessageForm.Left);
  //Загружаем положение формы по оси Y
  MessageForm.Top:=Ini.ReadInteger('MessageForm', 'Top', MessageForm.Top);
  //Загружаем высоту формы
  MessageForm.Height:=Ini.ReadInteger('MessageForm', 'Height', MessageForm.Height);
  //Загружаем ширину формы
  MessageForm.Width:=Ini.ReadInteger('MessageForm', 'Width', MessageForm.Width);
  //Загружаем статус формы: или нормальная или на полный экран
  if Ini.ReadBool('MessageForm', 'WindowState', False)=True then
    WindowState:=TWindowState.wsMaximized else
      WindowState:=TWindowState.wsNormal;
  //Освобождаем ресурсы
  Ini.Free;
  //очищаем richedit
  RchEdt.Clear;
  //таймер включаем
  Tmr.Enabled:=True;
end;

procedure TMessageForm.RchEdtChange(Sender: TObject);
//Процедура класса - событие - изменение текста в поле ввода
begin
  //Проматываем вниз
  SendMessage(RchEdt.handle, WM_VSCROLL, SB_BOTTOM, 0);
  //скрываем каретку - украшение интерфейса
  HideCaret(MessageForm.RchEdt.Handle);
end;

procedure TMessageForm.RchEdtMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
//Процедура класса - событие - нажатие мыши в richedit
begin
  //скрываем каретку - украшение интерфейса
  HideCaret(MessageForm.RchEdt.Handle);
end;

procedure TMessageForm.TmrTimer(Sender: TObject);
//Процедура класса - событие - обработчик таймера (раз в 500 мс)
begin
  //если идет ожидание ответа то выходим - проверим сообщения в следующий раз
  if WaitResult=True then Exit;
  //запрещаем общаться с сервером (отправлять сообщения)
  WaitResult:=True;
  //получаем собщения
  GetNewMessages;
  //разрешаем общаться с сервером (отправлять сообщения)
  WaitResult:=False;
end;

end.
