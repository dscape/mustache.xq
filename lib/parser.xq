(:
  XQuery Recursive Descent Parser for mustache

  Copyright 2011 John Snelson 
  twitter: @jpcs
:)
xquery version "3.0";
module namespace parser = "parser.xq";
declare default function namespace "parser.xq";

declare variable $parser:_EOF_ := 0;
declare variable $parser:_START_SECTION_ := 1;
declare variable $parser:_START_INVERT_ := 2;
declare variable $parser:_START_END_ := 3;
declare variable $parser:_START_VAR_ := 4;
declare variable $parser:_START_COMMENT_ := 5;
declare variable $parser:_START_PARTIAL_ := 6;
declare variable $parser:_START_DELIM_ := 7;
declare variable $parser:_START_TRIPLE_ := 8;
declare variable $parser:_START_UNESCAPE_ := 9;
declare variable $parser:_START_EXT_ := 10;
declare variable $parser:_END_ := 11;
declare variable $parser:_STRING_ := 12;

declare function parse( $template ) {
   parseContent($template, "{{", "}}")
};

declare function parseContent($in as xs:string?, $sd as xs:string, $ed as xs:string)
{
   let $r      := nextToken( $in, $sd, $ed )
   let $token  := $r/@token/fn:number()
   let $remain := $r/@remain/fn:string()
   return
     if($token eq $parser:_EOF_) then
       element multi { attribute remain { "" } }
     else if($token eq $parser:_START_SECTION_ or
             $token eq $parser:_START_INVERT_) then
       let $r1 := parseSection( $remain, $token, $sd, $ed )
       let $r2 := parseContent( $r1/@remain, $sd, $ed )
       return element multi { $r2/@remain, $r1/node(), $r2/node() }
     else if($token eq $parser:_START_VAR_ or
             $token eq $parser:_START_EXT_ or
             $token eq $parser:_START_COMMENT_ or
             $token eq $parser:_START_PARTIAL_ or
             $token eq $parser:_START_UNESCAPE_) then
       let $r1 := parseETag( $remain, $token, $sd, $ed )
       let $r2 := parseContent( $r1/@remain, $sd, $ed )
       return element multi { $r2/@remain, $r1/node(), $r2/node() }
     else if($token eq $parser:_START_TRIPLE_) then
       let $r1 := parseETag( $remain, $token, $sd, fn:concat("}", $ed) )
       let $r2 := parseContent( $r1/@remain, $sd, $ed )
       return element multi { $r2/@remain, $r1/node(), $r2/node() }
     else if($token eq $parser:_START_DELIM_) then
       let $r1 := parseDelim( $remain, $sd, fn:concat("=", $ed) )
       let $r2 := parseContent( $r1/@remain, $r1/@start, $r1/@end )
       return element multi { $r2/@remain, $r2/node() }
     else if($token eq $parser:_START_END_) then
       element multi { attribute remain { $remain } }
     else if($token eq $parser:_STRING_) then
       let $r1 := parseContent( $remain, $sd, $ed )
       return element multi { $r1/@remain, element static { $r/@value/fn:string() }, $r1/node() }
     else error($r)
};

declare function token($token, $in, $length)
{
  <token token="{$token}" value="{fn:substring($in,1,$length)}"
    remain="{fn:substring($in, $length + 1)}"/>
};

declare function nextToken($in as xs:string?, $sdelim, $edelim)
{
  nextToken_($in, $sdelim, $edelim)
};

declare function nextToken_($in as xs:string?, $sdelim as xs:string, $edelim as xs:string)
{
  if(fn:starts-with($in, $sdelim)) then
    let $nextc := fn:substring($in, 3, 1)
    let $slen := fn:string-length($sdelim)
    return
      if($nextc eq "#") then token($parser:_START_SECTION_, $in, $slen + 1)
      else if($nextc eq "^") then token($parser:_START_INVERT_, $in, $slen + 1)
      else if($nextc eq "/") then token($parser:_START_END_, $in, $slen + 1)
      else if($nextc eq "!") then token($parser:_START_COMMENT_, $in, $slen + 1)
      else if($nextc eq ">") then token($parser:_START_PARTIAL_, $in, $slen + 1)
      else if($nextc eq "=") then token($parser:_START_DELIM_, $in, $slen + 1)
      else if($nextc eq "{") then token($parser:_START_TRIPLE_, $in, $slen + 1)
      else if($nextc eq "&amp;") then token($parser:_START_UNESCAPE_, $in, $slen + 1)
      else if($nextc eq "*") then token($parser:_START_EXT_, $in, $slen + 1)
      else token($parser:_START_VAR_, $in, $slen)
  else if(fn:starts-with($in, $edelim)) then
    token($parser:_END_, $in, fn:string-length($edelim))
  else
    let $ls := fn:string-length(fn:substring-before($in, $sdelim))
    let $le := fn:string-length(fn:substring-before($in, $edelim))
    let $li := fn:string-length($in)
    return
      if($ls ne 0 and $ls lt $le) then token($parser:_STRING_, $in, $ls)
      else if($le ne 0) then token($parser:_STRING_, $in, $le)
      else if($li ne 0) then token($parser:_STRING_, $in, $li)
      else token($parser:_EOF_, "", 0)
};

