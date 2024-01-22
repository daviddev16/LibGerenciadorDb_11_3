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
    const REGKEY_PATH = 'SOFTWARE\ControleFerias\Conexao';

    private
      fHost : String;
      fDatabaseName : String;

    public
      property Host : String read fHost write fHost;
      property Database : String read fDatabaseName write fDatabaseName;

      class function CarregarConexao(out fdDbConn: TFdDbConn): Boolean;
      class procedure SalvarConexao(fdDbConn: TfdDbConn);
      class function ExisteConfiguracao(): Boolean;

  end;

implementation

class function TFdDbConn.ExisteConfiguracao(): Boolean;
var
  Registry : TRegistry;
begin
  try
    try
      Registry := TRegistry.Create(KEY_ALL_ACCESS);
      with Registry do
      begin
        Registry.RootKey := HKEY_CURRENT_USER;
        Result := Registry.KeyExists(REGKEY_PATH);
        CloseKey;
      end;
    except
      Result := False;
    end;
  finally
    Registry.Free;
  end;
end;

class procedure TFdDbConn.SalvarConexao(fdDbConn: TfdDbConn);
var
  Registry : TRegistry;
begin
  try
    try
      Registry := TRegistry.Create(KEY_ALL_ACCESS);
      with Registry do
      begin
        RootKey := HKEY_CURRENT_USER;
        if OpenKey(REGKEY_PATH, True) then
        begin
          WriteString('Host', fdDbConn.Host);
          WriteString('Database', fdDbConn.Database);
          CloseKey;
        end;
      end;
    except
      on E: Exception do
      begin
        raise Exception.Create(Format('Não foi possível salvar o ' +
          'registro %s/%s. Verifique as permissões. [%s]', ['HKLM', REGKEY_PATH, e.Message]));
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
        RootKey := HKEY_CURRENT_USER;
        if OpenKeyReadOnly(REGKEY_PATH) then
        begin
          fdDbConn := TFdDbConn.Create;
          fdDbConn.Host := ReadString('Host');
          fdDbConn.Database := ReadString('Database');
          Result := True;
          CloseKey;
        end;
      end;
    except
      on E: Exception do
      begin
        raise Exception.Create(Format('Não foi possível ler o ' +
          'registro %s/%s. Verifique as permissões. [%s]', ['HKLM', REGKEY_PATH]));
        Result := False;
      end;
    end;
  finally
    Registry.Free;
  end;
end;

end.
