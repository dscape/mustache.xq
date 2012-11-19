(:
  mustache.xq — Logic-less templates in XQuery
  See http://mustache.github.com/ for more info.
:)
xquery version "3.0" ;
module namespace mustache = "mustache.xq" ;

import module namespace parser   = "parser.xq"
  at "lib/parser.xq" ;
import module namespace compiler = "compiler.xq"
  at "lib/compiler.xqy" ;

declare function mustache:render( $template, $json2 ) {
  mustache:compile( mustache:parse( $template ), $json2 ) } ;

declare function mustache:parse( $template ) {
  parser:parse( $template) } ;

declare function mustache:compile($parseTree, $json2) {
  compiler:compile( $parseTree, $json2 ) } ;
