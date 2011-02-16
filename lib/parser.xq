(:
  XQuery Recursive Descent Parser for mustache

  Copyright John Snelson 
  twitter: @jpcs
:)
xquery version "1.0" ;
module namespace parser = "parser.xq" ;

declare function parser:parse( $in as xs:string? ) {
   parser:parseContent($in, "{{", "}}") };

declare function parser:nextToken($in as xs:string?, $sdelim, $edelim) {
   if ( fn:starts-with( $in, $sdelim ) )
   then (
     let $nextc := fn:substring( $in, 3, 1 )
     return
       if ( $nextc eq "#" ) 
       then ( <token token="{{{{#" remain="{fn:substring($in, 4)}"/> )
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
       then ( <token token="{$beforeStart}" remain="{substring($in, $ls + 1)}"/> ) 
       else ( <token token="{$beforeEnd}" remain="{substring($in, $le + 1)}"/> ) ) };

declare function parser:parseContent($in as xs:string?, $sd, $ed) {
   let $r      := parser:nextToken( $in, $sd, $ed )
   let $token  := $r/@token/fn:string()
   let $remain := $r/@remain/fn:string()
   return
     if ( $token eq "" ) 
     then (element mustache { attribute remain { "" } }) 
     else if ( $token eq "{{#" ) 
     then (
       let $r1 := parser:parseSection( $remain, $sd, $ed )
       let $r2 := parser:parseContent( $r1/@remain, $sd, $ed )
       return element mustache { $r2/@remain, $r1/node(), $r2/node() } ) 
     else if ( $token eq "{{" ) 
     then (
       let $r1 := parser:parseETag( $remain, $sd, $ed )
       let $r2 := parser:parseContent( $r1/@remain, $sd, $ed )
       return element mustache { $r2/@remain, $r1/node(), $r2/node() } ) 
     else if ( $token eq "{{/" ) 
     then (element mustache { attribute remain { $remain } }) 
     else if ( $token eq "}}" ) 
     then ( fn:error( (), "bad content }}" ) ) 
     else (
       let $r1 := parser:parseContent( $remain, $sd, $ed )
       return element mustache { $r1/@remain, text { $token }, $r1/node() } ) };

declare function parser:parseSection($in as xs:string?, $sd, $ed)
{
   let $r      := parser:nextToken($in, $sd, $ed)
   let $token  := $r/@token/fn:string()
   let $remain := $r/@remain/fn:string()
   return
     if ( $token eq "" ) 
     then ( fn:error( (), "no tokens" ) ) 
     else if ( $token eq "{{#" ) 
     then ( fn:error( (), "bad start section {{#" ) ) 
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
           let $token4 := $r4/@token/string()
         let $remain4 := $r4/@remain/string()
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
                 else element mustache {
                   attribute remain { $remain5 },
                   element section {
                     attribute name { $token },
                     $r3/node() } } ) ) ) };

declare function parser:parseETag($in as xs:string?, $sd, $ed) {
   let $r := parser:nextToken($in, $sd, $ed)
   let $token := $r/@token/fn:string()
   let $remain := $r/@remain/fn:string()
   return
     if ( $token eq "" ) 
     then ( fn:error((), "no tokens") ) 
     else if ( $token eq "{{#" ) 
     then ( fn:error((), "bad subst {{#" ) ) 
     else if ( $token eq "{{"  ) then ( fn:error((), "bad subst {{") ) 
     else if ( $token eq "{{/" ) then ( fn:error((), "bad subst {{/") ) 
     else if ( $token eq "}}"  ) then ( fn:error((), "bad subst }}") ) 
     else (
       let $r2 := parser:nextToken($remain, $sd, $ed)
       let $token2 := $r2/@token/fn:string()
       let $remain2 := $r2/@remain/fn:string()
     return
       if( $token2 ne "}}" ) 
       then ( fn:error((), "bad subst not }}" ) ) 
       else 
         element mustache {
           attribute remain { $remain2 },
           element etag {
             attribute name { $token } } } ) };