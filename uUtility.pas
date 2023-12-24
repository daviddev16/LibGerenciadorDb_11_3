unit uUtility;

interface

uses
  DB,
  System.Variants,
  System.Rtti,
  System.Classes,
  System.Generics.Collections,
  SysUtils,
  Vcl.Dialogs;

type

  TValidationException = class(Exception);
  TDAOException = class(Exception);

  {
    TRttiUtil = Utilitários de RTTI
    Descrição: Classes com algumas funções que ajudam na interação com tipos  RTTI.
  }
  TRttiUtil = class
    public
      class function GetAttrFromField<T:class>(field: TRttiField; out attr: T): Boolean;
      class function GettAttrFromType<T:class>(classType: TRttiType; out attr: T): Boolean;
  end;

  TMiscUtil = class
    public
      class function ConvertBooleanToStr(const bool: Boolean): String;
      class function GetFieldList(var field: TField) : TArray<Variant>;
      class function CheckStrInArray(const str: String; values: Array of String): Boolean;
  end;

implementation

{
  Descrição: Retorna o attributo de tipo T se for encontrado no método de TRttiField.

  field      : TRttiField atual;
  attr       : o objeto de tipo <T>;
}
class function TRttiUtil.GetAttrFromField<T>(field: TRttiField; out attr: T): Boolean;
begin
  Result := False;
  for var FieldAttribute in field.GetAttributes do
    if FieldAttribute is T then
    begin
      attr := FieldAttribute as T;
      Exit(True);
    end;
end;

{
  Descrição: Retorna o attributo de tipo T se for encontrado no tip de TRttiType.

  classType  : TRttiType atual;
  attr       : o objeto de tipo <T>;
}
class function TRttiUtil.GettAttrFromType<T>(classType: TRttiType; out attr: T): Boolean;
begin
  Result := False;
  for var TypeAttribute in classType.GetAttributes do
    if TypeAttribute is T then
    begin
      attr := TypeAttribute as T;
      Exit(True);
    end;
end;

class function TMiscUtil.CheckStrInArray(const str: String; values: Array of String): Boolean;
begin
  Result := False;
  for var ValStr in values do
    if SameText(ValStr, str) then
    begin
      Exit(True);
    end;
end;

class function TMiscUtil.GetFieldList(var field: TField) : TArray<Variant>;
var
  VariantList : TList<Variant>;
  NestedDataSet : TDataSet;
  I : Integer;
begin
  if not VarIsArray(field.AsVariant) then
    raise Exception.Create('Este field não é um array');

  NestedDataSet := TDataSetField(field).NestedDataSet;
  VariantList := TList<Variant>.Create;

  while not NestedDataSet.Eof do
  begin
    VariantList.Add(NestedDataSet.Fields.Fields[0].AsVariant);
    NestedDataSet.Next;
  end;
  Result := VariantList.ToArray;
  VariantList.Free;
end;

class function TMiscUtil.ConvertBooleanToStr(const bool: Boolean): String;
begin
  if bool then
    Result := 'true'
  else
    Result := 'false';
end;


end.
