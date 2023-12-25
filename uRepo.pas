unit uRepo;

{
  *******************************************************************************
  *                                                                             *
  *    uRepo - Repositório de implementação de DAO's para acesso ao banco de    *
  *            dados. Permite a utilização de RTTI para dinamicamente, gerar    *
  *            entidades e queries SQL.                                         *
  *                                                                             *
  *    Autor: David Duarte Pinheiro                                             *
  *    Github: daviddev16                                                       *
  *                                                                             *
  *******************************************************************************
}

interface

uses
  DB,
  RTTI,
  TypInfo,
  SysUtils,
  System.JSON,
  System.Classes,
  System.Variants,
  uUtility,
  uSQLAttr,
  uSQLRTTIBuilders,
  System.Generics.Collections,
  System.Generics.Defaults,
  FireDAC.Comp.Client,
  FireDAC.Stan.Error,
  FireDAC.Stan.Option;

type


  {
    IDAORepository<Tid; E> = DAO Repository
    Descrição: Básica assinatura de como um Direct Access Object deve se comportar
               com entidades relacionais. Define os métodos básicos para interação
               com o banco de dados. Onde Update, Delete, Insert, Find e FindUnique
               serão onde o acesso ao banco de dados será executado, apenas.

    Tid : Representa o tipo do ID da entidade;
    E   : Representa o tipo da própria entidade;
  }
  IDAORepository<E: class> = interface
    function Insert(entity: E): Boolean;

    [TDeprecated] procedure Delete(const fieldName: String; value: Variant);
    procedure DeleteWhere(SqlFilter: TSQLFilterBuilder);

    [TDeprecated] procedure Update(const fieldName: String; value: Variant; changes: TDictionary<String, Variant>);

    procedure UpdateWhere(var sqlFilter: TSQLFilterBuilder; var changes: TDictionary<String, Variant>;
                          var parameters: TDictionary<String, Variant>);

    function Find(value: Variant; const fieldName: String; out entities: TList<E>): Boolean;
    function FindUnique(value: Variant; const fieldName: String; out entity: E): Boolean;
    function FindAll(out entities: TList<E>): Boolean;

  end;

  IDbErrorHandler = interface
    procedure HandleException(exception: EFDDBEngineException);
  end;

  {
    TFDDAOBase<Tid; E> = FireDAC DAO Base
    Descrição: Classe abstrata que se adapta a utilização do FireDAC para o acesso
               ao banco de dados. Essa classe fornece o acesso direto ao TFDConnection
               e NÃO implementa nenhuma operação ao banco de dados. Também fornece
               a assinatura do método DaoQuery que será usado para executar queries
               no banco de dados através da classe filha.
  }
  TFDDAOBase<E:class> = class abstract (TComponent, IDAORepository<E>)
    private
      var fFdConnection : TFDConnection;
      fErrorHandler : IDbErrorHandler;

    protected
      function DaoQuery(const sqlText: String; out fdQuery: TFDQuery;
                        parameters: TDictionary<String, Variant>;
                        dml: Boolean): Boolean;

      property FdConnection : TFDConnection read fFdConnection write fFdConnection;

    public
      constructor Create(var fdConnection: TFDConnection); virtual;

      function Insert(entity: E): Boolean; virtual; abstract;
      procedure Delete(const fieldName: String; value: Variant); virtual; abstract;
      procedure DeleteWhere(SqlFilter: TSQLFilterBuilder); virtual; abstract;
      procedure Update(const fieldName: String; value: Variant; changes: TDictionary<String, Variant>); virtual; abstract;

      procedure UpdateWhere(var sqlFilter: TSQLFilterBuilder; var changes: TDictionary<String, Variant>;
                            var parameters: TDictionary<String, Variant>); virtual; abstract;

      function Find(value: Variant; const fieldName: String; out entities: TList<E>): Boolean; virtual; abstract;
      function FindUnique(value: Variant; const fieldName: String; out entity: E): Boolean; virtual; abstract;
      function FindAll(out entities: TList<E>): Boolean; virtual; abstract;

      property ErrorHandler : IDbErrorHandler read fErrorHandler write fErrorHandler;

  end;

  {
    TFdRTDao<Tid; E> = FireDAC RTTI DAO
    Descrição: É uma implementação de TFDDAOBase que permite a interação com entidades
               sem precisar escrever queries básicas para Update, Delete, Insert, Find e
               FindUnique. Utiliza de RTTI para mapear o objeto das entidades e transformar
               em queries SQL e instânciar entidades dinâmicamente com seus respectivos
               valores do DataSet. TFdRTDao também implementa métodos para interação
               RTTI, a implementação, não deve ser feita dentro de métodos do TFDDAOBase.
  }
  TFdRTDao<E: class> = class (TFDDAOBase<E>)
    private
      function InternalRTTIInsert(entity: E; var fdQuery: TFDQuery): Boolean;
      procedure InternalRTTIUpdate(var sqlFilter: TSQLFilterBuilder; changes: TDictionary<String, Variant>;
                                   var parameters: TDictionary<String, Variant>; var fdQuery: TFDQuery);

      procedure InternalRTTIDelete(sqlFilter: TSQLFilterBuilder; var fdQuery: TFDQuery);

      function InternalRTTIFind(value: Variant; const fieldName: String; var fdQuery: TFDQuery;
                                unique: Boolean): TList<E>;

      function InternalRTTIFindAll(var fdQuery: TFDQuery): TList<E>;

      class function InternalRTTIQuery(const SqlText: String; var parameters: TDictionary<String, Variant>;
                                       out entities: TList<E>; unique: Boolean; var fdConnection: TFDConnection;
                                       var fdQuery: TFDQuery): Boolean;

    protected
      class function GetEntities<T: class>(var fdQuery: TFDQuery; unique: Boolean): TList<T>;
      class procedure CreateGenericEntity(var context: TRttiContext; var classType: TRttiType;
                                          out instance: TObject);

      class procedure ConvertDataSetField(var entityInstance: TObject; var datasetField: TField;
                                          entityField: TRttiField);

      class procedure PrepareGenericEntity(var context: TRttiContext; var classType: TRttiType;
                                           var entityInstance: TObject; var fdQuery: TFDQuery);

    public
      function Insert(entity: E): Boolean; virtual;
      procedure Delete(const fieldName: String; value: Variant); virtual;
      procedure DeleteWhere(SqlFilter: TSQLFilterBuilder); virtual;
      procedure Update(const fieldName: String; value: Variant; changes: TDictionary<String, Variant>); virtual;

      procedure UpdateWhere(var sqlFilter: TSQLFilterBuilder; var changes: TDictionary<String, Variant>;
                            var parameters: TDictionary<String, Variant>); virtual;



      function Find(value: Variant; const fieldName: String; out entities: TList<E>): Boolean; virtual;
      function FindUnique(value: Variant; const fieldName: String; out entity: E): Boolean; virtual;
      function FindAll(out entities: TList<E>): Boolean; virtual;

      function CustomFindUnique(const SqlText: String; parameters: TDictionary<String, Variant>;
                                out entity: E): Boolean; virtual;

      class function Query(const SqlText: String; parameters: TDictionary<String, Variant>;
                           out entities: TList<E>; fdConnection: TFDConnection): Boolean;

  end;

  {
    TQueryManager = Query Manager
    Descrição: Essa classe fica responsável por monitoras e criar os objetos de
               query que serão usados nas classes DAO's. Esta classe é Singleton
               Não deve ser instânciada mais de uma vez.
  }
  TQueryManager = class sealed

    private
      class var fQueryManager : TQueryManager;

    strict private
      constructor Create();
      destructor Destroy();

    public
      class procedure Inicializar;
      procedure MonitorQuery(owner: TObject; var fdQuery: TFDQuery);
      procedure CreateQuery(const sqlText: String;
                            fdConnection: TFDConnection;
                            out fdQuery: TFDQuery;
                            parameters: TDictionary<String, Variant>;
                            dml: Boolean);

      class property Instancia: TQueryManager read fQueryManager;
      {TODO}
  end;

  TDeprecated = class(TCustomAttribute) end;

