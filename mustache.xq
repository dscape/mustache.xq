(:
  mustache.xq — Logic-less templates in XQuery
  See http://mustache.github.com/ for more info.
:)
xquery version "1.0" ;
module namespace mustache = "mustache.xq" ;

declare namespace s = "http://www.w3.org/2009/xpath-functions/analyze-string" ;

declare variable $otag        := "{{" ;
declare variable $ctag        := "}}" ;
declare variable $oisec       := '^' ;
declare variable $osec        := '#' ;
declare variable $csec        := '/' ;
declare variable $templ       := '&gt;' ;  (: > :)
declare variable $unesc       := '&amp;' ; (: & :)
declare variable $uneschtml   := '{' ;
declare variable $r-tag       := '\s*(.+)\s*' ;
declare variable $r-osec      := 
  fn:string-join( mustache:escape-for-regexp( ( $oisec, $osec ) ), "|" ) ;
declare variable $r-csec      := mustache:escape-for-regexp( $csec ) ;
declare variable $r-modifiers := 
  fn:string-join( mustache:escape-for-regexp( ( $templ, $unesc, $uneschtml ) ), "|" ) ;
declare variable $mustaches := 
  mustache:r-mustache( $r-modifiers, '*' ) ;
declare variable $sections :=
  fn:concat(
    mustache:r-mustache( $r-osec, '' ),
    $r-tag,
    mustache:r-mustache( $r-csec, '' ) ) ;

(: ~ parser :)
declare function mustache:parse( $template ) {
  let $sections :=
    <multi> {
    mustache:passthru-sections( fn:analyze-string($template, $sections ) )
    } </multi>
  return <multi> { mustache:passthru( $sections ) } </multi> };

declare function mustache:passthru-sections($nodes) {
  for $node in $nodes/node() return mustache:dispatch-sections($node) };

declare function mustache:dispatch-sections( $node ) {
  typeswitch($node)
    case element(s:non-match) return $node/fn:string()
    case element(s:match) return <section> { 
      if ($node/s:group[@nr=2]='#') then () else attribute type { "inverted" },
      attribute name {$node/s:group[@nr=3]/fn:string()},
      $node/s:group[@nr=5]/fn:string() } </section>
    default return mustache:passthru-sections($node) };

declare function mustache:passthru($nodes) {
  for $node in $nodes/node() return mustache:dispatch($node) };

declare function mustache:dispatch( $node ) {
  typeswitch($node)
    case element(section) return <section>{$node/@*, mustache:passthru($node)}</section>
    case text() return mustache:passthru-simple(fn:analyze-string($node/fn:string(), $mustaches))
    default return mustache:passthru( $node ) } ;

declare function mustache:passthru-simple( $nodes ) {
  for $node in $nodes/node() return mustache:dispatch-simple($node) };

declare function mustache:dispatch-simple( $node ) {
  typeswitch($node)
    case element(s:non-match) return <static>{$node/fn:string()}</static>
    case element(s:match) return <etag>
      {attribute name {$node/s:group[@nr=3]},
         let $modifier := $node/s:group[@nr=2]
         return if($modifier)
          then attribute modifier { $modifier/fn:string() }
          else ()
     }</etag>
    case text() return $node
    default return $node };

(: credit: http://www.xqueryfunctions.com/xq/functx_escape-for-regex.html :)
declare function mustache:escape-for-regexp( $s as xs:string ) {
  fn:replace($s,'(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))','\\$1') };

declare function mustache:r-mustache( $modifiers, $quantifier ){
  fn:concat( 
    mustache:group( mustache:escape-for-regexp( $otag ) ), 
    mustache:group( $modifiers, $quantifier), 
    $r-tag,
    mustache:group( mustache:escape-for-regexp( $ctag ) ) ) };

declare function mustache:group( $r ) {
  mustache:group($r, '') };

declare function mustache:group( $r, $quantifier ) {
    fn:concat("(", $r, ")", $quantifier) } ;