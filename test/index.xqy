xquery version "1.0-ml" ;

declare variable $parser-tests :=
  <tests>
    <test name="Variables" type="etag">
      <template>{'Hello {{word}}!'}</template>
      <hash>{'{"word": "world"}'}</hash>
      <output><div>Hello world!</div></output>
      <parseTree>
        <multi>
          <static>Hello </static>
          <etag name="word"/>
          <static>!</static>
        </multi>
      </parseTree>
    </test>
    <test name="Two mustaches With No Whitespace" type="whitespace">
      <template>{'{{word}}{{word}}!'}</template>
      <hash>{'{"word": "la"}'}</hash>
      <output><div>lala!</div></output>
      <parseTree>
        <multi>
          <etag name="word"/> 
          <etag name="word"/> 
          <static>!</static>
        </multi>
      </parseTree>
    </test>
    <test name="Variables with embedded XQuery" section="etag">
      <template>{'x=4+5*2={{x}}'}</template>
      <hash>{'{ "x": ( xs:integer(4) + 5 ) * 2 }'}</hash>
      <output><div>x=4+5*2=18</div></output>
      <parseTree>
        <multi> 
          <static>x=4+5*2=</static> 
          <etag name="x"/> 
        </multi>
      </parseTree>
    </test>
    <test name="Escaped Variables with {'{{{var}}}'}" type="utag">
      <template>{'* {{name}}
      * {{age}}
      * {{company}}
      * {{{company}}}'}</template>
      <hash>{'{
        "name": "Chris",
        "company": "<b>GitHub</b>"
      }'}</hash>
      <output>
        <div>
          * Chris 
          *
          * &lt;b&gt;GitHub&lt;/b&gt;
          * <b>GitHub</b>
        </div>
      </output>
      <parseTree>
        <multi> 
          <static>* </static> 
          <etag name="name"/> 
          <static>* </static> 
          <etag name="age"/> 
          <static>* </static> 
          <etag name="company"/> 
          <static>* </static> 
          <utag name="company"/> 
        </multi>
      </parseTree>
    </test>
    <test name="Simple Escaped Variables with {{&amp;var}}" section="utag">
      <template>{'{{&amp; name}}'}</template>
      <hash>{'{"name":"<b>Pete Aven</b>"}'}</hash>
      <output><div><b>Pete Aven</b></div></output>
      <parseTree>
        <multi> 
          <utag name="name"/> 
        </multi>
      </parseTree>
    </test>
    <test name="Escaped Variables with {{&amp;var}}" type="utag">
      <template>{'* {{name}}
      * {{age}}
      * {{company}}
      * {{&amp;company}}'}</template>
      <hash>{'{
        "name": "Chris",
        "company": "<b>GitHub</b>"
      }'}</hash>
      <output>
        <div>
          * Chris 
          *
          * &lt;b&gt;GitHub&lt;/b&gt;
          * <b>GitHub</b>
        </div>
      </output>
      <parseTree>
        <multi> 
          <static>* </static> 
          <etag name="name"/> 
          <static>* </static> 
          <etag name="age"/> 
          <static>* </static> 
          <etag name="company"/> 
          <static>* </static> 
          <utag name="company"/> 
        </multi>
      </parseTree>
    </test>
    <test name="Missing Sections" type="section">
      <template>{'Shown.
      {{#nothin}}
        Never shown!
      {{/nothin}}'}</template>
      <hash>{'{
        "person": true
      }'}</hash>
      <output><div>Shown.</div></output>
      <parseTree>
        <multi> 
          <static>Shown.</static> 
          <section name="nothin"> 
            <static>Never shown!</static> 
          </section> 
        </multi>
      </parseTree>
    </test>
    <test name="True Sections" type="section">
      <template>{'Shown.
      {{#nothin}}
        Also shown!
      {{/nothin}}'}</template>
      <hash>{'{
        "nothin": true
      }'}</hash>
      <output><div>Shown. Also shown!</div></output>
      <parseTree>
        <multi> 
          <static>Shown.</static> 
          <section name="nothin"> 
            <static>Also shown!</static> 
          </section> 
        </multi>
      </parseTree>
    </test>
    <test name="False Sections" type="section">
      <template>{'Shown.
      {{#nothin}}
        Never shown!
      {{/nothin}}'}</template>
      <hash>{'{
        "nothin": false
      }'}</hash>
      <output><div>Shown.</div></output>
      <parseTree>
        <multi> 
          <static>Shown.</static> 
          <section name="nothin"> 
            <static>Never shown!</static> 
          </section> 
        </multi>
      </parseTree>
    </test>
    <test name="Empty Lists Sections" type="section">
      <template>{'Shown.
      {{#nothin}}
        Never shown!
      {{/nothin}}'}</template>
      <hash>{'{
        "nothin": []
      }'}</hash>
      <output><div>Shown.</div></output>
      <parseTree>
        <multi> 
          <static>Shown.</static> 
          <section name="nothin"> 
            <static>Never shown!</static> 
          </section> 
        </multi>
      </parseTree>
    </test>
    <test name="Non-empty Lists Sections" type="section">
      <template>{'{{#repo}}
      <b>{{name}}</b>
    {{/repo}}'}</template>
      <hash>{'{
        "repo": [
          { "name": "resque" },
          { "name": "hub" },
          { "name": "rip" }
        ]
      }'}</hash>
      <output><div><b>resque</b>
      <b>hub</b>
      <b>rip</b></div></output>
      <parseTree>
        <multi> 
          <section name="repo"> 
            <static>&lt;b&gt;</static> 
            <etag name="name"/> 
            <static>&lt;/b&gt;</static> 
          </section> 
        </multi>
      </parseTree>
    </test>
    <test name="Missing Inverted Sections" type="inverted-section">
      <template>{'Shown.
      {{^nothin}}
        Also shown!
      {{/nothin}}'}</template>
      <hash>{'{
        "person": true
      }'}</hash>
      <output><div>Shown. Also shown!</div></output>
      <parseTree>
        <multi> 
          <static>Shown.</static> 
          <inverted-section name="nothin"> 
            <static>Also shown!</static> 
          </inverted-section> 
        </multi>
      </parseTree>
    </test>
    <test name="True Inverted Sections" type="inverted-section">
      <template>{'Shown.
      {{^nothin}}
        Not shown!
      {{/nothin}}'}</template>
      <hash>{'{
        "nothin": true
      }'}</hash>
      <output><div>Shown.</div></output>
      <parseTree>
        <multi> 
          <static>Shown.</static> 
          <inverted-section name="nothin"> 
            <static>Not shown!</static> 
          </inverted-section> 
        </multi>
      </parseTree>
    </test>
    <test name="False Inverted Sections" type="inverted-section">
      <template>{'Shown.
      {{^nothin}}
        Also shown!
      {{/nothin}}'}</template>
      <hash>{'{
        "nothin": false
      }'}</hash>
      <output><div>Shown. Also shown!</div></output>
      <parseTree>
        <multi> 
          <static>Shown.</static> 
          <inverted-section name="nothin"> 
            <static>Also shown!</static> 
          </inverted-section> 
        </multi>
      </parseTree>
    </test>
    <test name="Empty Lists Inverted Sections" type="inverted-section">
      <template>{'Shown.
      {{^nothin}}
        Also shown!
      {{/nothin}}'}</template>
      <hash>{'{
        "nothin": []
      }'}</hash>
      <output><div>Shown. Also shown!</div></output>
      <parseTree>
        <multi> 
          <static>Shown.</static> 
          <inverted-section name="nothin"> 
            <static>Also shown!</static> 
          </inverted-section> 
        </multi>
      </parseTree>
    </test>
    <test name="Non-empty Lists Inverted Sections" type="inverted-section">
      <template>{'Testing {{^repo}}
      <b>{{name}}</b>
    {{/repo}}'}</template>
      <hash>{'{
        "repo": [
          { "name": "resque" },
          { "name": "hub" },
          { "name": "rip" }
        ]
      }'}</hash>
      <output><div>Testing</div></output>
      <parseTree>
        <multi> 
          <static>Testing</static> 
          <inverted-section name="repo"> 
            <static>&lt;b&gt;</static> 
            <etag name="name"/> 
            <static>&lt;/b&gt;</static> 
          </inverted-section> 
        </multi>
      </parseTree>
    </test>
    <test name="Comments"  type="comment">
      <template>{'<h1>Today{{! ignore me }}.</h1>'}</template>
      <hash>{'{}'}</hash>
      <output><div><h1>Today.</h1></div></output>
      <parseTree>
        <multi> 
          <static>&lt;h1&gt;Today</static> 
          <comment>ignore me</comment> 
          <static>.&lt;/h1&gt;</static> 
        </multi>
      </parseTree>
    </test>
    <test name="After Taxes" section="complex">
      <template>{'Hello {{name}}! You have just won ${{value}}! 
      {{#in_ca}} Well, 
        ${{taxed_value}}, after taxes.
      {{/in_ca}}'}</template>
      <hash>{'{
        "name": "Chris",
        "value": 10000,
        "taxed_value": 10000 - (10000 * 0.4),
        "in_ca": true }'}</hash>
      <output><div>Hello Chris! You have just won $10000! Well, $6000, after taxes.</div></output>
      <parseTree>
        <multi>
          <static>Hello </static>
          <etag name="name"/>
          <static>! You have just won $</static>
          <etag name="value"/>
          <static>!</static>
          <section name="in_ca">
            <static>Well, $</static>
            <etag name="taxed_value"/>
            <static>, after taxes.</static>
          </section>
        </multi>
      </parseTree>
    </test>
    <test name="No Repos Inverted Sections" section="inverted-section">
      <template>{'{{#repo}}
        <b>{{name}}</b>
      {{/repo}}
      {{^repo}}
        No repos :(
      {{/repo}}'}</template>
      <hash>{'{
        "repo": []
      }'}</hash>
      <output><div>No repos :(</div></output>
      <parseTree>
        <multi> 
          <section name="repo"> 
            <static>&lt;b&gt;</static> 
            <etag name="name"/> 
            <static>&lt;/b&gt;</static> 
          </section> 
          <static/> 
          <inverted-section name="repo"> 
            <static>No repos :(</static> 
          </inverted-section> 
        </multi>
      </parseTree>
    </test>
    <test name="Simple Whitespace" section="whitespace">
      <template>{'{{tag}} foo'}</template>
      <hash>{'{ "tag": "yo" }'}</hash>
      <output><div>yo foo</div></output>
      <parseTree>
        <multi>
          <etag name="tag"/>
          <static>foo</static>
        </multi>
      </parseTree>
    </test>
    <test name="Nested Sections" section="complex">
      <template>{'{{#foo}}
        {{#a}}
          {{b}}
        {{/a}}
      {{/foo}}'}</template>
      <hash>{'{ foo: [
        {a: {b: 1}},
        {a: {b: 2}},
        {a: {b: 3}}
      ] }'}</hash>
      <output><div>1 2 3</div></output>
      <parseTree>
        <multi>
          <section name="foo">
            <static/>
            <section name="a">
              <etag name="b"/>
            </section>
            <static/>
          </section>
       </multi>
      </parseTree>
    </test>
    <test name="Book with lots of nested Sections" section="complex">
      <template>{
        '{{#book}}
           {{#section}}
             {{#section}}
               {{#section}}
                 {{p}}
               {{/section}}
             {{/section}}
          {{/section}}
        {{/book}}'}</template>
      <hash>{'
        {"book": {"section": {"section": {"section": {"p": "Alive!"}}}}}'}</hash>
      <output><div>Alive!</div></output>
      <parseTree>
        <multi>
          <section name="book">
            <static/>
            <section name="section">
              <static/>
              <section name="section">
                <static/>
                <section name="section">
                  <etag name="p"/>
                </section>
                <static/>
              </section>
              <static/>
            </section>
            <static/>
          </section>
        </multi>
      </parseTree>
    </test>
    <test name="Colors Sample (Nested Sections)" section="complex">
      <template>{'<h1>{{header}}</h1>
      {{#bug}}
      {{/bug}}

      {{#items}}
        {{#first}}
          <li><strong>{{name}}</strong></li>
        {{/first}}
        {{#link}}
          <li><a href="{{url}}">{{name}}</a></li>
        {{/link}}
      {{/items}}

      {{#empty}}
        <p>The list is empty.</p>
      {{/empty}}
      '}</template>
      <hash>{'{
        "header": "Colors",
        "items": [
            {"name": "red", "first": true, "url": "#Red"},
            {"name": "green", "link": true, "url": "#Green"},
            {"name": "blue", "link": true, "url": "#Blue"}
        ],
        "empty": false
      }'}</hash>
      <output><div><h1>Colors</h1>
      <li><strong>red</strong></li>
      <li><a href="#Green">green</a></li>
      <li><a href="#Blue">blue</a></li></div></output>
      <parseTree>
        <multi> 
          <static>&lt;h1&gt;</static> 
          <etag name="header"/> 
          <static>&lt;/h1&gt;</static> 
          <section name="bug"> 
            <static/> 
          </section> 
          <static/> 
          <section name="items"> 
            <static/> 
            <section name="first"> 
              <static>&lt;li&gt;&lt;strong&gt;</static> 
              <etag name="name"/> 
              <static>&lt;/strong&gt;&lt;/li&gt;</static> 
            </section> 
            <static/> 
            <section name="link"> 
              <static>&lt;li&gt;&lt;a href=&quot;</static> 
              <etag name="url"/> 
              <static>&quot;&gt;</static>
              <etag name="name"/> 
              <static>&lt;/a&gt;&lt;/li&gt;</static> 
            </section> 
            <static/> 
          </section> 
          <static/> 
          <section name="empty"> 
            <static>&lt;p&gt;The list is empty.&lt;/p&gt;</static> 
          </section> 
          <static/> 
        </multi>
      </parseTree>
    </test>
    <test name="Apos" section="complex">
      <template>{'{{apos}}{{control}}'}</template>
      <hash>{'{"apos": "&#39;", "control":"X")}'}</hash>
      <output><div>&#39;X</div></output>
      <parseTree>
        <multi> 
          <etag name="apos"/> 
          <etag name="control"/> 
        </multi>
      </parseTree>
    </test>
    <test name="Sequencial Mustaches" section="complex">
      <template>{'I like going to the {{location}} because I find it {{verb}}'}</template>
      <hash>{'{"location": "mall", "verb": "fun"}'}</hash>
      <output><div>I like going to the mall because I find it fun</div></output>
      <parseTree>
        <multi> 
          <static>I like going to the</static> 
          <etag name="location"/> 
          <static>because I find it</static> 
          <etag name="verb"/> 
        </multi>
      </parseTree>
    </test>
    <test name="Not Found" section="complex">
      <template>{'{{foo}}'}</template>
      <hash>{'{ "bar": "yo" }'}</hash>
      <output><div/></output>
      <parseTree>
        <multi>
          <etag name="foo"/>
        </multi>
      </parseTree>
    </test>
    <test name="Nil" type="complex">
      <template>{'Hello {{name}}
      glytch {{glytch}}
      binary {{binary}}
      value {{value}}
      numeric {{numeric}}'}</template>
      <hash>{'{
        name: "Elise",
        glytch: true,
        binary: false,
        value: null,
        numeric: NaN}'}</hash>
      <output>{'Hello Elise
      glytch true
      binary false
      value
      numeric NaN'}</output>
      <parseTree>
        <multi>
          <static>Hello</static>
          <etag name="name"/>
          <static>glytch</static>
          <etag name="glytch"/>
          <static>binary</static>
          <etag name="binary"/>
          <static>value</static>
          <etag name="value"/>
          <static>numeric</static>
          <etag name="numeric"/>
        </multi>
      </parseTree>
    </test>
    
    <test name="Parser Non-False Values" section="parser">
      <template>{'{{#person?}}
        Hi {{name}}!
      {{/person?}}'}</template>
      <parseTree>
        <multi> 
          <section name="person?"> 
            <static>Hi</static> 
            <etag name="name"/> 
            <static>!</static> 
          </section> 
        </multi>
      </parseTree>
    </test>
    <test name="Parser Simple Partial &gt;" section="parser">
      <template>{'Hello {{> world}}'}</template>
      <parseTree>
        <multi> 
          <static>Hello</static> 
          <partial name="world"/> 
        </multi>
      </parseTree>
    </test>
    <test name="Parser Simple Partial &lt;"  section="parser">
      <template>{'Hello {{< world}}'}</template>
      <parseTree>
        <multi> 
          <static>Hello</static> 
          <partial name="world"/> 
        </multi>
      </parseTree>
    </test>
    <test name="Parser Simple Comment" section="parser">
      <template>{'Hello World
        {{! author }}
        Nuno'}</template>
      <parseTree>
        <multi> 
          <static>Hello World</static> 
          <comment>author</comment> 
          <static>Nuno</static> 
        </multi>
      </parseTree>
    </test>
    <test name="Parser Triple Mustache" section="parser">
      <template>{'{{{world}}}'}</template>
      <parseTree>
        <multi>
          <utag name="world"/>
        </multi>
      </parseTree>
    </test>
    <test name="Parser Simple Lambda" section="parser">
      <template>{'{{#wrapped}}
        {{name}} is awesome.
      {{/wrapped}}'}</template>
      <parseTree>
        <multi> 
          <section name="wrapped"> 
            <etag name="name"/> 
            <static>is awesome.</static> 
          </section> 
        </multi>
      </parseTree>
    </test>
    <test name="Parser Partial Test" section="parser">
      <template>{'{{> next_more}}'}</template>
      <parseTree>
        <multi> 
          <partial name="next_more"/> 
        </multi>
      </parseTree>
    </test>

<!--
        <test name="" section="">
          <template>{''}</template>
          <hash>{''}</hash>
          <output><div></div></output>
          <parseTree>
            <multi/>
          </parseTree>
        </test>
    -->
<!--


    
  
    <test name="Dot Notation">
      <template>{'{{person.name}}'}</template>
      <hash>{'{ "person": {
        "name": "Chris",
        "company": "<b>GitHub</b>"
      } }'}</hash>
      <output>{'Chris'}</output>
      <parseTree>
        <multi> 
          <section name="person">
            <etag name="name"/>
          </section> 
        </multi>
      </parseTree>
    </test>
    <test name="Dot Notation 2">
      <template>{'{{person.name.first}}'}</template>
      <hash>{'{ "person": {
        "name": {"first": "Chris"},
        "company": "<b>GitHub</b>"
      } }'}</hash>
      <output>{'Chris'}</output>
      <parseTree>
        <multi> 
          <section name="person">
            <section name="name">
              <etag name="first"/>
            </section>
          </section> 
        </multi>
      </parseTree>
    </test>
    <test name="Recursive Descendant 2">
      <template>{'* {{*name}}'}</template>
      <hash>{'{
          "people": {
              "person": {
                  "name": "Chris"
              },
              "name": "Jan" 
          } 
      }'}</hash>
      <output>{'* Chris Jan'}</output>
      <parseTree>
        <multi> 
          <static>*</static>
          <rtag name="name"/> 
        </multi>
      </parseTree>
    </test>
    <test name="Array of Strings">
      <template>{'{{#array_of_strings}}{{.}} {{/array_of_strings}}'}</template>
      <hash>{'{array_of_strings: ["hello", "world"]}'}</hash>
      <output>{'hello world'}</output>
      <parseTree>
        <multi>
          <section name="array_of_strings">
            <etag name="."/>
          </section>
        </multi>
      </parseTree>
    </test>

    <test name="Partial Recursion">
      <template>{'{{name}}
      {{#kids}}
      {{>partial}}
      {{/kids}}'}</template>
      <hash>{'{
        name: "1",
        kids: [ { 
          name: "1.1",
          children: [
          {name: "1.1.1"} ] } ] }'}</hash>
      <output>{'1
      1.1
      1.1.1'}</output>
      <parseTree>
        <multi>
          <etag name="name"/>
          <section name="kids">
            <partial name="partial"/>
          </section>
        </multi>
      </parseTree>
    </test>
    <test name="Recursion with same names">
      <template>{'{{ name }}
      {{ description }}

      {{#terms}}
        {{name}}
        {{index}}
      {{/terms}}'}</template>
      <hash>{'{
        name: "name",
        description: "desc",
        terms: [
          {name: "t1", index: 0},
          {name: "t2", index: 1} ] }'}</hash>
      <output>{'name
          desc
            t1
            0
            t2
            1'}</output>
      <parseTree>
        <multi>
          <etag name="name"/>
          <etag name="description"/>
          <section name="terms">
            <etag name="name"/>
            <etag name="index"/>
          </section>
        </multi>
      </parseTree>
    </test>
    <test name="Reuse of enumerables">
      <template>{'{{#terms}}
        {{name}}
        {{index}}
      {{/terms}}
      {{#terms}}
        {{name}}
        {{index}}
      {{/terms}}
      '}</template>
      <hash>{'{
        terms: [
          {name: "t1", index: 0},
          {name: "t2", index: 1},
        ]
      }'}</hash>
      <output>{'t1
      0
      t2
      1
      t1
      0
      t2
      1'}</output>
      <parseTree>
        <multi>
          <section name="terms">
            <etag name="name"/>
            <etag name="index"/>
            <etag name="/terms"/>
            <section name="terms"/>
            <etag name="#terms"/>
            <etag name="name"/>
            <etag name="index"/>
          </section>
        </multi>
      </parseTree>
    </test>
    <test name="Section as Context">
      <template>{'{{#a_object}}
        <h1>{{title}}</h1>
        <p>{{description}}</p>
        <ul>
          {{#a_list}}
          <li>{{label}}</li>
          {{/a_list}}
        </ul>
      {{/a_object}}'}</template>
      <hash>{'{
        a_object: {
          title: "this is an object",
          description: "one of its attributes is a list",
          a_list: [{label: "listitem1"}, {label: "listitem2"}]
        }'}</hash>
      <output>{'<h1>this is an object</h1>
        <p>one of its attributes is a list</p>
        <ul>
              <li>listitem1</li>
              <li>listitem2</li>
          </ul>'}</output>
      <parseTree>
        <multi>
          <section name="a_object">
            <static>&lt;h1&gt;</static>
            <etag name="title"/>
            <static>&lt;/h1&gt; &lt;p&gt;</static>
            <etag name="description"/>
            <static>&lt;/p&gt; &lt;ul&gt;</static>
            <section name="a_list">
              <static>&lt;li&gt;</static>
              <etag name="label"/>
              <static>&lt;/li&gt;</static>
            </section>
            <static>&lt;/ul&gt;</static>
          </section>
        </multi>
      </parseTree>
    </test>
    <test name="Template Partial">
      <template>{'<h1>{{title}}</h1>
      {{>partial}}'}</template>
      <hash>{'{
        title: function() {
          return "Welcome";
        },
        partial: {
          again: "Goodbye"
        }
      }'}</hash>
      <output>{'<h1>Welcome</h1>
      Again, Goodbye!'}</output>
      <parseTree>
        <multi>
          <static>&lt;h1&gt;</static>
          <etag name="title"/>
          <static>&lt;/h1&gt;</static>
          <partial name="partial"/>
        </multi>
      </parseTree>
    </test>
    <test name="Two in a row">
      <template>{'{{greeting}}, {{name}}!'}</template>
      <hash>{'{
        name: "Joe",
        greeting: "Welcome" }'}</hash>
      <output>{'Welcome,Joe!'}</output>
      <parseTree>
        <multi>
          <etag name="greeting"/>
          <static>,</static>
          <etag name="name"/>
          <static>!</static>
        </multi>
      </parseTree>
    </test>

    </test> -->
  </tests> ;
  
declare function local:parser-test( $template, $parseTree ) {
  xdmp:invoke( 'run-parser.xqy', ( xs:QName( 'template' ), $template, xs:QName( 'parseTree' ), $parseTree ) ) };

declare function local:compiler-test( $template, $hash, $output ) {
    xdmp:invoke( 'run-compiler.xqy', ( xs:QName( 'template' ), $template, xs:QName( 'hash' ), $hash,
      xs:QName( 'output' ), $output ) ) };

xdmp:set-response-content-type('application/xml'),
let $results := <tests> {
for $test at $i in $parser-tests/test
return try {
let $template       := $test/template/fn:string()
let $hash           := $test/hash/fn:string()
let $output         := $test/output/*
let $parseTree      := $test/parseTree/*
let $result         := local:parser-test( $template,$parseTree )
let $valid          := $result [1]
let $mTree          := $result [2]
let $compilerTest   := $hash and $output and $parseTree
let $compiled       := if($compilerTest) then local:compiler-test( $template, $hash, $output ) else ()
let $validCompiler  := $compiled [1]
let $outputCompiler := $compiled [2]
return <test position="{$i}" parseTest="{if($valid) then 'ok' else 'NOK'}">
         { if($compilerTest) then attribute compileTest {if($validCompiler) then 'ok' else 'NOK'} else () }
         { fn:string($test/@name)} 
         { if($valid) then ()
           else 
             <parseTestExplanation> 
               {xdmp:log((fn:concat($i, ' failed on >> parse: ')))}
               <p> Template: {$template} </p>
               <p> Expected: {$parseTree} </p>  
               <p> Got: {$mTree} </p>
             </parseTestExplanation>}
         { if ($compilerTest) 
           then if($validCompiler) then ()
           else 
              <compileTestExplanation> 
                {xdmp:log((fn:concat($i, ' failed on >> compile: ')))}
                <p> Template: {$template} </p>
                <p> Hash: {$hash} </p>
                <p> Expected: {$output} </p>
                <p> Got: {$outputCompiler} </p>
              </compileTestExplanation>
           else ()}
       </test> } catch ($e) { <test i="{$i}">{xdmp:log($e),fn:string($test/@name)} Failed with exception</test> }
} </tests>
let $parseTests       := fn:count($results/test/@parseTest)
let $compileTests     := fn:count($results/test/@compileTest)
let $okParseTests     := fn:count($results/test[@parseTest='ok'])
let $nokParseTests    := fn:count($results/test[@parseTest='NOK'])
let $okCompileTests   := fn:count($results/test[@compileTest='ok'])
let $nokCompileTests  := fn:count($results/test[@compileTest='NOK'])
return <summary total="{$parseTests+$compileTests}">
    <parseTests   pass="{$okParseTests}"   fail="{$nokParseTests}"   perc="{if($okParseTests=0) then '100' else 100 - fn:round(100 * $nokParseTests div $okParseTests)}"/>
    <compileTests pass="{$okCompileTests}" fail="{$nokCompileTests}" perc="{if($okCompileTests=0) then '100' else 100 - fn:round(100 * $nokCompileTests div $okCompileTests)}"/>
    {$results}
  </summary>