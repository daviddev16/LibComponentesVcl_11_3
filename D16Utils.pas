unit D16Utils;

interface

uses
  System.SysUtils,
  System.Classes,
  System.NetEncoding,
  System.Hash,
  Vcl.Imaging.pngimage,
  Vcl.Graphics,
  Vcl.Forms,
  Windows;

type
  TUtil = class
    public
      class function HashStr(const password: string): String;
      class function HexToColor(hexStr: String) : TColor;
      class function ColorToHex(color: TColor): String;
      class procedure LoadStreamFromFile(var Stream: TStream; fileName: String);
      class procedure CenterForm(const form: TForm);
      class function LoadPicture(pngPath: String): TPngImage;

  end;

implementation

class function TUtil.LoadPicture(pngPath: String): TPngImage;
var
  MemStream : TMemoryStream;
begin
  try
    MemStream := TMemoryStream.Create;
    MemStream.LoadFromFile(pngPath);
    Result := TPngImage.Create;
    MemStream.Position := 0;
    Result.LoadFromStream(MemStream);
  finally
    MemStream.Free;
  end;
end;


class function TUtil.HashStr(const password: string): String;
begin
  Result := THashSHA2.GetHashString(password);
end;

class function TUtil.HexToColor(hexStr: string): TColor;
var
  R, G, B: Byte;
begin
  if hexStr[1] = '#' then
  begin
    Delete(hexStr, 1, 1);
  end;
  R := StrToInt('$' + Copy(hexStr, 1, 2));
  G := StrToInt('$' + Copy(hexStr, 3, 2));
  B := StrToInt('$' + Copy(hexStr, 5, 2));
  Result := RGB(R, G, B);
end;

class function TUtil.ColorToHex(color: TColor): String;
var
  RGBValue: Longint;
  Red, Green, Blue: Byte;
begin
  RGBValue := ColorToRGB(color);
  Red := GetRValue(RGBValue);
  Green := GetGValue(RGBValue);
  Blue := GetBValue(RGBValue);
  Result := Format('#%.2x%.2x%.2x', [Red, Green, Blue]);
end;

class procedure TUtil.LoadStreamFromFile(var Stream: TStream; fileName: String);
begin
  Stream := TMemoryStream.Create;
  try
    (Stream as TMemoryStream).LoadFromFile(FileName);
  except
    Stream.Free;
    raise;
  end;
end;

class procedure TUtil.CenterForm(const form: TForm);
begin
  form.Left :=(Screen.Width-form.Width)  div 2;
  form.Top :=(Screen.Height-form.Height) div 2;
end;

end.
