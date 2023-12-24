unit D16Grids;

{
  *******************************************************************************
  *                                                                             *
  *    D16Grids - Unit que armazena as implementações para grids. TDCGrid       *
  *               herda de TStringGrid, porém, renderiza conteudo JSON em       *
  *               gráfico na grid. Tipos de objetos que podem ser renderi       *
  *               zados: BADGE, SINGLE_TEXT, MULTILINE_TEXT, IMAGE_INDEX        *
  *                                                                             *
  *    Autor: David Duarte Pinheiro                                             *
  *    Github: daviddev16                                                       *
  *                                                                             *
  *******************************************************************************
}


interface

uses
  D16Utils,
  TypInfo,
  Winapi.Windows,
  System.SysUtils,
  System.StrUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  System.Generics.Collections,
  System.JSON,
  Vcl.Grids,
  Vcl.Dialogs,
  Vcl.Graphics,
  Vcl.Imaging.pngimage,
  Vcl.Imaging.jpeg,
  DBClient,
  D16Custom,
  DB,
  Math,
  RTTI;

type

  TDCGridException = class(Exception);
  TInvalidDataException = class(TDCGridException);
  TInvalidOperationException = class(TDCGridException);

  EDataCellType = (
    BADGE,
    SINGLE_TEXT,
    MULTILINE_TEXT,
    IMAGE_INDEX
  );

  TDCCellDataBase = class abstract
    private
      fCellType     : EDataCellType;
      fIsColumnCell : Boolean;

    public
      class function ConvertStrToDataCellType(dataTypeName: String): EDataCellType;
      property CellDataType : EDataCellType read fCellType;
      function GetRawStr : String; virtual; abstract;

    protected
      property IsColumnCell : Boolean read fIsColumnCell write fIsColumnCell;

  end;

  TDCBadgeCellData = class(TDCCellDataBase)
    private
      fClFonte : TColor;
      fClFundo : TColor;
      fTexto   : String;

    public
      class function CreateJSONObject(const clFonte, clFundo, texto: String): TJSONObject;
      constructor Create(clFonte : String; clFundo: String; texto: String);
      function GetRawStr : String; override;
      property CorFonte  : TColor read fClFonte;
      property CorFundo  : TColor read fClFundo;
      property Texto     : String read fTexto;
  end;

  TDCTextCellData = class(TDCCellDataBase)
    private
      fTexto   : String;
      fClFonte : TColor;

    public
     class function CreateJSONObject(const clFonte, texto: String): TJSONObject;
     constructor Create(texto: String; clFonte: String); overload;
     constructor Create(texto: String; clFonte: TColor); overload;
     function GetRawStr : String; override;

     property Texto    : String read fTexto;
     property CorFonte : TColor read fClFonte;

  end;

  TDCMultiTextCellData = class(TDCCellDataBase)
    private
      fLinhas : TArray<String>;
      fClFonte : TColor;
    public
      class function CreateJSONObject(linhas: TArray<String>; const clTexto: String): TJSONObject;
      constructor Create(linhas: TArray<String>; clFundo: String);

      property CorFonte : TColor read fClFonte;
      property Linhas : TArray<String> read fLinhas;

  end;

  TDCImageIndexCellData = class(TDCCellDataBase)
    private
      fIndex : Integer;
      public
        constructor Create(index : Integer);

        property ImageIndex : Integer read fIndex;

  end;

  IDCDataSetInterceptor = interface
    function GetDataCellValue(var field: TField; fieldName: String; RowIndex: Integer; var dataSet: TDataSet): String;
    function GetColumnCellValue(columnValue: String): String;
  End;

  TDefaultDataSetInterceptor = class(TInterfacedObject, IDCDataSetInterceptor)
    public
      function GetDataCellValue(var field: TField; fieldName: String; RowIndex: Integer; var dataSet: TDataSet): String;
      function GetColumnCellValue(columnValue: String): String;
  end;

  IDCGridCellDataFactory<T> = interface
    function ValidateBefore(var rawContent: String) : Boolean;
    function CreateCellDataFromContent(var childNode: T): TDCCellDataBase;
    function CreateBadgeData(var childNode: T): TDCBadgeCellData;
    function CreateTextCellData(var childNode: T): TDCTextCellData;
    function CreateMultiTextCellData(var childNode: T): TDCMultiTextCellData;
    function CreateImageIndexCellData(var childNode: T): TDCImageIndexCellData;

  end;

  TDCJSONCellDataFactory = class(TInterfacedObject, IDCGridCellDataFactory<TJSONObject>)
    public
      function ValidateBefore(var rawContent: String) : Boolean;
      function CreateCellDataFromContent(var childNode: TJSONObject): TDCCellDataBase;
      function CreateBadgeData(var childNode: TJSONObject): TDCBadgeCellData;
      function CreateTextCellData(var childNode: TJSONObject): TDCTextCellData;
      function CreateMultiTextCellData(var childNode: TJSONObject): TDCMultiTextCellData;
      function CreateImageIndexCellData(var childNode: TJSONObject): TDCImageIndexCellData;
  end;

  TDCGridDrawOptions = class
    private
      fSelectionFontColor   : TColor;
      fSelectionFillColor   : TColor;
      fSelectionBadgeColor  : TColor;
      fColumnTitleFontColor : TColor;
      fRowLeftMargin : Integer;
      fRowTopMargin  : Integer;
      fBadgeTopPadding   : Integer;
      fBadgeLeftPadding  : Integer;
      fBadgeSpacing      : Integer;
      fTitleColumnHeight : Integer;
      fDrawColumnLine : Boolean;
      fCenterColumnNames : Boolean;

      const cfDefSelectionFillColor   = clBlue;
      const cfDefSelectionFontColor   = clWhite;
      const cfDefSelectionBadgeColor  = clWebSkyBlue;
      const cfDefColumnTitleFontColor = clBlue;
      const cfRowLeftMaginMin = 2;
      const cfRowTopMaginMin  = 2;
      const cfBadgeTopPaddingMin  = 2;
      const cfBadgeLeftPaddingMin = 1;
      const cfBadgeSpacingMin     = 2;
      const cfTitleColumnHeight   = 20;

      procedure SetRowLeftMargin(rowLeftMargin: Integer);
      procedure SetRowTopMargin(rowTopMargin: Integer);
      procedure SetBadgeTopPadding(badgeTopPadding: Integer);
      procedure SetBadgeLeftPadding(badgeLeftPadding: Integer);
      procedure SetBadgeSpacing(badgeSpacing: Integer);
      procedure SetTitleColumnHeight(columnHeight: Integer);

    public
      property SelectionFontColor   : TColor read fSelectionFontColor write fSelectionFontColor;
      property SelectionFillColor   : TColor read fSelectionFillColor write fSelectionFillColor;
      property SelectionBadgeColor  : TColor read fSelectionBadgeColor write fSelectionBadgeColor;
      property ColumnTitleFontColor : TColor read fColumnTitleFontColor write fColumnTitleFontColor;
      property RowLeftMargin : Integer read fRowLeftMargin write SetRowLeftMargin;
      property RowTopMargin  : Integer read fRowTopMargin write SetRowTopMargin;
      property BadgeTopPadding   : Integer read fBadgeTopPadding write fBadgeTopPadding;
      property BadgeLeftPadding  : Integer read fBadgeLeftPadding write SetBadgeLeftPadding;
      property BadgeSpacing      : Integer read fBadgeSpacing write SetBadgeSpacing;
      property TitleColumnHeight : Integer read fTitleColumnHeight write SetTitleColumnHeight;
      property DrawColumnLine : Boolean read fDrawColumnLine write fDrawColumnLine;
      property CenterColumnNames : Boolean read fCenterColumnNames write fCenterColumnNames;

      procedure SetupDefaults();

  end;

  TDCGrid = class(TStringGrid)
    private

      JsonCellFactory : TDCJSONCellDataFactory;
      ImageMapper     : TDictionary<Integer, TGraphic>;
      DsInterceptor   : IDCDataSetInterceptor;
      DrawOptions     : TDCGridDrawOptions;
      CurrentDataSet  : TDataSet;
      LastRowIndex    : Integer;

      procedure SetupGridInitialParameters;
      procedure FillBackground(Rect : TRect);

      procedure GridDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);

      procedure DrawSingleText(var Rect: TRect; var LastSingleLineWidth: Integer;
        var CurrentBaseHeight : Integer; var CellData: TDCCellDataBase; IsSelected: Boolean);

      procedure DrawColumnText(var Rect: TRect; var LastSingleLineWidth: Integer;
        var CurrentBaseHeight : Integer; var CellData: TDCCellDataBase; IsSelected: Boolean);

      procedure DrawMultilineText(var Rect: TRect; var CurrentBaseHeight : Integer;
        var CellData: TDCCellDataBase; IsSelected: Boolean);

      procedure DrawBadgeText(var Rect: TRect; var LastBadgeHeight: Integer;
        var CurrentBaseHeight: Integer; var CellData: TDCCellDataBase; IsSelected: Boolean);

      procedure DrawIndexedImage(var Rect: TRect; var CurrentBaseHeight: Integer;
        var CellData: TDCCellDataBase; IsSelected: Boolean);

      procedure UpdateCellValue(Row: Integer; Col: Integer; NewValue: String);
      procedure InsertOffsetValues(Data: TArray<String>);
      procedure SetCurrentDataSet(DataSet: TDataSet);

    public
      constructor Create(AOwner: TComponent); override;
      procedure Unselect;
      procedure ClearTableCells;
      procedure SetTitles(ColumnNames: Array of String);
      procedure RegisterImageIndex(index : Integer; res: String);
      procedure ResizeColumnsToGridWidth();
      property CustomDrawOptions : TDCGridDrawOptions read DrawOptions;
      property DataSet : TDataSet read CurrentDataSet write SetCurrentDataSet;
      property DataSetInterceptor : IDCDataSetInterceptor read DsInterceptor write DsInterceptor;


    protected
  end;

  TKeyDict = class
    public
      const clFonteKey  = 'fg';
      const clFundoKey  = 'bg';
      const vlTextoKey  = 'tx';
      const vlLinhasKey =  'ln';
      const vlTipoKey   = 'tp';
      const vlIndexKey  = 'idx';
  end;

