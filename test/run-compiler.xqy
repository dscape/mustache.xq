xquery version "3.0" ;

import module namespace mustache = "mustache.xq" at "../mustache.xq";

declare variable $template external ;
declare variable $hash      external ;
declare variable $output    external ;

declare function local:canonicalize($nodes) {
  for $node in $nodes/node() 
  return local:dispatch($node) };

declare function local:dispatch( $node ) {
  typeswitch($node)
    case element()         return element   {fn:node-name($node)} { $node/@*, local:canonicalize($node) }
    case text()            return fn:normalize-space($node)
    default                return local:canonicalize( $node ) } ;

let $render  := local:canonicalize( document {  mustache:render( $template, $hash ) } )
let $output := local:canonicalize(document { $output })
return (fn:deep-equal($render, $output), $render)
