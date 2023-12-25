# LibGerenciadorDb

LibGerenciadorDb é uma biblioteca que desenvolvi especialmente para facilitar as operações de Insert, Delete, Update e Select no banco de dados PostgreSQL. 
Também fornece mapeamento de DataSet em objetos da linguagem, fazendo com que seja possível interagir com o banco de dados rapidamente e criar DAOs com facilidade.

## Aviso

Essa biblioteca ainda está em desenvolvimento. É utilizada em alguns projetos que estou fazendo, sendo assim, é possível que haja bugs ou algumas implementações faltando.

## Exemplo

Neste exemplo, é possível observar a utilização do ``TFdRTDao<TColaborador>``, que será responsável por lidar com todo o acesso direto ao banco de dados e mapeamento de entidades, que nesse caso é o ``TColaborador``.

```pascal

uses
  uRepo;

type

  [TDbTable('public.colaborador')]
  TColaborador = class

    { nome colunas colaborador }
    const clIdColaborador      = 'IdColaborador';
    const clDsColaborador      = 'DsColaborador';
    const clLogin              = 'Login';
    const clObservacao         = 'Observacao';
    const clStAtivo            = 'StAtivo';
    const clDtCadastro         = 'DtCadastro';
    const clTotalDiasPrevistos = 'TotalDiasPrevistos';
	
	const constUqNmUsuario = 'uq_colaborador_nmusuario';

    private
      [TDbSeqId]
      [TDbField(clIdColaborador)]
      fId : Integer;

      [TDbField(clDsColaborador)]
      fDescricao : String;

      [TDbField(clLogin)]
      fLogin : String;

      [TDbField(clObservacao)]
      fObservacao : String;

      [TDbField(clStAtivo)]
      fStAtivo : Boolean;

      [TDbField(clDtCadastro)]
      fDataCadastro : TDateTime;

      [TDbField(clTotalDiasPrevistos)]
      fTotalDiasPrevistos : Integer;

    public
      property Id : Integer read fId;
      property Descricao : String read fDescricao write fDescricao;
      property Login : String read fLogin write fLogin;
      property Observacao : String read fObservacao write fObservacao;
      property StAtivo : Boolean read fStAtivo write fStAtivo;
      property DataCadastro : TDateTime read fDataCadastro write fDataCadastro;
      property TotalDiasPrevistos : Integer read fTotalDiasPrevistos write fTotalDiasPrevistos;


  end;

  TDAOColaborador = class(TFdRTDao<TColaborador>) end;

  TGerenciadorColaborador = class(TInterfacedObject, IDbErrorHandler)
    private
      fDaoColaborador : TDAOColaborador;
      procedure HandleException(exception: EFDDBEngineException);

    protected
      property DaoColaborador : TDAOColaborador read fDaoColaborador;

    public
      constructor Create(var fdConnection: TFDConnection);

      function LocalizarPorLogin(const nome: String; out colaborador: TColaborador): Boolean;
      procedure AtualizarColaboradorPorId(const idColaborador: Integer; alteracoes: TDictionary<String, Variant>);
      function LocalizarTodos(out colaboradores: TList<TColaborador>): Boolean;
      procedure ExcluirColaboradorPorId(idcolaborador: Integer);
      function CriarColaborador(colaborador: TColaborador): Boolean;
  end;

var
  GerenciadorColaborador : TGerenciadorColaborador;

implementation

constructor TGerenciadorColaborador.Create(var fdConnection: TFDConnection);
begin
  fDaoColaborador := TDAOColaborador.Create(fdConnection);
  fDaoColaborador.ErrorHandler := Self;
end;

function TGerenciadorColaborador.LocalizarTodos(out colaboradores: TList<TColaborador>): Boolean;
begin
  Result := DaoColaborador.FindAll(colaboradores);
end;

procedure TGerenciadorColaborador.AtualizarColaboradorPorId(const idColaborador: Integer;
                                                            alteracoes: TDictionary<String, Variant>);
begin
  DaoColaborador.Update(TColaborador.clIdColaborador, idColaborador, alteracoes);
end;

procedure TGerenciadorColaborador.ExcluirColaboradorPorId(idcolaborador: Integer);
begin
  DaoColaborador.Delete(TColaborador.clIdColaborador, idcolaborador);
end;

function TGerenciadorColaborador.LocalizarPorLogin(const nome: String;
                                                    out colaborador: TColaborador): Boolean;
begin
  Result := DaoColaborador.FindUnique(nome, TColaborador.clLogin, colaborador);
end;

procedure TGerenciadorColaborador.HandleException(exception: EFDDBEngineException);
var
  ConstraintName : String;
begin
  if exception.Kind = ekUKViolated then
  begin
    ConstraintName := exception[0].ObjName;
    {colaborador}
    if SameText(ConstraintName, TColaborador.constUqNmUsuario) then
      TFrmValidacaoSimples.MostrarValidacao('Operação não permitida!', 'Já existe um colaborador com este login! Verifique.', '')
  end;
end;

```
