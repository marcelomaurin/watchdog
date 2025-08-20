unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Menus,
  StdCtrls, ComCtrls, AdvLed, Windows, ShellAPI, JwaTlHelp32, setmain, config,
  funcoes, hint;

type

  { Tfrmmain }

  Tfrmmain = class(TForm)
    btStop: TButton;
    Button1: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    lbversao: TLabel;
    ledStart: TAdvLed;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    PageControl1: TPageControl;
    Separator3: TMenuItem;
    Separator2: TMenuItem;
    Separator1: TMenuItem;
    PopupMenu1: TPopupMenu;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    Timer1: TTimer;
    TrayIcon1: TTrayIcon;

    procedure btStopClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormDestroy(Sender: TObject);
    procedure MenuItem1Click(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);
    procedure MenuItem3Click(Sender: TObject);
    procedure MenuItem4Click(Sender: TObject);
    procedure MenuItem5Click(Sender: TObject);
    procedure Timer1StartTimer(Sender: TObject);
    procedure Timer1StopTimer(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Configurar();
    procedure AtivarWatchdog();
  private
    function GetProcessID(const ExeFileName: string): DWORD;
    procedure MaximizeApplicationWindow(const PID: DWORD);
  public
  end;

Const
  Versao = '2.0';

var
  frmmain: Tfrmmain;

implementation

{$R *.lfm}

{ Tfrmmain }

procedure Tfrmmain.Timer1Timer(Sender: TObject);
var
  PID: DWORD;
begin
  try
    hide;
    try
      PID := GetProcessID(fsetmain.ProcessName);
    except
      on E: Exception do
      begin
        //ShowMessage('Erro ao obter o PID: ' + E.Message);
        frmHint.MessageHint('Erro ao obter o PID: ' + E.Message);
        Exit;
      end;
    end;

    if PID = 0 then
    begin
      // Tenta iniciar a aplicação se não estiver em execução
      try
        ShellExecute(0, 'open', PChar(fsetmain.ProcessPath), nil, nil, SW_SHOWNORMAL);
      except
        on E: Exception do
          //ShowMessage('Erro ao iniciar a aplicação: ' + E.Message);
          frmHint.MessageHint('Erro ao iniciar a aplicação: ' + E.Message);
      end;
    end
    else
    begin
      // Tenta maximizar a janela se estiver minimizada
      try
        MaximizeApplicationWindow(PID);
      except
        on E: Exception do
          //ShowMessage('Erro ao maximizar a janela: ' + E.Message);
          frmHint.MessageHint('Erro ao maximizar a janela: ' + E.Message);
      end;
    end;
  except
    on E: Exception do
      //ShowMessage('Erro no Timer1Timer: ' + E.Message);
      frmHint.MessageHint('Erro no Timer1Timer: ' + E.Message);
  end;
end;


procedure Tfrmmain.MenuItem1Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure Tfrmmain.MenuItem2Click(Sender: TObject);
begin
  configurar();
end;

procedure Tfrmmain.MenuItem3Click(Sender: TObject);
begin
  try
    if (FSetMain.ProcessName = '') then
    begin
      try
        Configurar();
      except
        on E: Exception do
          frmhint.messagehint('Erro ao configurar: ' + E.Message);
      end;
    end
    else
    begin
      try
        AtivarWatchdog();
      except
        on E: Exception do
          frmhint.messagehint('Erro ao ativar o watchdog: ' + E.Message);
      end;
    end;
  except
    on E: Exception do
      frmhint.messagehint('Erro no MenuItem3Click: ' + E.Message);
  end;
end;


procedure Tfrmmain.MenuItem4Click(Sender: TObject);
begin
  Timer1.Enabled:= false;
end;

procedure Tfrmmain.MenuItem5Click(Sender: TObject);
begin
  Show;
end;

procedure Tfrmmain.Timer1StartTimer(Sender: TObject);
begin
  ledStart.State:= lsOn;
end;

procedure Tfrmmain.Timer1StopTimer(Sender: TObject);
begin
    ledStart.State:= lsOff;
end;

procedure Tfrmmain.Button1Click(Sender: TObject);
begin
  configurar();
end;

procedure Tfrmmain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if CanClose then
  begin
    CanClose:= false;
    hide;
  end;
end;

procedure Tfrmmain.FormDestroy(Sender: TObject);
begin
  try
    FSetMain.SalvaContexto(false);
  except
    on E: Exception do
      frmhint.messagehint('Erro ao salvar contexto: ' + E.Message);
  end;
  FSetMain.free;
  frmHint.free;
end;

procedure Tfrmmain.btStopClick(Sender: TObject);
begin
  Timer1.Enabled := False;

end;

function Tfrmmain.GetProcessID(const ExeFileName: string): DWORD;
var
  Snapshot: THandle;
  pe: TProcessEntry32;
begin
  Result := 0;
  // Cria um snapshot dos processos em execução
  Snapshot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if Snapshot = INVALID_HANDLE_VALUE then
    Exit;

  try
    pe.dwSize := SizeOf(pe);
    // Obtém o primeiro processo do snapshot
    if Process32First(Snapshot, pe) then
    begin
      repeat
        // Compara o nome do executável com o processo procurado
        if SameText(ExtractFileName(pe.szExeFile), ExeFileName) then
        begin
          Result := pe.th32ProcessID;
          Break;
        end;
      until not Process32Next(Snapshot, pe); // Percorre todos os processos
    end;
  finally
    // Fecha o snapshot
    CloseHandle(Snapshot);
  end;
end;

type
  PEnumData = ^TEnumData;
  TEnumData = record
    PID: DWORD;
    Handle: HWND;
  end;

function EnumWindowsProc(hWnd: HWND; lParam: LPARAM): BOOL; stdcall;
var
  WindowPID: DWORD;
  EnumData: PEnumData;
begin
  EnumData := PEnumData(lParam);
  GetWindowThreadProcessId(hWnd, @WindowPID);
  if (WindowPID = EnumData^.PID) and IsWindowVisible(hWnd) then
  begin
    EnumData^.Handle := hWnd;
    Result := False; // Para a enumeração quando a janela é encontrada
  end
  else
    Result := True; // Continua a enumeração
end;

procedure Tfrmmain.MaximizeApplicationWindow(const PID: DWORD);
var
  EnumData: TEnumData;
begin
  EnumData.PID := PID;
  EnumData.Handle := 0;
  EnumWindows(@EnumWindowsProc, LPARAM(@EnumData));
  if EnumData.Handle <> 0 then
  begin
    ShowWindow(EnumData.Handle, SW_SHOWMAXIMIZED);
    SetForegroundWindow(EnumData.Handle);
  end
  else
    //ShowMessage('Janela não encontrada para o PID fornecido.');
    frmHint.MessageHint('Janela não encontrada para o PID fornecido.');
end;

procedure Tfrmmain.FormCreate(Sender: TObject);
begin
  fsetmain := TSetMain.create();
  fsetmain.CarregaContexto();
  frmhint := TfrmHint.create(self);

  lbversao.Caption:=VERSAO;
  if(FSetMain.ProcessName='') then
  begin
       Configurar();
  end
  else
  begin
       AtivarWatchdog();
  end;
end;

procedure Tfrmmain.Configurar();
begin
   frmconfig := Tfrmconfig.create(self);
   frmconfig.showmodal;
   frmconfig.free;
   frmconfig := nil;
end;

procedure Tfrmmain.AtivarWatchdog();
begin
  if FSetMain.Watchdog then
  begin
    // Configuração do Timer
    //Timer1.Interval := 5000; // Verifica a cada 5 segundos
    ConvertStringToTimer(fsetmain.Time,Timer1); // Verifica a cada 5 segundos
    Timer1.OnTimer := @Timer1Timer;
    Timer1.Enabled := True;
  end;
end;

end.

