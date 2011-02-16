xquery version "1.0-ml" ;

declare variable $parser-tests :=
  <tests>
    <test name="Simple Mustache">
      <template>{'Hello {{world}}'}</template>
      <parseTree>
        <multi>
          <static>Hello </static>
          <etag name="world"/>
        </multi>
      </parseTree>
    </test>
    <test name="Simple Partial &gt;">
      <template>{'Hello {{> world}}'}</template>
      <parseTree>
        <multi> 
          <static>Hello</static> 
          <partial name="world"/> 
        </multi>
      </parseTree>
    </test>
    <test name="Simple Partial &lt;">
      <template>{'Hello {{< world}}'}</template>
      <parseTree>
        <multi> 
          <static>Hello</static> 
          <partial name="world"/> 
        </multi>
      </parseTree>
    </test>
    <test name="Simple Comment">
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
    <test name="Inverted Section">
      <template>{'Shown.
      {{^ nothin}}
        Never shown!
      {{/ nothin}}'}</template>
      <hash>{'{
        "person": true,
      }'}</hash>
      <output>{'Shown.'}</output>
      <parseTree>
        <multi> 
          <static>Shown.</static> 
          <inverted-section name="nothin"> 
            <static>Never shown!</static> 
          </inverted-section> 
        </multi>
      </parseTree>
    </test>
    <test name="Manual First Section">
      <template>{'Hello {{name}}
      You have just won ${{value}}!
      {{#in_ca}}
      Well, ${{taxed_value}}, after taxes.
      {{/in_ca}}'}</template>
      <hash>{'{
        "name": "Chris",
        "value": 10000,
        "taxed_value": 10000 - (10000 * 0.4),
        "in_ca": true }'}</hash>
      <output>{'Hello Chris
        You have just won $10000!
        Well, $6000.0, after taxes.'}</output>
      <parseTree>
        <multi>
          <static>Hello </static>
          <etag name="name"/>
          <static>You have just won $</static>
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
    <test name="Escaping">
      <template>{'* {{name}}
      * {{age}}
      * {{company}}
      * {{{company}}}'}</template>
      <hash>{'{
        "name": "Chris",
        "company": "<b>GitHub</b>"
      }'}</hash>
      <output>{'* Chris
      *
      * &lt;b&gt;GitHub&lt;/b&gt;
      * <b>GitHub</b>'}</output>
      <parseTree>
        <multi> 
          <static>*</static> 
          <etag name="name"/> 
          <static>*</static> 
          <etag name="age"/> 
          <static>*</static> 
          <etag name="company"/> 
          <static>*</static> 
          <utag name="company"/> 
        </multi>
      </parseTree>
    </test>
    <test name="Triple Mustache">
      <template>{'{{{world}}}'}</template>
      <parseTree>
        <multi>
          <utag name="world"/>
        </multi>
      </parseTree>
    </test>
    <test name="Static Section">
      <template>{'Shown.
      {{#nothin}}
        Never shown!
      {{/nothin}}'}</template>
      <parseTree>
        <multi> 
          <static>Shown.</static> 
          <section name="nothin"> 
            <static>Never shown!</static> 
          </section> 
        </multi>
      </parseTree>
    </test>
    <test name="Simple amp utag">
      <template>{'{{&amp; name}}'}</template>
      <parseTree>
        <multi> 
          <utag name="name"/> 
        </multi>
      </parseTree>
    </test>
    <test name="Repo Section">
      <template>{'{{#repo}}
      <b>{{name}}</b>
    {{/repo}}'}</template>
      <hash>{'{
        "repo": [
          { "name": "resque" },
          { "name": "hub" },
          { "name": "rip" },
        ]
      }'}</hash>
      <output>{'<b>resque</b>
      <b>hub</b>
      <b>rip</b>'}</output>
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
    <test name="Simple Lambda">
      <template>{'{{#wrapped}}
        {{name}} is awesome.
      {{/wrapped}}'}</template>
      <hash>{'{
        "name": "Willy",
        "wrapped": function() {
          return function(text) {
            return "<b>" + render(text) + "</b>"
          }
        }
      }'}</hash>
      <output>{'<b>Willy is awesome.</b>'}</output>
      <parseTree>
        <multi> 
          <section name="wrapped"> 
            <etag name="name"/> 
            <static>is awesome.</static> 
          </section> 
        </multi>
      </parseTree>
    </test>
    <test name="Non-False Values">
      <template>{'{{#person?}}
        Hi {{name}}!
      {{/person?}}'}</template>
      <hash>{'{
        "person?": { "name": "Jon" }
      }'}</hash>
      <output>{'Hi Jon!'}</output>
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
    <test name="Inverted Sections">
      <template>{'{{#repo}}
        <b>{{name}}</b>
      {{/repo}}
      {{^repo}}
        No repos :(
      {{/repo}}'}</template>
      <hash>{'{
        "repo": []
      }'}</hash>
      <output>{'No repos :('}</output>
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
    <test name="Comments">
      <template>{'<h1>Today{{! ignore me }}.</h1>'}</template>
      <hash>{'{}'}</hash>
      <output>{'<h1>Today.</h1>'}</output>
      <parseTree>
        <multi> 
          <static>&lt;h1&gt;Today</static> 
          <comment>ignore me</comment> 
          <static>.&lt;/h1&gt;</static> 
        </multi>
      </parseTree>
    </test>
    <test name="Partial Test">
      <template>{'{{> next_more}}'}</template>
      <parseTree>
        <multi> 
          <partial name="next_more"/> 
        </multi>
      </parseTree>
    </test>
    <test name="Nested Sections">
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
      <output>{'<h1>Colors</h1>
      <li><strong>red</strong></li>
      <li><a href="#Green">green</a></li>
      <li><a href="#Blue">blue</a></li>'}</output>
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
    <test name="Two Sequencial Mustaches">
      <template>{'I like going to the {{location}} because I find it {{verb}}'}</template>
      <parseTree>
        <multi> 
          <static>I like going to the</static> 
          <etag name="location"/> 
          <static>because I find it</static> 
          <etag name="verb"/> 
        </multi>
      </parseTree>
    </test>
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
    <test name="Recursive Descendant">
      <template>{'{{*name}}'}</template>
      <hash>{'{ "person": {
        "name": "Chris",
        "company": "<b>GitHub</b>"
      } }'}</hash>
      <output>{'Chris'}</output>
      <parseTree>
        <multi> 
          <rtag name="name"/> 
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
    <!-- tests from mustache.js -->
    <test name="Apos">
      <template>{'{{apos}}{{control}}'}</template>
      <hash>{'{"apos": "&#39;", "control":"X")}'}</hash>
      <output>{'&#39;X'}</output>
      <parseTree>
        <multi> 
          <etag name="apos"/> 
          <etag name="control"/> 
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
    <test name="Whitespace">
      <template>{'{{tag}} foo'}</template>
      <hash>{'{ "tag": "yo" }'}</hash>
      <output>{'yo foo'}</output>
      <parseTree>
        <multi>
          <etag name="tag"/>
          <static>foo</static>
        </multi>
      </parseTree>
    </test>
    <test name="Not Found">
      <template>{'{{foo}}'}</template>
      <hash>{'{ "bar": "yo" }'}</hash>
      <output>{''}</output>
      <parseTree>
        <multi>
          <etag name="foo"/>
        </multi>
      </parseTree>
    </test>
    <test name="Nesting">
      <template>{'{{#foo}}
        {{#a}}
          {{b}}
        {{/a}}
      {{/foo}}'}</template>
      <hash>{'foo: [
        {a: {b: 1}},
        {a: {b: 2}},
        {a: {b: 3}}
      ]'}</hash>
      <output>{'1
        2
        3'}</output>
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
    <test name="Book with lots of sections">
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
        {"book":
      {"section": {"section": {}}}}'}</hash>
      <output>{''}</output>
      <parseTree>
        <multi>
          <section name="book">
            <section name="section">
              <section name="section">
                <static/>
                <section name="section">
                  <etag name="p"/>
                </section>
                <static/>
              </section>
            </section>
          </section>
        </multi>
      </parseTree>
    </test>
<!--
    <test name="">
      <template>{''}</template>
      <hash>{''}</hash>
      <output>{''}</output>
      <parseTree>
        <multi/>
      </parseTree>
    </test>
-->
  </tests> ;
  
declare function local:parser-test($template,$parseTree){
  xdmp:invoke('parser.xqy', (xs:QName('template'), $template, xs:QName('parseTree'), $parseTree)) };

xdmp:set-response-content-type('application/xml'),
<tests> {
for $test at $i in $parser-tests/test
let $template  := $test/template/fn:string()
let $parseTree := $test/parseTree/*
let $result    := local:parser-test( $template,$parseTree )
let $valid     := $result [1]
let $mTree     := $result [2]
return <test position="{$i}" parseTest="{if($valid) then 'ok' else 'NOK'}">
         { fn:string($test/@name)} 
         { if($valid) then ()
           else 
             <parseTestExplanation> 
               {xdmp:log((fn:concat($i, ' >> ', $template), $parseTree,$mTree))}
               Template: {$template}
               Expected: {$parseTree}
               Got: {$mTree}
             </parseTestExplanation>}
       </test>
} </tests>