(:
  XQuery Parser for mustache
  Hybrid between proper parser and state machine (regexp)
:)
xquery version "3.0" ;
module namespace parser = "parser.xq" ;

declare namespace s = "http://www.w3.org/2009/xpath-functions/analyze-string" ;

declare variable $parser:otag        := "{{" ;
declare variable $parser:ctag        := "}}" ;
declare variable $parser:oisec       := '^' ;
declare variable $parser:osec        := '#' ;
declare variable $parser:csec        := '/' ;
declare variable $parser:comment     := '!' ;
declare variable $parser:descendants := '*' ;
declare variable $parser:templ       := ('&gt;') ;  (: > :)
declare variable $parser:unesc       := ('{', '&amp;') ;    (: { & :)
declare variable $parser:r-tag       := '\s*((\w|_|\s|\?|!|/|\.|-)+)\s*' ;     (: (\w|[?!\/-])* :)
declare variable $parser:r-osec      := 
  fn:string-join( parser:escape-for-regexp( ( $parser:oisec, $parser:osec ) ), "|" ) ;
declare variable $parser:r-csec      := parser:escape-for-regexp( $parser:csec ) ;
declare variable $parser:r-sec := 
  fn:concat($parser:r-osec, '|', $parser:r-csec) ;

declare variable $parser:r-modifiers := 
  fn:string-join( parser:escape-for-regexp( ( $parser:osec, $parser:oisec, $parser:templ, $parser:unesc, $parser:comment, $parser:descendants ) ), "|" ) ;
declare variable $parser:r-mustaches := 
  parser:r-mustache( $parser:r-modifiers, '*' ) ;
declare variable $parser:r-sections :=
  fn:concat(
    parser:r-mustache( $parser:r-osec, '' ),
    '\s*(.+?)\s*',
    parser:r-mustache( $parser:r-csec, '' ) ) ;

(: ~ parser :)
declare function parser:parse( $template ) {

  let $simple   := <multi> { parser:passthru-simple(fn:analyze-string($template, $parser:r-mustaches)) } </multi>
  let $fixedNestedSections := <multi>{
    let $etagsToBeFixed := $simple/etag [fn:starts-with(@name, $parser:osec) or fn:starts-with(@name, $parser:oisec)]
      return parser:fixSections($simple/*, $etagsToBeFixed, (), () )
  }</multi>
  return $fixedNestedSections };

declare function  parser:fixSections($seq, $etagsToBeFixed, $before, $after ) {
  let $currentSection := $etagsToBeFixed [1]
  return 
    if ($currentSection/@name=$seq/@name)
    then
      let $name           := fn:replace( $currentSection/@name, $parser:r-sec, '')
      let $inv-symbol         := 
      if(fn:replace( $currentSection/@name, fn:concat('(',$parser:r-sec,').*'), '$1')=$parser:oisec)
      then $parser:osec else $parser:oisec
      let $symbol   := if($inv-symbol=$parser:osec) then $parser:oisec else $parser:osec
      let $inverted       := 
        let $node := $seq [ @name = fn:concat( $inv-symbol, $name ) ] [ fn:last() ]
        return if($node is $currentSection) then () else $node
      let $inbetween :=
        let $node := $seq [ @name = fn:concat( $symbol, $name ) ] [ fn:last() ] [./preceding-sibling::etag[1]/@name=fn:concat( '/', $name )]
        return if($node is $currentSection) then () else $node
      let $following-inbetween := ($inbetween, $inbetween/following-sibling::*)
      let $following-inverted := ($inverted, $inverted/following-sibling::*)
      let $closingSection :=
        if ($inverted)
        then 
          $inverted/preceding-sibling::etag [@name=fn:concat( $parser:csec, $name )] [1]
        else if($inbetween)
        then $inbetween/preceding-sibling::etag [@name=fn:concat( $parser:csec, $name )] [1]
        else
        $seq [ fn:matches( @name, fn:concat( $parser:csec , '\s*', $name, '\s*' ) ) ] [ fn:last() ]
      return
        if ( $closingSection )
        then
            let $beforeClose    := $closingSection/preceding-sibling::*,
                $afterClose     := $closingSection/following-sibling::* [if($after) then . << $after[1] else fn:true()] 
                  except (if($following-inverted) then $following-inverted else $following-inbetween),
                $beforeOpen     := $currentSection/preceding-sibling::* [if($before) then . >> $before[fn:last()] else fn:true()],
                $afterOpen      := $currentSection/following-sibling::* ,
                $childs         := $afterOpen intersect $beforeClose
            return 
               ($beforeOpen,
                  element {if(fn:starts-with($currentSection/@name,$parser:osec)) then 'section' else 'inverted-section'}
                   { attribute name {$name},
                parser:fixSections( $childs, ( $etagsToBeFixed except $currentSection ), $currentSection,  $closingSection )
                 }
              , 
              if ($following-inverted) 
              then parser:fixSections( $following-inverted, 
                $following-inverted[fn:starts-with(@name, $parser:osec) or fn:starts-with(@name, $parser:oisec)],
                $following-inverted,$following-inverted[fn:last()] ) 
              else if ($following-inbetween)
               then parser:fixSections( $following-inbetween, 
                $following-inbetween[fn:starts-with(@name, $parser:osec) or fn:starts-with(@name, $parser:oisec)],
                $following-inbetween,$following-inbetween[fn:last()] )
                else (),
              parser:fixSections( $afterClose,
                $afterClose[fn:starts-with(@name, $parser:osec) or fn:starts-with(@name, $parser:oisec)],
                $afterClose,$afterClose[fn:last()] )
                )
        else fn:error( (),  fn:concat( "no end of section for: ", $name ) )
    else 
    $seq };

declare function parser:passthru-simple( $nodes ) {
  for $node in $nodes/node() return parser:dispatch-simple($node) };

declare function parser:dispatch-simple( $node ) {
  typeswitch($node)
    case element(s:non-match) return <static>{fn:replace($node,'\}', '')}</static>
    case element(s:match) return 
      let $modifier := $node/s:group[@nr=2]
      let $g3       := $node/s:group[@nr=3]
      let $contents := 
        if (fn:matches($modifier, $parser:r-osec))
        then fn:concat($modifier, $g3) else $g3
      let $normalized-contents :=  fn:normalize-space($contents) 
      let $is-section := fn:contains( $normalized-contents, '.' ) and fn:not($normalized-contents='.')
      return 
        if($is-section)
        then 
          let $tokens := fn:tokenize( $normalized-contents, '\.' )
          return parser:build-section-tree($tokens) 
        else element {
         if      ( $modifier = $parser:comment )     then 'comment'
         else if ( $modifier = $parser:templ )       then 'partial'
         else if ( $modifier = $parser:unesc )       then 'utag'
         else if ( $modifier = $parser:descendants ) then 'rtag'
         else 'etag' }
      {  if ( $modifier = $parser:comment )
          then $contents/fn:string()
          else if ($modifier = ($parser:templ,$parser:unesc,$parser:descendants)) 
                   then attribute name { $normalized-contents }  
                   else attribute name { $normalized-contents } }
    case text() return $node
    default return $node };

(: credit: http://www.xqueryfunctions.com/xq/functx_escape-for-regex.html :)
declare function parser:escape-for-regexp( $strings ) {
  for $s in $strings return fn:replace($s,'(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))','\\$1') };

declare function parser:r-mustache( $modifiers, $quantifier ) {
  parser:r-mustache( $modifiers, $quantifier, $parser:r-tag) } ;

declare function parser:r-mustache( $modifiers, $quantifier, $r-tag ) {
  fn:concat( 
    parser:group( parser:escape-for-regexp( $parser:otag ) ), 
    parser:group( $modifiers, $quantifier), 
    $r-tag,
    parser:group( parser:escape-for-regexp( $parser:ctag ) ) ) };

declare function parser:group( $r ) {
  parser:group($r, '') };

declare function parser:group( $r, $quantifier ) {
    fn:concat("(", $r, ")", $quantifier) } ;

declare function parser:build-section-tree($tokens) {
  let $current := $tokens [1]
  let $last    := $tokens [fn:last()]
  return
    if ( $current )
    then 
      let $element-name := if ($current=$last) then 'etag' else 'section'
      return element {$element-name} 
        {attribute name {$current}, parser:build-section-tree($tokens[fn:position()=2 to fn:last()]) }
    else () };
