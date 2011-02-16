import module namespace compiler = "compiler.xq"
 at "../lib/compiler.xq";
 
let $parseTree :=
<multi>
  <static>Hello </static>
  <etag name="world"/>
</multi>
let $json := 
'{"word": "world"}'
return compiler:compile($parseTree, $json)