declare function error($token)
{
  fn:error(xs:QName("parser:ERR001"),
    fn:concat("Unexpected token: """, $token/@value, """"))
};

declare function parseSection($in as xs:string?, $n, $sd as xs:string, $ed as xs:string)
{
   let $r      := nextToken($in, $sd, $ed)
   let $token  := $r/@token/fn:number()
   let $remain := $r/@remain/fn:string()
   return
     if($token eq $parser:_STRING_) then
       let $r2      := nextToken($remain, $sd, $ed)
       let $token2  := $r2/@token/fn:number()
       let $remain2 := $r2/@remain/fn:string()
       return
         if($token2 eq $parser:_END_) then
           let $r3      := parseContent($remain2, $sd, $ed)
           let $r4      := nextToken($r3/@remain, $sd, $ed)
           let $token4  := $r4/@token/fn:number()
           let $remain4 := $r4/@remain/fn:string()
           return
             if($r4/@value ne $r/@value) then
               fn:error(xs:QName("parser:ERR002"),
                 fn:concat("mismatched sections: ", $r/@value, " and ", $r4/@value))
             else
               let $r5 := nextToken($remain4, $sd, $ed)
               let $token5 := $r5/@token/fn:number()
               let $remain5 := $r5/@remain/fn:string()
               return
                 if($token5 eq $parser:_END_) then
                   element multi {
                     attribute remain { $remain5 },
                     element {
                       if($n eq $parser:_START_SECTION_) then "section"
                       else "inverted-section"
                     } {
                       attribute name { fn:normalize-space($r/@value) },
                       $r3/node()
                     }
                   }
                 else error($r5)
         else error($r2)
     else error($r)
};

declare function parseDotNotation($n, $name)
{
  let $before := fn:substring-before($name, ".")
  let $after := fn:substring-after($name, ".")
  return if($before and $after) then
    element section {
      attribute name { $before },
      parseDotNotation($n, $after)
    }
  else
    element {
      if($n eq $parser:_START_VAR_) then 'etag'
      else if($n eq $parser:_START_EXT_) then 'rtag'
      else "utag"
    } {
      attribute name { $name }
    }
};

declare function parseETag($in as xs:string?, $n, $sd as xs:string, $ed as xs:string) {
   let $r := nextToken($in, $sd, $ed)
   let $token := $r/@token/fn:number()
   let $remain := $r/@remain/fn:string()
   return
     if($token eq $parser:_STRING_) then
       let $r2 := nextToken($remain, $sd, $ed)
       let $token2 := $r2/@token/fn:number()
       let $remain2 := $r2/@remain/fn:string()
       let $name := fn:normalize-space($r/@value)
       return
         if($token2 eq $parser:_END_) then
           element multi {
             attribute remain { $remain2 },
             if($n eq $parser:_START_VAR_ or
                $n eq $parser:_START_EXT_ or
                $n eq $parser:_START_UNESCAPE_ or
                $n eq $parser:_START_TRIPLE_) then
               parseDotNotation($n, $name)
             else if($n eq $parser:_START_COMMENT_) then
               element comment { text{ $r/@value } }
             else
               element partial { attribute name { $name } }
           }
         else error($r2)
     else error($r)
};

declare function parseDelim($in as xs:string?, $sd as xs:string, $ed as xs:string) {
   let $r := nextToken($in, $sd, $ed)
   let $token := $r/@token/fn:number()
   let $remain := $r/@remain/fn:string()
   return
     if($token eq $parser:_STRING_) then
       let $r2 := nextToken($remain, $sd, $ed)
       let $token2 := $r2/@token/fn:number()
       let $remain2 := $r2/@remain/fn:string()
       return
         if($token2 eq $parser:_END_) then
           let $delims := fn:tokenize(fn:normalize-space($r/@value), "\s+")
           return
             if(fn:count($delims) ne 2) then
               fn:error(xs:QName("parser:ERR003"),
                 fn:concat("Invalid delimeter syntax: """, $r/@value, """"))
             else element delims {
               attribute remain { $remain2 },
               attribute start { $delims[1] },
               attribute end { $delims[2] }
             }
         else error($r2)
     else error($r)
};
