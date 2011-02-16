import module namespace compiler = "compiler.xq"
 at "../lib/compiler.xqy";
 
let $parseTree :=
<multi>
  <static>Hello </static>
  <etag name="word"/>
</multi>
let $json := 
'{"word": "world"}'
return compiler:compile($parseTree, $json)