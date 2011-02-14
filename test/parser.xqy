xquery version "1.0-ml" ;

import module namespace mustache = "mustache.xq"
  at "../mustache.xq" ;

declare variable $template external ;
declare variable $parseTree external ;

declare function local:canonicalize($nodes) {
  for $node in $nodes/node() return local:dispatch($node) };

declare function local:dispatch( $node ) {
  typeswitch($node)
    case element()   return element   {fn:node-name($node)} { $node/@*, local:canonicalize($node) }
    case text() return fn:normalize-space($node)
    default return local:canonicalize( $node ) } ;

let $mres  := local:canonicalize(document { mustache:parse($template) })
let $ptree := local:canonicalize(document { $parseTree })
return (fn:deep-equal($mres, $ptree), $mres)