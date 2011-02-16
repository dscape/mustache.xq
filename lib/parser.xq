(:
  XQuery Recursive Descent Parser for mustache

  Copyright John Snelson 
  twitter: @jpcs
:)
xquery version "1.0" ;
module namespace parser = "parser.xq" ;

declare function parser:parse( $template ) {
   parser:parseContent($template, "{{", "}}") };

declare function parser:parseContent($in as xs:string?, $sd, $ed) {
   let $r      := parser:nextToken( $in, $sd, $ed )
   let $token  := $r/@token/fn:string()
   let $remain := $r/@remain/fn:string()
   return
     if ( $token eq "" ) 
     then (element multi { attribute remain { "" } }) 
     else if ( $token eq "{{#" or $token eq "{{^") 
     then (
       let $r1 := parser:parseSection( $remain, fn:substring($token,3,1), $sd, $ed )
       let $r2 := parser:parseContent( $r1/@remain, $sd, $ed )
       return element multi { $r2/@remain, $r1/node(), $r2/node() } ) 
     else if ( $token eq "{{" ) 
     then (
       let $r1 := parser:parseETag( $remain, $sd, $ed )
       let $r2 := parser:parseContent( $r1/@remain, $sd, $ed )
       return element multi { $r2/@remain, $r1/node(), $r2/node() } ) 
     else if ( $token eq "{{/" ) 
     then (element multi { attribute remain { $remain } }) 
     else if ( $token eq "}}" ) 
     then ( fn:error( (), "bad content }}" ) ) 
     else (
       let $r1 := parser:parseContent( $remain, $sd, $ed )
       return element multi { $r1/@remain, element static { $token }, $r1/node() } ) };

declare function parser:nextToken($in as xs:string?, $sdelim, $edelim) {
   if ( fn:starts-with( $in, $sdelim ) )
   then (
     let $nextc := fn:substring( $in, 3, 1 )
     return
       if ( $nextc eq "#" ) 
       then ( <token token="{{{{#" remain="{fn:substring($in, 4)}"/> )
       else if ( $nextc eq "^" ) 
       then ( <token token="{{{{^" remain="{fn:substring($in, 4)}"/> )
       else if( $nextc eq "/" ) 
       then ( <token token="{{{{/" remain="{fn:substring($in, 4)}"/> ) 
       else ( <token token="{{{{" remain="{fn:substring($in, 3)}"/> ) )
   else if( fn:starts-with( $in, $edelim ) ) 
   then ( <token token="}}}}" remain="{fn:substring($in, 3)}"/> ) 
   else (
     let $beforeStart := fn:substring-before( $in, $sdelim )
     let $beforeEnd   := fn:substring-before( $in, $edelim )
     let $ls          := fn:string-length( $beforeStart )
     let $le          := fn:string-length( $beforeEnd )
     return
       if( $ls ne 0 and $ls lt $le ) 
       then ( <token token="{$beforeStart}" remain="{fn:substring($in, $ls + 1)}"/> ) 
       else ( <token token="{$beforeEnd}" remain="{fn:substring($in, $le + 1)}"/> ) ) };

declare function parser:parseSection($in as xs:string?, $n, $sd, $ed) {
   let $r      := parser:nextToken($in, $sd, $ed)
   let $token  := $r/@token/fn:string()
   let $remain := $r/@remain/fn:string()
   return
     if ( $token eq "" ) 
     then ( fn:error( (), "no tokens" ) ) 
     else if ( $token eq "{{#" ) 
     then ( fn:error( (), "bad start section {{#" ) )
     else if ( $token eq "{{^" ) 
     then ( fn:error( (), "bad start section {{^" ) )
     else if ( $token eq "{{" ) 
     then ( fn:error( (), "bad start section {{" ) ) 
     else if ( $token eq "{{/" ) 
     then ( fn:error( (), "bad start section {{/" ) ) 
     else if ( $token eq "}}" ) 
     then ( fn:error( (), "bad start section }} ") ) 
     else (
       let $r2 := parser:nextToken($remain, $sd, $ed)
       let $token2 := $r2/@token/fn:string()
       let $remain2 := $r2/@remain/fn:string()
       return
         if ( $token2 ne "}}" )
         then ( fn:error( (), "bad start section not }}" ) ) 
         else (
           let $r3 := parser:parseContent($remain2, $sd, $ed)
           let $r4 := parser:nextToken($r3/@remain, $sd, $ed)
           let $token4 := $r4/@token/fn:string()
         let $remain4 := $r4/@remain/fn:string()
         return
           if($token4 ne $token) 
           then ( fn:error( (), 
             fn:concat( "mismatched sections: ", $token, " and ", $token4 ) ) ) 
             else (
               let $r5 := parser:nextToken($remain4, $sd, $ed)
               let $token5 := $r5/@token/fn:string()
               let $remain5 := $r5/@remain/fn:string()
               return
                 if( $token5 ne "}}" ) 
                 then ( fn:error( (), "bad end section not }}" ) ) 
                 else element multi {
                   attribute remain { $remain5 },
                   element {if($n='#') then 'section' else 'inverted-section'} {
                     attribute name { fn:normalize-space($token) },
                     $r3/node() } } ) ) ) };

declare function parser:parseETag($in as xs:string?, $sd, $ed) {
   let $r := parser:nextToken($in, $sd, $ed)
   let $token := $r/@token/fn:string()
   let $remain := $r/@remain/fn:string()
   return
     if ( $token eq "" )         then ( fn:error((), "no tokens") ) 
     else if ( $token eq "{{#" ) then ( fn:error((), "bad subst {{#" ) ) 
     else if ( $token eq "{{^" ) then ( fn:error((), "bad subst {{^" ) ) 
     else if ( $token eq "{{&amp;" ) then ( fn:error((), "bad subst {{&amp;" ) ) 
     else if ( $token eq "{{<" ) then ( fn:error((), "bad subst {{<" ) ) 
     else if ( $token eq "{{*" ) then ( fn:error((), "bad subst {{*" ) ) 
     else if ( $token eq "{{{" ) then ( fn:error((), "bad subst {{{" ) ) 
     else if ( $token eq "{{!" ) then ( fn:error((), "bad subst {{!" ) ) 
     else if ( $token eq "{{>" ) then ( fn:error((), "bad subst {{>" ) ) 
     else if ( $token eq "{{"  ) then ( fn:error((), "bad subst {{") ) 
     else if ( $token eq "{{/" ) then ( fn:error((), "bad subst {{/") ) 
     else if ( $token eq "}}"  ) then ( fn:error((), "bad subst }}") ) 
     else (
       let $r2 := parser:nextToken($remain, $sd, $ed)
       let $token2 := $r2/@token/fn:string()
       let $remain2 := $r2/@remain/fn:string()
     return
       if( $token2 ne "}}" ) then ( fn:error((), "bad subst not }}" ) ) 
       else 
         let $analyze-string := fn:analyze-string($token, '(>|<|!|\{|&amp;|\*)*\s*(.+)\s*')
         let $name := fn:normalize-space($analyze-string//*:group[@nr=2]/fn:string())
         let $operator := fn:normalize-space($analyze-string//*:group[@nr=1]/fn:string())
         return (element multi {
           attribute remain { $remain2 },
           element {
             if($operator='>' or $operator='<') then 'partial'
             else if($operator='!') then 'comment'
             else if($operator='*') then 'rtag'
             else if($operator='{' or $operator='&amp;') then 'utag'
             else 'etag'
           } 
           { if($operator='!') then text{ $name } else
             attribute name { $name } } } ) ) };