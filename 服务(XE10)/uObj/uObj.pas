unit uObj;

interface

uses System.SyncObjs, System.Classes, System.SysUtils;

type
  TObjBase = class(TPersistent)
  private
    FCS: TCriticalSection;
    procedure Lock;
    procedure Unlock;
  public
    procedure Clear; virtual; abstract;
    constructor Create; virtual;
    destructor Destroy; override;
  end;

  //营业时段
  TMealItemClass = class of TMealItem;

  TMealItem = class(TCollectionItem)
  private
    fCode: string;      //INT
    fName: string;      //varchar(30)
    fBegin: TDateTime;  //TDateTime
    fEnd: TDateTime;    //TDateTime
  published
    property Code: string read fCode write fCode;
    property Name: string read fName write fName;
    property dBegin: TDateTime read fBegin write fBegin;          //与系统关键字Begin重复
    property dEnd: TDateTime read fEnd write fEnd;                //与系统关键字End重复
  public
    procedure Assign(Source: TMealItem); reintroduce;
  end;

  TMealItems = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TMealItem;
    procedure SetItem(Index: Integer; const Value: TMealItem);
  public
    property Items[Index: Integer]: TMealItem read GetItem write SetItem; default;
    function Add: TMealItem;
    procedure Delete(Index: Integer);
    function Owner: TPersistent;
    destructor Destroy; override;
  end;

  TMeals = class(TObjBase)
  private
    FMealItems: TMealItems;
    function GetCount: Integer;
  protected
    function GeTMealItemClass: TMealItemClass;
  public
    constructor Create; override;                                       //对象创建
    destructor Destroy; override;                                       //对象释放
    procedure Clear; override;                                          //清空缓存，在LoadFromDB或LoadFromDBByREQ调用时需要调用
    property Count: Integer read GetCount;                               //缓存记录数
    property Items: TMealItems read FMealItems;           //所有缓存信息
    function LoadFromDB(sWhere: string = ''): Boolean;                   //从数据库中载入满足条件的数据至缓存
    function LocateByTime(ATime: TDateTime): TMealItem;        //根据时间返回营业时段
  end;

implementation

uses uDM_DAC, uVar, uSQL, uPublic;

{ TMealItem }

procedure TMealItem.Assign(Source: TMealItem);
begin
  if Source= nil then
    Exit;
  fCode := Source.Code;
  fName := Source.Name;
  fBegin := Source.dBegin;
  fEnd := Source.dEnd;
end;

{ TMealItems }

function TMealItems.Add: TMealItem;
begin
  Result := inherited Add as TMealItem;
end;

procedure TMealItems.Delete(Index: Integer);
begin
  inherited Delete(Index);
end;

destructor TMealItems.Destroy;
begin

  inherited;
end;

function TMealItems.GetItem(Index: Integer): TMealItem;
begin
  Result := inherited GetItem(Index) as TMealItem;
end;

function TMealItems.Owner: TPersistent;
begin
  Result := GetOwner;
end;

procedure TMealItems.SetItem(Index: Integer; const Value: TMealItem);
begin
  inherited SetItem(Index, Value);
end;

{ TMeals }

procedure TMeals.Clear;
begin
  Lock;
  try
    FMealItems.Clear;
  finally
    Unlock;
  end;
end;

constructor TMeals.Create;
begin
  inherited;
  FMealItems := TMealItems.Create(Self, GeTMealItemClass);
end;

destructor TMeals.Destroy;
begin
  Lock;
  try
    Clear;
    FreeAndNil(FMealItems);
  finally
    Unlock;
  end;
  inherited;
end;

function TMeals.GetCount: Integer;
begin
  Result := FMealItems.Count;
end;

function TMeals.GeTMealItemClass: TMealItemClass;
begin
  Result := TMealItem;
end;

function TMeals.LoadFromDB(sWhere: string): Boolean;
var
  AItem: TMealItem;
  sSql: string;
begin
  Result:= False;
  if not Assigned(GAppRunClass.dm) then
    Exit;
  with GAppRunClass.dm do
  begin
    if not FDConnection.Connected then
      FDConnection.Connected:= True;   //在连接池里获取一个连接
    sSql:= Format(SQL_Meals_SELECT, [sWhere]);
    try
      with FDQuery do
      begin
        Close;
        SQL.Text:= sSql;
        try
          Open;
          Clear;
          Result:= True;
        except
          Exit;
        end;
        if IsEmpty then
          Exit;
        while not eof do
        begin
          AItem := FMealItems.Add;
          AItem.Code    := FieldByName('fMeal_Id').AsString;
          AItem.Name    := FieldByName('fMeal_Name').AsString;
          AItem.dBegin  := FieldByName('fBegin_Time').AsDateTime;
          AItem.dEnd    := FieldByName('fEnd_Time').AsDateTime;
          Next;
        end;
        systemLog(Format('加载餐段[%d]条', [RecordCount]));
      end;
    finally
      FDConnection.Connected:= False;  //归还连接 不是断开
    end;
  end;
end;

function TMeals.LocateByTime(ATime: TDateTime): TMealItem;
var
  I: Integer;
  ADTime, ADBegin, ADEnd: TDateTime;
begin
  result := nil;
  ADTime := ATime;
  ADTime := ADTime - Trunc(ADTime);
  for I := 0 to Count - 1 do
  begin
    ADBegin := FMealItems[I].dBegin - Trunc(FMealItems[I].dBegin);
    ADEnd := FMealItems[I].dEnd - Trunc(FMealItems[I].dEnd);
    if (ADTime >= ADBegin) and (ADTime <= ADEnd) then
    begin
      Result := FMealItems[I];
      Break;
    end;
  end;
end;

{ TObjBase }

constructor TObjBase.Create;
begin
  if not Assigned(FCS) then
    FCS := TCriticalSection.Create;
end;

destructor TObjBase.Destroy;
begin
  if Assigned(FCS) then
    FreeAndNil(FCS);
  inherited;
end;

procedure TObjBase.Lock;
begin
  FCS.Enter;
end;

procedure TObjBase.Unlock;
begin
  FCS.Leave;
end;

end.
