(:
  mustache.xq — Logic-less templates in XQuery
  See http://mustache.github.com/ for more info.
:)
xquery version "1.0" ;
module namespace mustache = "mustache.xq" ;

declare namespace s = "http://www.w3.org/2009/xpath-functions/analyze-string" ;

declare variable $mustache:otag        := "{{" ;
declare variable $mustache:ctag        := "}}" ;
declare variable $mustache:oisec       := '^' ;
declare variable $mustache:osec        := '#' ;
declare variable $mustache:csec        := '/' ;
declare variable $mustache:templ       := '&gt;' ;  (: > :)
declare variable $mustache:unesc       := '&amp;' ; (: & :)
declare variable $mustache:uneschtml   := '{' ;
declare variable $mustache:r-tag       := '\s*(.+)\s*' ;
declare variable $mustache:r-osec      := 
  fn:string-join( mustache:escape-for-regexp( ( $mustache:oisec, $mustache:osec ) ), "|" ) ;
declare variable $mustache:r-csec      := mustache:escape-for-regexp( $mustache:csec ) ;
declare variable $mustache:r-modifiers := 
  fn:string-join( mustache:escape-for-regexp( ( $mustache:templ, $mustache:unesc, $mustache:uneschtml ) ), "|" ) ;
declare variable $mustache:r-mustaches := 
  mustache:r-mustache( $mustache:r-modifiers, '*' ) ;
declare variable $mustache:r-sections :=
  fn:concat(
    mustache:r-mustache( $mustache:r-osec, '' ),
    $mustache:r-tag,
    mustache:r-mustache( $mustache:r-csec, '' ) ) ;

(: ~ parser :)
declare function mustache:parse( $template ) {
  let $sections :=
    <multi> {
    mustache:passthru-sections( fn:analyze-string($template, $mustache:r-sections ) )
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
    case text() return mustache:passthru-simple(fn:analyze-string($node/fn:string(), $mustache:r-mustaches))
    default return mustache:passthru( $node ) } ;

declare function mustache:passthru-simple( $nodes ) {
  for $node in $nodes/node() return mustache:dispatch-simple($node) };

declare function mustache:dispatch-simple( $node ) {
  typeswitch($node)
    case element(s:non-match) return <static>{$node/fn:string()}</static>
    case element(s:match) return <etag>
      {attribute name {fn:replace($node/s:group[@nr=3],'\}$', '')},
         let $modifier := $node/s:group[@nr=2]
         return if($modifier)
          then attribute modifier { $modifier/fn:string() }
          else ()
     }</etag>
    case text() return $node
    default return $node };

(: credit: http://www.xqueryfunctions.com/xq/functx_escape-for-regex.html :)
declare function mustache:escape-for-regexp( $strings ) {
  for $s in $strings return fn:replace($s,'(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))','\\$1') };

declare function mustache:r-mustache( $modifiers, $quantifier ){
  fn:concat( 
    mustache:group( mustache:escape-for-regexp( $mustache:otag ) ), 
    mustache:group( $modifiers, $quantifier), 
    $mustache:r-tag,
    mustache:group( mustache:escape-for-regexp( $mustache:ctag ) ) ) };

declare function mustache:group( $r ) {
  mustache:group($r, '') };

declare function mustache:group( $r, $quantifier ) {
    fn:concat("(", $r, ")", $quantifier) } ;