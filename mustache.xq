(:
  mustache.xq — Logic-less templates in XQuery
  See http://mustache.github.com/ for more info.
:)
xquery version "1.0" ;
module namespace mustache = "mustache.xq" ;

import module namespace parser   = "parser.xq"
  at "lib/parser-regexp.xq" ;
import module namespace compiler = "compiler.xq"
  at "lib/compiler.xqy" ;

declare function mustache:render( $template, $json ) {
  mustache:compile( mustache:parse( $template ), $json ) } ;

declare function mustache:parse( $template ) {
  parser:parse( $template) } ;

declare function mustache:compile($parseTree, $json) {
  compiler:compile( $parseTree, $json ) } ;