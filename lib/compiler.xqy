(:
  XQuery Generator for mustache
:)
xquery version "1.0-ml" ;
module namespace compiler = "compiler.xq" ;

import module 
  namespace json = "http://marklogic.com/json"
  at "json.xqy" ;

declare function compiler:compile( $parseTree, $json ) {
  fn:normalize-space( fn:string-join( compiler:compile-xpath( $parseTree, json:jsonToXML( $json ), fn:true() ), '' ) ) } ;

declare function compiler:compile-xpath( $parseTree, $json, $dispEtag ) { 
  for $node in $parseTree/node() return compiler:compile-node( $node, $json, $dispEtag ) } ;

declare function compiler:compile-node( $node, $json, $dispEtag ) {
  typeswitch($node)
    case element(etag)   return if($dispEtag) then compiler:eval( $node/@name, $json ) else ()
    case element(static) return $node/fn:string()
    case element(section) return
      let $keyValue := compiler:unpath( fn:string( $node/@name ) , $json )/@boolean = 'true'
      return compiler:compile-xpath( $node, $json, $keyValue )
    case text() return $node
    default return compiler:compile-xpath( $node, $json, fn:true() ) }; 

declare function compiler:eval( $node-name, $json ) { 
  let $unpath :=  compiler:unpath( $node-name, $json )
  return try {
    fn:string( xdmp:eval( $unpath ) )
  } catch ( $e ) { $unpath } };

declare function compiler:unpath( $node-name, $json ) { 
  xdmp:unpath(fn:concat('$json/json/', $node-name,'[1]')) };