procedure Register;

implementation

{ TDCGrid }

constructor TDCGrid.Create(AOwner: TComponent);
begin
  inherited;
  SetupGridInitialParameters;
end;

procedure TDCGrid.SetTitles(ColumnNames: Array of String);
var
  I : Integer;
begin
  if Length(ColumnNames) <= 0 then
    TInvalidOperationException.Create('Número de colunas inválido.');

  if RowCount <= 0 then
    RowCount := 1;

  ColCount := Length(ColumnNames);

  for I := 0 to Length(ColumnNames) - 1 do
  begin
    UpdateCellValue(0, I, TDCTextCellData.Create(ColumnNames[I],
      DrawOptions.fColumnTitleFontColor).GetRawStr);
  end;
  ResizeColumnsToGridWidth;
  Invalidate;
  Update;
end;


procedure TDCGrid.SetupGridInitialParameters;
begin
  if JsonCellFactory = nil then
    JsonCellFactory := TDCJSONCellDataFactory.Create;

  if DrawOptions = nil then
  begin
    DrawOptions := TDCGridDrawOptions.Create;
    DrawOptions.SetupDefaults;
  end;

  if ImageMapper = nil then
    ImageMapper := TDictionary<Integer, TGraphic>.Create;

  {if DsInterceptor = nil then
    DsInterceptor := TDefaultDataSetInterceptor.Create;}

  DefaultDrawing := False;
  GridLineWidth := 0;
  FixedRows := 1;
  FixedCols := 0;

  Options := [
    goFixedVertLine,
    goFixedHorzLine,
    goVertLine,
    goHorzLine,
    goRangeSelect,
    goDrawFocusSelected,
    goRowSizing,
    goColSizing,
    goEditing,
    goRowSelect,
    goThumbTracking,
    goFixedRowDefAlign
  ];
  OnDrawCell := GridDrawCell;
