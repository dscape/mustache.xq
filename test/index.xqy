xquery version "3.0" ;

declare variable $tests := xquery:invoke('tests.xml') ;

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
  xquery:invoke( 'run-parser.xqy', map{
	'template' := $template,
	'parseTree' := $parseTree
  })
};

declare function local:compiler-test( $template, $hash, $output ) {
    xquery:invoke( 'run-compiler.xqy', map{
	'template' := $template,
	'hash' := $hash,
	'output' := $output
  })
};

let $results := <tests> {
for $test at $i in $tests//test
order by $test/@section
return try {
let $template       := $test/template/fn:string()
let $hash           := $test/hash/fn:string()
let $section        := $test/@section
let $parseTree      := $test/parseTree/*
let $result         := local:parser-test( $template,$parseTree )
let $valid          := $result [1]
let $mTree          := $result [2]
let $output         := if ($valid) then $test/output/* else () (: Don't run compile tests if parsing failed :)
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
       </test> } catch * { <test type="ERROR" i="{$err:code}"  parseTest="NOK" compileTest="NOK">{
         $test/@name}
         <stackTrace>{$err:description}</stackTrace>
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
