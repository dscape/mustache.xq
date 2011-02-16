xquery version "1.0-ml" ;

import module namespace mustache = "mustache.xq"
  at "../mustache.xq" ;

declare variable $parseTree external ;
declare variable $hash      external ;
declare variable $output    external ;

let $parsed  := mustache:compile( $parseTree, $hash )
return ($parsed=$output, $parsed)