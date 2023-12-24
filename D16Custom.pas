unit D16Custom;

interface

uses
  System.Classes,
  System.SysUtils,
  System.StrUtils,
  Vcl.Forms,
  Windows,
  Vcl.Controls,
  Vcl.Graphics,
  Messages,
  Vcl.ExtCtrls,
  Vcl.StdCtrls;

type
  TDCLabelPreview = class(TGraphicControl)
    private
      fTexto : String;
      fCorTexto : TColor;
      fCorFundo : TColor;

    protected
      procedure SetTexto(texto: String);
      procedure Paint; override;
      procedure WMEraseBkGnd(var msg: TWMEraseBkGnd);
        message WM_ERASEBKGND;

    public
      property Texto : String read fTexto write SetTexto;
      property CorTexto : TColor read fCorTexto write fCorTexto;
      property CorFundo : TColor read fCorFundo write fCorFundo;

      constructor Create(AOwner: TComponent);

  end;

implementation

constructor TDCLabelPreview.Create(AOwner: TComponent);
begin
  inherited;

end;

procedure TDCLabelPreview.SetTexto(texto: String);
var
  TextWidth : Integer;
begin
  fTexto := texto.Trim;
  Canvas.Font.Style := [TFontStyle.fsBold];
  TextWidth := Canvas.TextWidth(fTexto);
  Width := TextWidth + 40;
end;

procedure TDCLabelPreview.WMEraseBkGnd(var msg: TWMEraseBkGnd);
begin
  SetBkMode (msg.DC, TRANSPARENT);
  msg.result := 1;
end;

procedure TDCLabelPreview.Paint;
var
  TextWidth, TextHeight: Integer;
  TextRect: TRect;
begin
  Canvas.Font.Style := [TFontStyle.fsBold];
  TextWidth := Canvas.TextWidth(Texto);
  TextHeight := Canvas.TextHeight(Texto);

  Canvas.Brush.Color := CorFundo;
  Canvas.Pen.Color := CorFundo;
  Canvas.RoundRect(0, 0, Width, Height, 6, 6);

  Canvas.Font.Color := CorTexto;

  TextRect := Rect(0, 0, Width, Height);

  DrawText(
    Canvas.Handle,
    PChar(Texto),
    Length(Texto),
    TextRect,
    DT_SINGLELINE or DT_CENTER or DT_VCENTER
  );

  Canvas.Font.Style := [];
end;

end.
end.