implementation


{
  Descrição: Executa a inserção da entidade na tabela do banco de dados;

  entity : Objeto da entidade que será mapeada para o SQL de INSERT;
}
function TFdRTDao<E>.Insert(entity: E): Boolean;
var
  FdQuery : TFDQuery;
begin
  try
    Result := InternalRTTIInsert(entity, FdQuery);
  finally
    FdQuery.Free;
  end;
end;

{
  Descrição: Faz a atualização dos dados da entidade. É utilizado o fieldName e
             value para que seja feito a atualização nas entidades corretas.

  fieldName : Nome da coluna quer será usada para filtrar a entidade no WHERE;
  value     : Valor que a coluna deve ter para que a atualização ocorra;
  changes   : Mapa com as informações que serão atualizadas no banco de dados;
}
procedure TFdRTDao<E>.Update(const fieldName: String; value: Variant; changes: TDictionary<String, Variant>);
var
  FdQuery : TFDQuery;
  SqlFilter : TSQLFilterBuilder;
  Parameters : TDictionary<String, Variant>;
  ParamFieldName : String;
begin
  SqlFilter := TSQLFilterBuilder.Create;
  Parameters := TDictionary<String, Variant>.Create;
  try
    ParamFieldName := TMiscUtil.CreateParam(fieldName);
    Parameters.Add(ParamFieldName, value);
    SqlFilter.Add(fieldName, Concat(':', ParamFieldName));
    InternalRTTIUpdate(SqlFilter, changes, Parameters, FdQuery);
  finally
    FdQuery.Free;
    SqlFilter.Free;
    Parameters.Free;
  end;
