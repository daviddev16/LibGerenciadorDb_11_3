unit uSQLAttr;

{
  *******************************************************************************
  *                                                                             *
  *    uSQLAttr - Unit que armazena os atributos que s�o utilizados para marcar *
                  As classes que s�o mapeadas para SQL ou SQL para objeto;      *
  *                                                                             *
  *    Autor: David Duarte Pinheiro                                             *
  *    Github: daviddev16                                                       *
  *                                                                             *
  *******************************************************************************
}

interface

type

  TDbField = class(TCustomAttribute)
    public
      fFieldName : String;
    public
      constructor Create(fieldName: String);
      property FieldName : String read fFieldName;
  end;

  TDbSeqId = class(TCustomAttribute)
  {APENAS PARA MARCA��O}
  end;

  TDbTable = class(TCustomAttribute)
    public
      fTableName : String;
    public
      constructor Create(tableName: String);
      property TableName : String read fTableName;
  end;

  TDbDummy = class(TCustomAttribute)
  {APENAS PARA MARCA��O}
  end;


implementation

constructor TDbField.Create(fieldName: String);
begin
  fFieldName := fieldName;
end;

constructor TDbTable.Create(tableName: String);
begin
  fTableName := tableName;
end;

end.
