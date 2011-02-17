(:
  XQuery Generator for mustache
:)
xquery version "1.0-ml" ;
module namespace compiler = "compiler.xq" ;

import module 
  namespace json = "http://marklogic.com/json"
  at "json.xqy" ;

declare function compiler:compile( $parseTree, $json ) {
 let $div := xdmp:unquote( fn:concat( '&lt;div&gt;',
   fn:string-join(compiler:compile-xpath( $parseTree, json:jsonToXML( $json ), 1, '' ), ''),  '&lt;/div&gt;') )
 return compiler:handle-escaping($div) } ;

declare function compiler:compile-xpath( $parseTree, $json, $pos, $xpath ) { 
  for $node in $parseTree/node() 
  return compiler:compile-node( $node, $json, $pos, $xpath ) } ;

declare function compiler:compile-node( $node, $json, $pos, $xpath ) {
  typeswitch($node)
    case element(etag)    return compiler:eval( $node/@name, $json, $pos, $xpath )
    case element(utag)    return compiler:eval( $node/@name, $json, $pos, $xpath, fn:false() )
    case element(static)  return $node /fn:string()
    case element(comment) return ()
    case element(inverted-section) return
      let $sNode := compiler:unpath( fn:string( $node/@name ) , $json, $pos, $xpath )
      return 
        if ( $sNode/@boolean = "true" ) 
        then ()
        else compiler:compile-xpath( $node, $json, 1, '' ) 
    case element(section) return

      let $sNode := compiler:unpath( fn:string( $node/@name ) , $json, $pos, $xpath )
      return 
        if ( $sNode/@boolean = "true" ) 
        then compiler:compile-xpath( $node, $json, 1, '' ) 
        else
          if ( $sNode/@type = "array" )
          then 
            for $n at $p in $sNode/node()
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
    let $value := fn:string( xdmp:eval( xdmp:quote($unpath) ) )
    return if ($etag) 
    then fn:concat('{{b64:', xdmp:base64-encode($value), '}}') (: recursive mustache ftw :)
    else $value
  } catch ( $e ) { $unpath } };

declare function compiler:unpath( $node-name, $json, $pos, $xpath ) { 
  xdmp:unpath( fn:concat( '($json/json/', $xpath , $node-name,
    ')[', $pos, ']' ) ) };

declare function compiler:handle-escaping( $div ) {
  for $n in $div/node()
  return compiler:handle-base64($n) };

declare function compiler:handle-base64( $node ) {
  typeswitch($node)
    case element()         return element {fn:node-name($node)} {$node/@*, compiler:handle-escaping( $node )}
    case text()            return
      fn:string-join( for $token in fn:tokenize($node, " ")
      return 
        if ( fn:matches( $token, '\{\{b64:(.+?)\}\}' ) )
        then 
          let $as := fn:analyze-string($token, '\{\{b64:(.+?)\}\}')
          let $b64    := $as//*:group[@nr=1]
          let $before := $b64/preceding::*:non-match[1]/fn:string()
          let $after  := $b64/following::*:non-match[1]/fn:string()
          return fn:concat($before, xdmp:base64-decode($b64), $after)
        else if ( fn:matches( $token, '\{\{b64:\}\}' ) )
        then ""
        else $token, " ")
    default                return compiler:handle-escaping( $node ) };