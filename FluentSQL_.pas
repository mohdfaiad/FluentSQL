unit FluentSQL_;

interface

uses
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Dialogs,
  Data.DB, Uni, CRGrid;

type
  TFluentSQL = class
    type
      TStringArray       = Array of String;
      TVarArray          = Array of Variant;
      TVarArray2D        = Array of Array of Variant;
      TStringArrayHelper = record helper for TStringArray
        function Count: Integer;
        function Concat(aDelimiter: String): string;
      end;
      TVarArrayHelper = record helper for TVarArray
        function Count: Integer;
      end;
      TVarArray2DHelper = record helper for TVarArray2D
        function Count: Integer;
        function ColCount: Integer;
        function Item(I, J: Integer): TVarArray;
      end;
    strict private
      _CON    : TUniConnection;   //  Connection object                                                     //
      _QR     : TUniQuery;        //  Dataset object                                                        //
      _DS     : TUniDataSource;   //  DataSource object                                                     //
      _GRID   : TCRDBGrid;        //  DBGrid object                                                         //
      _ERRORS : TStringList;      //  Error stack                                                           //
      _SELECT : String;           //  SELECT Sentence                                                       //
      _EXECUTE: String;           //  EXECUTABLE SQL sentence. It is a stored procedure, view, query or DDL //
    private
    protected
      function _if(aKriter: Boolean; aTrue, aFalse: String): String;
    public
      constructor Setup(var aConnection: TUniConnection; var aDataSet: TUniQuery; var aDataSource: TUniDataSource; var aGrid: TCRDBGrid);//: TFluentSQL;
      destructor Destroy;
      destructor Free;
      function SetColWidth(aWidth: Integer): TFluentSQL;
      function Select(aSQLCommand: String): TFluentSQL; overload;
      function Select(aFields: TStringArray): TFluentSQL; overload;
      function From(aTableName: String; aAlias: String = ''): TFluentSQL;
      function LeftOuterJoin(aTableName: String; aAlias: String; aOn: string): TFluentSQL;
      function Where(aCriterias: TStringArray): TFluentSQL;
      function OrderBy(aSortFields: TStringArray): TFluentSQL;
      function ShowSource: TFluentSQL;
      function ShowErrors: TFluentSQL;
      function Run: TFluentSQL;
      function Insert: TFluentSQL;
      function Edit: TFluentSQL; overload;
      function Post: TFluentSQL;
      function Del: TFluentSQL;
      function SetValue(aFieldName: string; aValue: Variant): TFluentSQL;
      function Truncate(aTableName: String): TFluentSQL;
      function GetVal(aFieldName: String; var aVariant: Variant): TFluentSQL;
      function SetVal(aFieldName: String; aVariant: Variant): TFluentSQL;
      function InsertInto(aFields: TStringArray; aValues: TVarArray2D): TFluentSQL; overload;
      function Bekle(aMilisaniye: Cardinal): TFluentSQL;
      function Refresh: TFluentSQL;
      function GetSQL(var aString: String): TFluentSQL;
      function GetErrors(var aString: string): TFluentSQL;
  end;

implementation

{ TFluentSQL }

function TFluentSQL.SetColWidth(aWidth: Integer): TFluentSQL;
var
  I: Integer;
begin
  for I := 0 to _GRID.Columns.Count-1 do _GRID.Columns.Items[I].Width := 65;
  Result := Self;
end;

constructor TFluentSQL.Setup(var aConnection: TUniConnection; var aDataSet: TUniQuery; var aDataSource: TUniDataSource; var aGrid: TCRDBGrid); //: TFluentSQL;
begin
  Create;
  Self._CON := aConnection;
  Self._QR  := aDataSet;
  Self._DS  := aDataSource;
  Self._GRID:= aGrid;
  Self._Errors:= TStringList.Create;
  Self.Select('SELECT NULL');
  Self.Refresh;
end;

function TFluentSQL.SetVal(aFieldName: String; aVariant: Variant): TFluentSQL;
begin
  if  (Self._QR.State in dsEditModes)
  then Self._QR.FieldByName(aFieldName).Value := aVariant
  else begin
       Self._QR.Edit;
       Self._QR.FieldByName(aFieldName).Value := aVariant
  end;
  Result := Self;
end;

function TFluentSQL.SetValue(aFieldName: string; aValue: Variant): TFluentSQL;
begin
  if (Self._QR.State in dsEditModes) then begin
      try
        Self._QR.FieldByName(aFieldName.Trim).AsVariant := aValue;
      except
        on e: Exception do begin
            Self._ERRORS.Add(Format('SetValue(%s, %s) > Error : %s', [aFieldName, VarToStr(aValue), E.Message]));
            Self._QR.Cancel;
        end;
      end;
  end;
  Result := Self;
end;

function TFluentSQL.ShowErrors: TFluentSQL;
begin
  if (Self._ERRORS.Text.Trim.IsEmpty = FALSE) then ShowMessage(Self._ERRORS.Text);
  Result := Self;
end;

function TFluentSQL.ShowSource: TFluentSQL;
begin
  ShowMessage(Self._SELECT);
  Result := Self;
end;

function TFluentSQL.Truncate(aTableName: String): TFluentSQL;
begin
  Self._CON.ExecSQL( Format('TRUNCATE TABLE %s', [aTableName]) );
  Self._QR.Refresh;
  Result := Self;
