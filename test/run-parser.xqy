xquery version "3.0" ;

import module namespace mustache = "mustache.xq" at "../mustache.xq";

declare variable $template external ;
declare variable $parseTree external ;

declare function local:emptyStatic($node) {
  fn:node-name($node)=xs:QName('static') and fn:normalize-space($node)='' } ;

declare function local:canonicalize($nodes) {
  for $node in $nodes/node() 
  where fn:not(local:emptyStatic($node))
  return local:dispatch($node) };

declare function local:dispatch( $node ) {
  typeswitch($node)
    case element()         return element   {fn:node-name($node)} { $node/@*[fn:not(fn:node-name(.)=xs:QName('remain'))], local:canonicalize($node) }
    case text()            return fn:normalize-space($node)
    default                return local:canonicalize( $node ) } ;

let $mres  := local:canonicalize(document { mustache:parse($template) })
let $ptree := local:canonicalize(document { $parseTree })
return (fn:deep-equal($mres, $ptree), $mres)