end;

{TODO: DESC detalhada }
procedure TFdRTDao<E>.UpdateWhere(var sqlFilter: TSQLFilterBuilder; var changes: TDictionary<String, Variant>;
                                  var parameters: TDictionary<String, Variant>);

var
  FdQuery : TFDQuery;
begin
  try
    InternalRTTIUpdate(SqlFilter, changes, parameters, FdQuery);
  finally
    FdQuery.Free;
  end;
end;

{
  Descrição: Encontra e retorna todos os valores encontrados na query. Caso precise
             localizar uma entidade com constraint unique em uma coluna, utilize
             FindUnique ao invés de Find.

  fieldName : Nome da coluna que será usada no filtro SQL;
  value     : Valor que a coluna precisar para achar a entidade única;
  entity    : Objeto da entidade mapeada;
}
function TFdRTDao<E>.Find(value: Variant; const fieldName: String; out entities: TList<E>): Boolean;
var
  FdQuery : TFDQuery;
begin
  Result := False;
  try
    entities := InternalRTTIFind(value, fieldName, FdQuery, False);
    Result := True;
  finally
    fdQuery := nil;
  end;
end;

{
  Descrição: Encontra um valor único. FindUnique difere de Find por que FindUnique
             não vai percorer o DataSet inteiro para achar o valor.

  fieldName : Nome da coluna que será usada no filtro SQL;
  value     : Valor que a coluna precisar para achar a entidade única;
  entity    : Objeto da entidade mapeada;
}
function TFdRTDao<E>.FindUnique(value: Variant; const fieldName: String; out entity: E): Boolean;
var
  FdQuery : TFDQuery;
  Entities : TList<E>;
begin
  Result := False;
  try
    Entities := InternalRTTIFind(value, fieldName, FdQuery, True);
    if Entities.Count > 0 then
    begin
      entity := Entities[0];
      Result := True;
    end;
  finally
    FdQuery := nil;
  end;
end;

{
  Descrição: Retorna todas as entidades sem filtro no SQL;

  entities : Objetos das entidades mapeadas no SQL;
}
function TFdRTDao<E>.FindAll(out entities: TList<E>): Boolean;
var
  FdQuery : TFDQuery;
