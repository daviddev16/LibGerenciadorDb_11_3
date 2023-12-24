unit uSQLRTTIBuilders;

{
  *******************************************************************************
  *                                                                             *
  *    uSQLRTTIBuilders - Classes utilitárias que auxiliam na criação de        *
                          queries. Utilizada em "uRepo" para geração de SQL     *
                          dinâmico.                                             *
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
  uSQLAttr,
  uUtility,
  TypInfo,
  SysUtils,
  System.JSON,
  System.Classes,
  System.Variants,
  System.Generics.Collections,
  System.Generics.Defaults,
  FireDAC.Comp.Client,
  FireDAC.Stan.Error,
  Vcl.Dialogs;

type
  TSQLFilterBuilder = class
    private
      Filter : TStringBuilder;
      procedure SetText(text: String);
      function GetText(): String;

    public
      constructor Create;
      destructor Destroy;

      function Add(colunmName: String; value: Variant): TSQLFilterBuilder;
      function SqlAnd(): TSQLFilterBuilder;
      function SqlOr(): TSQLFilterBuilder;

      property Text : String read GetText write SetText;

  end;

  TRtSQLEntityBuilder = class
    public
      class function CreateDelete(classTypeInfo: Pointer; filter: TSQLFilterBuilder): String;
      class function CreateInsert(classTypeInfo: Pointer; entityInstance: TObject): String;
      class function CreateUpdate(classTypeInfo: Pointer; filter: TSQLFilterBuilder;
                                  changes: TDictionary<String, Variant>): String;
      class function CreateSelect(classTypeInfo: Pointer; fields: TArray<String>;
                                  filter: TSQLFilterBuilder): String;
  end;

implementation

class function TRtSQLEntityBuilder.CreateDelete(classTypeInfo: Pointer;
                                                filter: TSQLFilterBuilder): String;
var
  Context : TRttiContext;
  ClassType : TRttiType;
  SqlBuilder : TStringBuilder;
  AttrDbTable : TDbTable;
  ColSize : Integer;
begin

  Context := TRttiContext.Create;
  ClassType := Context.GetType(classTypeInfo);

  if not TRttiUtil.GettAttrFromType<TDbTable>(ClassType, AttrDbTable) then
    raise TDAOException.Create('Não é possível mapear um tipo sem TDbTable.');

  if not Assigned(filter) then
    raise TDAOException.Create('Não é possível excluir uma entidade sem filtro SQL.');

  SqlBuilder := TStringBuilder.Create;

  with (SqlBuilder) do
  begin
    Append('DELETE FROM ');
    Append(AttrDbTable.fTableName);
    Append(' WHERE ');
    Append(filter.Text);
    Append(';');
  end;

  Result := SqlBuilder.ToString;
  SqlBuilder.Free;
  Context.Free;
end;

class function TRtSQLEntityBuilder.CreateSelect(classTypeInfo: Pointer; fields: TArray<String>;
                                                filter: TSQLFilterBuilder): String;
var
  Context : TRttiContext;
  ClassType : TRttiType;
  SqlBuilder : TStringBuilder;
  AttrDbTable : TDbTable;
begin

  Context := TRttiContext.Create;
  ClassType := Context.GetType(classTypeInfo);

  if not TRttiUtil.GettAttrFromType<TDbTable>(ClassType, AttrDbTable) then
    raise TDAOException.Create('Não é possível mapear um tipo sem TDbTable.');

  SqlBuilder := TStringBuilder.Create;

  with (SqlBuilder) do
  begin
    Append('SELECT ');
    if System.Length(fields) > 0 then
      Append(String.Join(',', fields))
    else
      Append('*');

    Append(' FROM ');
    Append(AttrDbTable.fTableName);
    if Assigned(filter) then
    begin
      Append(' WHERE ');
      Append(filter.Text);
    end;
    Append(';');
  end;

  Result := SqlBuilder.ToString;
  SqlBuilder.Free;
  Context.Free;
end;

class function TRtSQLEntityBuilder.CreateUpdate(classTypeInfo: Pointer; filter: TSQLFilterBuilder;
                                                changes: TDictionary<String, Variant>): String;
var
  Context : TRttiContext;
  ClassType : TRttiType;
  SqlBuilder : TStringBuilder;
  SetList : TStringList;
  AttrDbTable : TDbTable;
begin
  Context := TRttiContext.Create;
  ClassType := Context.GetType(classTypeInfo);

  if not TRttiUtil.GettAttrFromType<TDbTable>(ClassType, AttrDbTable) then
    raise TDAOException.Create('Não é possível mapear um tipo sem TDbTable.');

  SetList := TStringList.Create;

  for var ChangePair in changes do
      SetList.Add(Format('%s=''%s''', [ChangePair.Key, ChangePair.Value]));

  if String.IsNullOrWhitespace(SetList.Text) then
    raise TDAOException.Create('Não há mudanças a serem feitas! Verifique.');

  SqlBuilder := TStringBuilder.Create;

  with (SqlBuilder) do
  begin
    Append('UPDATE ');
    Append(AttrDbTable.fTableName);
    Append(' SET ');
    Append(String.Join(', ', SetList.ToStringArray));
    Append( ' WHERE ');
    Append(filter.Text);
    Append(';');
  end;

  Result := SqlBuilder.ToString;
  SqlBuilder.Free;
  SetList.Free;
  Context.Free;
end;

class function TRtSQLEntityBuilder.CreateInsert(classTypeInfo: Pointer;
                                                entityInstance: TObject): String;
var
  Context : TRttiContext;
  ClassType : TRttiType;
  DeclaredFields : TArray<TRttiField>;
  AttrDbField : TDbField;
  FreeColumnNames : TStringList;
  FieldValues : TStringList;
  SqlBuilder : TStringBuilder;
  FieldValue : TValue;
  AttrDbTable : TDbTable;
begin

  Context := TRttiContext.Create;
  ClassType := Context.GetType(classTypeInfo);

  DeclaredFields := ClassType.GetDeclaredFields;

  if not TRttiUtil.GettAttrFromType<TDbTable>(ClassType, AttrDbTable) then
    raise TDAOException.Create('Não é possível mapear um tipo sem TDbTable.');

  FreeColumnNames := TStringList.Create;
  FieldValues := TStringList.Create;

  for var Field in DeclaredFields do
  begin
    if Field.HasAttribute<TDbSeqId> then
      continue;

    if TRttiUtil.GetAttrFromField<TDbField>(Field, AttrDbField) then
    begin
      FieldValue := Field.GetValue(entityInstance);
      FreeColumnNames.Add(AttrDbField.fFieldName);
      FieldValues.Add(Format('''%s''', [ VarToStr(FieldValue.AsVariant) ]));
    end;

  end;

  if String.IsNullOrWhitespace(FreeColumnNames.Text) then
    raise TDAOException.Create('Não é possível executar um insert sem colunas.');

  SqlBuilder := TStringBuilder.Create;

  with (SqlBuilder) do
  begin
    Append('INSERT INTO ');
    Append(AttrDbTable.fTableName);
    Append(' (');
    Append(String.Join(', ', FreeColumnNames.ToStringArray));
    Append(') VALUES (');
    Append(String.Join(', ', FieldValues.ToStringArray));
    Append(');');
  end;
  Result := SqlBuilder.ToString;
  SqlBuilder.Free;
  FreeColumnNames.Free;
  DeclaredFields := nil;
  Context.Free;
end;


constructor TSQLFilterBuilder.Create;
begin
  Filter := TStringBuilder.Create;
end;

destructor TSQLFilterBuilder.Destroy;
begin
  Filter.Free;
end;

function TSQLFilterBuilder.Add(colunmName: String; value: Variant): TSQLFilterBuilder;
begin
  Filter.Append(Format('%s = %s', [colunmName, VarToStr(value)]));
  Result := Self;
end;

function TSQLFilterBuilder.SqlAnd(): TSQLFilterBuilder;
begin
  Filter.Append(' AND ');
  Result := Self;
end;

function TSQLFilterBuilder.SqlOr(): TSQLFilterBuilder;
begin
  Filter.Append(' OR ');
  Result := Self;
end;

function TSQLFilterBuilder.GetText(): String;
begin
  Result := Filter.ToString;
end;

procedure TSQLFilterBuilder.SetText(text: String);
begin
  Filter.Clear;
  Filter.Append(text);
end;

end.