end;

procedure TDCGrid.GridDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var
  CellText : string;
  CurrentCellData : TDCCellDataBase;
  CurrentColCellData : TDCTextCellData;
  CellJsonArray : TJSONArray;
  ChildJSONObject : TJSONObject;
  LastSingleLineWidth : Integer;
  LastBadgeHeight : Integer;
  CurrentBaseHeight : Integer;
  TitleLineRect : TRect;
  IsSelected : Boolean;
begin

  CellText := Cells[ACol, ARow];
  IsSelected := gdSelected in State;

  if IsSelected then
    Canvas.Brush.Color := DrawOptions.fSelectionFillColor
  else
    Canvas.Brush.Color := clWhite;

  Canvas.FillRect(Rect);

  if JsonCellFactory.ValidateBefore(CellText) then
  begin
    LastBadgeHeight := 0;
    LastSingleLineWidth := 0;
    CurrentBaseHeight := 0;
    CellJsonArray := TJSONArray.ParseJSONValue(CellText) as TJSONArray;

    for var JsonValueChildNode in CellJsonArray do
    begin
      ChildJSONObject := JsonValueChildNode as TJSONObject;
      CurrentCellData := JsonCellFactory.CreateCellDataFromContent(ChildJSONObject);

      if ARow <> 0 then
      begin
      if CurrentCellData.CellDataType = EDataCellType.SINGLE_TEXT then
        DrawSingleText(Rect, LastSingleLineWidth, CurrentBaseHeight, CurrentCellData, IsSelected)

      else if CurrentCellData.CellDataType = EDataCellType.BADGE then
        DrawBadgeText(rect, LastBadgeHeight, CurrentBaseHeight, CurrentCellData, IsSelected)

      else if CurrentCellData.CellDataType = EDataCellType.MULTILINE_TEXT then
        DrawMultilineText(Rect, CurrentBaseHeight, CurrentCellData, IsSelected)

      else if CurrentCellData.CellDataType = EDataCellType.IMAGE_INDEX then
           DrawIndexedImage(Rect, CurrentBaseHeight, CurrentCellData, IsSelected);
      end
      else
      begin
        DrawColumnText(Rect, LastSingleLineWidth,
          CurrentBaseHeight, CurrentCellData, IsSelected);
      end;

      if RowHeights[Arow] < CurrentBaseHeight then
        RowHeights[ARow] := CurrentBaseHeight;

    end;
  end;
  Canvas.Pen.Color := clBlack;
  Canvas.Pen.Style := TPenStyle.psSolid;