begin
  try
    entities := InternalRTTIFindAll(FdQuery);
  finally
    FdQuery := nil;
  end;
end;


{
  Descrição: Executa operações DELETE no banco de dados, filtrando pelo nome da coluna
             e valor. É obrigatório possuir um filtro para que o delete não tenha efeitos
             destrutivos;

  fieldName : Nome da coluna que será usada no filtro SQL;
  value     : Valor que a coluna precisar ter para que o DELETE seja feito;
}
procedure TFdRTDao<E>.Delete(const fieldName: String; value: Variant);
var
  SqlFilter : TSQLFilterBuilder;
begin
  try
    SqlFilter := TSQLFilterBuilder.Create;
    SqlFilter.Add(fieldName, value);
    DeleteWhere(SqlFilter);
  finally
    SqlFilter.Free;
  end;
end;

{NEW: TODO: DESC}
procedure TFdRTDao<E>.DeleteWhere(SqlFilter: TSQLFilterBuilder);
var
  FdQuery : TFDQuery;
begin
  try
    InternalRTTIDelete(SqlFilter, FdQuery);
  finally
    FdQuery.Free;
  end;
end;

{
  Descrição: Implementação do método Insert. Insere informações de um entidade objeto
             e cria um comando de INSERT para inserir as informações no banco de dados;

  entity    : Objeto da entidade que será mapeada para o SQL;
  fdQuery   : TFDQuery utilizado na pesquisa;
}
function TFdRTDao<E>.InternalRTTIInsert(entity: E; var fdQuery: TFDQuery): Boolean;
var
  SqlText : String;
begin
  SqlText := TRtSQLEntityBuilder
    .CreateInsert(TypeInfo(E), entity);

  Result := DaoQuery(SqlText, fdQuery, nil, True);
end;

{
  Descrição: Implementação do método Update. Faz a atualização das informações de
             acordo com os valores passados no dicionário. Cria um UPDATE dinâmico
             e executando a query no banco de dados;

  sqlFiltr  : Builder do filtro SQL que será utilizado para a atualização;
  changes   : Mapa com as informações que serão atualizadas no banco de dados;
  fdQuery   : TFDQuery utilizado na pesquisa;
}
procedure TFdRTDao<E>.InternalRTTIUpdate(var sqlFilter: TSQLFilterBuilder; changes: TDictionary<String, Variant>;
                                         var parameters: TDictionary<String, Variant>; var fdQuery: TFDQuery);
var
  SqlText : String;
begin
  SqlText := TRtSQLEntityBuilder
    .CreateUpdate(TypeInfo(E), SqlFilter, changes);

  writeln(sqlText);
  DaoQuery(SqlText, fdQuery, parameters, True);
end;

{
  Descrição: Implementação do método Delete. Deleta informações no banco de dados
             criando um DELETE dinâmico e executando a query no banco de dados;

  sqlFilter : Filtro SQL utilizado para remoção;
  fdQuery   : TFDQuery utilizado na pesquisa;
  unique    : Se deve retornar apenas uma entidade. Utilizado para não recuperar todas as
              entidades do banco, somente uma linha;
}
procedure TFdRTDao<E>.InternalRTTIDelete(sqlFilter: TSQLFilterBuilder; var fdQuery: TFDQuery);
var
  SqlText : String;
begin
  SqlText := TRtSQLEntityBuilder
    .CreateDelete(TypeInfo(E), SqlFilter);

  DaoQuery(SqlText, fdQuery, nil, True);
end;

{
  Descrição: Implementação do método Find. Recupera as informações do banco de dados
             criando um SELECT dinâmico e inserido os valores em uma lista genérica;

  value     : Valor que a coluna precisa ter para atender ao SELECT;
  fieldName : Nome da coluna que será usado no filtro do SELECT;
  fdQuery   : TFDQuery utilizado na pesquisa;
  unique    : Se deve retornar apenas uma entidade. Utilizado para não recuperar todas as
              entidades do banco, somente uma linha;
}
function TFdRTDao<E>.InternalRTTIFind(value: Variant; const fieldName: String;
                                           var fdQuery: TFDQuery; unique: Boolean): TList<E>;
