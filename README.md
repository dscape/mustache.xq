# Mustache

Inspired by [ctemplate][1] and [et][2], Mustache is a
framework-agnostic way to render logic-free views.

As ctemplates says, "It emphasizes separating logic from presentation:
it is impossible to embed application logic in this template language."

For a list of implementations (other than Ruby) and tips, see
<http://mustache.github.com/>.

For a language-agnostic overview of Mustache’s template syntax, see the
`mustache(5)` manpage or <http://mustache.github.com/mustache.5.html>.

## Why?

Mustache.xq is designed to help you when:

1. You want to avoid fn:concat to generate strings to keep your code more readable
2. Want to render json as a string
3. Internationalization

Mustache.xq was designed using MarkLogic Server <http://marklogic.com/> but can be 
used in any XQuery processor

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

    http://127.0.0.1:8090/tests

Make sure all the tests pass before sending in your pull request!

### Tests

If you want to contribute with a test case please file a [issue][2] and attach 
the following information:

* Name
* Template
* Hash
* Output

This will help us be faster fixing the problem.

An example for a Hello World test would be:

     <test name="Variables (ETag)">
       <template>{'Hello {{word}}!'}</template>
       <hash>{'{"word": "world"}'}</hash>
       <output><div>Hello world !</div></output>
     </test>

## Usage

A quick example how to use mustache.xq:

    import module namespace mustache = "mustache.xq"
     at "mustache.xqy";
    mustache:render( 'Hello {{text}} !', '{ "text": "world"}' )

Returns

    <div>Hello world !</div>

## Supported Features

### Mustache v1

#### Variables (ETag)  ✔
     Template : {{car}}
     Hash     : { "car": "bmw"}
     Output   : bmw

#### Escaped Variabled (Utag)  ✔
     Template : * {{name}} * {{age}} * {{company}} * {{{company}}}
     Hash     : { "name": "Chris", "company": "<b>GitHub</b>" }
     Output   : * Chris * * &lt;b&gt;GitHub&lt;/b&gt; * <b>GitHub</b>

#### Lambdas ✕


### Mustache v2

Something

### Add-Ons 

Something

### Known Limitations

In this section we have the know limitations excluding the features that are not supported. 
To better understand what is supported refer to the Supported Features section

* Test cases can only be run in MarkLogic
* Bundled generator is MarkLogic Specific "1.0-ml"
* Output is returned inside a <div/> tag. This is to support escaping.

## Meta

* Code: `git clone git://github.com/dscape/mustache.xq.git`
* Home: <http://mustache.github.com>
* Discussion: <http://convore.com/mustache>
* Bugs: <http://github.com/dscape/mustache.xq/issues>

[1]: http://code.google.com/p/google-ctemplate/
[2]: http://www.ivan.fomichev.name/2008/05/erlang-template-engine-prototype.html
[3]: http://github.com/dscape/mustache.xq/issues