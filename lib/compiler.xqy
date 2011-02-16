(:
  XQuery Generator for mustache
:)
xquery version "1.0-ml" ;
module namespace compiler = "compiler.xq" ;

import module 
  namespace json = "http://marklogic.com/json"
  at "json.xqy" ;

declare function compiler:compile( $parseTree, $json ) {
  xdmp:log(json:jsonToXML( $json )),
  compiler:compile-xpath( $parseTree, json:jsonToXML( $json ) ) } ;

declare function compiler:compile-xpath( $parseTree, $json ) {
  compiler:compile-xpath( $parseTree, $json, 'json/' ) 
};
declare function compiler:compile-xpath( $parseTree, $json, $xpath ) { 
  for $node in $parseTree/node() return compiler:compile-node( $node, $json, $xpath ) } ;

declare function compiler:compile-node( $node, $json, $xpath ) {
  xdmp:log(fn:concat('$json/', $xpath, $node/@name,'[1]')),
  typeswitch($node)
    case element(etag)   return 
      fn:string(xdmp:unpath(fn:concat('$json/', $xpath, $node/@name,'[1]')))
    case text()          return $node
    default return compiler:compile-xpath( $node, $json ) }; 