unit Tests.Policy;

interface
uses
  DUnitX.TestFramework, Casbin.Policy.Types;

type

  [TestFixture]
  TTestPolicyManager = class(TObject)
  private
    fPolicy: IPolicyManager;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure testPolicies;

    [Test]
    procedure testSection;

    [Test]
    procedure testPolicyExists;

    [Test]
    [TestCase ('Alice', 'p, alice, data1#read', '#')]
    [TestCase ('Bob', 'p, BOB, data2#write', '#')]
    [TestCase ('Non-existant', 'p, 123, aaaa#undefined', '#')]
    procedure testPolicy(const aFilter: string; const aExpected: string);
  end;

implementation

uses
  Casbin.Policy, System.Generics.Collections, System.SysUtils;

procedure TTestPolicyManager.Setup;
begin
  fPolicy:=TPolicyManager.Create('..\..\..\Examples\Default\basic_policy.csv')
end;

procedure TTestPolicyManager.TearDown;
begin
end;


procedure TTestPolicyManager.testPolicies;
var
  list: TList<string>;
begin
  list:=fPolicy.policies;
  Assert.AreEqual(2, list.Count, 'Count');
  Assert.AreEqual('p, alice, data1, read', list.Items[0], 'Line 1');
  Assert.AreEqual('p, bob, data2, write', list.Items[1], 'Line 2');
  list.Free;
end;

procedure TTestPolicyManager.testPolicy(const aFilter, aExpected: string);
begin
  Assert.AreEqual(aExpected, fPolicy.policy(aFilter.Split([','])));
end;

procedure TTestPolicyManager.testPolicyExists;
begin
  Assert.AreEqual(True, fPolicy.policyExists(['p','bob','DATA2','write']));
  Assert.AreEqual(false, fPolicy.policyExists(['p','bob','DATA100','write']));
end;

procedure TTestPolicyManager.testSection;
var
  expected: string;
begin
  expected:='p, alice, data1, read'+sLineBreak+'p, bob, data2, write';
  Assert.AreEqual(expected, trim(fPolicy.section));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPolicyManager);
end.