var
  SqlText : String;
  SqlFilter : TSQLFilterBuilder;
  Parameters : TDictionary<String, Variant>;
  ParamFieldName : String;
begin

  Parameters := TDictionary<String, Variant>.Create;
  ParamFieldName := TMiscUtil.CreateParam(fieldName);
  Parameters.Add(ParamFieldName, value);

  try
    SqlFilter := TSQLFilterBuilder.Create
      .Add(fieldName, Concat(':', ParamFieldName));

    SqlText := TRtSQLEntityBuilder
      .CreateSelect(TypeInfo(E), [], SqlFilter);

    DaoQuery(SqlText, fdQuery, Parameters, False);
    Result := GetEntities<E>(fdQuery, False);

  finally
    SqlFilter.Free;
    Parameters.Free;
  end;
end;

{
  Descrição: Implementação do método FindAll. Recupera todas as  informações do
             banco de dados criando um SELECT dinâmico e inserido os valores em
             uma lista genérica;

  fdQuery   : TFDQuery utilizado na pesquisa;
}
function TFdRTDao<E>.InternalRTTIFindAll(var fdQuery: TFDQuery): TList<E>;
var
  SqlText : String;
begin
  SqlText := TRtSQLEntityBuilder
    .CreateSelect(TypeInfo(E), [], nil);

  DaoQuery(SqlText, fdQuery, nil, False);
  Result := GetEntities<E>(fdQuery, False);
end;

function TFdRTDao<E>.CustomFindUnique(const SqlText: String;
                                      parameters: TDictionary<String, Variant>; out entity: E): Boolean;
var
  FdQuery : TFDQuery;
  Entities : TList<E>;
begin
  Result := False;
  try
    DaoQuery(SqlText, FdQuery, parameters, False);
    Entities := GetEntities<E>(FdQuery, True);
    if Entities.Count > 0 then
    begin
      entity := Entities[0];
      Result := entity <> nil;
    end;
  finally
    FdQuery := nil;
  end;
end;

{TODO: desc}
class function TFdRTDao<E>.Query(const SqlText: String; parameters: TDictionary<String, Variant>;
                                    out entities: TList<E>; fdConnection: TFDConnection): Boolean;
var
  FdQuery : TFDQuery;
begin
  Result := False;
  try
    InternalRTTIQuery(SqlText, parameters, entities, False, fdConnection, FdQuery);
  finally
    Result := Assigned(entities) and (entities.Count > 0);
  end;
end;

{TODO: desc}
class function TFdRTDao<E>.InternalRTTIQuery(const SqlText: String; var parameters: TDictionary<String, Variant>;
                                             out entities: TList<E>; unique: Boolean; var fdConnection: TFDConnection;
                                             var fdQuery: TFDQuery): Boolean;
begin
  if String.IsNullOrWhiteSpace(SqlText) then
  begin
    raise TDAOException.Create('O SqlText não pode ser nulo ou vazio em InternalRTTIQuery.');
  end;
  TQueryManager.Instancia
    .CreateQuery(SqlText, fdConnection, fdQuery, parameters, False);

  if Assigned(fdQuery) and (fdQuery.Active) then
    entities := GetEntities<E>(fdQuery, unique);
end;

{
  Descrição: Retorna uma lista com todos os objetos instânciados que foram encontrados
             no banco de dados. Utiliza CreateGenericEntity e PrepareGenericEntity para
             criar e preparar os objetos para uso, pegando as informações do TFDQuery;

  fdQuery : TFDQuery atual utilizado na query;
  unique  : Se deve retornar apenas uma entidade. Utilizado para não recuperar todas as
            entidades do banco, somente uma linha;
}
class function TFdRTDao<E>.GetEntities<T>(var fdQuery: TFDQuery; unique: Boolean): TList<T>;
var
  EntityInstance : TObject;
  RttiContext : TRttiContext;
  ClassType : TRttiType;
