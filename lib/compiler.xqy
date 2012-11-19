(:
  XQuery Generator for mustache
:)
xquery version "3.0" ;
module namespace compiler = "compiler.xq" ;

declare function compiler:compile( $parseTree, $json ) {
 let $div := parse-xml( fn:concat( '&lt;div&gt;',
   fn:string-join(compiler:compile-xpath( $parseTree, json:parse( $json ) ), ''),  '&lt;/div&gt;') )
 let $handle := compiler:handle-escaping($div)
  return $handle
};

declare function  compiler:compile-xpath( $parseTree, $json ) {
  compiler:compile-xpath( $parseTree, $json, 1, '' )
}; 

declare function compiler:compile-xpath( $parseTree, $json, $pos, $xpath ) { 
  for $node in $parseTree/node() 
  return compiler:compile-node( $node, $json, $pos, $xpath ) } ;

declare function compiler:compile-node( $node, $json, $pos, $xpath ) {
  typeswitch($node)
    case element(etag)    return
    compiler:eval( $node/@name, $json, $pos, $xpath )
    case element(utag)    return compiler:eval( $node/@name, $json, $pos, $xpath, fn:false() )
    case element(rtag)    return 
      fn:string-join(compiler:eval( $node/@name, $json, $pos, $xpath, fn:true(), 'desc' ), " ")
    case element(static)  return $node/fn:string()
    case element(comment) return ()
    case element(inverted-section) return
      let $sNode := compiler:unpath( fn:string( $node/@name ) , $json, $pos, $xpath )
      return 
        if ( $sNode/@boolean = "true" or ( not( empty( tokenize( $json/@booleans, '\s')[.=$node/@name] ) ) ) )
        then ()
        else if ( $sNode/@type = "array" or ( not( empty( tokenize( $json/@arrays, '\s')[.=$node/@name] ) ) ) )
             then if (fn:exists($sNode/node())) 
             then () 
             else compiler:compile-xpath( $node, $json )
       else compiler:compile-xpath( $node, $json ) 
    case element(section) return
      let $sNode := compiler:unpath( fn:string( $node/@name ) , $json, $pos, $xpath )
      return 
        if ( $sNode/@boolean = "true" or ( not( empty( tokenize( $json/@booleans, '\s')[.=$node/@name] ) ) and $sNode/text() = "true" ) )
        then compiler:compile-xpath( $node, $json, $pos, $xpath )
        else
          if ( $sNode/@type = "array" or ( not( empty( tokenize( $json/@arrays, '\s')[.=$node/@name] ) ) ) )
          then (
            for $n at $p in $sNode/node()
            return compiler:compile-xpath( $node, $json, $p, fn:concat( $xpath, '/', fn:node-name($sNode), '/value' ) ) )
          else if($sNode/@type = "object" or ( not( empty( tokenize( $json/@objects, '\s')[.=$node/@name] ) ) ) ) then 
          compiler:compile-xpath( $node, $json, $pos, fn:concat( $xpath,'/', fn:node-name( $sNode ) ) ) else ()
    case text() return $node
    default return compiler:compile-xpath( $node, $json ) }; 

declare function compiler:eval( $node-name, $json, $pos ) { 
  compiler:eval($node-name, $json, $pos, '', fn:true() ) };
      
declare function compiler:eval( $node-name, $json, $pos, $xpath ) { 
  compiler:eval($node-name, $json, $pos, $xpath, fn:true() ) };

declare function compiler:eval( $node-name, $json, $pos, $xpath, $etag ) { 
 compiler:eval( $node-name, $json, $pos, $xpath, $etag, '' )
};

declare function compiler:eval( $node-name, $json, $pos, $xpath, $etag, $desc ) { 
  let $unpath :=  compiler:unpath( $node-name, $json, $pos, $xpath, $desc )
  return try {
    let $value := fn:string( xquery:eval( $unpath ) )
    return if ($etag) 
    then fn:concat('{{b64:', Q{java:org.basex.util.Base64}encode($value), '}}') (: recursive mustache ftw :)
    else $value
  } catch * { $unpath } };

declare function compiler:unpath( $node-name, $json, $pos, $xpath ) { 
  compiler:unpath( $node-name, $json, $pos, $xpath, '' )
};

declare function compiler:unpath( $node-name, $json, $pos, $xpath, $desc ) { 
  let $xp := fn:concat( '$json', $xpath, '[', $pos, ']/',
    if ($desc='desc') then '/' else '', $node-name )
  let $eval := xquery:eval( $xp, map { '$json' := $json } )
  return $eval
};

declare function compiler:handle-escaping( $div ) {
  for $n in $div/node()
  return compiler:handle-base64($n) };

declare function compiler:handle-base64( $node ) {
  typeswitch($node)
    case element()         return element {fn:node-name($node)} {
      for $a in $node/@*
      return attribute {fn:node-name($a)} {compiler:resolve-mustache-base64($a)}, 
      compiler:handle-escaping( $node )}
    case text()            return compiler:resolve-mustache-base64( $node)
    default                return compiler:handle-escaping( $node ) };

declare function compiler:resolve-mustache-base64( $text ) {
 fn:string-join( for $token in fn:tokenize($text, " ")
  return 
    if ( fn:matches( $token, '\{\{b64:(.+?)\}\}' ) )
    then 
      let $as := fn:analyze-string($token, '\{\{b64:(.+?)\}\}')
      let $b64    := $as//*:group[@nr=1]
      let $before := $as/*:match[1]/preceding::*:non-match[1]/fn:string()
      let $after  := $as/*:match[fn:last()]/following::*:non-match[1]/fn:string()
      return fn:string-join( ($before, for $decoded in Q{java:org.basex.util.base64}decode( $b64 )
      let $executed := 
        if ( fn:matches( $decoded, "(&lt;|&gt;|&amp;|&quot;|&apos;)" ) )
        then fn:string($decoded)
        else fn:string(try { xquery:eval( $decoded ) } catch * { $decoded })
      return $executed, $after), '' )
    else if ( fn:matches( $token, '\{\{b64:\}\}' ) )
    then ""
    else $token, " ") };