end;

{ desenha os titulos das colunas }
procedure TDCGrid.DrawColumnText(var Rect: TRect; var LastSingleLineWidth: Integer;
        var CurrentBaseHeight : Integer; var CellData: TDCCellDataBase; IsSelected: Boolean);
var
  StrColValue : String;
  ColCellData : TDCTextCellData;
  TitleLineRect : TRect;
  Left : Integer;
  Top : Integer;
begin
  ColCellData := CellData as TDCTextCellData;
  StrColValue := ColCellData.Texto;
  if Not String.IsNullOrWhiteSpace(StrColValue) then
  begin
    Canvas.Font.Color := clBlack;

    if DrawOptions.CenterColumnNames then
    begin
      Left := (Rect.Left + Rect.Right) div 2 - Canvas.TextWidth(ColCellData.Texto) div 2;
      Top := (Rect.Top + Rect.Bottom) div 2 - Canvas.textHeight(ColCellData.Texto) div 2;
    end
    else
    begin
      Left := Rect.Left + DrawOptions.RowLeftMargin;
      Top := (Rect.Top) + DrawOptions.RowTopMargin;
    end;

    Canvas.TextOut(Left, Top, StrColValue );

    if DrawOptions.DrawColumnLine then
    begin
      Canvas.Brush.Color := clBlack;
      TitleLineRect := Rect;
      TitleLineRect.Left := TitleLineRect.Left + DrawOptions.RowLeftMargin div 2;
      TitleLineRect.Right := TitleLineRect.Right - DrawOptions.RowLeftMargin div 2;
      TitleLineRect.Top := TitleLineRect.Bottom - 1;
      Canvas.FillRect(TitleLineRect);

    end;
    CurrentBaseHeight := Canvas.TextHeight(StrColValue) + DrawOptions.RowTopMargin * 2;
  end;
  ColCellData.Free;
end;

{ desenha SINGLELINE texto com uma linha sem quebra de linha }
procedure TDCGrid.DrawSingleText(var Rect: TRect; var LastSingleLineWidth: Integer;
  var CurrentBaseHeight : Integer; var CellData: TDCCellDataBase; IsSelected: Boolean);
var
  StrTextValue : String;
  TextCellData : TDCTextCellData;
begin
  TextCellData := CellData as TDCTextCellData;
  StrTextValue := TextCellData.Texto;
  if Not String.IsNullOrWhiteSpace(StrTextValue) then
  begin
    if isSelected then
      Canvas.Font.Color := DrawOptions.SelectionFontColor
    else
      Canvas.Font.Color := TextCellData.CorFonte;

    Canvas.TextOut(
      Rect.Left + DrawOptions.RowLeftMargin + LastSingleLineWidth + 1,
      Rect.Top + DrawOptions.RowTopMargin,
      StrTextValue
    );

    Inc(LastSingleLineWidth, Canvas.TextWidth(StrTextValue));
    CurrentBaseHeight := Canvas.TextHeight(StrTextValue) + DrawOptions.RowTopMargin * 2;
  end;
  TextCellData.Free;
end;

{ desenha textos com multilinas }
procedure TDCGrid.DrawMultilineText(var Rect: TRect; var CurrentBaseHeight : Integer;
  var CellData: TDCCellDataBase; IsSelected: Boolean);
var
  StrLine : String;
  LineCount : Integer;
  MultiTextCellData : TDCMultiTextCellData;
  LastLineHeight : Integer;