begin
  if not (Assigned(fdQuery) and fdQuery.Active) then
  begin
    raise TDAOException.Create('Não é possível criar entidades em um DataSet nulo ou inativo.');
  end;
  try
    Result := TObjectList<T>.Create;
    RttiContext := TRttiContext.Create;
    ClassType := RttiContext.GetType(TypeInfo(E));
    fdQuery.DisableControls;
    while not fdQuery.Eof do
    begin
      EntityInstance := nil;
      CreateGenericEntity(RttiContext, ClassType, EntityInstance);
      PrepareGenericEntity(RttiContext, ClassType, EntityInstance, fdQuery);
      Result.Add(EntityInstance as T);
      if (EntityInstance <> nil) and (unique) then
      begin
        break;
      end;
      fdQuery.Next;
    end;
  finally
    RttiContext.Free;
  end;
end;

{
  Descrição: Responsável por preencher os valores das variáveis da entidade de acordo
             com o valor da coluna retornada no FDQuery.

  context        : Instância de TRttiContext atual;
  entityInstance : Instância criada da entidade;
  fdQuery        : TFDQuery executada na implementação;
  classType      : Objeto de TRttiType que representa o tipo da entidade;
}
class procedure TFdRTDao<E>.PrepareGenericEntity(var context: TRttiContext; var classType: TRttiType;
                                                 var entityInstance: TObject; var fdQuery: TFDQuery);
var
  DeclaredFields : TArray<TRttiField>;
  QueryField : TField;
  DbField : TDbField;
begin

  if not Assigned(entityInstance) then
    raise Exception.Create('Não foi possível preparar uma entidade. O objeto não foi criado.');

  DeclaredFields := classType.GetDeclaredFields;

  for var EntityField in DeclaredFields do
    if TRttiUtil.GetAttrFromField<TDbField>(EntityField, DbField) then
    begin
      QueryField := fdQuery.FieldByName(DbField.fFieldName);
      if QueryField <> nil then
        ConvertDataSetField(entityInstance, QueryField, EntityField);

    end;

end;

{
  Descrição: Permite criar instâncias de objetos de tipo genérico, sem explicitamente
             utilizar o Create para instânciar o objeto. A classe entidade genérica
             precisa necessariamente ter um construtor sem parâmetro.

  context : Instância de TRttiContext atual;
  entity  : Retorno da entidade instânciada através do tipo genérico;
}
class procedure TFdRTDao<E>.CreateGenericEntity(var context: TRttiContext; var classType: TRttiType;
                                                out instance: TObject);
var
  ClassConstructorMethod: TRttiMethod;
  ClassInstance : TValue;
begin

  for var Method in ClassType.GetMethods do
    if (Method.IsConstructor) and (Length(Method.GetParameters) = 0) then
    begin
      ClassConstructorMethod := Method;
    end;

  if Assigned(ClassConstructorMethod) then
    ClassInstance := ClassConstructorMethod
      .Invoke(ClassType.AsInstance.MetaclassType, []);

  if not ClassInstance.IsEmpty then
    instance := ClassInstance.AsObject;

end;

{
  Descriçõa: Insere o valor de TField na variável correspondente a coluna na entidade.

  entityInstance : Instância criada da entidade;
  datasetField   : TField correspondente á variável entityField;

}
class procedure TFdRTDao<E>.ConvertDataSetField(var entityInstance: TObject; var datasetField: TField;
                                                entityField: TRttiField);
