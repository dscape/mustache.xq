xquery version "1.0-ml" ;

declare variable $tests := xdmp:invoke('tests.xml') ;

declare function local:summarize( $name, $nodes ) {
  let $parseTests       := fn:count($nodes/@parseTest)
  let $compileTests     := fn:count($nodes/@compileTest)
  let $okParseTests     := fn:count($nodes[@parseTest='ok'])
  let $nokParseTests    := fn:count($nodes[@parseTest='NOK'])
  let $okCompileTests   := fn:count($nodes[@compileTest='ok'])
  let $nokCompileTests  := fn:count($nodes[@compileTest='NOK'])
  return element {$name}
  {(attribute total {$parseTests+$compileTests},
  <parseTests   pass="{$okParseTests}"   fail="{$nokParseTests}"   
    perc="{if($nokParseTests=0) then '100' else fn:round(100 * $okParseTests div ($okParseTests+ $nokParseTests))}"/>,
  <compileTests pass="{$okCompileTests}" fail="{$nokCompileTests}" 
    perc="{if ($nokCompileTests=0) then '100' else fn:round(100 * $okCompileTests div ($okCompileTests+$nokCompileTests))}"/>)} };

declare function local:parser-test( $template, $parseTree ) {
  xdmp:invoke( 'run-parser.xqy', ( xs:QName( 'template' ), $template, xs:QName( 'parseTree' ), $parseTree ) ) };

declare function local:compiler-test( $template, $hash, $output ) {
    xdmp:invoke( 'run-compiler.xqy', ( xs:QName( 'template' ), $template, xs:QName( 'hash' ), $hash,
      xs:QName( 'output' ), $output ) ) };

xdmp:set-response-content-type('application/xml'),
let $results := <tests> {
for $test at $i in $tests//test
order by $test/@section
return try {
let $template       := $test/template/fn:string()
let $hash           := $test/hash/fn:string()
let $section        := $test/@section
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
         { $section, if($compilerTest) then attribute compileTest {if($validCompiler) then 'ok' else 'NOK'} else () }
         { fn:string($test/@name)} 
         { if($valid) then ()
           else 
             <parseTestExplanation> 
               <p> Template: {$template} </p>
               <p> Expected: {$parseTree} </p>  
               <p> Got: {$mTree} </p>
             </parseTestExplanation>}
         { if ($compilerTest) 
           then if($validCompiler) then ()
           else 
              <compileTestExplanation> 
                <p> Template: {$template} </p>
                <p> Hash: {$hash} </p>
                <p> Expected: {$output} </p>
                <p> Got: {$outputCompiler} </p>
              </compileTestExplanation>
           else ()}
       </test> } catch ($e) { <test type="ERROR" i="{$i}"  parseTest="NOK" compileTest="NOK">{
         $test/@name}
         <stackTrace>{$e}</stackTrace>
         </test> }
} </tests>
return <result>
       { local:summarize( 'summary', $results/test ) }
    <sectionResults>
      { let $sections := fn:distinct-values($results//@section)
       for $section in $sections return  local:summarize( $section, $results/test[@section=$section] ) }
    </sectionResults>
    {$results}
  </result>