unit Parser;

interface

uses
  Core.Base.Types, Parser.Types, Parser.Config.Types, Core.Logger.Types,
  System.Generics.Collections, Parser.Messages, Model.Sections.Types,
  Lexer.Tokens.List, System.Rtti;

type
  TParser = class (TBaseInterfacedObject, IParser)
  private
    fConfig: IParserConfig;
    fLogger: ILogger;
    fMessages: TObjectList<TParserMessage>;

    fSections: TObjectList<TSection>;
    fSectionsExternallyAssigned: Boolean;

    fTokenList: TTokenList;
    fStatus: TParserStatus;
    fSectionsDictionary: TDictionary<string, TSection>;
    procedure loadSections;
    procedure checkSyntaxErrors;
    procedure cleanWhiteSpace;
  private
{$REGION 'Interface'}
    function getConfig: IParserConfig;
    function getLogger: ILogger;
    function getMessages: TObjectList<TParserMessage>;
    function getSections: TObjectList<TSection>;
    procedure parse;
    function toOutputString: string;
    procedure setConfig(const aValue: IParserConfig);
    procedure setLogger(const aValue: ILogger);
    procedure setSections(const aValue: TObjectList<TSection>);
    function getStatus: TParserStatus;
{$ENDREGION}
  public
    constructor Create(const aTokenList: TTokenList);
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils, Parser.Config, Core.Logger.Default, Lexer.Tokens.Types;

constructor TParser.Create(const aTokenList: TTokenList);
begin
  inherited Create;
  if not Assigned(aTokenList) then
    raise Exception.Create('Token List is nil in '+self.ClassName);
  fConfig:=TParserConfig.Create;
  fLogger:=TDefaultLogger.Create;
  fMessages:=TObjectList<TParserMessage>.Create;
  fSections:=TObjectList<TSection>.Create;
  fSectionsExternallyAssigned:=False;
  fTokenList:=aTokenList;
  fStatus:=psNotStarted;
  fSectionsDictionary:=TDictionary<string, TSection>.Create;
  loadSections;
end;

destructor TParser.Destroy;
begin
  fMessages.Free;
  fSectionsDictionary.Free;
  if not fSectionsExternallyAssigned then
    fSections.Free;
  inherited;
end;

procedure TParser.checkSyntaxErrors;
var
  token: PToken;
begin
  fLogger.log('Checking for syntax errors...');

  for token in fTokenList do
  begin

  end;

  fLogger.log('Syntax checking finished...');
end;

procedure TParser.cleanWhiteSpace;
var
  token,
  secToken: PToken;
  numAssignments: Integer;
  insideComment: Boolean;
begin
  fLogger.log('Cleaning white space...');

  numAssignments:=0;
  insideComment:=False;
  for token in fTokenList do
  begin
    //Clean comments;
    if token^.&Type=ttComment then
      insideComment:=True;
    if insideComment then
      token^.IsDeleted:=True;

    //Spaces
    if (token^.&Type=ttAssignment) and
          (numAssignments = 0) then
      numAssignments := 1;
    if token^.&Type=ttSpace then
    begin
      token^.IsDeleted:= True;
      if fConfig.RespectSpacesInValues and (numAssignments >= 1) then
          token^.IsDeleted:= False;
    end;

    //Reset counters
    if token^.&Type=ttEOL then
    begin
      insideComment:=False;
      numAssignments:=0;
    end;
  end;

  //Remove deleted tokens
  for token in fTokenList do
    if token^.IsDeleted then
    begin
      fTokenList.Remove(token);
      Dispose(token);
    end;

  fLogger.log('Cleaning white space finished');
end;

{ TParser }

function TParser.getConfig: IParserConfig;
begin
  Result:=fConfig;
end;

function TParser.getLogger: ILogger;
begin
  Result:=fLogger;
end;

function TParser.getMessages: TObjectList<TParserMessage>;
begin
  Result:=fMessages;
end;

function TParser.getSections: TObjectList<TSection>;
begin
  Result:=fSections;
end;

function TParser.getStatus: TParserStatus;
begin
  Result:=fStatus;
end;

procedure TParser.loadSections;
var
  section: TSection;
begin
  if fConfig.AutoAssignSections then
  begin
    fSections.Clear;

    section:=TSection.Create;
    section.EnforceTag:=True;
    section.Header:='request_definition';
    section.Required:=True;
    section.Tag:='r';
    section.&Type:=stRequestDefinition;
    fSections.Add(section);

    section:=TSection.Create;
    section.EnforceTag:=True;
    section.Header:='policy_definition';
    section.Required:=True;
    section.Tag:='p';
    section.&Type:=stPolicyDefinition;
    fSections.Add(section);

    section:=TSection.Create;
    section.EnforceTag:=True;
    section.Header:='role_definition';
    section.Required:=False;
    section.Tag:='g';
    section.&Type:=stRoleDefinition;
    fSections.Add(section);

    section:=TSection.Create;
    section.EnforceTag:=True;
    section.Header:='policy_effect';
    section.Required:=True;
    section.Tag:='e';
    section.&Type:=stPolicyEffect;
    fSections.Add(section);

    section:=TSection.Create;
    section.EnforceTag:=True;
    section.Header:='matchers';
    section.Required:=True;
    section.Tag:='m';
    section.&Type:=stMatchers;
    fSections.Add(section);
  end;

  fSectionsDictionary.Clear;
  for section in fSections do
    fSectionsDictionary.Add(section.Header, section);

end;

procedure TParser.parse;
begin
  fMessages.Clear;
  fLogger.log('Parsing is starting...');
  fStatus:=psRunning;

  cleanWhiteSpace;

  checkSyntaxErrors;

  fLogger.log('Parsing finished');
  fStatus:=psFinished;
end;

procedure TParser.setConfig(const aValue: IParserConfig);
begin
  if not Assigned(aValue) then
    raise Exception.Create('Config is nil in '+self.ClassName);
  fConfig:=nil;
  fConfig:=aValue;
  loadSections;
end;

procedure TParser.setLogger(const aValue: ILogger);
begin
  if not Assigned(aValue) then
    raise Exception.Create('Logger is nil in '+self.ClassName);
  fLogger:=nil;
  fLogger:=aValue;
end;

procedure TParser.setSections(const aValue: TObjectList<TSection>);
begin
  if not Assigned(aValue) then
    raise Exception.Create('Sections list is nil in '+self.ClassName);
  fSections.Free;
  fSections:=aValue;
  fSectionsExternallyAssigned:=True;
  loadSections;
end;

function TParser.toOutputString: string;
var
  token: PToken;
begin
  for token in fTokenList do
    Result:=Result+token^.Value;
end;

end.