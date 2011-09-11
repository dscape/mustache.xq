# Mustache

Inspired by [ctemplate][1] and [et][2], Mustache is a
framework-agnostic way to render logic-free views.

As ctemplates says, "It emphasizes separating logic from presentation:
it is impossible to embed application logic in this template language."

For a list of implementations (other than XQuery) and tips, see
<http://mustache.github.com/>.

For a language-agnostic overview of Mustache’s template syntax, see the
`mustache(5)` manpage or <http://mustache.github.com/mustache.5.html>.

## Why?

Mustache.xq is designed to help you when:

1. You want to avoid fn:concat to generate strings to keep your code more readable
2. Want to render json as a string
3. Internationalization

Mustache.xq was designed using [MarkLogic][4] Server but can be 
used in any XQuery processor

## Usage

A quick example how to use mustache.xq:

``` xquery
    import module namespace mustache = "mustache.xq"
     at "mustache.xqy";
    mustache:render( 'Hello {{text}}!', '{ "text": "world"}' )
```

Returns

``` xquery
    <div>Hello world!</div>
```

A slightly more complicated example

``` xquery
    mustache:render(
      '<h1>{{header}}</h1> {{#bug}} {{/bug}}
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
      {{/empty}}', 
      '{ "header": "Colors",
          "items": [
              {"name": "red", "first": true, "url": "#Red"},
              {"name": "green", "link": true, "url": "#Green"},
              {"name": "blue", "link": true, "url": "#Blue"}
          ],
          "empty": false }')
```

Outputs:

``` xml
    <div>
      <h1>Colors</h1>
      <li>
        <strong>red</strong>
      </li>
      <li>
        <a href="#Green">green</a>
      </li>
      <li>
        <a href="#Blue">blue</a>
      </li>
    </div>
```

For more (fun) examples refer to test/tests.xml. If you are new to mustache you can use it to learn more about it.

## Contribute

Everyone is welcome to contribute. 

1. Fork mustache.xq in github
2. Create a new branch - `git checkout -b my_branch`
3. Test your changes
4. Commit your changes
5. Push to your branch - `git push origin my_branch`
6. Create an pull request

The documentation is severely lacking. Feel free to contribute to the wiki if 
you think something could be improved.

### Running the tests

To run the tests simply point an MarkLogic HTTP AppServer to the root of mustache.xqy

You can run the tests by accessing:
(assuming 127.0.0.1 is the host and 8090 is the port)

    http://127.0.0.1:8090/test

Make sure all the tests pass before sending in your pull request!

### Report a bug

If you want to contribute with a test case please file a [issue][2] and attach 
the following information:

* Name
* Template
* Hash
* Output

This will help us be faster fixing the problem.

An example for a Hello World test would be:

``` xml
     <test name="Hello World">
       <template>{'Hello {{word}}!'}</template>
       <hash>{'{"word": "world"}'}</hash>
       <output><div>Hello world !</div></output>
     </test>
```

This is not the actual test that we run (you can see a list of those in test/index.xqy) but it's all the information we need for a bug report.

## Supported Functionality

####  ✔ Variables
     Template : {{car}}
     Hash     : { "car": "bmw"}
     Output   : <div>bmw</div>

####  ✔ Unescaped Variables
     Template : {{company}} {{{company}}}
     Hash     : { "company": "<b>MarkLogic</b>" }
     Output   : <div>&lt;b&gt;MarkLogic&lt;/b&gt; <b>MarkLogic</b></div>

####  ✔ Comments
     Template : <h1>Today{{! ignore me }}.</h1>
     Hash     : {}
     Output   : <div><h1>Today.</h1></div>

####  ✔ Sections
     Template : Shown. {{#nothin}} Never shown! {{/nothin}}
     Hash     : { "person": true }
     Output   : <div>Shown.</div>

####  ✔ Nested Sections
     Template : {{#foo}}{{#a}}{{b}}{{/a}}{{/foo}}
     Hash     : { foo: [ {a: {b: 1}}, {a: {b: 2}}, {a: {b: 3}} ] }
     Output   : <div>1 2 3</div>

####  ✔ Conditional Sections
     Template : {{#repo}} <b>{{name}}</b> {{/repo}} {{^repo}} No repos :( {{/repo}}
     Hash     :   { "repo": [] }
     Output   : <div>No Repos :(</div>

####  ✕ Partials

####  ✕ Lambdas

####  ✕ Set Delimiter

### Extensions

####  ✔ Variables with embedded XQuery
     Template : {{x}}
     Hash     : { "x": ( xs:integer(4) + 5 ) * 2 }
     Output   : <div>18</div>

####  ✔ Dot Notation
     Template :{{person.name.first}}
     Hash     :{ "person": { "name": { "first": "Eric" } } }
     Output   :<div>Eric</div>

####  ✔ Descendant Variable
     Template : * {{*name}}
     Hash     : { "people": { "person": { "name": "Chris" }, "name": "Jan" } }
     Output   : <div>* Chris Jan</div>

### Roadmap

If you are interested in any of these (or other) feature and don't want to wait just read the instructions
on "Contribute" and send in your code

* Support XML as well as JSON
* Clean up whitespace with "&#x0a;"
* XQuery Lambdas (still haven't thought about how this magic would look like)
* Partials
* Rewrite the compiler for XQuery 1.0 without MarkLogic Extensions

### Known Limitations

In this section we have the know limitations excluding the features that are not supported. 
To better understand what is supported refer to the Supported Features section

* Test cases can only be run in MarkLogic.
* Bundled generator is MarkLogic Specific "1.0-ml".
* Output is returned inside a <div/> tag. This is to support escaping.
* Key names must be valid QNames (limitation of json.xqy and generator.xqy)

## Meta

* Code: `git clone git://github.com/dscape/mustache.xq.git`
* Home: <http://mustache.github.com>
* Discussion: <http://convore.com/mustache>
* Bugs: <http://github.com/dscape/mustache.xq/issues>

(oO)--',- in [caos][5]

[1]: http://code.google.com/p/google-ctemplate/
[2]: http://www.ivan.fomichev.name/2008/05/erlang-template-engine-prototype.html
[3]: http://github.com/dscape/mustache.xq/issues
[4]: http://marklogic.com
[5]: http://caos.di.uminho.pt/