begin
  MultiTextCellData := CellData as TDCMultiTextCellData;
  LineCount := Length(MultiTextCellData.Linhas);
  if LineCount > 0 then
  begin
    LastLineHeight := 0;
    for StrLine in MultiTextCellData.Linhas do
    begin
      if Not String.IsNullOrWhiteSpace(StrLine) then
      begin
        if isSelected then
          Canvas.Font.Color := DrawOptions.SelectionFontColor
        else
          Canvas.Font.Color := MultiTextCellData.CorFonte;

        Canvas.TextOut(
          Rect.Left + DrawOptions.RowLeftMargin,
          Rect.Top + DrawOptions.RowTopMargin + CurrentBaseHeight,
          StrLine
        );
        Inc(LastLineHeight, Canvas.TextHeight(StrLine) + 1);
        Inc(CurrentBaseHeight, LastLineHeight);
      end;
    end;
  end;
  MultiTextCellData.Free;
end;

{ desenha badges na grid }
procedure TDCGrid.DrawBadgeText(var Rect: TRect; var LastBadgeHeight: Integer; var CurrentBaseHeight : Integer;
  var CellData: TDCCellDataBase; IsSelected: Boolean);
var
  StrBadgeValue   : String;
  BadgeCellData   : TDCBadgeCellData;
  BadgeDefHeight  : Integer;
  BadgeTextHeight     : Integer;
  BadgeTextWidth      : Integer;
  BadgeRect : TRect;

begin
  BadgeCellData := CellData as TDCBadgeCellData;
  StrBadgeValue := BadgeCellData.Texto;
  if Not String.IsNullOrWhiteSpace(StrBadgeValue) then
  begin
    Canvas.Font.Style := [TFontStyle.fsBold];

    BadgeTextHeight := Canvas.TextHeight(StrBadgeValue);
    BadgeTextWidth := Canvas.TextWidth(StrBadgeValue);

    BadgeRect := Rect;
    BadgeRect.Left   := BadgeRect.Left + DrawOptions.RowLeftMargin;
    BadgeRect.Top    := BadgeRect.Top + DrawOptions.RowTopMargin + LastBadgeHeight;
    BadgeRect.Right  := BadgeRect.Left + BadgeTextWidth + DrawOptions.BadgeLeftPadding;
    BadgeRect.Bottom := BadgeRect.Top + BadgeTextHeight + DrawOptions.BadgeTopPadding;

    if isSelected then
    begin
      Canvas.Pen.Color := DrawOptions.fSelectionFillColor;
      Canvas.Brush.Color := clWhite;
    end
    else
    begin
      Canvas.Pen.Color := clWhite;
      Canvas.Brush.Color := BadgeCellData.fClFundo;
    end;

    Canvas.Pen.Style := TPenStyle.psSolid;
    Canvas.Brush.Style := TBrushStyle.bsSolid;
    Canvas.RoundRect(BadgeRect, 6, 6);

    if isSelected then
      Canvas.Font.Color := DrawOptions.SelectionFillColor
    else
      Canvas.Font.Color := BadgeCellData.CorFonte;

    Canvas.TextOut(
      (BadgeRect.Left + BadgeRect.Right) div 2 - BadgeTextWidth div 2,
      (BadgeRect.Top + BadgeRect.Bottom) div 2 - BadgeTextHeight div 2,
      StrBadgeValue
    );
    Canvas.Font.Style := [];

    Inc(LastBadgeHeight, BadgeTextHeight + DrawOptions.BadgeTopPadding + DrawOptions.BadgeSpacing);
    {melhorar dps}
    Inc(CurrentBaseHeight, BadgeRect.Size.Height - DrawOptions.BadgeSpacing + DrawOptions.BadgeTopPadding + DrawOptions.RowTopMargin);
  end;
  BadgeCellData.Free;
end;

{TODO: DESENHAR IMAGEM INDEXADA NA GRID }
procedure TDCGrid.DrawIndexedImage(var Rect: TRect; var CurrentBaseHeight: Integer;
  var CellData: TDCCellDataBase; IsSelected: Boolean);
var
  ImageIndexCellData : TDCImageIndexCellData;
  ImageGraphic : TGraphic;
begin
  ImageIndexCellData := (CellData as TDCImageIndexCellData);
  if (ImageMapper.TryGetValue(ImageIndexCellData.ImageIndex, ImageGraphic)) then
  begin
    Canvas.Draw(
    Rect.Left + DrawOptions.RowLeftMargin,
    Rect.Top + DrawOptions.RowTopMargin,
    ImageGraphic);
  end;
  ImageIndexCellData.Free;
end;

