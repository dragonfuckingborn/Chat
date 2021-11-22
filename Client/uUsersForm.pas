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

uses uMainForm;

Procedure LoadUsersList;
var
  Users:string;
  I:Integer;
begin
  IndySendText('*');
  Users:=IndyReadText;
  UsersForm.ListBox.Items.Clear;
  UsersForm.ListBox.Items.Add('Общий');
  while Users<>'' do
  begin
    UsersForm.ListBox.Items.Add(Copy(Users, 1, AnsiPos('#', Users)-1));
    Delete(Users, 1, AnsiPos('#', Users));
  end;
  for I := 0 to UsersForm.ListBox.Count-1 do
  begin
    if UsersForm.ListBox.Items[I]=MainForm.EdtName.Text then
    begin
      UsersForm.ListBox.Items.Delete(I);
      Break;
    end;
  end;
end;

procedure TUsersForm.BtnRefreshClick(Sender: TObject);
begin
  LoadUsersList;
end;

procedure TUsersForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  MainForm.Close;
end;

procedure TUsersForm.FormShow(Sender: TObject);
begin
  LoadUsersList;
end;

end.