begin
  if not datasetField.IsNull then
  begin
    case datasetField.DataType of
      ftInteger:
        entityField.SetValue(entityInstance, datasetField.AsInteger);
      ftFloat:
        entityField.SetValue(entityInstance, datasetField.AsFloat);
      ftString:
        entityField.SetValue(entityInstance, datasetField.AsString);
      ftBoolean:
        entityField.SetValue(entityInstance, datasetField.AsBoolean);
      ftWideString:
        entityField.SetValue(entityInstance, datasetField.AsWideString);
      ftTimeStamp, ftTime, ftTimeStampOffset, ftDateTime, ftDate:
        entityField.SetValue(entityInstance, datasetField.AsDateTime);
      ftMemo:
        entityField.SetValue(entityInstance, datasetField.AsString);
      ftWideMemo:
        entityField.SetValue(entityInstance, datasetField.AsWideString);
      ftUnknown:
        entityField.SetValue(entityInstance, VarToStr(datasetField.AsVariant));
      ftVariant:
        entityField.SetValue(entityInstance, VarToStr(datasetField.AsVariant));
       { TODO: fazer conversão para outros tipos de dados }
    end;
  end;

end;

class procedure TQueryManager.Inicializar;
begin

  if fQueryManager <> nil then
    raise Exception.Create('TQueryManager já inicializado. Utilize ''TQueryManager.Instancia''.');

  fQueryManager := TQueryManager.Create;

end;

procedure TQueryManager.CreateQuery(const sqlText: String; fdConnection: TFDConnection; out fdQuery: TFDQuery;
                                    parameters: TDictionary<String, Variant>; dml: Boolean);
begin
  if String.IsNullOrWhitespace(sqlText) then
    raise TDAOException.Create('Não é possível criar uma Query com texto SQL vazio.');

  fdQuery := TFDQuery.Create(nil);
  fdQuery.Connection := FdConnection;
  fdQuery.FetchOptions.Mode := fmAll;
  fdQuery.SQL.Text := sqlText;

  if (parameters <> nil) then
    for var pair in parameters do
    begin
      fdQuery.ParamByName(pair.Key).Value := pair.Value;
    end;

  MonitorQuery(Self, fdQuery);

  try
    if not dml then
    begin
      fdQuery.Open;
    end
    else
      fdQuery.ExecSQL;

  except
    on E: Exception do
    begin
      Writeln('[SQL_ERROR]: ' + E.Message);
      raise;
    end;
  end;

end;

procedure TQueryManager.MonitorQuery(owner: TObject; var fdQuery: TFDQuery);
var
  I : Integer;
  JSON : TJSONObject;
  JSONArray : TJSONArray;
begin
  JSON := TJSONObject.Create;
  JSONArray := TJSONArray.Create;
  WriteLn('SQL   : ' + fdQuery.SQL.Text);
  for I := 0 to fdQuery.Params.Count - 1 do
  begin
    JSONArray.Add(TJSONObject.Create
      .AddPair(fdQuery.Params[I].Name, VarToStr(fdQuery.Params[I].Value)));
  end;
  Writeln('Params: ' + JSONArray.ToString + sLineBreak);
  JSON.Free;
end;

constructor TFDDAOBase<E>.Create(var fdConnection: TFDConnection);
begin

  if not Assigned(fdConnection) or Not fdConnection.Connected then
    raise TDAOException.Create('Não é possível criar um ''' + ClassName
      + ''' com TFDConnection nulo ou não conectado.');

  Self.fFdConnection := fdConnection;

end;

function TFDDAOBase<E>.DaoQuery(const sqlText: String; out fdQuery: TFDQuery;
                                parameters: TDictionary<String, Variant>;
                                dml: Boolean): Boolean;
begin
  Result := True;
  try
    TQueryManager.Instancia
      .CreateQuery(sqlText, fFdConnection, fdQuery, parameters, dml);
  except
    on DbException: EFDDBEngineException do
    begin
      Result := False;
      if Assigned(ErrorHandler) then
        ErrorHandler.HandleException(DbException);
    end;
  end;
end;

constructor TQueryManager.Create();
begin
  {objeto criado em TQueryManager.Inicializar}
end;

destructor TQueryManager.Destroy();
begin
  {não utilizado}
end;

end.