{ FAZ AS COLUNAS SE AJUSTAREM DO TAMANHO DA TELA}
procedure TDCGrid.ResizeColumnsToGridWidth();
var
  TotalColumnWidth : Integer;
  GridWidth : Integer;
  ColumnsToResize: Integer;
  I: Integer;
begin
  TotalColumnWidth := 0;
  for i := 0 to ColCount - 1 do
    TotalColumnWidth := TotalColumnWidth + ColWidths[i];

  GridWidth := ClientWidth - FixedCols * DefaultColWidth;
  ColumnsToResize := ColCount - FixedCols;

  for i := FixedCols to ColCount - 1 do
    ColWidths[i] := Round(GridWidth * ColWidths[i] / TotalColumnWidth);
end;

{TESTANDO IMAGENS NA GRID }
procedure TDCGrid.RegisterImageIndex(index : Integer; res: String);
var
  jpge : TJPEGImage;
  Stream : TMemoryStream;
begin
  {try
    try
      Stream := TMemoryStream.Create;
      Stream.LoadFromFile('C:\Users\David\Pictures\aa.jpg');

      jpge := TJPEGImage.Create;
    finally

    Stream.Position := 0;
    jpge.LoadFromStream(Stream);
    ImageMapper.AddOrSetValue(index, jpge);

    end;
  except
    on E: Exception do
    begin
      if Assigned(jpge) then
      begin
      end;
      raise TInvalidOperationException.Create(Format('Houve um erro no carregamento ' +
        'da imagem de indice %d. [%s]', [index, E.Message]));
    end;
  end;}
end;

procedure TDCGrid.FillBackground(Rect : TRect);
begin
{todo:}
  Canvas.FillRect(Rect);
end;

procedure TDCGrid.SetCurrentDataSet(DataSet: TDataSet);
var
  ColumnNames : TArray<String>;
  FieldList   : TFieldList;
  TempValues  : TArray<String>;
  Field : TField;
  I : Integer;
begin

  if DsInterceptor = nil then
  begin
    raise TInvalidOperationException.Create('Não foi definido um DataSetInterceptor válido.');
  end;

  FieldList := DataSet.FieldList;
  SetLength(ColumnNames, FieldList.Count);

  for I := 0 to FieldList.Count - 1 do
  begin
    ColumnNames[I] := DsInterceptor.GetColumnCellValue(FieldList[I].FieldName);
  end;

  SetTitles(ColumnNames);

  ClearTableCells;
  RowCount := DataSet.RecordCount + 1;
  DataSet.DisableControls;
  try
    while not DataSet.Eof do
    begin
      SetLength(TempValues, DataSet.Fields.Count);
      for I := 0 to DataSet.Fields.Count - 1 do
      begin
        Field := DataSet.Fields[I];
        TempValues[I] := DsInterceptor.GetDataCellValue(Field, Field.FieldName, LastRowIndex + 1, DataSet);
      end;
      InsertOffsetValues(TempValues);
      DataSet.Next;
    end;
  finally
    DataSet.EnableControls;
  end;

end;

procedure TDCGrid.InsertOffsetValues(Data: TArray<String>);
var
  I : Integer;
begin
  for I := 0 to Length(Data) - 1 do
  begin
    UpdateCellValue(LastRowIndex, I, Data[I]);
  end;
  Inc(LastRowIndex);
end;

procedure TDCGrid.UpdateCellValue(Row: Integer; Col: Integer; NewValue: String);
begin
  Cells[Col, Row] := NewValue;
end;

procedure TDCGrid.Unselect;
begin
  Selection := TGridRect(Rect(-1, -1, -1, -1));
end;

procedure TDCGrid.ClearTableCells;
var
  i, j: Integer;
begin
  for I := 1 to RowCount - 1 do
    for J := 0 to ColCount - 1 do
    begin
      Cells[J, I] := '';
    end;
  RowCount := 2;
  LastRowIndex := 1;
end;

function TDefaultDataSetInterceptor.GetDataCellValue(var field: TField;
  fieldName: String; RowIndex: Integer; var dataset: TDataSet): String;
begin
  Result := TDCTextCellData.Create(VarToStr(Field.Value), clblack).GetRawStr;
end;

{TODO: melhorar apresentação dps }
function TDefaultDataSetInterceptor.GetColumnCellValue(columnValue: String): String;
begin
  Result := columnValue;
end;

{ ITDCCellDataBase }

class function TDCCellDataBase.ConvertStrToDataCellType(dataTypeName: String): EDataCellType;
var
  EnumValue: Integer;
begin
  EnumValue := GetEnumValue(TypeInfo(EDataCellType), dataTypeName);
  if EnumValue <> -1 then
    Result := EDataCellType(EnumValue)
  else
    TInvalidDataException.Create(Format('"%s" não é um valor válido para EDataCellType.', [dataTypeName]));
