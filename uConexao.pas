unit uConexao;

{
  *******************************************************************************
  *                                                                             *
  *    uConexao - Unit que armazena a configuração de host e database para      *
  *               conexões futuras.                                             *
  *                                                                             *
  *    Autor: David Duarte Pinheiro                                             *
  *    Github: daviddev16                                                       *
  *                                                                             *
  *******************************************************************************
}

interface

uses
  Registry,
  Windows,
  SysUtils;

type
  TFdDbConn = class
    const REGKEY_PATH = '\SOFTWARE\WOW6432Node\ControleFerias\Conexao';

    private
      fHost : String;
      fDatabaseName : String;

      procedure SetDatabase(const database: String);
      procedure SetHost(const host: String);

    public
      property Host : String read fHost;
      property Database : String read fDatabaseName;

      class function CarregarConexao(out fdDbConn: TFdDbConn): Boolean;
      class procedure SalvarConexao(fdDbConn: TfdDbConn);

  end;

implementation

class procedure TFdDbConn.SalvarConexao(fdDbConn: TfdDbConn);
var
  Registry : TRegistry;
begin
  try
    try
      Registry := TRegistry.Create(KEY_ALL_ACCESS);
      with Registry do
      begin
        RootKey := HKEY_LOCAL_MACHINE;
        if OpenKey(REGKEY_PATH, True) then
        begin
          WriteString('Host', fdDbConn.Host);
          WriteString('Database', fdDbConn.Database);
        end;
      end;
    except
      on E: Exception do
      begin
        raise Exception.Create(Format('Não foi possível salvar o ' +
          'registro %s/%s. Verifique as permissões. [%s]', ['HKLM', REGKEY_PATH]));
      end;
    end;
  finally
    Registry.Free;
  end;
end;

class function TFdDbConn.CarregarConexao(out fdDbConn: TFdDbConn): Boolean;
var
  Registry : TRegistry;
begin
  try
    try
      Registry := TRegistry.Create(KEY_ALL_ACCESS);
      with Registry do
      begin
        RootKey := HKEY_LOCAL_MACHINE;
        if OpenKey(REGKEY_PATH, True) then
        begin
          fdDbConn := TFdDbConn.Create;
          fdDbConn.SetHost(ReadString('Host'));
          fdDbConn.SetDatabase(ReadString('Database'));
        end;
      end;
    except
      on E: Exception do
      begin
        raise Exception.Create(Format('Não foi possível ler o ' +
          'registro %s/%s. Verifique as permissões. [%s]', ['HKLM', REGKEY_PATH]));
      end;
    end;
  finally
    Registry.Free;
  end;
end;

procedure TFdDbConn.SetDatabase(const database: String);
begin
  fDatabaseName := database;
end;

procedure TFdDbConn.SetHost(const host: String);
begin
  fHost := host;
end;

end.
