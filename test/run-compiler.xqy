xquery version "1.0-ml" ;

import module namespace mustache = "mustache.xq"
  at "../mustache.xq" ;

declare variable $template external ;
declare variable $hash      external ;
declare variable $output    external ;

let $render  := mustache:render( $template, $hash )
return ( fn:normalize-space( $render ) = fn:normalize-space( $output ) , $render )