end;

{ TDCBadgeCellData }

class function TDCBadgeCellData.CreateJSONObject(const clFonte, clFundo, texto: String): TJSONObject;
var
  JSONObject : TJSONObject;
begin
  JSONObject := TJSONObject.Create;
  JSONObject.AddPair(TKeyDict.vlTipoKey, 'BADGE');
  JSONObject.AddPair(TKeyDict.clFonteKey, clFonte);
  JSONObject.AddPair(TKeyDict.vlTextoKey, texto);
  JSONObject.AddPair(TKeyDict.clFundoKey, clFundo);
  Result := JSONObject;
end;

constructor TDCBadgeCellData.Create(clFonte : String; clFundo: String; texto: String);
begin
  fTexto := texto;
  fClFonte := TUtil.HexToColor(clFonte);
  fClFundo := TUtil.HexToColor(clFundo);
  fCellType := BADGE;
end;

{ TDCMultiTextCellData }

class function TDCMultiTextCellData.CreateJSONObject(linhas: TArray<String>; const clTexto: String): TJSONObject;
var
  JSONObject : TJSONObject;
  LnJSONObject : TJSONObject;
  JSONArray : TJSONArray;
begin
  JSONArray := TJSONArray.Create;
  JSONObject := TJSONObject.Create;
  JSONObject.AddPair(TKeyDict.vlTipoKey, 'MULTILINE_TEXT');
  JSONObject.AddPair(TKeyDict.clFonteKey, clTexto);
  for var linha in linhas do
  begin
    LnJSONObject := TJSONObject.Create;
    LnJSONObject.AddPair(TKeyDict.vlTextoKey, linha);
    JSONArray.Add(LnJSONObject);
  end;

  JSONObject.AddPair(TKeyDict.vlLinhasKey, JSONArray);
  Result := JSONObject;
end;

constructor TDCMultiTextCellData.Create(linhas: TArray<String>; clFundo: String);
begin
  fLinhas := linhas;
  fCellType := MULTILINE_TEXT;
end;

class function TDCTextCellData.CreateJSONObject(const clFonte, texto: String): TJSONObject;
var
  JSONObject : TJSONObject;
begin
  JSONObject := TJSONObject.Create;
  JSONObject.AddPair(TKeyDict.vlTipoKey, 'SINGLE_TEXT');
  JSONObject.AddPair(TKeyDict.clFonteKey, clFonte);
  JSONObject.AddPair(TKeyDict.vlTextoKey, texto);
  Result := JSONObject;
end;

constructor TDCTextCellData.Create(texto: String; clFonte: String);
begin
  Self.Create(texto, TUtil.HexToColor(clFonte));
end;

constructor TDCTextCellData.Create(texto: String; clFonte: TColor);
begin
  fTexto := texto;
  fClFonte := clFonte;
  fCellType := SINGLE_TEXT;
end;

{ melhorar dps }
function TDCTextCellData.GetRawStr: String;
begin
  Result := Format('[{"%s":"%s","%s":"%s","%s":"%s"}]', [TKeyDict.vlTipoKey,'SINGLE_TEXT',
    TKeyDict.vlTextoKey, Texto, TKeyDict.clFonteKey, TUtil.ColorToHex(CorFonte)]);
end;

function TDCBadgeCellData.GetRawStr: String;
begin
  Result := Format('[{"%s":"%s","%s":"%s","%s":"%s","%":"%s"}]', [TKeyDict.vlTipoKey,'BADGE',
    TKeyDict.vlTextoKey, Texto, TKeyDict.clFonteKey, TUtil.ColorToHex(CorFonte),
    TKeyDict.clFundoKey, TUtil.ColorToHex(CorFundo)]);
end;

constructor TDCImageIndexCellData.Create(index : Integer);
begin
  fIndex := index;
  fCellType := IMAGE_INDEX;
end;

function TDCJSONCellDataFactory.ValidateBefore(var rawContent: String) : Boolean;
begin
  rawContent := rawContent.Trim;
  Result := rawContent.StartsWith('[{') and rawContent.EndsWith('}]');
end;

function TDCJSONCellDataFactory.CreateCellDataFromContent(var childNode: TJSONObject): TDCCellDataBase;
var
  CellType : EDataCellType;
