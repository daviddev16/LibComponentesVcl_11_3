# LibComponentesVcl

A biblioteca LibComponentesVcl armazena componentes VCL que criei durante o desenvolvimento de alguns projetos. 
O componente principal é o ``TDCGrid``, que é capaz de renderizar Badges, Texto, Memo e Icones através de um JSONArray
que informa quais customizações serão feitas na célula. Quando utilizado um ``TDataSet``, é necessário implementar um
``IDCDataSetInterceptor`` que determinará como o campo do dataSet será renderizado na Grid.

## Aviso
Essa biblioteca ainda está em desenvolvimento. É utilizada em alguns projetos que estou fazendo, sendo assim, é possível que haja bugs ou algumas implementações faltando.

# Exemplo
Neste exemplo, criamos uma classe que extende ``IDCDataSetInterceptor`` chamada ``TMainGridInterceptor``, que fará a renderização de uma Grid principal. 

```pascal

...

procedure TMainGridInterceptor.RenderizarProjeto(var field: TField; var ComJSONArray: TJSONArray);
var
  QueryIdProjetos : TArray<Variant>;
  TemProjeto : Boolean;
begin
  TemProjeto := False;
  QueryIdProjetos := TMiscUtil.GetFieldList(Field);
  for var QrIdProjeto in QueryIdProjetos do
    for var LocalProjeto in CargaLocalProjetos do
    begin
      if QrIdProjeto = LocalProjeto.IdProjeto then
      begin
        TemProjeto := True;
        ComJSONArray.Add(
          TDCBadgeCellData.CreateJSONObject(
            LocalProjeto.CorTexto,
            LocalProjeto.CorFundo,
            LocalProjeto.Nome));
      end;
    end;
  if not TemProjeto then
  begin
    ComJSONArray.Add(
      TDCBadgeCellData.CreateJSONObject(
        GerenciadorConfiguracao.CorFgTextoDesabilitado,
        GerenciadorConfiguracao.CorBgTextoDesabilitado,
        'Sem projeto definido'));
  end;
  SetLength(QueryIdProjetos, 0);
end;

...

function TMainGridInterceptor.GetDataCellValue(var field: TField; fieldName: String;
                                               RowIndex: Integer; var dataSet: TDataSet): String;
var
  ComJSONArray : TJSONArray;
  CorTextoSimples : String;
begin
  CorTextoSimples := GetCalcularCorTextoSimples(dataSet);
  ComJSONArray := TJSONArray.Create;

  if fieldName = 'projetos' then
    RenderizarProjeto(field, ComJSONArray)

  else if fieldName = 'idcbperiodos' then
    RenderizarPeriodos(field, ComJSONArray)

  else if MatchText(fieldName, ['login', 'dscolaborador','observacao',
                                'totaldiasprevistos', 'totaldiasregistrados', 'icone']) then
    TGlobalVisualMiscs.RenderizarTextoSimples(field, ComJSONArray, CorTextoSimples);

  Result := ComJSONArray.ToString;
  ComJSONArray.Free;
end;

...

````

![Exemplo01](https://i.imgur.com/PEmeeSJ.png)
