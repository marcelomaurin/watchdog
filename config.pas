unit config;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, EditBtn,
  rxfolderlister, RxTimeEdit, setmain;

type

  { Tfrmconfig }

  Tfrmconfig = class(TForm)
    btGravar: TButton;
    btCancelar: TButton;
    ckWatchdog: TCheckBox;
    edAplicacao: TEdit;
    edCaminho: TFileNameEdit;
    edTime: TRxTimeEdit;
    FileNameEdit1: TFileNameEdit;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    procedure btCancelarClick(Sender: TObject);
    procedure btGravarClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  frmconfig: Tfrmconfig;

implementation

{$R *.lfm}

{ Tfrmconfig }

procedure Tfrmconfig.FormCreate(Sender: TObject);
begin
  edAplicacao.text :=   FSetMain.ProcessName;
  edCaminho.text := FSetMain.ProcessPath;
  edTime.Caption:=FSetMain.time;
  ckWatchdog.Checked:= FSetMain.Watchdog;
  edCaminho.InitialDir:= ExtractFileDir(FSetMain.ProcessPath);
end;

procedure Tfrmconfig.btCancelarClick(Sender: TObject);
begin
  close;
end;

procedure Tfrmconfig.btGravarClick(Sender: TObject);
begin
  FSetMain.ProcessName:= edAplicacao.text;
  FSetMain.ProcessPath:= edCaminho.text;
  FSetMain.Time:= edTime.Caption;
  FSetMain.Watchdog:= ckWatchdog.Checked;
  FSetMain.SalvaContexto(false);

  Close;
end;

end.

