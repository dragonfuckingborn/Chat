unit uUsersForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TUsersForm = class(TForm)
    LbUsers: TLabel;
    ListBox: TListBox;
    BtnOK: TButton;
    BtnRefresh: TButton;
    procedure FormShow(Sender: TObject);
    procedure BtnRefreshClick(Sender: TObject);
    procedure BtnOKClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  UsersForm: TUsersForm;

implementation

{$R *.dfm}

uses uMainForm, uMessageForm;

Procedure LoadUsersList;
//процедура получения списка пользоватлей
var
  Users:string; //Ответ от сервера
  I:Integer; //счетчик
begin
  //Отправляем запрос на список пользователей
  IndySendText('*');
  //Получаем ответ
  Users:=IndyReadText;
  //Очищаем список
  UsersForm.ListBox.Items.Clear;
  //Добавляем общий чат
  UsersForm.ListBox.Items.Add('Общий');
  //Если ответ не равен пустоте то
  while Users<>'' do
  begin
    //Добавляем в listbox
    UsersForm.ListBox.Items.Add(Copy(Users, 1, AnsiPos('#', Users)-1));
    //Удаляем из ответа, разделитель #
    Delete(Users, 1, AnsiPos('#', Users));
  end;
  //Удаляем себя из списка
  //Перебираем список
  for I := 0 to UsersForm.ListBox.Count-1 do
  begin
    //Если имя совпало то
    if UsersForm.ListBox.Items[I]=MainForm.EdtName.Text then
    begin
      //Удаляем и покидаем цикл
      UsersForm.ListBox.Items.Delete(I);
      Break;
    end;
  end;
end;

//==============================================================================

procedure TUsersForm.BtnOKClick(Sender: TObject);
//Процедура класса - событие - кнопка ОК нажата
begin
  //Если никого не выбрали в списке то выходим
  if ListBox.ItemIndex=-1 then Exit;
  //Записали имя пользователя для чата
  MessageForm.UserName:=ListBox.Items[ListBox.ItemIndex];
  //Написали в заголовке имя с кем общаемся
  MessageForm.Caption:='Чат: '+MessageForm.UserName;
  //Уведомляем сервер о начале диалога (убрать себя из доступных)
  IndySendText('?'+MainForm.EdtName.Text);
  //если пришла ошибка (Result<>0) то
  if IndyReadText<>'0' then
  begin
    //Уведомляем и выходим из процедуры
    ShowMessage('Ошибка создания диалога. Попробуйте обновить список.');
    Exit;
  end;
  //Скрываем текущую форму
  UsersForm.Hide;
  //показываем форму с чатом
  MessageForm.Show;
end;

procedure TUsersForm.BtnRefreshClick(Sender: TObject);
//Процедура класса - событие - нажатие на кнопку Обновить
begin
  //Получаем список
  LoadUsersList;
end;

procedure TUsersForm.FormClose(Sender: TObject; var Action: TCloseAction);
//Процедура класса - событие - закрытие формы
begin
  //Завершаем работу приложения путем закрытия главной формы
  MainForm.Close;
end;

procedure TUsersForm.FormShow(Sender: TObject);
//Процедура класса - событие - показ формы
begin
  //Получаем список
  LoadUsersList;
end;

end.
