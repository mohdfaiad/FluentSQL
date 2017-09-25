# FluentSQL

It's kind of an experiment. Please do not get serious.

###### For example.

```pascal
var
  S: string;
begin
  TFluentSQL
  .Setup(CON, QR, DS, GRID)
  .Truncate('dbo.Test')
  .Select(['T1.Ref', 'T1.Hesap', 'T1.Mesap', 'T1.Kesap', 'T1.Para', 'T2.Hesap as T2Hesap'])
  .From('dbo.Test', 'T1')
  .LeftOuterJoin('dbo.Test','T2','T2.Ref = T1.Ref')
  .Where(['T1.Ref > 0'])
  .Run
  .InsertInto ( ['Hesap','Mesap','Kesap','Para'] ,
              [ ['Ali', 1, 2, 3.7]
              , [3, 'Veli', 5, 4.8]
              , [6, 7, 'Celil', 5.9]
              ])
  .Refresh
  .Select('SELECT NULL')
  .Refresh
  .Select('SELECT * FROM dbo.Test')
  .SetColWidth(50)
  .GetSQL(S)
  .GetErrors(S)
  .Free
  ;
  Memo1.Text := S;
end;
```