end;

function TFluentSQL.Where(aCriterias: TStringArray): TFluentSQL;
begin
  _SELECT := _SELECT + format(' WHERE %s ', [ aCriterias.Concat(#13#10) ]);
  Result := Self;
end;

function TFluentSQL._if(aKriter: Boolean; aTrue, aFalse: String): String;
begin
  if aKriter then Result := aTrue else Result := aFalse;
end;

function TFluentSQL.Bekle(aMilisaniye: Cardinal): TFluentSQL;
begin
  Sleep(aMilisaniye);
  Result := Self;
end;

function TFluentSQL.Del: TFluentSQL;
begin
  _QR.Delete;
  Result := Self;
end;

destructor TFluentSQL.Destroy;
begin
  FreeAndNil(Self._ERRORS);
end;

function TFluentSQL.Edit: TFluentSQL;
begin
  _QR.Edit;
  Result := Self;
end;

destructor TFluentSQL.Free;
begin
  FreeAndNil(Self._ERRORS);
end;

function TFluentSQL.From(aTableName, aAlias: String): TFluentSQL;
begin
  _SELECT := _SELECT + format(' FROM %s %s ', [aTableName.Trim, _if(aAlias.Trim.IsEmpty, '', 'AS ' + aAlias.Trim)]);
  Result := Self;
end;

function TFluentSQL.GetErrors(var aString: string): TFluentSQL;
begin
  aString := aString + _ERRORS.Text + #13#10;
  Result := Self;
end;

function TFluentSQL.GetSQL(var aString: String): TFluentSQL;
begin
  aString := aString + _SELECT + #13#10;
  Result := Self;
end;

function TFluentSQL.GetVal(aFieldName: String; var aVariant: Variant): TFluentSQL;
begin
  aVariant := Self._QR.FieldByName(aFieldName).AsVariant;
  Result := Self;
end;

function TFluentSQL.InsertInto(aFields: TStringArray; aValues: TVarArray2D): TFluentSQL;
var
  I, J: Integer;
begin
  try
    for I := 0 to High(aValues) do begin
        try
          _QR.Insert;
          for J := 0 to High(aValues[I])
           do _QR.FieldByName(aFields[J]).AsVariant :=  VarToStr(aValues[I, J]);
          _QR.Post;
        except
          on E: Exception do begin
             _ERRORS.Add(E.Message);
             _QR.Cancel;
          end;
        end;
    end;
  finally
    Self._QR.Refresh;
    Result := Self;
  end;
end;

function TFluentSQL.LeftOuterJoin(aTableName, aAlias, aOn: string): TFluentSQL;
begin
  _SELECT := _SELECT + format(' LEFT OUTER JOIN %s %s ON %s ', [aTableName.Trim, _if(aAlias.Trim.IsEmpty, '', 'AS ' + aAlias.Trim), aOn.Trim]);
  Result := Self;
end;

function TFluentSQL.OrderBy(aSortFields: TStringArray): TFluentSQL;
begin
  _SELECT := _SELECT + format(' ORDER BY %s ', [aSortFields.Concat(', ') ]);
  Result := Self;
end;

function TFluentSQL.Insert: TFluentSQL;
begin
  _QR.Insert;
  Result := Self;
end;

function TFluentSQL.Post: TFluentSQL;
begin
  _QR.Post;
  Result := Self;
end;

function TFluentSQL.Refresh: TFluentSQL;
begin
  Self._QR.Refresh;
  Result := Self;
end;

function TFluentSQL.Run: TFluentSQL;
begin
  _QR.Close;
  _QR.SQL.Text := Self._SELECT;
  _QR.Open;
  _GRID.Columns.Clear;
  _GRID.AdjustColumns;

  Result := Self;
end;

function TFluentSQL.Select(aFields: TStringArray): TFluentSQL;
begin
  _SELECT := format(' SELECT %s ', [aFields.Concat(', ')]);
  Result := Self;
end;

function TFluentSQL.Select(aSQLCommand: String): TFluentSQL;
begin
  Self._QR.Close;
  Self._QR.SQL.Text := aSQLCommand;
  Self._QR.Open;
  Result := Self;
end;

{ TFluentSQL.TStringArrayHelper }

function TFluentSQL.TStringArrayHelper.Concat(aDelimiter: String): string;
var
 I: Integer;
begin
 for I := Low(Self) to High(Self)
  do if  (I < High(Self) )
     then Result := Result + Self[I] + aDelimiter
     else Result := Result + Self[I];
end;

function TFluentSQL.TStringArrayHelper.Count: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := Low(Self) to High(Self) do Inc(Result);
end;

{ TFluentSQL.TVarArrayHelper }

function TFluentSQL.TVarArrayHelper.Count: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := Low(Self) to High(Self) do Inc(Result);
end;

{ TFluentSQL.TMultiVarArrayHelper }

function TFluentSQL.TVarArray2DHelper.ColCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := Low(Self[0]) to High(Self[0]) do Inc(Result);
end;

function TFluentSQL.TVarArray2DHelper.Count: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := Low(Self) to High(Self) do Inc(Result);
end;

function TFluentSQL.TVarArray2DHelper.Item(I, J: Integer): TVarArray;
begin
  Result := Self[I][J];
end;

end.
