(:
  XQuery Generator for mustache
:)
xquery version "1.0-ml" ;
module namespace compiler = "compiler.xq" ;

import module 
  namespace json = "http://marklogic.com/json"
  at "json.xqy" ;

declare function compiler:compile( $parseTree, $json ) {
 <div> {
   compiler:compile-xpath( $parseTree, json:jsonToXML( $json ), 1, '' ) } </div> } ;

declare function compiler:compile-xpath( $parseTree, $json, $pos, $xpath ) { 
  for $node in $parseTree/node() return compiler:compile-node( $node, $json, $pos, $xpath ) } ;

declare function compiler:compile-node( $node, $json, $pos, $xpath ) {
  typeswitch($node)
    case element(etag)   return compiler:eval( $node/@name, $json, $pos, $xpath )
    case element(utag)   return compiler:eval( $node/@name, $json, $pos, $xpath, fn:false() )
    case element(static) return $node/fn:string()
    case element(section) return
      let $sNode := compiler:unpath( fn:string( $node/@name ) , $json, $pos, $xpath )
      return 
        if ($sNode/@boolean = 'true') 
        then compiler:compile-xpath( $node, $json, 1, '' ) 
        else
          if ($sNode/@type="array")
          then 
            if ( fn:empty( $sNode/node() ) ) 
            then () 
            else for $n at $p in $sNode 
                 return compiler:compile-xpath( $node, $json, $p, fn:concat(fn:node-name($sNode), '/item/') )
          else ()
    case text() return $node
    default return compiler:compile-xpath( $node, $json, 1, '' ) }; 

declare function compiler:eval( $node-name, $json, $pos ) { 
  compiler:eval($node-name, $json, $pos, '', fn:true() ) };
      
declare function compiler:eval( $node-name, $json, $pos, $xpath ) { 
  compiler:eval($node-name, $json, $pos, $xpath, fn:true() ) };

declare function compiler:eval( $node-name, $json, $pos, $xpath, $etag ) { 
  let $unpath :=  compiler:unpath( $node-name, $json, $pos, $xpath )
  return try {
    if ($etag) then fn:string( xdmp:eval( xdmp:quote($unpath) ) ) else xdmp:unquote($unpath)/*
  } catch ( $e ) { $unpath } };

declare function compiler:unpath( $node-name, $json, $pos, $xpath ) { 
  xdmp:unpath( fn:concat( '$json/json/', $xpath , $node-name,
    '[', $pos, ']' ) ) };