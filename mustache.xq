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
declare variable $mustache:comment     := '!' ;
declare variable $mustache:descendants := '*' ;
declare variable $mustache:templ       := ('&gt;', '&lt;') ;  (: > < :)
declare variable $mustache:unesc       := ('{', '&amp;') ;    (: { & :)
declare variable $mustache:r-tag       := '\s*(.+?)\s*' ;
declare variable $mustache:r-osec      := 
  fn:string-join( mustache:escape-for-regexp( ( $mustache:oisec, $mustache:osec ) ), "|" ) ;
declare variable $mustache:r-csec      := mustache:escape-for-regexp( $mustache:csec ) ;
declare variable $mustache:r-sec := 
  fn:concat($mustache:r-osec, '|', $mustache:r-csec) ;

declare variable $mustache:r-modifiers := 
  fn:string-join( mustache:escape-for-regexp( ( $mustache:templ, $mustache:unesc, $mustache:comment, $mustache:descendants ) ), "|" ) ;
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
  let $simple   := <multi> { mustache:passthru( $sections ) } </multi>
  let $fixedNestedSections := 
    let $etagsToBeFixed := $simple/etag [fn:starts-with(@name, $mustache:osec) or fn:starts-with(@name, $mustache:oisec)]
    return <multi>{ mustache:fixSections($simple/*, $etagsToBeFixed, (), () ) }</multi>
  return $fixedNestedSections };

declare function  mustache:fixSections($seq, $etagsToBeFixed, $before, $after ) {
  let $currentSection := $etagsToBeFixed [1]
  return 
    if ($currentSection)
    then
      let $name           := fn:replace( $currentSection/@name, $mustache:r-sec, '')
      let $closingSection := $seq [ fn:matches( @name, fn:concat( '/\s*',$name,'\s*' ) ) ] [ fn:last() ]
      return
        if ( $closingSection )
        then
          let $beforeClose    := $closingSection/preceding-sibling::*,
              $afterClose     := $closingSection/following-sibling::* [if($after) then . << $after else fn:true()],
              $beforeOpen     := $currentSection/preceding-sibling::* [if($before) then . >> $before else fn:true()],
              $afterOpen      := $currentSection/following-sibling::*,
              $childs         := $afterOpen intersect $beforeClose
          return 
             ($beforeOpen, <section name="{$name}"> {
              mustache:fixSections( $childs, ( $etagsToBeFixed except $currentSection ), $currentSection,  $closingSection ) }
            </section>, $afterClose)
        else fn:error( (),  fn:concat( "no end of section for: ", $name ) )
    else $seq };

declare function mustache:passthru-sections($nodes) {
  for $node in $nodes/node() return mustache:dispatch-sections($node) };

declare function mustache:dispatch-sections( $node ) {
  typeswitch($node)
    case element(s:non-match) return $node/fn:string()
    case element(s:match) return element 
      { if ($node/s:group[@nr=2]='#') then 'section' else 'inverted-section' } 
      { attribute name {$node/s:group[@nr=3]/fn:string() },
      $node/s:group[@nr=5]/fn:string() }
    default return mustache:passthru-sections($node) };

declare function mustache:passthru($nodes) {
  for $node in $nodes/node() return mustache:dispatch($node) };

declare function mustache:dispatch( $node ) {
  typeswitch($node)
    case element(section) return <section>{$node/@*, mustache:passthru($node)}</section>
    case element(inverted-section) return <inverted-section>{$node/@*, mustache:passthru($node)}</inverted-section>
    case text() return mustache:passthru-simple(fn:analyze-string($node/fn:string(), $mustache:r-mustaches))
    default return mustache:passthru( $node ) } ;

declare function mustache:passthru-simple( $nodes ) {
  for $node in $nodes/node() return mustache:dispatch-simple($node) };

declare function mustache:dispatch-simple( $node ) {
  typeswitch($node)
    case element(s:non-match) return <static>{$node/fn:string()}</static>
    case element(s:match) return 
      let $modifier := $node/s:group[@nr=2]
      let $contents := $node/s:group[@nr=3]
      let $normalized-contents :=  fn:normalize-space(fn:replace($contents,'\}$', '')) 
      let $is-section := fn:contains( $normalized-contents, '.' )
      return element {
         if      ( $modifier = $mustache:comment )     then 'comment'
         else if ( $modifier = $mustache:templ )       then 'partial'
         else if ( $modifier = $mustache:unesc )       then 'utag'
         else if ( $modifier = $mustache:descendants ) then 'rtag'
         else if ( $is-section ) then 'etag'           else 'etag' } (: . notiation not supported yet :)
      {  if ( $modifier = $mustache:comment )
          then $contents/fn:string()
          else if ($modifier = ($mustache:templ,$mustache:unesc,$mustache:descendants)) 
                   then attribute name { $normalized-contents }  
                   else if ( $is-section )
                        then attribute name { $normalized-contents } (: . notiation not supported yet :)
                        else attribute name { $normalized-contents } }
    case text() return $node
    default return $node };

(: credit: http://www.xqueryfunctions.com/xq/functx_escape-for-regex.html :)
declare function mustache:escape-for-regexp( $strings ) {
  for $s in $strings return fn:replace($s,'(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))','\\$1') };

declare function mustache:r-mustache( $modifiers, $quantifier ) {
  mustache:r-mustache( $modifiers, $quantifier, $mustache:r-tag) } ;

declare function mustache:r-mustache( $modifiers, $quantifier, $r-tag ) {
  fn:concat( 
    mustache:group( mustache:escape-for-regexp( $mustache:otag ) ), 
    mustache:group( $modifiers, $quantifier), 
    $r-tag,
    mustache:group( mustache:escape-for-regexp( $mustache:ctag ) ) ) };

declare function mustache:group( $r ) {
  mustache:group($r, '') };

declare function mustache:group( $r, $quantifier ) {
    fn:concat("(", $r, ")", $quantifier) } ;