begin
  CellType := TDCCellDataBase.ConvertStrToDataCellType(
    childNode.GetValue<String>(TKeyDict.vlTipoKey)
  );

  if CellType = EDataCellType.SINGLE_TEXT then
    Result := CreateTextCellData(childNode)

  else if CellType = EDataCellType.BADGE then
    Result := CreateBadgeData(childNode)

  else if CellType = EDataCellType.MULTILINE_TEXT then
    Result := CreateMultiTextCellData(childNode)

  else if CellType = EDataCellType.IMAGE_INDEX then
    Result := CreateImageIndexCellData(childnode);

end;

function TDCJSONCellDataFactory.CreateImageIndexCellData(var childNode: TJSONObject): TDCImageIndexCellData;
begin
  Result := TDCImageIndexCellData.Create(
    childNode.GetValue<Integer>(TKeyDict.vlIndexKey)
  );
end;

function TDCJSONCellDataFactory.CreateBadgeData(var childNode: TJSONObject): TDCBadgeCellData;
begin
  Result := TDCBadgeCellData.Create(
    childNode.GetValue<String>(TKeyDict.clFonteKey),
    childNode.GetValue<String>(TKeyDict.clFundoKey),
    childNode.GetValue<String>(TKeyDict.vlTextoKey));
end;

function TDCJSONCellDataFactory.CreateTextCellData(var childNode: TJSONObject): TDCTextCellData;
begin
  Result := TDCTextCellData.Create(
    childNode.GetValue<String>(TKeyDict.vlTextoKey),
    childNode.GetValue<String>(TKeyDict.clFonteKey));
end;

function TDCJSONCellDataFactory.CreateMultiTextCellData(var childNode: TJSONObject): TDCMultiTextCellData;
var
  LinhasJsonArray : TJSONArray;
  ChildJSONObject : TJSONObject;
  LinhasArray     : TArray<String>;
  vlFonteStr      : String;
  I : Integer;
begin
  vlFonteStr := childNode.GetValue<String>(TKeyDict.clFonteKey);
  LinhasJsonArray := childNode.GetValue<TJSONArray>(TKeyDict.vlLinhasKey);
  SetLength(LinhasArray, LinhasJsonArray.Count);
  for I := 0 to LinhasJsonArray.Count - 1 do
  begin
    LinhasArray[I] := (LinhasJsonArray.Get(I) as TJSONObject)
      .GetValue(TKeyDict.vlTextoKey).Value;
  end;
  Result := TDCMultiTextCellData.Create(LinhasArray, vlFonteStr);
  LinhasJsonArray.Free;
end;



procedure TDCGridDrawOptions.SetRowLeftMargin(rowLeftMargin: Integer);
begin
  fRowLeftMargin := Max(cfRowLeftMaginMin, rowLeftMargin);
end;

procedure TDCGridDrawOptions.SetRowTopMargin(rowTopMargin: Integer);
begin
  fRowTopMargin := Max(cfRowTopMaginMin, rowTopMargin);
end;

procedure TDCGridDrawOptions.SetBadgeTopPadding(badgeTopPadding: Integer);
begin
  fbadgeTopPadding := Max(cfRowTopMaginMin, rowTopMargin);
end;

procedure TDCGridDrawOptions.SetBadgeLeftPadding(badgeLeftPadding: Integer);
begin
  fbadgeLeftPadding := Max(cfBadgeLeftPaddingMin, badgeLeftPadding);
end;

procedure TDCGridDrawOptions.SetBadgeSpacing(badgeSpacing: Integer);
begin
  fBadgeSpacing := Max(cfBadgeSpacingMin, badgeSpacing);
end;

procedure TDCGridDrawOptions.SetTitleColumnHeight(columnHeight: Integer);
begin
  fTitleColumnHeight := Max(cfTitleColumnHeight, columnHeight);
end;

procedure TDCGridDrawOptions.SetupDefaults();
begin
  BadgeTopPadding  := cfBadgeTopPaddingMin;
  BadgeLeftPadding := cfBadgeLeftPaddingMin;
  BadgeSpacing     := cfBadgeSpacingMin;
  RowLeftMargin := cfRowLeftMaginMin;
  RowTopMargin  := cfRowTopMaginMin;
  TitleColumnHeight    := cfTitleColumnHeight;
  SelectionFontColor   := cfDefSelectionFontColor;
  SelectionFillColor   := cfDefSelectionFillColor;
  SelectionBadgeColor  := cfDefSelectionBadgeColor;
  ColumnTitleFontColor := cfDefColumnTitleFontColor;
  fDrawColumnLine := True;
  CenterColumnNames := False;
end;

procedure Register;
begin
  RegisterComponents('TDCGrid', [TDCGrid]);
  RegisterComponents('TDCLabelPreview', [TDCLabelPreview]);
end;

end.
