(:
  mustache.xq — Logic-less templates in XQuery
  See http://mustache.github.com/ for more info.
:)
xquery version "1.0" ;
module namespace mustache = "mustache.xq" ;

import module namespace parser = "parser.xq"
  at "lib/parser-regexp.xq" ;

declare function mustache:parse( $template ) {
  parser:parse( $template) } ;