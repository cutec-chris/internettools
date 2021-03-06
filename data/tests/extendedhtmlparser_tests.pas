unit extendedhtmlparser_tests;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

procedure unitTests(testerrors: boolean);

implementation

uses extendedhtmlparser, xquery, bbutils, simplehtmltreeparser;


procedure unitTests(testerrors: boolean);
var data: array[1..285] of array[1..3] of string = (
//---classic tests--- (remark: the oldest, most verbose syntax is tested first; the new, simple syntax at the end)
 //simple reading
 ('<a><b><template:read source="text()" var="test"/></b></a>',
 '<a><b>Dies wird Variable test</b></a>',
 'test=Dies wird Variable test'),
 ('<a><b><template:read source="text()" var="test"/></b></a>',
 '<a><b>Dies wird erneut Variable test</b><b>Nicht Test</b><b>Test</b></a>',
 'test=Dies wird erneut Variable test'),
 ('<a><b>Test:</b><b><template:read source="text()" var="test"/></b></a>',
 '<a><b>Nicht Test</b><b>Test:</b><b>Dies wird erneut Variable test2</b></a>',
 'test=Dies wird erneut Variable test2'),
 ('<a><b>Test:</b><b><template:read source="text()" var="test"/></b></a>',
 '<a><b>1</b><b>Test:</b><b>2</b><b>3</b></a>',
 'test=2'),
 ('<a><b><template:read source="@att" var="att-test"/></b></a>',
 '<a><b att="HAllo Welt!"></b></a>',
 'att-test=HAllo Welt!'),
 ('<a><b><template:read source="@att" var="regex" regex="<\d*>"/></b></a>',
 '<a><b att="Zahlencode: <675> abc"></b></a>',
 'regex=<675>'),
 ('<a><b><template:read source="@att" var="regex" regex="<(\d* \d*)>" submatch="1"/></b></a>',
 '<a><b att="Zahlencode: <123 543> abc"></b></a>',
 'regex=123 543'),
 ('<a><b><template:read source="text()" var="test"/></b></a>',
 '<a><b>1</b><b>2</b><b>3</b><b>4</b><b>5</b></a>',
 'test=1'),
 ('<a><b><template:read source="comment()" var="test"/></b></a>',
 '<a><b><!--cCc--></b><b>2</b><b>3</b><b>4</b><b>5</b></a>',
 'test=cCc'),
 ('<a><b><template:read'#9'source="text()"'#13'var="test"/></b></a>',
 '<a><b>Dies wird'#9'Variable test</b></a>',
 'test=Dies wird'#9'Variable test'),
 ('<a><b'#13'attrib'#10'='#9'"test"><template:read'#9'source="text()"'#13'var="test"/></b></a>',
 '<a><b'#9'attrib           =         '#10'  test>Dies'#9'wird'#9'Variable test</b></a>',
 'test=Dies'#9'wird'#9'Variable test'),
 //reading with matching node text
 ('<a><b>Nur diese: <template:read source="text()" var="test" regex="\d+"/></b></a>',
 '<a><b>1</b><b>2</b><b>Nur diese: 3</b><b>4</b><b>5</b></a>',
 'test=3'),
 ('<a><b><template:read source="text()" var="test" regex="\d+"/>Nur diese: </b></a>',
 '<a><b>1</b><b>Nur diese: 2</b><b>3</b><b>4</b><b>5</b></a>',
 'test=2'),
 ('<b>Hier<template:read source="@v" var="test"/></b>',
 '<a><b v="abc">1</b><b v="def"></b>      <b>2</b><b>3</b><b v="ok">Hier</b><b v="!">5</b></a>',
 'test=ok'),
 //look ahead testing
 ('<b><template:read source="@v" var="test"/>Hier</b>',
 '<a><b v="abc">1</b><b v="def"></b>      <b>2</b><b>3</b><b v="100101">Hier</b><b v="!">5</b></a>',
 'test=100101'),
 //simple reading
 ('<b><template:read source="@v" var="test"/>Hier</b>',
 '<a><b v="abc">1</b><b v="def"></b><b>2</b><b>3</b><b v="ok">Hier</b><b v="!">5</b></a>',
 'test=ok'),
 //No reading
 ('<a><b><template:read var="test" source=" ''Saga der sieben Sonnen''"/></b></a>',
 '<a><b>456</b></a>',
 'test=Saga der sieben Sonnen'),
 //Reading concat 2-params
 ('<a><b><template:read var="test" source=" concat( ''123'', text() )"/></b></a>',
 '<a><b>456</b></a>',
 'test=123456'),
 //Reading concat 3-params
 ('<a><b><template:read var="test" source=" concat( ''abc'', text() , ''ghi'' )"/></b></a>',
 '<a><b>def</b></a>',
 'test=abcdefghi'),
 //non closed html tags
 ('<a><p><template:read var="test" source="text()"/></p></a>',
 '<a><p>Offener Paragraph</a>',
 'test=Offener Paragraph'),
 ('<a><img> <template:read var="test" source="@src"/> </img></a>',
 '<a><img src="abc.jpg"></a>',
 'test=abc.jpg'),
 //several non closed
 ('<a><img width="100"> <template:read var="test" source="@src"/> </img></a>',
 '<a><img width=120 src="abc.jpg"><img width=320 src="def.jpg"><img width=100 src="123.jpg"><img width=500 src="baum.jpg"></a>',
 'test=123.jpg'),
 //if tests (== strue)         (also tests variable reading for the first time)
 ('<a><b><template:read source="text()" var="test"/></b><template:if test=''$test="abc"''><c><template:read source="text()" var="test"/></c></template:if></a>',
 '<a><b>abc</b><c>dies kommt raus</c></a>',
 'test=abc'#13#10'test=dies kommt raus'),
 //if test (== false),
 ('<a><b><template:read source="text()" var="test"/></b><template:if test=''$test="abc"''><c><template:read source="text()" var="test"/></c></template:if></a>',
   '<a><b>abcd</b><c>dies kommt nicht raus</c></a>',
   'test=abcd'),
 //IF-Test (!= true)
 ('<a><b><template:read source="text()" var="test"/></b><template:if test=''$test!="abc"''><c><template:read source="text()" var="test"/></c></template:if></a>',
  '<a><b>abcd</b><c>dies kommt raus</c></a>',
  'test=abcd'#13#10'test=dies kommt raus'),
 //IF-Test (!= false)
  ('<a><b><template:read source="text()" var="test"/></b><template:if test=''"abc"!=$test''><c><template:read source="text()" var="test"/></c></template:if></a>',
  '<a><b>abc</b><c>dies kommt nicht raus</c></a>',
  'test=abc'),
 //Text + If
   ('<a><b><template:read source="text()" var="test"/><template:if test=''"ok"=x"{$test}"''><c><template:read source="text()" var="test"/></c></template:if></b></a>',
   '<a><b>nicht ok<c>dies kommt nicht raus</c></b></a>',
   'test=nicht ok'),
  ('<a><b><template:read source="text()" var="test"/><template:if test=''"ok"=x"{$test}"''><c><template:read source="text()" var="test"/></c></template:if></b></a>',
   '<a><b>ok<c>dies kommt raus!</c></b></a>',
   'test=ok'#13'test=dies kommt raus!'),
  //text + if + not closed
  ('<a><b><template:read source="text()" var="test"/><template:if test=''"ok"=x"{$test}''><img><template:read source="@src" var="test"/></img></template:if></b></a>',
   '<a><b>ok<img src="abc.png"></b></a>',
   'test=ok'#13'test=abc.png'),
   //text + if + not closed + text
  ('<a><b><template:read source="text()" var="test"/><template:if test=''"ok"=x"{$test}''><img><template:read source="@src" var="test"/></img><template:read source="text()" var="ende"/></template:if></b></a>',
  '<a><b>ok<img src="abcd.png"></b></a>',
  'test=ok'#13'test=abcd.png'#13'ende=ok'),
  //text + if + not closed + text
 ('<a><b><template:read source="text()" var="test"/><template:if test=''"ok"=x"{$test}''>  <img><template:read source="@src" var="test"/><template:read source="text()" var="ende"/></img>  </template:if></b></a>',
 '<a><b>ok<img src="abcd.png"></b></a>',
 'test=ok'#13'test=abcd.png'#13'ende='),
 //loop complete
 ('<a><template:loop><b><template:read source="text()" var="test"/></b></template:loop></a>',
 '<a><b>1</b><b>2</b><b>3</b><b>4</b><b>5</b></a>',
 'test=1'#13'test=2'#13'test=3'#13'test=4'#13'test=5'),
 //loop empty
 ('<a><x><template:read source="text()" var="test"/></x><template:loop><b><template:read source="text()" var="test"/></b></template:loop></a>',
  '<a><x>abc</x></a>',
  'test=abc'),
  ('<a><ax><b>1</b></ax><ax><b><template:read source="text()" var="test"/></b></ax></a>',
  '<a><ax>123124</ax><ax><b>525324</b></ax><ax><b>1</b></ax><ax><b>3</b></ax></a>',
  'test=3'),
 //optional elements
  ('<a><b template:optional="true"><template:read source="text()" var="test"/></b><c><template:read source="text()" var="test"/></c></a>',
  '<a><xx></xx><c>!!!</c></a>',
  'test=!!!'),
  ('<a><b template:optional="true"><template:read source="text()" var="test"/></b><c><template:read source="text()" var="test"/></c></a>',
  '<a><c>???</c></a>',
  'test=???'),
  ('<a><b template:optional="true"><template:read source="text()" var="test"/></b><c><template:read source="text()" var="test"/></c></a>',
  '<a><b>1</b><c>2</c></a>',
  'test=1'#13'test=2'),
  ('<a><b template:optional="true"><template:read source="text()" var="test"/></b><c><template:read source="text()" var="test"/></c><b template:optional="true"><template:read source="text()" var="test"/></b></a>',
   '<a><b>1</b><c>2</c><b>3</b></a>',
   'test=1'#13'test=2'#13'test=3'),
  ('<a><b template:optional="true"><template:read source="text()" var="test"/></b><c><template:read source="text()" var="test"/></c><b template:optional="true">'+'<template:read source="text()" var="test"/></b><c template:optional="true"/><d template:optional="true"/><e template:optional="true"/></a>',
    '<a><b>1</b><c>2</c><b>test*test</b></a>',
    'test=1'#13'test=2'#13'test=test*test'),
  ('<a><b template:optional="true"><template:read source="text()" var="test"/></b><c><template:read source="text()" var="test"/></c><b template:optional="true">'+'<template:read source="text()" var="test"/></b><c template:optional="true"/><d template:optional="true"/><template:read source="text()" var="bla"/><e template:optional="true"/></a>',
  '<a><b>1</b><c>2</c><b>hallo</b>welt</a>',
  'test=1'#13'test=2'#13'test=hallo'#13'bla=welt'),
 //delayed optional elements
  ('<a><x><b template:optional="true"><template:read source="text()" var="test"/></b></x></a>',
   '<a><x>Hallo!<a></a><c></c><b>piquadrat</b>welt</x></a>',
   'test=piquadrat'),
 //multiple loops+concat
  ('<a><s><template:read source="text()" var="test"/></s><template:loop><b><template:read source="concat($test,text())" var="test"/></b></template:loop></a>',
   '<a><s>los:</s><b>1</b><b>2</b><b>3</b></a>',
   'test=los:'#13'test=los:1'#13'test=los:12'#13'test=los:123'),
  ('<a><s><template:read source="text()" var="test"/></s><template:loop><c><template:loop><b><template:read source=''concat($test,text())'' var="test"/></b></template:loop></c></template:loop></a>',
   '<a><s>los:</s><c><b>a</b><b>b</b><b>c</b></c><c><b>1</b><b>2</b><b>3</b></c><c><b>A</b><b>B</b><b>C</b></c></a>',
   'test=los:'#13'test=los:a'#13'test=los:ab'#13'test=los:abc'#13'test=los:abc1'#13'test=los:abc12'#13'test=los:abc123'#13'test=los:abc123A'#13'test=los:abc123AB'#13'test=los:abc123ABC'),
 //deep-ode-text()
  ('<a><x><template:read source="deep-text()" var="test"/></x></a>',
   '<a><x>Test:<b>in b</b><c>in c</c>!</x></a>',
   'test=Test:in bin c!'),
 //deepNodeText with optional element
  ('<a><x><template:read source="text()" var="test1"/><br template:optional="true"/><template:read source="deep-text()" var="test2"/></x></a>',
   '<a><x>Test:<br><b>in b</b><c>in c</c>!</x></a>',
   'test1=Test:'#13'test2=Test:in bin c!'),
  ('<a><pre><template:read source="text()" var="test2"/></pre><x><template:read source="text()" var="test1"/><br template:optional="true"/><template:read source="deep-text()" var="test2"/></x></a>',
   '<a><pre>not called at all</pre><x>Test:<b>in b</b><c>in c</c>!</x></a>',
   'test2=not called at all'#13'test1=Test:'#13'test2=Test:in bin c!'),
//root node()
('<a><x template:optional="true"><template:read source="/a/lh/text()" var="test"/></x></a>',
'<a><lb>ab</lb><x>mia</x><lh>xy</lh></a>',
'test=xy'),
('<a><x template:optional="true"><template:read source="/a/lh/text()" var="test"/></x></a>',
'<a><lb>ab</lb><lh>xy</lh></a>',
''),
('<a><x template:optional="true"><template:read source="/a/lb/text()" var="test"/></x></a>',
'<a><lb>ab</lb><x>mia</x><lh>xy</lh></a>',
'test=ab'),
//Search
('<a><x><template:read source="//lh/text()" var="test"/></x></a>',
'<a><lb>ab</lb><x>mia</x><lh>xy</lh></a>',
'test=xy'),
 //html script tags containing <
   ('<a><script></script><b><template:read source="text()" var="test"/></b></a>',
   '<a><script>abc<def</script><b>test<b></a>',
   'test=test'),
   ('<a><script><template:read source="text()" var="sitself"/></script><b><template:read source="text()" var="test"/></b></a>',
   '<a><script>abc<def</script><b>test<b></a>',
   'sitself=abc<def'#13'test=test'),
 //direct closed tags
   ('<a><br/><br/><template:read source="text()" var="test"/><br/></a>',
   '<a><br/><br   />abc<br /></a>',
   'test=abc'),
 //xpath conditions
   ('<html><a template:condition="filter(@cond, ''a+'') = ''aaa'' "><template:read source="text()" var="test"/></a></html>',
   '<html><a>a1</a><a cond="xyz">a2</a><a cond="a">a3</a><a cond="xaay">a4</a><a cond="aaaa">a5</a><a cond="xaaay">a6</a><a cond="xaaaay">a7</a><a cond="xaay">a8</a></html>',
   'test=a6'),


//--new tests--
   //simple read
   ('<table id="right"><tr><td><template:read source="text()" var="col"/></td></tr></table>',
    '<html><table id="right"><tr><td></td><td>other</td></tr></table></html>',
    'col='),
   ('<html><script><template:read source="text()" var="col"/></script></html>',
    '<html><script><!--abc--></script></html>',
    'col=<!--abc-->'),
   ('<html><script><template:read source="text()" var="col"/></script></html>',
    '<html><script>--<!--a--b--c-->--</script></html>',
    'col=--<!--a--b--c-->--'),

   //loop corner cases
   ('<template:loop><tr><td><template:read source="text()" var="col"/></td></tr></template:loop>',
    '<html><body><table id="wrong"><tr><td>Hallo</td></tr></table><table id="right"><tr><td>123</td><td>other</td></tr><tr><td>foo</td><td>columns</td></tr><tr><td>bar</td><td>are</td></tr><tr><td>xyz</td><td>ignored</td></tr></table></html>',
    'col=Hallo'#13'col=123'#13'col=foo'#13'col=bar'#13'col=xyz'),
   ('<table><template:loop><tr><td><template:read source="text()" var="col"/></td></tr></template:loop></table>',
    '<html><body><table id="wrong"><tr><td>Hallo</td></tr></table><table id="right"><tr><td>123</td><td>other</td></tr><tr><td>foo</td><td>columns</td></tr><tr><td>bar</td><td>are</td></tr><tr><td>xyz</td><td>ignored</td></tr></table></html>',
    'col=Hallo'),
   ('<table></table><template:loop><tr><td><template:read source="text()" var="col"/></td></tr></template:loop>',
    '<html><body><table id="wrong"><tr><td>Hallo</td></tr></table><table id="right"><tr><td>123</td><td>other</td></tr><tr><td>foo</td><td>columns</td></tr><tr><td>bar</td><td>are</td></tr><tr><td>xyz</td><td>ignored</td></tr></table></html>',
    'col=123'#13'col=foo'#13'col=bar'#13'col=xyz'),
   ('<tr/><template:loop><tr><td><template:read source="text()" var="col"/></td></tr></template:loop>',
    '<html><body><table id="wrong"><tr><td>Hallo</td></tr></table><table id="right"><tr><td>123</td><td>other</td></tr><tr><td>foo</td><td>columns</td></tr><tr><td>bar</td><td>are</td></tr><tr><td>xyz</td><td>ignored</td></tr></table></html>',
    'col=123'#13'col=foo'#13'col=bar'#13'col=xyz'),
   ('<template:loop><tr><td><template:read source="text()" var="col"/></td></tr></template:loop><tr/>',
    '<html><body><table id="wrong"><tr><td>Hallo</td></tr></table><table id="right"><tr><td>123</td><td>other</td></tr><tr><td>foo</td><td>columns</td></tr><tr><td>bar</td><td>are</td></tr><tr><td>xyz</td><td>ignored</td></tr></table></html>',
    'col=Hallo'#13'col=123'#13'col=foo'#13'col=bar'),
   ('<table></table><table><template:loop><tr><td><template:read source="text()" var="col"/></td></tr></template:loop></table>',
    '<html><body><table id="wrong"><tr><td>Hallo</td></tr></table><table id="right"><tr><td>123</td><td>other</td></tr><tr><td>foo</td><td>columns</td></tr><tr><td>bar</td><td>are</td></tr><tr><td>xyz</td><td>ignored</td></tr></table></html>',
     'col=123'#13'col=foo'#13'col=bar'#13'col=xyz'),
   ('<template:loop><template:loop><tr><td><template:read source="text()" var="col"/></td></tr></template:loop></template:loop>',
    '<html><body><table id="wrong"><tr><td>Hallo</td></tr></table><table id="right"><tr><td>123</td><td>other</td></tr><tr><td>foo</td><td>columns</td></tr><tr><td>bar</td><td>are</td></tr><tr><td>xyz</td><td>ignored</td></tr></table></html>',
    'col=Hallo'#13'col=123'#13'col=foo'#13'col=bar'#13'col=xyz'),
   ('<table><template:loop><tr><td><x template:optional="true"><template:read source="text()" var="k"/></x><template:read source="text()" var="col"/></td></tr></template:loop></table>',
    '<html><body><table id="wrong"><tr><td><x>hallo</x>Hillo</td></tr><tr><td><x>hallo2</x>Hillo2</td></tr><tr><td><x>hallo3</x>Hallo3</td></tr><tr><td>we3</td></tr><tr><td><x>hallo4</x>Hallo4</td></tr></table></html>',
    'k=hallo'#13'col=Hillo'#13'k=hallo2'#13'col=Hillo2'#13'k=hallo3'#13'col=Hallo3'#13'col=we3'#13'k=hallo4'#13'col=Hallo4')


   //loops with fixed length
   , ('<m><t:loop><a><t:read source="text()" var="a"/></a></t:loop></m>', '<m><a>1</a><a>2</a><a>3</a><a>4</a><a>5</a></m>', 'a=1'#13'a=2'#13'a=3'#13'a=4'#13'a=5')
   , ('<m><t:loop max="3"><a><t:read source="text()" var="a"/></a></t:loop></m>', '<m><a>1</a><a>2</a><a>3</a><a>4</a><a>5</a></m>', 'a=1'#13'a=2'#13'a=3')
   , ('<m><t:loop max="99"><a><t:read source="text()" var="a"/></a></t:loop></m>', '<m><a>1</a><a>2</a><a>3</a><a>4</a><a>5</a></m>', 'a=1'#13'a=2'#13'a=3'#13'a=4'#13'a=5')
   , ('<m><t:loop max="0"><a><t:read source="text()" var="a"/></a></t:loop></m>', '<m><a>1</a><a>2</a><a>3</a><a>4</a><a>5</a></m>', '')
   , ('<m><t:loop><a><t:read source="text()" var="a"/></a></t:loop></m>', '<m><a>x1</a><a>x2</a><a>x3</a></m><m><a>y1</a><a>y2</a><a>y3</a><a>y4</a><a>y5</a></m>', 'a=x1'#13'a=x2'#13'a=x3')
   , ('<m><t:loop min="3"><a><t:read source="text()" var="a"/></a></t:loop></m>', '<m><a>x1</a><a>x2</a><a>x3</a></m><m><a>y1</a><a>y2</a><a>y3</a><a>y4</a><a>y5</a></m>', 'a=x1'#13'a=x2'#13'a=x3')
   , ('<m><t:loop min="4"><a><t:read source="text()" var="a"/></a></t:loop></m>', '<m><a>x1</a><a>x2</a><a>x3</a></m><m><a>y1</a><a>y2</a><a>y3</a><a>y4</a><a>y5</a></m>', 'a=y1'#13'a=y2'#13'a=y3'#13'a=y4'#13'a=y5')
   , ('<m><t:loop min="4" max="4"><a><t:read source="text()" var="a"/></a></t:loop></m>', '<m><a>x1</a><a>x2</a><a>x3</a></m><m><a>y1</a><a>y2</a><a>y3</a><a>y4</a><a>y5</a></m>', 'a=y1'#13'a=y2'#13'a=y3'#13'a=y4')
//   , ('<m><t:loop min="4" max="2"><a><t:read source="text()" var="a"/></a></t:loop></m>', '<m><a>x1</a><a>x2</a><a>x3</a></m><m><a>y1</a><a>y2</a><a>y3</a><a>y4</a><a>y5</a></m>', '')


   //optional elements
   ,('<a>as<template:read source="text()" var="a"/></a><b template:optional="true"></b>',
    '<a>asx</a><x/>',
    'a=asx'),
   ('<a>as<template:read source="text()" var="a"/></a><b template:optional="true"></b>',
    '<a>asx</a>',
    'a=asx'),
   //optional elements: test that the first optional element has the highest priority
   ('<a>as<template:read source="text()" var="a"/></a> <b template:optional="true"><template:read source="''found''" var="b"/></b>  <c template:optional="true"><template:read source="''found''" var="c"/></c>',
    '<a>asx</a>',
    'a=asx'),
   ('<a>as<template:read source="text()" var="a"/></a> <b template:optional="true"><template:read source="''found''" var="b"/></b>  <c template:optional="true"><template:read source="''found''" var="c"/></c>',
    '<a>asx</a><b/>',
    'a=asx'#13'b=found'),
   ('<a>as<template:read source="text()" var="a"/></a> <b template:optional="true"><template:read source="''found''" var="b"/></b>  <c template:optional="true"><template:read source="''found''" var="c"/></c>',
    '<a>asx</a><c/>',
    'a=asx'#13'c=found'),
   ('<a>as<template:read source="text()" var="a"/></a> <b template:optional="true"><template:read source="''found''" var="b"/></b>  <c template:optional="true"><template:read source="''found''" var="c"/></c>',
    '<a>asx</a><b/><c/>',
    'a=asx'#13'b=found'#13'c=found'),
   ('<a>as<template:read source="text()" var="a"/></a> <b template:optional="true"><template:read source="''found''" var="b"/></b>  <c template:optional="true"><template:read source="''found''" var="c"/></c>',
    '<a>asx</a><c/><b/><c/>',
    'a=asx'#13'b=found'#13'c=found'),
   ('<a>as<template:read source="text()" var="a"/></a> <b template:optional="true"><template:read source="''found''" var="b"/></b>  <c template:optional="true"><template:read source="''found''" var="c"/></c>',
    '<a>asx</a><c/><b/>',
    'a=asx'#13'b=found'),
    //optional elements: test that the first optional element has the highest priority even in loops
    ('<a>as<template:read source="text()" var="a"/></a> <template:loop> <b template:optional="true"><template:read source="text()" var="b"/></b>  <c template:optional="true"><template:read source="text()" var="c"/></c> </template:loop>',
     '<a>asx</a><b>B1</b><b>B2</b><b>B3</b>',
     'a=asx'#13'b=B1'#13'b=B2'#13'b=B3'),
    ('<a>as<template:read source="text()" var="a"/></a> <template:loop> <b template:optional="true"><template:read source="text()" var="b"/></b>  <c template:optional="true"><template:read source="text()" var="c"/></c> </template:loop>',
     '<a>asx</a><c>C1</c><c>C2</c><c>C3</c>',
     'a=asx'#13'c=C1'#13'c=C2'#13'c=C3'),
    ('<a>as<template:read source="text()" var="a"/></a> <template:loop> <b template:optional="true"><template:read source="text()" var="b"/></b>  <c template:optional="true"><template:read source="text()" var="c"/></c> </template:loop>',
     '<a>asx</a><b>B1</b><b>B2</b><b>B3</b><c>C1</c><c>C2</c><c>C3</c>',
     'a=asx'#13'b=B1'#13'c=C1'), //TODO: is this really the expected behaviour? it searches a <b> and then a <c>, and then the file reaches eof.
    ('<a>as<template:read source="text()" var="a"/></a> <template:loop> <b template:optional="true"><template:read source="text()" var="b"/></b>  <c template:optional="true"><template:read source="text()" var="c"/></c> </template:loop>',
     '<a>asx</a><c>C1</c><c>C2</c><c>C3</c><b>B1</b><b>B2</b><b>B3</b>',
     'a=asx'#13'b=B1'#13'b=B2'#13'b=B3'), //it searches a <b>, then a <c>, but after the <b> only <c>s are coming
    ('<a>as<template:read source="text()" var="a"/></a> <template:loop> <b template:optional="true"><template:read source="text()" var="b"/></b>  <c template:optional="true"><template:read source="text()" var="c"/></c> </template:loop>',
     '<a>asx</a><b>B1</b><c>C1</c><b>B2</b><c>C2</c><b>B3</b><c>C3</c>',
     'a=asx'#13'b=B1'#13'c=C1'#13'b=B2'#13'c=C2'#13'b=B3'#13'c=C3'),
     ('<a>as<template:read source="text()" var="a"/></a> <template:loop> <b template:optional="true"><template:read source="text()" var="b"/></b>  <c template:optional="true"><template:read source="text()" var="c"/></c> </template:loop>',
      '<a>asx</a><b>B1</b><c>C1</c><c>C2</c><b>B3</b><c>C3</c>',
      'a=asx'#13'b=B1'#13'c=C1'#13'b=B3'#13'c=C3'),

     //switch
     //trivial tests
     ('<a><template:switch><b><template:read var="v" source="''bBb''"/></b><c><template:read var="v" source="''cCc''"/></c></template:switch></a>',
      '<a><b></b></a>',
      'v=bBb'),
     ('<a><template:switch><b><template:read var="v" source="''bBb''"/></b><c><template:read var="v" source="''cCc''"/></c></template:switch></a>',
      '<a><c></c></a>',
      'v=cCc'),
     ('<a><template:loop><template:switch><b><template:read var="b" source="text()"/></b><c><template:read var="c" source="text()"/></c></template:switch></template:loop></a>',
      '<a><b>1</b><c>2</c><b>4</b><b>5</b><c>6</c><d>ign</d><b>7</b>bla<b>8</b>blub</a>',
      'b=1'#13'c=2'#13'b=4'#13'b=5'#13'c=6'#13'b=7'#13'b=8'),
     ('<a><template:loop><template:switch><b><template:read var="b" source="text()"/></b><c><template:read var="c" source="text()"/></c></template:switch></template:loop></a>',
      '<a><b>1</b><nestene><c>rose</c><consciousness><b>obvious</b><b>ardi</b></consciousness><c>blub</c></nestene></a>',
      'b=1'#13'c=rose'#13'b=obvious'#13'b=ardi'#13'c=blub'),
     ('<a><template:loop><template:switch><b><template:read var="b" source="text()"/></b><c><template:read var="c" source="text()"/></c></template:switch></template:loop></a>',
      '<a><b>1</b><nestene><c>rose</c><consciousness><b>obvious</b><b>ardi</b></consciousness><c>blub</c></nestene></a>',
      'b=1'#13'c=rose'#13'b=obvious'#13'b=ardi'#13'c=blub'),
      //recursive
      ('<a><template:loop><template:switch><b><x><template:read var="bx" source="text()"/></x></b><b><y><template:read var="by" source="text()"/></y></b></template:switch></template:loop></a>',
       '<a><b><x>tx</x></b><n><b><y>ty</y></b>non<b>sense<ll><y>TY</y></ll></b></n><b><y>AY</y></b><c>dep</c><b><x>X</x></b></a>',
       'bx=tx'#13'by=ty'#13'by=TY'#13'by=AY'#13'bx=X'),
      ('<a><template:loop><template:switch><b><x><template:read var="bx" source="text()"/></x></b><b><y><template:read var="by" source="text()"/></y></b></template:switch></template:loop></a>',
       '<a><b><x>tx</x><n><b><y>ty</y></b>non<b>sense<ll><y>TY</y></ll></b></n><b><y>AY</y></b><c>dep</c><b><x>X</x></b></b></a>',
       'bx=tx'), //carefully: here the first </b> is missing/off

   //different text() interpretations
   ('<a><template:read source="text()" var="A"/><x/><template:read source="text()" var="B"/></a>',
    '<a>hallo<x></x>a</a>',
    'A=hallo'#13'B=a'),
   ('<table id="right"><template:loop><tr><td><template:read source="../text()" var="col"/></td></tr></template:loop></table>',
    '<table id="right"><tr>pre<td>123</td><td>other</td></tr><tr>ff<td>foo</td><td>columns</td></tr><tr>gg<td>bar</td><td>are</td></tr><tr>hh<td>xyz</td><td>ignored</td></tr></table>',
    'col=pre'#10'col=ff'#10'col=gg'#10'col=hh'),

    //case insensitiveness
    ('<A><template:read source="text()" var="A"/><x/><template:read source="text()" var="B"/></A>',
     '<a>hallo<x></x>a</a>',
     'A=hallo'#13'B=a'),
    ('<A att="HALLO"> <template:read source="@aTT" var="A"/></A>',
     '<a ATT="hallo">xyz</a>',
     'A=hallo'),
    ('<a ATT="olP"> <template:read source="@aTT" var="A"/></A>',  '<A att="oLp">xyz</a>',   'A=oLp')

     //examples taken from http://msdn.microsoft.com/en-us/library/ms256086.aspx
     ,('',
      '<?xml version="1.0"?>'#13#10 +
      '<?xml-stylesheet type="text/xsl" href="myfile.xsl" ?>'#13#10 +
      '<bookstore specialty="novel">'#13#10 +
      '  <book style="autobiography">'#13#10 +
      '    <author>'#13#10 +
      '      <first-name>Joe</first-name>'#13#10 +
      '      <last-name>Bob</last-name>'#13#10 +
      '      <award>Trenton Literary Review Honorable Mention</award>'#13#10 +
      '    </author>'#13#10 +
      '    <price>12</price>'#13#10 +
      '  </book>'#13#10 +
      '  <book style="textbook">'#13#10 +
      '    <author>'#13#10 +
      '      <first-name>Mary</first-name>'#13#10 +
      '      <last-name>Bob</last-name>'#13#10 +
      '      <publication>Selected Short Stories of'#13#10 +
      '        <first-name>Mary</first-name>'#13#10 +
      '        <last-name>Bob</last-name>'#13#10 +
      '      </publication>'#13#10 +
      '    </author>'#13#10 +
      '    <editor>'#13#10 +
      '      <first-name>Britney</first-name>'#13#10 +
      '      <last-name>Bob</last-name>'#13#10 +
      '    </editor>'#13#10 +
      '    <price>55</price>'#13#10 +
      '  </book>'#13#10 +
      '  <magazine style="glossy" frequency="monthly">'#13#10 +
      '    <price>2.50</price>'#13#10 +
      '    <subscription price="24" per="year"/>'#13#10 +
      '  </magazine>'#13#10 +
      '  <book style="novel" id="myfave">'#13#10 +
      '    <author>'#13#10 +
      '      <first-name>Toni</first-name>'#13#10 +
      '      <last-name>Bob</last-name>'#13#10 +
      '      <degree from="Trenton U">B.A.</degree>'#13#10 +
      '      <degree from="Harvard">Ph.D.</degree>'#13#10 +
      '      <award>Pulitzer</award>'#13#10 +
      '      <publication>Still in Trenton</publication>'#13#10 +
      '      <publication>Trenton Forever</publication>'#13#10 +
      '    </author>'#13#10 +
      '    <price intl="Canada" exchange="0.7">6.50</price>'#13#10 +
      '    <excerpt>'#13#10 +
      '      <p>It was a dark and stormy night.</p>'#13#10 +
      '      <p>But then all nights in Trenton seem dark and'#13#10 +
      '      stormy to someone who has gone through what'#13#10 +
      '      <emph>I</emph> have.</p>'#13#10 +
      '      <definition-list>'#13#10 +
      '        <my:title xmlns:my="uri:mynamespace">additional title</my:title>'#13#10 +
      '        <term>Trenton</term>'#13#10 +
      '        <definition>misery</definition>'#13#10 +
      '      </definition-list>'#13#10 +
      '    </excerpt>'#13#10 +
      '  </book>'#13#10 +
      '  <my:book xmlns:my="uri:mynamespace" style="leather" price="29.50">'#13#10 +
      '    <my:title>Who''s Who in Trenton</my:title>'#13#10 +
      '    <my:author>Robert Bob</my:author>'#13#10 +
      '  </my:book>'#13#10 +
      '</bookstore>'#13#10
     ,'')

      ,('<book style="autobiography"><template:read source="./author" var="test"/></book>','','test=Joe[[#10]]      Bob[[#10]]      Trenton Literary Review Honorable Mention')
      ,('<book style="autobiography"><template:read source="author" var="test2"/></book>','','test2=Joe[[#10]]      Bob[[#10]]      Trenton Literary Review Honorable Mention')
      ,('<book style="autobiography"><template:read source="//author" var="test3"/></book>','','test3=Joe[[#10]]      Bob[[#10]]      Trenton Literary Review Honorable Mention')
      ,('<book style="autobiography"><template:read source="string-join(//author,'','')" var="test"/></book>','','test=Joe[[#10]]      Bob[[#10]]      Trenton Literary Review Honorable Mention,Mary[[#10]]      Bob[[#10]]      Selected Short Stories of[[#10]]        Mary[[#10]]        Bob,Toni[[#10]]      Bob[[#10]]      B.A.[[#10]]      Ph.D.[[#10]]      Pulitzer[[#10]]      Still in Trenton[[#10]]      Trenton Forever')
      ,('<bookstore><template:read source="/bookstore/@specialty" var="test"/></bookstore>','','test=novel')
      ,('<bookstore><template:read source="book[/bookstore/@specialty=@style]/@id" var="test"/></bookstore>','','test=myfave')
      ,('<bookstore><book><template:read source="author/first-name" var="test"/></book></bookstore>','','test=Joe')
      ,('<template:read source="string-join(bookstore//my:title,'','')" var="test"/>','','test=additional title,Who''s Who in Trenton')
      ,('<template:read source="string-join( bookstore//book/excerpt//emph,'','')" var="test"/>','','test=I')
      ,('<bookstore><book><template:read source="string-join( author/*,'','')" var="test"/></book></bookstore>','','test=Joe,Bob,Trenton Literary Review Honorable Mention')
      ,('<bookstore><book><template:read source="string-join( author/*,'','')" var="test"/></book></bookstore>','','test=Joe,Bob,Trenton Literary Review Honorable Mention')
      ,('<bookstore><template:read source="string-join( book/*/last-name,'','')" var="test"/></bookstore>','','test=Bob,Bob,Bob,Bob')
      ,('<bookstore><book style="textbook"><template:read source="string-join( */*,'','')" var="test"/></book></bookstore>','','test=Mary,Bob,Selected Short Stories of[[#10]]        Mary[[#10]]        Bob,Britney,Bob')
      ,('<template:read source="string-join(*[@specialty]/node-name(.),'','')" var="test"/>','','test=bookstore')
      ,('<bookstore><book><template:read source="@style" var="test"/></book></bookstore>','','test=autobiography')
      ,('<bookstore><template:read source="//price/@exchange" var="test"/></bookstore>  ','','test=0.7')
      ,('<bookstore><template:read source="//price/@exchange/total" var="test"/></bookstore>  ','','test=') //todo: attribute nodes failed test
      ,('<bookstore><template:read source="string-join(book[@style]/price/text(),'','')" var="test"/></bookstore>  ','','test=12,55,6.50')
      ,('<bookstore><template:read source="string-join(book/@style,'','')" var="test"/></bookstore>  ','','test=autobiography,textbook,novel')
      ,('<bookstore><template:read source="string-join(@*,'','')" var="test"/></bookstore>  ','','test=novel')
      ,('<bookstore><book><author><template:read source="string-join( ./first-name,'','')" var="test"/></author></book></bookstore>  ','','test=Joe')
      ,('<bookstore><book><author><template:read source="string-join( first-name,'','')" var="test"/></author></book></bookstore>  ','','test=Joe')
      ,('<bookstore><book style="textbook"><template:read source="string-join( author[1],'','')" var="test"/></book></bookstore>  ','','test=Mary[[#10]]      Bob[[#10]]      Selected Short Stories of[[#10]]        Mary[[#10]]        Bob')
      ,('<bookstore><book style="textbook"><template:read source="string-join( author[first-name][1],'','')" var="test"/></book></bookstore>  ','','test=Mary[[#10]]      Bob[[#10]]      Selected Short Stories of[[#10]]        Mary[[#10]]        Bob')
      ,('<bookstore><template:read source="book[last()]//text()" var="test"/></bookstore>  ','','test=')
      ,('<bookstore><template:read source="string-join(book/author[last()]/first-name,'','')" var="test"/></bookstore>','','test=Joe,Mary,Toni')
      ,('<bookstore><template:read source="string-join((book/author)[last()]/first-name,'','')" var="test"/></bookstore>','','test=Toni')
      ,('<bookstore><template:read source="string-join( book[excerpt]/@style,'','')" var="test"/></bookstore>','','test=novel')
      ,('<bookstore><template:read source="string-join( book[excerpt]/title,'','')" var="test"/></bookstore>','','test=')
      ,('<bookstore><template:read source="string-join(  book[excerpt]/author[degree] ,'','')" var="test"/></bookstore>','','test=Toni[[#10]]      Bob[[#10]]      B.A.[[#10]]      Ph.D.[[#10]]      Pulitzer[[#10]]      Still in Trenton[[#10]]      Trenton Forever')
      ,('<bookstore><template:read source="string-join(   book[author/degree]/@style   ,'','')" var="test"/></bookstore>','','test=novel')
      ,('<bookstore><template:read source="string-join( book/author[degree][award] /../@style   ,'','')" var="test"/></bookstore>','','test=novel')
      ,('<bookstore><template:read source="string-join( book/author[degree and award]  /  ../@style   ,'','')" var="test"/></bookstore>','','test=novel')
      ,('<bookstore><template:read source="string-join(book/author[(degree or award) and publication]/../@style,'','')" var="test"/></bookstore>','','test=novel')
      ,('<bookstore><template:read source="string-join(book/author[degree and not(publication)]/../@style,'','')" var="test"/></bookstore>','','test=')
      ,('<bookstore><template:read source="string-join(book/author[not(degree or award) and publication]/../@style,'','')" var="test"/></bookstore>','','test=textbook')
      ,('<bookstore><template:read source="string-join(book/author[last-name = ''Bob'']/first-name,'','')" var="test"/></bookstore>','','test=Joe,Mary,Toni')
      ,('<bookstore><template:read source="string-join(book/author[last-name[1] = ''Bob'']/first-name,'','')" var="test"/></bookstore>','','test=Joe,Mary,Toni')
      ,('<bookstore><template:read source="string-join(book/author[last-name[position()=1] = ''Bob'']/first-name,'','')" var="test"/></bookstore>','','test=Joe,Mary,Toni')
      //more skipped

      //from wikipedia
      ,('','<?xml version="1.0" encoding="utf-8" standalone="yes" ?>' +
       '<dok>' +
       '    <!-- ein XML-Dokument -->' +
       '    <kap title="Nettes Kapitel">' +
       '        <pa>Ein Absatz</pa>' +
       '        <pa>Noch ein Absatz</pa>' +
       '        <pa>Und noch ein Absatz</pa>' +
       '        <pa>Nett, oder?</pa>' +
       '    </kap>' +
       '    <kap title="Zweites Kapitel">' +
       '        <pa>Ein Absatz</pa>' +
       '    </kap>' +
       '</dok>','' )
      ,('<dok><kap><template:read source="string-join( /dok ,'';'')" var="test"/></kap></dok>','','test=Ein Absatz        Noch ein Absatz        Und noch ein Absatz        Nett, oder?                Ein Absatz')
      ,('<dok><kap><template:read source="string-join( /* ,'';'')" var="test"/></kap></dok>','','test=Ein Absatz        Noch ein Absatz        Und noch ein Absatz        Nett, oder?                Ein Absatz')
      ,('<dok><kap><template:read source="string-join( //dok/kap ,'';'')" var="test"/></kap></dok>','','test=Ein Absatz        Noch ein Absatz        Und noch ein Absatz        Nett, oder?;Ein Absatz')
      ,('<dok><kap><template:read source="string-join( //dok/kap[1] ,'';'')" var="test"/></kap></dok>','','test=Ein Absatz        Noch ein Absatz        Und noch ein Absatz        Nett, oder?')
      ,('<dok><kap><template:read source="string-join( //pa,'';'')" var="test"/></kap></dok>','','test=Ein Absatz;Noch ein Absatz;Und noch ein Absatz;Nett, oder?;Ein Absatz')
      ,('<dok><kap><template:read source="string-join( //kap[@title=''Nettes Kapitel'']/pa,'';'')" var="test"/></kap></dok>','','test=Ein Absatz;Noch ein Absatz;Und noch ein Absatz;Nett, oder?')
      ,('<dok><kap><template:read source="string-join( child::*,'';'')" var="test"/></kap></dok>','','test=Ein Absatz;Noch ein Absatz;Und noch ein Absatz;Nett, oder?')
      ,('<dok><kap><template:read source="string-join( child::pa,'';'')" var="test"/></kap></dok>','','test=Ein Absatz;Noch ein Absatz;Und noch ein Absatz;Nett, oder?')
      ,('<dok><kap><template:read source="string-join( child::text(),'';'')" var="test"/></kap></dok>','','test=;;;;')
      ,('<dok><kap><pa><template:read source="string-join( text(),'';'')" var="test"/></pa></kap></dok>','','test=Ein Absatz')
      ,('<dok><kap><pa><template:read source="string-join( ./*,'';'')" var="test"/></pa></kap></dok>','','test=')
      ,('<dok><kap><template:read source="string-join( ./*,'';'')" var="test"/></kap></dok>','','test=Ein Absatz;Noch ein Absatz;Und noch ein Absatz;Nett, oder?')


      //namespaces
      ,('<a>as<t:read source="text()" var="a"/></a><b template:optional="true"></b>','<a>asx</a><x/>', 'a=asx')
      ,('<a>as<t:read source="text()" var="a"/></a><b template:optional="true"></b>','<a>asx</a>','a=asx')
      ,('<a>as<template:read source="text()" var="a"/></a><b t:optional="true"></b>','<a>asx</a><x/>', 'a=asx')
      ,('<a>as<template:read source="text()" var="a"/></a><b t:optional="true"></b>','<a>asx</a>','a=asx')
      ,('<a>as<t:read source="text()" var="a"/></a><b t:optional="true"></b>','<a>asx</a><x/>', 'a=asx')
      ,('<a>as<t:read source="text()" var="a"/></a><b t:optional="true"></b>','<a>asx</a>','a=asx')
      ,('<a xmlns:bb="http://www.benibela.de/2011/templateparser">as<bb:read source="text()" var="a"/></a><b xmlns:bb="http://www.benibela.de/2011/templateparser" bb:optional="true"></b>','<a>asx</a><x/>', 'a=asx')
      ,('<a xmlns:bb="http://www.benibela.de/2011/templateparser">as<bb:read source="text()" var="a"/></a><b xmlns:bb="http://www.benibela.de/2011/templateparser" bb:optional="true"></b>','<a>asx</a>','a=asx')

      //test attribute
      ,('<a><t:if test="text()=''hallo''"><t:read var="res" source="b/text()"/></t:if></a>', '<a>hallo<b>gx</b></a>', 'res=gx')
      ,('<a><t:if test="text()=''hallo''"><t:read var="res" source="b/text()"/></t:if></a>', '<a>hallo2<b>gx</b></a>', '')
      ,('<a><t:read test="text()=''hallo''" var="res" source="b/text()"/></a>', '<a>hallo<b>gx</b></a>', 'res=gx')
      ,('<a><t:read test="text()=''hallo''" var="res" source="b/text()"/></a>', '<a>hallo2<b>gx</b></a>', '')

      //short test
      ,('<a><t:s>x:=text()</t:s></a>', '<a>hallo</a>', 'x=hallo')
      ,('<a><t:s>x:=.</t:s></a>', '<a>hallo</a>', 'x=hallo')
      ,('<a><t:s>ab:=.</t:s></a>', '<a>123</a>', 'ab=123')
      ,('<a><t:s>ab := .</t:s></a>', '<a>123456</a>', 'ab=123456')
      ,('<a><xxx></xxx><b><t:s>x:=.</t:s></b><yyy></yyy></a>', '<a>adas<xxx>asfas</xxx><b>here</b><yyy>asas</yyy>asfasf</a>', 'x=here')

      //switch
      ,('<a><t:switch value="3"><t:s value="1">x:=10</t:s><t:s value="2">x:=20</t:s><t:s value="3">x:=30</t:s><t:s value="4">x:=40</t:s><t:s value="5">x:=50</t:s></t:switch></a>', '<a>hallo</a>', 'x=30')
      ,('<a><t:switch value="3"><t:s value="1">x:=10</t:s><t:s value="3">x:="3a"</t:s><t:s value="3">x:="3b"</t:s><t:s value="3">x:="3c"</t:s><t:s value="5">x:=50</t:s></t:switch></a>', '<a>hallo</a>', 'x=3a')
      ,('<a><t:switch value="3"><t:s value="1">x:=10</t:s><t:s value="3" test="false()">x:="3a"</t:s><t:s value="3" test="true()">x:="3b"</t:s><t:s value="3">x:="3c"</t:s><t:s value="5">x:=50</t:s></t:switch></a>', '<a>hallo</a>', 'x=3b')
      ,('<a><t:switch value="3"><t:s value="1">x:=10</t:s><t:s value="3.0">x:="3a"</t:s><t:s value="3" test="true()">x:="3b"</t:s><t:s value="3">x:="3c"</t:s><t:s value="5">x:=50</t:s></t:switch></a>', '<a>hallo</a>', 'x=3a')
      ,('<a><t:switch value="10"><t:s value="1">x:=10</t:s><t:s value="3.0">x:="3a"</t:s><t:s value="3" test="true()">x:="3b"</t:s><t:s value="3">x:="3c"</t:s><t:s value="5">x:=50</t:s></t:switch></a>', '<a>hallo</a>', '')
      ,('<xx><t:switch value="3"><t:if value="1"><a><t:s>x:=text()</t:s></a></t:if><t:if value="2"><b><t:s>x:=text()</t:s></b></t:if><t:if value="3"><c><t:s>x:=text()</t:s></c></t:if><t:if value="4"><d><t:s>x:=text()</t:s></d></t:if></t:switch></xx>', '<xx><a>AA</a><b>BB</b><c>CC</c><d>DD</d></xx>', 'x=CC')
      ,('<xx><t:switch value="@choose"><t:if value="1"><a><t:s>x:=text()</t:s></a></t:if><t:if value="2"><b><t:s>x:=text()</t:s></b></t:if>'+'<t:if value="3"><c><t:s>x:=text()</t:s></c></t:if><t:if value="4"><d><t:s>x:=text()</t:s></d></t:if></t:switch></xx>', '<xx choose=1><a>AA</a><b>BB</b><c>CC</c><d>DD</d></xx>', 'x=AA')
      ,('<xx><t:switch value="@choose"><t:if value="1"><a><t:s>x:=text()</t:s></a></t:if><t:if value="2"><b><t:s>x:=text()</t:s></b></t:if>'+'<t:if value="3"><c><t:s>x:=text()</t:s></c></t:if><t:if value="4"><d><t:s>x:=text()</t:s></d></t:if></t:switch></xx>', '<xx choose=4><a>AA</a><b>BB</b><c>CC</c><d>DD</d></xx>', 'x=DD')
      ,('<xx><t:switch value="@choose"><t:if value="1"><a><t:s>x:=text()</t:s></a></t:if><t:if value="2"><b><t:s>x:=text()</t:s></b></t:if>'+'<t:if value="3"><c><t:s>x:=text()</t:s></c></t:if><t:if value="4"><d><t:s>x:=text()</t:s></d></t:if></t:switch></xx>', '<xx choose=40><a>AA</a><b>BB</b><c>CC</c><d>DD</d></xx>', '')
      ,('<xx><t:switch value="@choose"><t:if value="1"><a><t:s>x:=text()</t:s></a></t:if><t:if value="2"><b><t:s>x:=text()</t:s></b></t:if>'+'<t:if value="3"><c><t:s>x:=text()</t:s></c></t:if><t:if value="4"><d><t:s>x:=text()</t:s></d></t:if><t:s>x:="not found"</t:s></t:switch></xx>', '<xx choose=40><a>AA</a><b>BB</b><c>CC</c><d>DD</d></xx>', 'x=not found')
      ,('<xx><t:s>x:="pre"</t:s><t:switch value="@choose"><t:if value="1"><a><t:s>x:=text()</t:s></a></t:if><t:if value="2"><b><t:s>x:=text()</t:s></b></t:if>'+'<t:if value="3"><c><t:s>x:=text()</t:s></c></t:if><t:if value="4"><d><t:s>x:=text()</t:s></d></t:if><t:s>x:="not found"</t:s></t:switch><t:s>x:="post"</t:s></xx>', '<xx choose=40><a>AA</a><b>BB</b><c>CC</c><d>DD</d></xx>', 'x=pre'#13'x=not found'#13'x=post')
      ,('<xx><t:s>x:="pre"</t:s><t:switch value="@choose"><t:if value="1"><a><t:s>x:=text()</t:s></a></t:if><t:if value="2"><b><t:s>x:=text()</t:s></b></t:if>'+'<t:if value="3"><c><t:s>x:=text()</t:s></c></t:if><t:if value="4"><d><t:s>x:=text()</t:s></d></t:if><t:s>x:="not found"</t:s><t:s>x:=ignored</t:s></t:switch><t:s>x:="post"</t:s></xx>', '<xx choose=40><a>AA</a><b>BB</b><c>CC</c><d>DD</d></xx>', 'x=pre'#13'x=not found'#13'x=post')
      ,('<xx><t:s>x:="pre"</t:s><t:switch value="@choose"><t:if value="1 to 10"><a><t:s>x:=text()</t:s></a></t:if><t:if value="20 to 100"><b><t:s>x:=text()</t:s></b></t:if>'+'<t:if value="3"><c><t:s>x:=text()</t:s></c></t:if><t:if value="4"><d><t:s>x:=text()</t:s></d></t:if><t:s>x:="not found"</t:s><t:s>x:=ignored</t:s></t:switch><t:s>x:="post"</t:s></xx>', '<xx choose=40><a>AA</a><b>BB</b><c>CC</c><d>DD</d></xx>', 'x=pre'#13'x=BB'#13'x=post')
      ,('<xx><t:s>x:="pre"</t:s><t:switch value="@choose"></t:switch><t:s>x:="post"</t:s></xx>', '<xx choose=40><a>AA</a><b>BB</b><c>CC</c><d>DD</d></xx>', 'x=pre'#13'x=post')
      ,('<xx><t:s>x:="pre"</t:s><t:switch value="@choose"><t:s>x:="always"</t:s></t:switch><t:s>x:="post"</t:s></xx>', '<xx choose=40><a>AA</a><b>BB</b><c>CC</c><d>DD</d></xx>', 'x=pre'#13'x=always'#13'x=post')


      //directly used match-text command
      ,('<a><t:match-text starts-with="abc"/><t:s>x:=text()</t:s></a>', '<m><a>ab</a><a>abc</a><a>abcd</a></m>', 'x=abc')
      ,('<a><t:match-text starts-with="abc"/><t:s>x:=text()</t:s></a>', '<m><a>ab</a><a>abcd</a><a>abc</a></m>', 'x=abcd')
      ,('<a><t:match-text starts-with="abc"/><t:s>x:=text()</t:s></a>', '<m><a>ABCXX</a><a>abc</a><a>abcd</a></m>', 'x=ABCXX')
      ,('<a><t:match-text starts-with="abc"/><t:s>x:=text()</t:s></a>', '<m><a>tABCXX</a><a>abc</a><a>abcd</a></m>', 'x=abc')
      ,('<a><t:match-text starts-with="abc" case-sensitive/><t:s>x:=text()</t:s></a>', '<m><a>ABCXX</a><a>abc</a><a>abcd</a></m>', 'x=abc')
      ,('<a><t:match-text ends-with="abc"/><t:s>x:=text()</t:s></a>', '<m><a>ab</a><a>abc</a><a>abcd</a></m>', 'x=abc')
      ,('<a><t:match-text ends-with="abc"/><t:s>x:=text()</t:s></a>', '<m><a>ab</a><a>abcd</a><a>abc</a></m>', 'x=abc')
      ,('<a><t:match-text ends-with="abc"/><t:s>x:=text()</t:s></a>', '<m><a>XXABC</a><a>abc</a><a>abcd</a></m>', 'x=XXABC')
      ,('<a><t:match-text contains="abc"/><t:s>x:=text()</t:s></a>', '<m><a>ab</a><a>abc</a><a>abcd</a></m>', 'x=abc')
      ,('<a><t:match-text contains="abc"/><t:s>x:=text()</t:s></a>', '<m><a>ab</a><a>abcd</a><a>abc</a></m>', 'x=abcd')
      ,('<a><t:match-text contains="abc"/><t:s>x:=text()</t:s></a>', '<m><a>XXABC</a><a>abc</a><a>abcd</a></m>', 'x=XXABC')
      ,('<a><t:match-text contains="."/><t:s>x:=text()</t:s></a>', '<m><a>XXABC</a><a>abc</a><a>abcd</a><a>xx.xx</a></m>', 'x=xx.xx')
      ,('<a><t:match-text regex="."/><t:s>x:=text()</t:s></a>', '<m><a>XXABC</a><a>abc</a><a>abcd</a><a>xx.xx</a><a>t</a></m>', 'x=XXABC')
      ,('<a><t:match-text regex="^.$"/><t:s>x:=text()</t:s></a>', '<m><a>XXABC</a><a>abc</a><a>abcd</a><a>xx.xx</a><a>t</a></m>', 'x=t')
      ,('<a><t:match-text list-contains="abc"/><t:s>x:=text()</t:s></a>', '<m><a>XXABC</a><a>abc</a><a>abcd</a><a>xx.xx</a><a>t</a></m>', 'x=abc')
      ,('<a><t:match-text list-contains="abc"/><t:s>x:=text()</t:s></a>', '<m><a>XXABC,abc</a><a>abc</a><a>abcd</a><a>xx.xx</a><a>t</a></m>', 'x=XXABC,abc')
      ,('<a><t:match-text list-contains="abc"/><t:s>x:=text()</t:s></a>', '<m><a>XXABC  ,   abc  , foobar</a><a>abc</a><a>abcd</a><a>xx.xx</a><a>t</a></m>', 'x=XXABC  ,   abc  , foobar')
      ,('<a><t:match-text list-contains="abc"/><t:s>x:=text()</t:s></a>', '<m><a> abc  , foobar</a><a>abc</a><a>abcd</a><a>xx.xx</a><a>t</a></m>', 'x=abc  , foobar')
      ,('<a><t:match-text list-contains="abc"/><t:s>x:=text()</t:s></a>', '<m><a>   abc  </a><a>abc</a><a>abcd</a><a>xx.xx</a><a>t</a></m>', 'x=abc')
      ,('<a><t:match-text is="abc"/><t:s>x:=text()</t:s></a>', '<m><a>ab</a><a>abc</a><a>abcd</a></m>', 'x=abc')
      ,('<a><t:match-text starts-with="abc" condition="@foo=''bar''"/><t:s>x:=text()</t:s></a>', '<m><a>abc</a><a>abc</a><a foo="bar">abcd</a></m>', 'x=abcd')
      ,('<a><t:match-text starts-with="abc" ends-with="abc"/><t:s>x:=text()</t:s></a>', '<m><a>ab</a><a>abcd</a><a>abc</a></m>', 'x=abc')
      ,('<a><t:match-text starts-with="abc" ends-with="abc"/><t:s>x:=text()</t:s></a>', '<m><a>ab</a><a>abcdabc</a><a>abc</a></m>', 'x=abcdabc')

      //change default text matching
      ,('<a>abc<t:s>x:=text()</t:s></a>', '<m><a>ab</a><a>abc</a><a>abcd</a></m>', 'x=abc')
      ,('<a>abc<t:s>x:=text()</t:s></a>', '<m><a>ab</a><a>abcd</a><a>abc</a></m>', 'x=abcd')
      ,('<a>abc<t:s>x:=text()</t:s></a>', '<m><a>ABCXX</a><a>abc</a><a>abcd</a></m>', 'x=ABCXX')
      ,('<a>abc<t:s>x:=text()</t:s></a>', '<m><a>tABCXX</a><a>abc</a><a>abcd</a></m>', 'x=abc')
      ,('<a>äöü<t:s>x:=text()</t:s></a>', '<m><a>äö</a><a>äöü</a><a>äöüd</a></m>', 'x=äöü')
      ,('<a><t:meta default-text-case-sensitive="sensitive"/>abc<t:s>x:=text()</t:s></a>', '<m><a>ABCXX</a><a>abc</a><a>abcd</a></m>', 'x=abc')
      ,('<a><t:meta default-text-case-sensitive="false"/>abc<t:s>x:=text()</t:s></a>', '<m><a>ABCXX</a><a>abc</a><a>abcd</a></m>', 'x=ABCXX')
      ,('<a><t:meta default-text-case-sensitive="insensitive"/>abc<t:s>x:=text()</t:s></a>', '<m><a>ABCXX</a><a>abc</a><a>abcd</a></m>', 'x=ABCXX')
      ,('<a><t:meta default-text-case-sensitive="case-insensitive"/>abc<t:s>x:=text()</t:s></a>', '<m><a>ABCXX</a><a>abc</a><a>abcd</a></m>', 'x=ABCXX')
      ,('<a><t:meta default-text-matching="ends-with"/>abc<t:s>x:=text()</t:s></a>', '<m><a>ab</a><a>abcd</a><a>aBc</a></m>', 'x=aBc')
      ,('<a><t:meta default-text-matching="ends-with" default-text-case-sensitive/>abc<t:s>x:=text()</t:s></a>', '<m><a>ab</a><a>abcd</a><a>xxAbc</a><a>xxabc</a></m>', 'x=xxabc')
      ,('<m><a>abc<t:s>x:=text()</t:s></a><a><t:meta default-text-matching="ends-with" default-case-sensitive/>abc<t:s>x:=text()</t:s></a></m>', '<m><a>ab</a><a>abcd</a><a>xxAbc</a><a>xxabc</a></m>', 'x=abcd'#13'x=xxAbc')
      ,('<a><t:meta default-text-case-sensitive="ends-with"/><t:match-text starts-with="abc"/><t:s>x:=text()</t:s></a>', '<m><a>ABCXX</a><a>abc</a><a>abcd</a></m>', 'x=abc')


      //very short syntax
      ,('<a><t:s>x:=text()</t:s></a>', '<m><a>ab</a><a>abc</a><a>abcd</a></m>', 'x=ab')
      ,('<a>{x:=text()}</a>', '<m><a>ab</a><a>abc</a><a>abcd</a></m>', 'x=ab')
      ,('<a>*<t:s>x:=text()</t:s></a>', '<m><a>ab</a><a>abc</a><a>abcd</a></m>', 'x=ab'#13'x=abc'#13'x=abcd')
      ,('<a>*{x:=text()}</a>', '<m><a>ab</a><a>abc</a><a>abcd</a></m>', 'x=ab'#13'x=abc'#13'x=abcd')
      ,('<a><b>*{x:=text()}</b></a>', '<a></a><a><b>1</b><b>2</b></a>', '')
      ,('<a><b>+{x:=text()}</b></a>', '<a></a><a><b>1</b><b>2</b></a>', 'x=1'#13'x=2')
      ,('<a><b>{x:=text()}</b>*</a>', '<a></a><a><b>1</b><b>2</b></a>', '')
      ,('<a><b>{x:=text()}</b>+</a>', '<a></a><a><b>1</b><b>2</b></a>', 'x=1'#13'x=2')
      ,('<a><b>{x:=text()}</b>?</a>', '<a></a><a><b>1</b><b>2</b></a>', '') //optional is local?
      ,('<a><b>{x:=text()}</b>?</a>', '<a></a><a></a>', '')
      ,('<a><b>?{x:=text()}</b></a>', '<a></a><a><b>1</b><b>2</b></a>', '') //optional is local?
      ,('<a><b>?{x:=text()}</b></a>', '<a></a><a></a>', '')
      ,('<a>?<b>{x:=text()}</b></a>', '<a></a><a><b>1</b><b>2</b></a>', 'x=1')
      ,('<a>?<b>{x:=text()}</b></a>', '<a></a><a></a>', '')
      ,('<a><b>{x:=text()}</b>{2,3}</a>', '<a><b>A1</b></a><a><b>B1</b><b>B2</b><b>B3</b><b>B4</b></a>', 'x=B1'#13'x=B2'#13'x=B3')
      ,('<a><b>{2,3}{x:=text()}</b></a>', '<a><b>A1</b></a><a><b>B1</b><b>B2</b><b>B3</b><b>B4</b></a>', 'x=B1'#13'x=B2'#13'x=B3')
      ,('<a><b>{x:=text()}</b>{1,2}</a>', '<a><b>A1</b></a><a><b>B1</b><b>B2</b><b>B3</b><b>B4</b></a>', 'x=A1')
      ,('<a><b>{1,2}{x:=text()}</b></a>', '<a><b>A1</b></a><a><b>B1</b><b>B2</b><b>B3</b><b>B4</b></a>', 'x=A1')
      ,('<a><b>{1,1}{x:=text()}</b></a>', '<a><b>A1</b></a><a><b>B1</b><b>B2</b><b>B3</b><b>B4</b></a>', 'x=A1')
      ,('<a><b>{test:=/deep-text()}</b></a>', '<a><b>A1</b></a><a><b>B1</b><b>B2</b><b>B3</b><b>B4</b></a>', 'test=A1B1B2B3B4')
      ,('<a><b>{test:=static-base-uri()}</b></a>', '<a><b>A1</b></a><a><b>B1</b><b>B2</b><b>B3</b><b>B4</b></a>', 'test=unittest')
      ,('<a><b>{test:=123,abc:="foobar"}</b></a>', '<a><b>A1</b></a><a><b>B1</b><b>B2</b><b>B3</b><b>B4</b></a>', 'test=123'#13'abc=foobar')
      ,('<table id="foobar"><tr>{temp := 0}<td>abc</td><td>{temp := $temp + .}</td>*{result := $temp}</tr>*</table>', '<table id="foobar"><tr><td>abc</td><td>1</td><td>2</td></tr><tr><td>abc</td><td>20</td><td>50</td></tr></table>', 'temp=0'#13'temp=1'#13'temp=3'#13'result=3'#13'temp=0'#13'temp=20'#13'temp=70'#13'result=70')


      //anonymous variables
      ,('<a>{text()}</a>', '<a>hallo</a>', '_result=hallo')
      ,('<a>{t:=text()}</a>', '<a>hallo</a>', 't=hallo')
      ,('<a><t:read var="u" source="text()"/></a>', '<a>hallo</a>', 'u=hallo')
      ,('<a><t:read source="text()"/></a>', '<a>hallo</a>', '_result=hallo')
      ,('<a><t:read var="" source="text()"/></a>', '<a>hallo</a>', '=hallo')

      //else blocks
      ,('<a>{var:=true()}<t:if test="$var">{res:="choose-if"}</t:if></a>', '<a>hallo</a>', 'var=true'#13'res=choose-if')
      ,('<a>{var:=true()}<t:if test="$var">{res:="choose-if"}</t:if><t:else>{res:="choose-else"}</t:else></a>', '<a>hallo</a>', 'var=true'#13'res=choose-if')
      ,('<a>{var:=false()}<t:if test="$var">{res:="choose-if"}</t:if><t:else>{res:="choose-else"}</t:else></a>', '<a>hallo</a>', 'var=false'#13'res=choose-else')
      ,('<a>{var:=1}<t:if test="$var=1">{res:="alpha"}</t:if><t:else test="$var=2">{res:="beta"}</t:else><t:else>{res:="omega"}</t:else></a>', '<a>hallo</a>', 'var=1'#13'res=alpha')
      ,('<a>{var:=2}<t:if test="$var=1">{res:="alpha"}</t:if><t:else test="$var=2">{res:="beta"}</t:else><t:else>{res:="omega"}</t:else></a>', '<a>hallo</a>', 'var=2'#13'res=beta')
      ,('<a>{var:=3}<t:if test="$var=1">{res:="alpha"}</t:if><t:else test="$var=2">{res:="beta"}</t:else><t:else>{res:="omega"}</t:else></a>', '<a>hallo</a>', 'var=3'#13'res=omega')
      ,('<a>{var:=1}<t:if test="$var=1">{res:="alpha"}</t:if><t:else test="$var=2">{res:="beta"}</t:else><t:else test="$var=3">{res:="gamma"}</t:else><t:else test="$var=4">{res:="delta"}</t:else><t:else>{res:="omega"}</t:else></a>', '<a>hallo</a>', 'var=1'#13'res=alpha')
      ,('<a>{var:=2}<t:if test="$var=1">{res:="alpha"}</t:if><t:else test="$var=2">{res:="beta"}</t:else><t:else test="$var=3">{res:="gamma"}</t:else><t:else test="$var=4">{res:="delta"}</t:else><t:else>{res:="omega"}</t:else></a>', '<a>hallo</a>', 'var=2'#13'res=beta')
      ,('<a>{var:=3}<t:if test="$var=1">{res:="alpha"}</t:if><t:else test="$var=2">{res:="beta"}</t:else><t:else test="$var=3">{res:="gamma"}</t:else><t:else test="$var=4">{res:="delta"}</t:else><t:else>{res:="omega"}</t:else></a>', '<a>hallo</a>', 'var=3'#13'res=gamma')
      ,('<a>{var:=4}<t:if test="$var=1">{res:="alpha"}</t:if><t:else test="$var=2">{res:="beta"}</t:else><t:else test="$var=3">{res:="gamma"}</t:else><t:else test="$var=4">{res:="delta"}</t:else><t:else>{res:="omega"}</t:else></a>', '<a>hallo</a>', 'var=4'#13'res=delta')
      ,('<a>{var:=5}<t:if test="$var=1">{res:="alpha"}</t:if><t:else test="$var=2">{res:="beta"}</t:else><t:else test="$var=3">{res:="gamma"}</t:else><t:else test="$var=4">{res:="delta"}</t:else><t:else>{res:="omega"}</t:else></a>', '<a>hallo</a>', 'var=5'#13'res=omega')

      //t:test with html
      ,('<a>{go:="og"}<b t:test="$go=''og''">{text()}</b></a>', '<a><b>test</b></a>', 'go=og'#13'_result=test')
      ,('<a>{go:="go"}<b t:test="$go=''og''">{text()}</b></a>', '<a><b>test</b></a>', 'go=go')

      //switch-prioritized
      ,('<xx><t:switch-prioritized><a>{a:=text()}</a><b>{b:=text()}</b></t:switch-prioritized></xx>', '<xx><a>1</a><b>2</b></xx>', 'a=1')
      ,('<xx><t:switch-prioritized><a>{a:=text()}</a><b>{b:=text()}</b></t:switch-prioritized></xx>', '<xx><b>2</b></xx>', 'b=2')
      ,('<xx><t:switch-prioritized><a>{a:=text()}</a><b>{b:=text()}</b></t:switch-prioritized></xx>', '<xx><b>2</b><a>1</a></xx>', 'a=1')
      //+fillings
      ,('<xx><t:switch-prioritized><a>{a:=text()}</a><b>{b:=text()}</b></t:switch-prioritized></xx>', '<xx>....<t>...<a>1</a>aas</t>assa<u>fdas<b>2</b>asdasd</u></xx>', 'a=1')
      ,('<xx><t:switch-prioritized><a>{a:=text()}</a><b>{b:=text()}</b></t:switch-prioritized></xx>', '<xx><h>ass</h>assa<b>2</b>asdas</xx>', 'b=2')
      ,('<xx><t:switch-prioritized><a>{a:=text()}</a><b>{b:=text()}</b></t:switch-prioritized></xx>', '<xx><h><b>2</b></h>asassas<t><z><a>1</a>wwerew</z>asas</t></xx>', 'a=1')
      //+loop
      ,('<xx><t:switch-prioritized><a>{a:=text()}</a><b>{b:=text()}</b></t:switch-prioritized>*</xx>', '<xx><a>1</a><b>2</b></xx>', 'a=1'#13'b=2')
      ,('<xx><t:switch-prioritized><a>{a:=text()}</a><b>{b:=text()}</b></t:switch-prioritized>*</xx>', '<xx><b>2</b><a>1</a></xx>', 'a=1')
      ,('<xx><t:switch-prioritized><a>{a:=text()}</a><b>{b:=text()}</b></t:switch-prioritized>*</xx>', '<xx><a>1</a><b>2</b><a>3</a><a>4</a></xx>', 'a=1'#13'a=3'#13'a=4')
      ,('<xx><t:switch-prioritized><a>{a:=text()}</a><b>{b:=text()}</b></t:switch-prioritized>*</xx>', '<xx><a>1</a><b>2</b><a>3</a><a>4</a><b>5</b></xx>', 'a=1'#13'a=3'#13'a=4'#13'b=5')
      ,('<xx><t:switch-prioritized><a>{a:=text()}</a></t:switch-prioritized>*</xx>', '<xx><a>1</a><b>2</b><a>3</a><a>4</a><b>5</b></xx>', 'a=1'#13'a=3'#13'a=4')
      ,('<xx><t:switch-prioritized><b>{b:=text()}</b></t:switch-prioritized>*</xx>', '<xx><a>1</a><b>2</b><a>3</a><a>4</a><b>5</b></xx>', 'b=2'#13'b=5')
      ,('<xx><t:switch-prioritized><a>{a:=text()}</a><b>{b:=text()}</b><c>{c:=text()}</c></t:switch-prioritized>*</xx>', '<xx><c>0</c><a>1</a><b>2</b><a>3</a><a>4</a><b>5</b><c>6</c></xx>', 'a=1'#13'a=3'#13'a=4'#13'b=5'#13'c=6')



      //whitespace
      ,('<a><b>  abc <t:s>text()</t:s></b></a>', '<a><b>  abc1</b><b>abc2</b><b>abc3</b></a>', '_result=abc1')


      //some html parser tests
      ,('<html>{x:=outer-xml(.)}</html>', '<html>abc<input/>def1</html>', 'x=<html>abc<input/>def1</html>')
      ,('<html>{x:=outer-xml(.)}</html>', '<html>abc<input>def2</input></html>',        'x=<html>abc<input>def2</input></html>') //allow content within <input> tags (this is absolutely necessary for things like <input>{data:=concat(@name,'=',@value)}</input>)
      ,('<html>{x:=outer-xml(.)}</html>', '<html>abc<input>def3<input>123x</input>456</input></html>', 'x=<html>abc<input/>def3<input>123x</input>456</html>')
      ,('<html>{x:=outer-xml(.)}</html>', '<html>abc<input><b>def2</b></input></input></input></html>',        'x=<html>abc<input><b>def2</b></input></html>')
      ,('<html>{x:=outer-xml(.)}</html>', '<html></input></input></input></html>',        'x=<html/>')
      ,('<html>{x:=outer-xml(.)}</html>', '<html><b>abc<input>def</b></input></html>',        'x=<html><b>abc<input/>def</b></html>')
      ,('<html>{x:=outer-xml(.)}</html>', '<html><input><b>abc<input>def</b></input></html>',        'x=<html><input/><b>abc<input/>def</b></html>') //don't allow nesting of auto closed tags in each other
      ,('<html>{x:=outer-xml(.)}</html>', '<html>abc<img>def2</img></html>',        'x=<html>abc<img>def2</img></html>') //same for all auto closed tags
      ,('<img>{@src}</img>', '<html><img src="joke.gif"/></html>',        '_result=joke.gif') //real world example (but the template is parsed as xml, not html, so it does not really test anything)
      ,('<input>{post:=concat(@name,"=",@value)}</input>', '<html><input name="a" value="b"/></html>',        'post=a=b')
);

//test all possible (4*2) white space config options
var whiteSpaceData: array[1..40] of array[0..3] of string = (
//matching
 ('0f', '<a><b>  abc <t:s>text()</t:s></b></a>', '<a><b>  abc1</b><b>abc2</b><b>abc3</b></a>', '_result=abc2')
,('1f', '<a><b>  abc <t:s>text()</t:s></b></a>', '<a><b>  abc1</b><b>abc2</b><b>abc3</b></a>', '_result=  abc1')
,('2f', '<a><b>  abc <t:s>text()</t:s></b></a>', '<a><b>  abc1</b><b>abc2</b><b>abc3</b></a>', '_result=  abc1')
,('3f', '<a><b>  abc <t:s>text()</t:s></b></a>', '<a><b>  abc1</b><b>abc2</b><b>abc3</b></a>', '_result=abc1')
,('0t', '<a><b>  abc <t:s>text()</t:s></b></a>', '<a><b>  abc1</b><b>abc2</b><b>abc3</b></a>', '_result=abc2')
,('1t', '<a><b>  abc <t:s>text()</t:s></b></a>', '<a><b>  abc1</b><b>abc2</b><b>abc3</b></a>', '_result=abc1')
,('2t', '<a><b>  abc <t:s>text()</t:s></b></a>', '<a><b>  abc1</b><b>abc2</b><b>abc3</b></a>', '_result=abc1')
,('3t', '<a><b>  abc <t:s>text()</t:s></b></a>', '<a><b>  abc1</b><b>abc2</b><b>abc3</b></a>', '_result=abc1')
//nodes in tree
,('0f', '<a>{.}</a>', '<a> <x> : </x> <b> test  </b>  <x> ; </x>  </a>', '_result=  :   test     ;   ')
,('1f', '<a>{.}</a>', '<a> <x> : </x> <b> test  </b>  <x> ; </x>  </a>', '_result=  :   test     ;   ')
,('2f', '<a>{.}</a>', '<a> <x> : </x> <b> test  </b>  <x> ; </x>  </a>', '_result= :  test   ; ')
,('3f', '<a>{.}</a>', '<a> <x> : </x> <b> test  </b>  <x> ; </x>  </a>', '_result=:test;')
,('0t', '<a>{.}</a>', '<a> <x> : </x> <b> test  </b>  <x> ; </x>  </a>', '_result=:   test     ;')
,('1t', '<a>{.}</a>', '<a> <x> : </x> <b> test  </b>  <x> ; </x>  </a>', '_result=:   test     ;')
,('2t', '<a>{.}</a>', '<a> <x> : </x> <b> test  </b>  <x> ; </x>  </a>', '_result=:  test   ;')
,('3t', '<a>{.}</a>', '<a> <x> : </x> <b> test  </b>  <x> ; </x>  </a>', '_result=:test;')
,('0f', '<a><b>{.}</b></a>', '<a> <x> : </x> <b> test  </b>  <x> ; </x>  </a>', '_result= test  ')
,('1f', '<a><b>{.}</b></a>', '<a> <x> : </x> <b> test  </b>  <x> ; </x>  </a>', '_result= test  ')
,('2f', '<a><b>{.}</b></a>', '<a> <x> : </x> <b> test  </b>  <x> ; </x>  </a>', '_result= test  ')
,('3f', '<a><b>{.}</b></a>', '<a> <x> : </x> <b> test  </b>  <x> ; </x>  </a>', '_result=test')
,('0t', '<a><b>{.}</b></a>', '<a> <x> : </x> <b> test  </b>  <x> ; </x>  </a>', '_result=test')
,('1t', '<a><b>{.}</b></a>', '<a> <x> : </x> <b> test  </b>  <x> ; </x>  </a>', '_result=test')
,('2t', '<a><b>{.}</b></a>', '<a> <x> : </x> <b> test  </b>  <x> ; </x>  </a>', '_result=test')
,('3t', '<a><b>{.}</b></a>', '<a> <x> : </x> <b> test  </b>  <x> ; </x>  </a>', '_result=test')
,('0f', '<a>{string-join(./text(), "|")}</a>', '<a> <x> : </x> <b> test  </b>  <x> ; </x>  </a>', '_result= | |  |  ')
,('1f', '<a>{string-join(./text(), "|")}</a>', '<a> <x> : </x> <b> test  </b>  <x> ; </x>  </a>', '_result= | |  |  ')
,('2f', '<a>{string-join(./text(), "|")}</a>', '<a> <x> : </x> <b> test  </b>  <x> ; </x>  </a>', '_result=')
,('3f', '<a>{string-join(./text(), "|")}</a>', '<a> <x> : </x> <b> test  </b>  <x> ; </x>  </a>', '_result=')
,('0t', '<a>{string-join(./text(), "|")}</a>', '<a> <x> : </x> <b> test  </b>  <x> ; </x>  </a>', '_result=|||')
,('1t', '<a>{string-join(./text(), "|")}</a>', '<a> <x> : </x> <b> test  </b>  <x> ; </x>  </a>', '_result=|||')
,('2t', '<a>{string-join(./text(), "|")}</a>', '<a> <x> : </x> <b> test  </b>  <x> ; </x>  </a>', '_result=')
,('3t', '<a>{string-join(./text(), "|")}</a>', '<a> <x> : </x> <b> test  </b>  <x> ; </x>  </a>', '_result=')
,('0f', '<a>{string-join(text(), "|")}</a>', '<a> <x> : </x> <b> test  </b>  <x> ; </x>  </a>', '_result= ')
,('1f', '<a>{string-join(text(), "|")}</a>', '<a> <x> : </x> <b> test  </b>  <x> ; </x>  </a>', '_result= ')
,('2f', '<a>{string-join(text(), "|")}</a>', '<a> <x> : </x> <b> test  </b>  <x> ; </x>  </a>', '_result=')
,('3f', '<a>{string-join(text(), "|")}</a>', '<a> <x> : </x> <b> test  </b>  <x> ; </x>  </a>', '_result=')
,('0t', '<a>{string-join(text(), "|")}</a>', '<a> <x> : </x> <b> test  </b>  <x> ; </x>  </a>', '_result=')
,('1t', '<a>{string-join(text(), "|")}</a>', '<a> <x> : </x> <b> test  </b>  <x> ; </x>  </a>', '_result=')
,('2t', '<a>{string-join(text(), "|")}</a>', '<a> <x> : </x> <b> test  </b>  <x> ; </x>  </a>', '_result=')
,('3t', '<a>{string-join(text(), "|")}</a>', '<a> <x> : </x> <b> test  </b>  <x> ; </x>  </a>', '_result=')
);


var i:longint;
    extParser:THtmlTemplateParser;
    sl:TStringList;
  procedure checklog(s:string);
  var j: Integer;
    errormsg: String;
  begin
      sl.Text:=s;
      //check lines to avoid line ending trouble with win/linux
      if extParser.variableChangeLog.Count<>sl.Count then begin
        raise Exception.Create('Test failed (length): '+inttostr(i)+': ' +' got: "'+extParser.variableChangeLog.debugTextRepresentation+'" expected: "'+s+'"');
      end;
      for j:=0 to sl.count-1 do
        if (extParser.variableChangeLog.getName(j)<>sl.Names[j]) or
           ((extParser.variableChangeLog.get(j).toString)<>StringReplace(StringReplace(sl.ValueFromIndex[j], '[[#13]]', #13, [rfReplaceAll]), '[[#10]]', #10, [rfReplaceAll])  )     then begin
             errormsg := 'Test failed: '+ inttostr(i)+': '{+data[i][1] }+ #13#10' got: "'+extParser.variableChangeLog.get(j).toString+'" (btw. "'+extParser.variableChangeLog.debugTextRepresentation+'") expected: "'+s+'"';
             //errormsg:= StringReplace(errormsg, #13, '#13', [rfReplaceAll]);
             //errormsg:= StringReplace(errormsg, #10, '#10', [rfReplaceAll]);
             WriteLn(errormsg);
             raise ETemplateParseException.Create(errormsg);
           end;
  end;
var previoushtml: string;
  tempobj: TXQValueObject;
    procedure t(const template, html, expected: string);
    begin
      if html<>'' then previoushtml:=html;
      if template='' then exit;
      extParser.parseTemplate(template);
      extParser.parseHTML(previoushtml, 'unittest');
      checklog(expected);
    end;

    procedure f(const template, html: string);
    var
      ok: Boolean;
    begin
      if html<>'' then previoushtml:=html;
      if not testerrors then exit;
      extParser.parseTemplate(template);
      ok := false;
      try
        extParser.parseHTML(previoushtml, 'unittest');
      except
        on e: EHTMLParseMatchingException do ok := true;
      end;
      if not ok then raise Exception.Create('Negative test succeeded and therefore failed');
    end;

    procedure xstring(const inp,exp: string);
    begin
      if extParser.replaceEnclosedExpressions(inp) <> exp then raise Exception.Create('#0-Xstring test failed: got: '+extParser.replaceEnclosedExpressions(inp)+' expected ' + exp);
    end;

    procedure q(const template, expected: string; html: string = '');
    var
      query: IXQuery;
      got: String;
    begin
      query := extParser.QueryEngine.parseXQuery1(template);
      //if html <> '' then extParser.parseh;
      got := query.evaluate(extParser.HTMLTree).toString;
      if got <> expected then
        raise Exception.Create('Test failed got '+got+ ' expected '+expected);
    end;

   procedure cmp(a,b: string);
   begin
     if a <> b then raise Exception.Create('Test failed: '+a+' <> '+b);
   end;

begin
  extParser:=THtmlTemplateParser.create;
  extParser.QueryEngine.GlobalNamespaces.Add(TNamespace.create('uri:mynamespace', 'my'));
  sl:=TStringList.Create;
  for i:=low(data)to high(data) do
    t(data[i,1],data[i,2],data[i,3]);

  t('<a><b>{.}</b></a>', '<a><b>12</b><b>34</b><c>56</c></a>', '_result=12');
  t('<a><b>{.}</b>*</a>', '<a><b>12</b><b>34</b><c>56</c></a>', '_result=12'#10'_result=34');

  t('<a><b>{.}</b>{1,2}</a>', '<a><b>12</b><b>34</b><b>56</b><b>78</b><b>90</b></a>', '_result=12'#10'_result=34');
  t('<a><b>{.}</b>{1,3}</a>', '<a><b>12</b><b>34</b><b>56</b><b>78</b><b>90</b></a>', '_result=12'#10'_result=34'#10'_result=56');
  t('<a><b>{.}</b>{1,4}</a>', '<a><b>12</b><b>34</b><b>56</b><b>78</b><b>90</b></a>', '_result=12'#10'_result=34'#10'_result=56'#10'_result=78');
  t('<a><b>{.}</b>{3}</a>', '<a><b>12</b><b>34</b><b>56</b><b>78</b><b>90</b></a>', '_result=12'#10'_result=34'#10'_result=56');
  t('<a><b>{.}</b>{1}</a>', '<a><b>12</b><b>34</b><b>56</b><b>78</b><b>90</b></a>', '_result=12');
  t('<a><b>{.}</b>{0}</a>', '<a><b>12</b><b>34</b><b>56</b><b>78</b><b>90</b></a>', '');
  t('<a><b>{.}</b>{5}<c>{$d:=.}</c></a>', '<a><b>12</b><b>34</b><b>56</b><c>X</c><b>78</b><c>Y</c><b>90</b><c>Z</c></a>', '_result=12'#10'_result=34'#10'_result=56'#10'_result=78'#10'_result=90'#10'd=Z');
  t('<a><b>{.}</b>{4}<c>{$d:=.}</c></a>', '<a><b>12</b><b>34</b><b>56</b><c>X</c><b>78</b><c>Y</c><b>90</b><c>Z</c></a>', '_result=12'#10'_result=34'#10'_result=56'#10'_result=78'#10'd=Y');
  t('<a><b>{.}</b>{3}<c>{$d:=.}</c></a>', '<a><b>12</b><b>34</b><b>56</b><c>X</c><b>78</b><c>Y</c><b>90</b><c>Z</c></a>', '_result=12'#10'_result=34'#10'_result=56'#10'd=X');
  t('<a><b>{.}</b>{1}<c>{$d:=.}</c></a>', '<a><b>12</b><b>34</b><b>56</b><c>X</c><b>78</b><c>Y</c><b>90</b><c>Z</c></a>', '_result=12'#10'd=X');
  t('<a><b>{.}</b>{0}<c>{$d:=.}</c></a>', '<a><b>12</b><b>34</b><b>56</b><c>X</c><b>78</b><c>Y</c><b>90</b><c>Z</c></a>', 'd=X');

  t('<a><b>{$foobar}</b></a>', '<a><b>12</b><b>34</b><c>56</c></a>', 'foobar=12');
  t('<a><b>{$foobar}</b>*</a>', '<a><b>12</b><b>34</b><c>56</c></a>', 'foobar=12'#10'foobar=34');
  t('<a><b>{$foobar}</b><b>{$abc}</b><c>{$xyz}</c></a>', '<a><b>12</b><b>34</b><c>56</c></a>', 'foobar=12'#10'abc=34'#10'xyz=56');
  t('<a><b>{$foobar:={"a": "in"}}</b><b>{$foobar.xyz}</b><b>{res:=$foobar("xyz")}</b></a>', '<a><b>12</b><b>34</b><b></b></a>', 'foobar='#10'foobar='#10'res=34');

  t('<a x="{6+5}"/>', '<a x="7"/>', '_result=11');
  t('<a x="{.}"/>', '<a x="7"/>', '_result=7');
  t('<a x="{$abc := 6+5}"/>', '<a x="7"/>', 'abc=11');
  t('<a x="{$abc}"/>', '<a x="7"/>', 'abc=7');
  t('<r><a x="{../text()}"/></r>', '<r><a>1</a><a x>2</a></r>', '_result=2');
  t('<r><a x="{../text()}" y="{../text()}"/></r>', '<r><a>1</a><a x>2</a><a y>3</a><a x y>4</a><a x y>5</a></r>', '_result=4'#10'_result=4'#10);
  t('<r><a x="{../text()}" y="{../text()}"/></r>', '<r><a>1</a><a x>2</a><a y>3</a><a x="x" y>4</a><a x y="y">5</a></r>', '_result=4'#10'_result=4'#10);

  //testing optional flag on non-html elements
  t('<a><t:if t:optional="true"><b>{.}</b><c>{.}</c></t:if></a>', '<a><b>1</b><c>2</c></a>', '_result=1'#10'_result=2');
  t('<a><t:if t:optional="true"><b>{.}</b><c>{.}</c></t:if></a>', '<a><b>1</b></a>', '');
  t('<a><t:if t:optional="true"><b>{.}</b><c>{.}</c></t:if></a>', '<a><c>2</c></a>', '');
  t('<a><t:if t:optional="true"><b>{.}</b><c>{.}</c></t:if></a>', '<a></a>', '');

  f('<a><t:if><b>{.}</b><c>{.}</c></t:if></a>', '<a><c>2</c></a>');

  t('<a><t:if t:optional="true"><b>{.}</b><c>{.}</c></t:if><x>{$x}</x></a>', '<a><b>1</b><c>2</c><x>5</x></a>', '_result=1'#10'_result=2'#10'x=5');
  t('<a><t:if t:optional="true"><b>{.}</b><c>{.}</c></t:if><x>{$x}</x></a>', '<a><b>1</b><x>5</x></a>', 'x=5');
  t('<a><t:if t:optional="true"><b>{.}</b><c>{.}</c></t:if><x>{$x}</x></a>', '<a><c>2</c><x>5</x></a>', 'x=5');
  t('<a><t:if t:optional="true"><b>{.}</b><c>{.}</c></t:if><x>{$x}</x></a>', '<a><x>5</x></a>', 'x=5');

  t('<a><t:switch><x>{$x}</x><y>{$y}</y></t:switch></a>', '<a><x>5</x></a>', 'x=5');
  t('<a><t:switch><x>{$x}</x><y>{$y}</y></t:switch></a>', '<a><y>5</y></a>', 'y=5');
  f('<a><t:switch><x>{$x}</x><y>{$y}</y></t:switch></a>', '<a><z>5</z></a>');

  t('<a><t:switch><x>{$x}</x><y>{$y}</y></t:switch>?</a>', '<a><x>5</x></a>', 'x=5');
  t('<a><t:switch><x>{$x}</x><y>{$y}</y></t:switch>?</a>', '<a><y>5</y></a>', 'y=5');
  t('<a><t:switch><x>{$x}</x><y>{$y}</y></t:switch>?</a>', '<a><z>5</z></a>', '');

  t('<a>    <t:switch><x>A1A<t:s>a1:=.</t:s></x><x>A2A<t:s>a2:=.</t:s></x></t:switch>      <t:switch><x>B1B<t:s>b1:=.</t:s></x><x>B2B<t:s>b2:=.</t:s></x></t:switch>?  <t:switch><x>C1C<t:s>c1:=.</t:s></x><x>C2C<t:s>c2:=.</t:s></x></t:switch>  </a>', '<a><x>A1A</x><x>B1B</x><x>C2C</x></a>', 'a1=A1A'#10'b1=B1B'#10'c2=C2C');
  t('<a>    <t:switch><x>A1A<t:s>a1:=.</t:s></x><x>A2A<t:s>a2:=.</t:s></x></t:switch>      <t:switch><x>B1B<t:s>b1:=.</t:s></x><x>B2B<t:s>b2:=.</t:s></x></t:switch>?  <t:switch><x>C1C<t:s>c1:=.</t:s></x><x>C2C<t:s>c2:=.</t:s></x></t:switch>  </a>', '<a><x>A1A</x><x>B2B</x><x>C1C</x></a>', 'a1=A1A'#10'b2=B2B'#10'c1=C1C');
  t('<a>    <t:switch><x>A1A<t:s>a1:=.</t:s></x><x>A2A<t:s>a2:=.</t:s></x></t:switch>      <t:switch><x>B1B<t:s>b1:=.</t:s></x><x>B2B<t:s>b2:=.</t:s></x></t:switch>?  <t:switch><x>C1C<t:s>c1:=.</t:s></x><x>C2C<t:s>c2:=.</t:s></x></t:switch>  </a>', '<a><x>A2A</x><x>B2B</x><x>C2C</x></a>', 'a2=A2A'#10'b2=B2B'#10'c2=C2C');

  f('<a>    <t:switch><x>A1A<t:s>a1:=.</t:s></x><x>A2A<t:s>a2:=.</t:s></x></t:switch>      <t:switch><x>B1B<t:s>b1:=.</t:s></x><x>B2B<t:s>b2:=.</t:s></x></t:switch>?  <t:switch><x>C1C<t:s>c1:=.</t:s></x><x>C2C<t:s>c2:=.</t:s></x></t:switch>  </a>', '<a><x>B2B</x><x>C2C</x></a>');
  t('<a>    <t:switch><x>A1A<t:s>a1:=.</t:s></x><x>A2A<t:s>a2:=.</t:s></x></t:switch>      <t:switch><x>B1B<t:s>b1:=.</t:s></x><x>B2B<t:s>b2:=.</t:s></x></t:switch>?  <t:switch><x>C1C<t:s>c1:=.</t:s></x><x>C2C<t:s>c2:=.</t:s></x></t:switch>  </a>', '<a><x>A2A</x><x>C2C</x></a>', 'a2=A2A'#10'c2=C2C');
  f('<a>    <t:switch><x>A1A<t:s>a1:=.</t:s></x><x>A2A<t:s>a2:=.</t:s></x></t:switch>      <t:switch><x>B1B<t:s>b1:=.</t:s></x><x>B2B<t:s>b2:=.</t:s></x></t:switch>?  <t:switch><x>C1C<t:s>c1:=.</t:s></x><x>C2C<t:s>c2:=.</t:s></x></t:switch>  </a>', '<a><x>A2A</x><x>B2B</x></a>');

  t('<a><b t:ignore-self-test="true()">{.}</b></a>', '<a><c>foobar</c></a>', '_result=foobar');
  t('<a><b t:ignore-self-test="true()"><c>{.}</c></b></a>', '<a><c>foobar</c><b>1</b></a>', '_result=foobar');
  t('<a><t:if ignore-self-test="true()" test="false()"><b>{.}</b></t:if></a>', '<a><c>foobar</c><b>1</b></a>', '_result=1');
  t('<a><t:if test="false()"><b>{.}</b></t:if></a>', '<a><c>foobar</c><b>1</b></a>', '');

  t('<a><t:s>declare function testfunc(){''&amp;quot;''}; testfunc()</t:s></a>', '<a>t</a>', '_result=&quot;'); //xquery with xpath strings (&amp is replaced by xml not xquery parser)
  t('<a>{declare function testfunc(){"a"}; testfunc()}</a>', '<a>t</a>', '_result=a');
  //f('<a>{declare function testfunc2(){concat(testfunc(), "b")}; testfunc2()}</a>', '<a>t</a>'); fails as it should, but test harness does not test for EXQEvaluationException s

  //  t('<a><b>{.}</b>{3}</a>', '<a><b>12</b><b>34</b></a>', '_result=12'#10'_result=34');


  extParser.variableChangeLog.clear;
  tempobj := TXQValueObject.create();
  tempobj.setMutable('a', xqvalue('Hallo'));
  tempobj.setMutable('b', xqvalue(17));
  extParser.variableChangeLog.add('test', tempobj);
  cmp(extParser.variableChangeLog.get('test').getProperty('a').toString, 'Hallo');
  cmp(extParser.variableChangeLog.get('test').getProperty('b').toString, '17');
  cmp(extParser.VariableChangeLogCondensed.get('test').getProperty('a').toString, 'Hallo');
  cmp(extParser.VariableChangeLogCondensed.get('test').getProperty('b').toString, '17');

  extParser.parseTemplate('<a/>');
  extParser.parseHTML('<a/>');

  tempobj := TXQValueObject.create();
  tempobj.setMutable('a', xqvalue('Hallo2'));
  tempobj.setMutable('b', xqvalue(18));
  extParser.variableChangeLog.add('test', tempobj);
  cmp(extParser.variableChangeLog.get('test').getProperty('a').toString, 'Hallo2');
  cmp(extParser.variableChangeLog.get('test').getProperty('b').toString, '18');
  cmp(extParser.VariableChangeLogCondensed.get('test').getProperty('a').toString, 'Hallo2');
  cmp(extParser.VariableChangeLogCondensed.get('test').getProperty('b').toString, '18');

  //t('<a>{obj := object()}<b>{obj.b:=.}</b><c>{obj.c:=.}</c>{final := $obj.c}</a>', '<a><b>12</b><b>34</b><c>56</c></a>', 'obj='#10'obj.b=12'#10'obj.c=56'#10'final=56');

  for i:=low(whiteSpaceData) to high(whiteSpaceData) do begin
    extParser.trimTextNodes:=TTrimTextNodes(StrToInt(whiteSpaceData[i,0][1]));
    XQGlobalTrimNodes:=whiteSpaceData[i,0][2] <> 'f';
    t(whiteSpaceData[i,1],whiteSpaceData[i,2],whiteSpaceData[i,3]);
  end;
  XQGlobalTrimNodes:=true;

  //---special encoding tests---
  extParser.parseTemplate('<a><template:read source="text()" var="test"/></a>');
  //no coding change utf-8 -> utf-8
  extParser.outputEncoding:=eUTF8;
  extParser.parseHTML('<html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8" /><a>uu(bin:'#$C3#$84',ent:&Ouml;)uu</a></html>');
  if extParser.variableChangeLog.ValuesString['test']<>'uu(bin:'#$C3#$84',ent:'#$C3#$96')uu' then //ÄÖ
    raise Exception.create('ergebnis ungültig utf8->utf8');
  //no coding change latin1 -> latin1
  extParser.outputEncoding:=eWindows1252;
  extParser.parseHTML('<html><head><meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" /><a>ll(bin:'#$C4',ent:&Ouml;)ll</a></html>');
  if extParser.variableChangeLog.ValuesString['test']<>'ll(bin:'#$C4',ent:'#$D6')ll' then
    raise Exception.create('ergebnis ungültig latin1->latin1');
  //coding change latin1 -> utf-8
  extParser.outputEncoding:=eUTF8;
  extParser.parseHTML('<html><head><meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" /><a>lu(bin:'#$C4',ent:&Ouml;)lu</a></html>');
  if extParser.variableChangeLog.ValuesString['test']<>'lu(bin:'#$C3#$84',ent:'#$C3#$96')lu' then
    raise Exception.create('ergebnis ungültig latin1->utf8');
  //coding change utf8 -> latin1
  extParser.outputEncoding:=eWindows1252;
  extParser.parseHTML('<html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8" /><a>ul(bin:'#$C3#$84',ent:&Ouml;)ul</a></html>');
  if extParser.variableChangeLog.ValuesString['test']<>'ul(bin:'#$C4',ent:'#$D6')ul' then
    raise Exception.create('ergebnis ungültig utf8->latin1');

  extParser.parseHTML('<html><head><meta http-equiv="Content-Type" content="text/html; charset=" /><a>bin:'#$C4#$D6',ent:&Ouml;</a></html>');
  extParser.outputEncoding:=eUTF8;



  //---special keep variables test---
  i:=-2;
  //keep full
  extParser.variableChangeLog.Clear;
  extParser.KeepPreviousVariables:=kpvKeepInNewChangeLog;
  extParser.variableChangeLog.ValuesString['Hallo']:='diego';
  extParser.parseTemplate('<a><template:read source="text()" var="hello"/></a>');
  extParser.parseHTML('<a>maus</a>');
  if extParser.variableChangeLog.ValuesString['hello']<>'maus' then raise Exception.Create('invalid var');
  if extParser.variableChangeLog.ValuesString['Hallo']<>'diego' then raise Exception.Create('invalid var');
  if extParser.variables.ValuesString['hello']<>'maus' then raise Exception.Create('invalid var');
  if extParser.variables.ValuesString['Hallo']<>'diego' then raise Exception.Create('invalid var');
  checklog('Hallo=diego'#13'hello=maus');
  extParser.parseTemplate('<a><template:read source="text()" var="Hallo"/></a>');
  extParser.parseHTML('<a>maus</a>');
  if extParser.variableChangeLog.ValuesString['hello']<>'maus' then raise Exception.Create('invalid var');
  if extParser.variableChangeLog.ValuesString['Hallo']<>'maus' then raise Exception.Create('invalid var');
  if extParser.variables.ValuesString['Hallo']<>'maus' then raise Exception.Create('invalid var');
  if extParser.variables.ValuesString['Hallo']<>'maus' then raise Exception.Create('invalid var');
  checklog('Hallo=diego'#13'hello=maus'#13'Hallo=maus');
  extParser.parseTemplate('<a><template:read source="$Hallo" var="xy"/></a>');
  extParser.parseHTML('<a>xxxx</a>');
  checklog('Hallo=diego'#13'hello=maus'#13'Hallo=maus'#13'xy=maus');

  //keep values
  extParser.KeepPreviousVariables:=kpvKeepValues;
  extParser.parseTemplate('<a><template:read source="$Hallo" var="xyz"/></a>');
  extParser.parseHTML('<a>xxxx</a>');
  checklog('xyz=maus');
  if extParser.variables.ValuesString['xyz']<>'maus' then raise Exception.Create('invalid var');
  extParser.parseTemplate('<a><template:read source="$Hallo" var="abc"/></a>');
  extParser.parseHTML('<a>mxxxx</a>');
  checklog('abc=maus');
  if extParser.variables.ValuesString['abc']<>'maus' then raise Exception.Create('invalid var');
  extParser.parseTemplate('<a><template:read source="x" var="nodes"/><template:read source="string-join($nodes,'','')" var="joined"/><template:read source="type-of($nodes[1])" var="type"/></a>');
  extParser.parseHTML('<a>yyyy<x>A1</x><x>B2</x><x>C3</x><x>D4</x>xxxx</a>');
  checklog('nodes=A1'#13'joined=A1,B2,C3,D4'#13'type=node()');
  if extParser.variables.ValuesString['nodes']<>'A1' then raise Exception.Create('invalid var');
  if extParser.variables.ValuesString['joined']<>'A1,B2,C3,D4' then raise Exception.Create('invalid var');
  if extParser.variables.ValuesString['type']<>'node()' then raise Exception.Create('invalid var');
  extParser.parseTemplate('<a><template:read source="$nodes" var="oldnodes"/>'+
                             '<template:read source="$joined" var="oldjoined"/>'+
                             '<template:read source="string-join($nodes,'','')" var="newjoinedold"/>'+
                             '<template:read source="string-join($oldnodes,'','')" var="newjoinednew"/>'+
                             '<template:read source="type-of($nodes[1])" var="newtype"/>'+
                             '</a>');
  extParser.parseHTML('<a>yyyy<x>A1</x><x>B2</x><x>C3</x><x>D4</x>xxxx</a>');
  checklog('oldnodes=A1'#13'oldjoined=A1,B2,C3,D4'#13'newjoinedold=A1,B2,C3,D4'#13'newjoinednew=A1,B2,C3,D4'#13'newtype=string'); //test node to string reduction
  if extParser.variables.ValuesString['oldnodes']<>'A1' then raise Exception.Create('invalid var');
  if extParser.variables.ValuesString['newjoinedold']<>'A1,B2,C3,D4' then raise Exception.Create('invalid var');
  if extParser.variables.ValuesString['newjoinednew']<>'A1,B2,C3,D4' then raise Exception.Create('invalid var');
  if extParser.variables.ValuesString['newtype']<>'string' then raise Exception.Create('invalid var');

  extParser.parseTemplate('<a>{obj := {"a": .} }</a>');
  extParser.parseHTML('<a>1x</a>');
  cmp(extParser.variables.Values['obj'].debugAsStringWithTypeAnnotation(), 'object: {a: node(): 1x}');
  cmp(extParser.VariableChangeLogCondensed.Values['obj'].debugAsStringWithTypeAnnotation(), 'object: {a: node(): 1x}');
  extParser.parseTemplate('<a>{$obj.b := .}</a>');
  extParser.parseHTML('<a>2y</a>');
  cmp(extParser.variables.Values['obj'].debugAsStringWithTypeAnnotation(), 'object: {a: node(): 1x, b: node(): 2y}');
  cmp(extParser.VariableChangeLogCondensed.Values['obj'].debugAsStringWithTypeAnnotation(), 'object: {a: node(): 1x, b: node(): 2y}');
  extParser.parseTemplate('<a>{$obj.c := concat($obj.b, .)}</a>');
  extParser.parseHTML('<a>3z</a>');
  cmp(extParser.variables.Values['obj'].debugAsStringWithTypeAnnotation(), 'object: {a: node(): 1x, b: node(): 2y, c: string: 2y3z}');
  cmp(extParser.VariableChangeLogCondensed.Values['obj'].debugAsStringWithTypeAnnotation(), 'object: {a: node(): 1x, b: node(): 2y, c: string: 2y3z}');



  //test, if the testing here works
  q('1+2', '3');
  q('"abc"', 'abc');
  q('outer-xml(<a>b</a>)', '<a>b</a>');

  q('match(<a>{{.}}</a>, <r><a>123</a></r>)', '123');
  q('match(<a>{{.}}</a>, <a>123456</a>)', '123456');
  q('string-join(match(<a>{{.}}</a>, (<a>1</a>, <a>2</a>)), " ")', '1 2');
  q('string-join(match(<a>{{.}}</a>, (<a>1</a>, <a>2</a>, <a>3</a>, <a>4</a>)), " ")', '1 2 3 4');
  q('sum(match(<a>{{.}}</a>, (<a>1</a>, <a>2</a>, <a>3</a>, <a>4</a>)))', '10');
  q('string-join(match(<a>{{.}}</a>,  <r><a>1</a><a>2</a><a>3</a></r>), " ")', '1');
  q('string-join(match(<a>*{{.}}</a>,  <r><a>1</a><a>2</a><a>3</a></r>), " ")', '1 2 3');
  q('string-join(match(<a>*{{.}}</a>,  (<r><a>1</a><a>2</a><a>3</a></r>, <r><a>4</a><a>5</a><a>6</a></r>)), " ")', '1 2 3 4 5 6');
  q('string-join(match(<a>{{.}}</a>, (<r><a>1</a><a>2</a><a>3</a></r>, <r><a>4</a><a>5</a><a>6</a></r>)), " ")', '1 4');
  q('string-join(match(<r>{{.}}</r>, (<r><a>1</a><a>2</a><a>3</a></r>, <r><a>4</a><a>5</a><a>6</a></r>) ), " ")', '123 456');
  q('string-join(match((<a>{{.}}</a>, <r>{{.}}</r>), (<r><a>1</a><a>2</a><a>3</a></r>, <r><a>4</a><a>5</a><a>6</a></r>) ), " ")', '1 4 123 456');
  q('string-join(match((<a>{{.}}</a>, <a>{{.}}</a>), (<r><a>1</a><a>2</a><a>3</a></r>, <r><a>4</a><a>5</a><a>6</a></r>) ), " ")', '1 4 1 4');
  q('string-join(match(("<a>{.}</a>", "<a>{.}</a>"), (<r><a>1</a><a>2</a><a>3</a></r>, <r><a>4</a><a>5</a><a>6</a></r>) ), " ")', '1 4 1 4');

  q('string-join(match(<t:loop><a>{{.}}</a></t:loop>,  <r><a>1</a><a>2</a><a>3</a></r>), " ")', '1 2 3');
  q('string-join(match(<template:loop><a>{{.}}</a></template:loop>,  <r><a>1</a><a>2</a><a>3</a></r>), " ")', '1 2 3');
  q('string-join(match("<a>{.}</a>*",  <r><a>1</a><a>2</a><a>3</a></r>), " ")', '1 2 3');
  q('string-join(match("<t:loop><a>{.}</a></t:loop>",  <r><a>1</a><a>2</a><a>3</a></r>), " ")', '1 2 3');
  q('string-join(match("<template:loop><a>{.}</a></template:loop>",  <r><a>1</a><a>2</a><a>3</a></r>), " ")', '1 2 3');

  q('match(<a>{{$var}}</a>, <r><a>123</a></r>)', '');
  q('match(<a>{{$var}}</a>, <r><a>123</a></r>).var', '123');
  q('match(<r><a>{{$var}}</a><b>{{$var2}}</b></r>, <r><a>123</a><b>456</b></r>).var', '123');
  q('match(<r><a>{{$var}}</a><b>{{$var2}}</b></r>, <r><a>123</a><b>456</b></r>).var2', '456');
  q('match(<r><a>{{$var}}</a><b>{{$var2}}</b><b>{{$var3}}</b></r>, <r><a>123</a><b>456</b><b>789</b></r>).var', '123');
  q('match(<r><a>{{$var}}</a><b>{{$var2}}</b><b>{{$var3}}</b></r>, <r><a>123</a><b>456</b><b>789</b></r>).var2', '456');
  q('match(<r><a>{{$var}}</a><b>{{$var2}}</b><b>{{$var3}}</b></r>, <r><a>123</a><b>456</b><b>789</b></r>).var3', '789');
  q('string-join(match(<a>*{{$res := .}}</a>, <r><a>1</a><a>2</a><a>3</a></r>).res, " ")', '1 2 3');
  q('string-join(match(<a>{{$res := .}}</a>, <r><a>1</a><a>2</a><a>3</a></r>).res, " ")', '1');
  q('string-join(match(<r><a>{{$res := .}}</a>*<b>{{$foo := .}}</b></r>, <r><a>1</a><a>2</a><a>3</a><b>H</b></r>).res, " ")', '1 2 3');
  q('string-join(match(<r><a>{{$res := .}}</a>*<b>{{$foo := .}}</b></r>, <r><a>1</a><a>2</a><a>3</a><b>H</b></r>).foo, " ")', 'H');
  q('string-join(match(<r><a>{{$res := .}}</a>*<b>{{.}}</b></r>, <r><a>1</a><a>2</a><a>3</a><b>H</b></r>).res, " ")', '1 2 3');
  q('string-join(match(<r><a>{{$res := .}}</a>*<b>{{.}}</b></r>, <r><a>1</a><a>2</a><a>3</a><b>H</b></r>)._result, " ")', 'H');

  q('string-join(for $i in match(<a>{{.}}</a>, (<a>x</a>, <a>y</a>, <a>z</a>)) return $i, " ")', 'x y z');
  q('string-join(for $i in match(<a>{{$t := .}}</a>, (<a>x</a>, <a>y</a>, <a>z</a>)) return $i.t, " ")', 'x y z');

  q('count(match(<r><a>{{obj := object(), obj.name := text(), obj.url := @href}}</a>*</r>, <r><a href="x">1</a><a href="y">2</a><a href="z">3</a></r>).obj)', '3');
  q('string-join(for $i in match(<r><a>{{obj := object(), obj.name := text(), obj.url := @href}}</a>*</r>, <r><a href="x">1</a><a href="y">2</a><a href="z">3</a></r>).obj return concat($i.name, ":",$i.url), " ")', '1:x 2:y 3:z');
  q('declare function x(){0}; for $link in match(<a/>, <a/>) return $link', '');
  q('declare function x(){17}; match(<a id="{x()}">{{.}}</a>, <r><a id="1">A</a><a id="17">B</a><a id="30">C</a></r>)', 'B');
  q('declare function x(){17}; match(<a id="{x()}">{{concat(., x())}}</a>, <r><a id="1">A</a><a id="17">B</a><a id="30">C</a></r>)', 'B17');
  q('declare function x($arg){concat(17, $arg)}; match(<a id="{x("")}">{{x(.)}}</a>, <r><a id="1">A</a><a id="17">B</a><a id="30">C</a></r>)', '17B');
  q('declare variable $v := 1000; declare function x($arg){concat(17, $arg)}; match(<a id="{x("")}">{{concat(x(.), $v)}}</a>, <r><a id="1">A</a><a id="17">B</a><a id="30">C</a></r>)', '17B1000');

  t('<r>{xquery version "1.0"; declare variable $abc := 123; ()}<b>{$def := $abc}</b></r>', '<r><b>XXX</b></r>', '_result='#10'def=123');
  t('<r>{xquery version "1.0"; declare variable $abc := 123; ()}<b>{$def := concat(., $abc, .)}</b></r>', '<r><b>XXX</b></r>', '_result='#10'def=XXX123XXX');
  t('<r>{xquery version "1.0"; declare function doub($x) { 2 * $x }; ()}<b>{$def := doub(.)}</b></r>', '<r><b>100</b></r>', '_result='#10'def=200');
  t('<r>{xquery version "1.0"; declare function doub($x) { 2 * $x }; ()}<b>{$def := doub(.)}</b></r>', '<r><b>100</b></r>', '_result='#10'def=200');
  t('<r>{xquery version "1.0"; declare function add($x, $y) { $x + $y }; ()}<b>{$def := add(123, .)}</b></r>', '<r><b>100</b></r>', '_result='#10'def=223');
  t('<r>{xquery version "1.0"; declare function add($x, $y) { $x + $y }; ()}<b/>'+
       '{xquery version "1.0"; declare variable $v1 := 17; ()}<b/>'+
       '{xquery version "1.0"; declare function triple($x) {$x * 3}; ()}<b>{$def := add(triple(.), $v1)}</b></r>', '<r><b/><b/><b>100</b></r>',
    '_result='#10'_result='#10'_result='#10'def=317');

  t('<r><a>{text()}</a></r>', '<r><a>1</a><a>2</a></r>', '_result=1');
  t('<r><a>{following-sibling::a/text()}</a></r>', '<r><a>1</a><a>2</a><a>3</a></r>', '_result=2');
  t('<r><a>{following-sibling::a/(text())}</a></r>', '<r><a>1</a><a>2</a><a>3</a></r>', '_result=2');
  t('<r><a>{following-sibling::a/concat("-",text(),"-")}</a></r>', '<r><a>1</a><a>2</a><a>3</a></r>', '_result=-2-');

  t( '<r><a>{$t}</a>*</r>', '<r><a>1</a><a>2</a><a>3</a><a>4</a></r>', 't=1'#10't=2'#10't=3'#10't=4');
  t( '<r><a><t:read var="u" source="."/></a>*</r>', '<r><a>1</a><a>2</a><a>3</a><a>4</a></r>', 'u=1'#10'u=2'#10'u=3'#10'u=4');
  t( '<r><a><t:read var="u{.}" source="."/></a>*</r>', '<r><a>1</a><a>2</a><a>3</a><a>4</a></r>', 'u1=1'#10'u2=2'#10'u3=3'#10'u4=4');


  xstring('hallo"''"''world', 'hallo"''"''world');
  xstring('foo{1+2}bar', 'foo3bar');
  xstring('foo{1+2}{1+3}bar', 'foo34bar');
  xstring('foo{1+2}"''{1+3}bar', 'foo3"''4bar');
  xstring('foo{{1+2}}{{1+3}}bar', 'foo{1+2}{1+3}bar');
  xstring('{1+2}', '3');
  xstring('{1+2}"', '3"');
  xstring('"{1+2}', '"3');
  xstring('{1+2}{3+4}', '37');
  xstring('{1+2}{3+4}"', '37"');
  xstring('"{1+2}{3+4}', '"37');

  xstring('{{1+2}}', '{1+2}');
  xstring('{{1+2}}"', '{1+2}"');
  xstring('"{{1+2}}', '"{1+2}');
  xstring('{{1+2}}{3+4}', '{1+2}7');
  xstring('{{1+2}}{3+4}"', '{1+2}7"');
  xstring('"{{1+2}}{3+4}', '"{1+2}7');


  extParser.free;
  sl.Free;
end;




end.

