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
    <test name="Simple Section">
      <template>{'Hello {{name}}
      You have just won ${{value}}!
      {{#in_ca}}
      Well, ${{taxed_value}}, after taxes.
      {{/in_ca}}'}</template>
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
    <test name="Triple Mustache">
      <template>{'{{{world}}}'}</template>
      <parseTree>
        <multi>
          <etag name="world" modifier="{'{'}"/>
        </multi>
      </parseTree>
    </test>
  </tests> ;
  
declare function local:parser-test($template,$parseTree){
  xdmp:invoke('parser.xqy', (xs:QName('template'), $template, xs:QName('parseTree'), $parseTree)) };

for $test at $i in $parser-tests/test
let $template  := $test/template/fn:string()
let $parseTree := $test/parseTree/multi
let $result    := local:parser-test( $template,$parseTree )
let $valid     := $result [1]
let $mTree     := $result [2]
return <test position="{$i}" result="{if($valid) then 'ok' else 'NOK'}">
         { fn:string($test/@name)} 
         { if($valid) then ()
           else 
             <explanation> 
               {xdmp:log((fn:concat($i, ' >> ', $template), $parseTree,$mTree))}
               Template: {$template}
               Expected: {$parseTree}
               Got: {$mTree}
             </explanation>}
       </test>