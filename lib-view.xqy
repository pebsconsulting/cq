(:
 : cq: lib-view.xqy
 :
 : Copyright (c)2002-2005 Mark Logic Corporation. All Rights Reserved.
 :
 : Licensed under the Apache License, Version 2.0 (the "License");
 : you may not use this file except in compliance with the License.
 : You may obtain a copy of the License at
 :
 : http://www.apache.org/licenses/LICENSE-2.0
 :
 : Unless required by applicable law or agreed to in writing, software
 : distributed under the License is distributed on an "AS IS" BASIS,
 : WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 : See the License for the specific language governing permissions and
 : limitations under the License.
 :
 : The use of the Apache License does not indicate that this project is
 : affiliated with the Apache Software Foundation.
 :
 :)

module "com.marklogic.xqzone.cq.view"

declare namespace v = "com.marklogic.xqzone.cq.view"

default function namespace = "http://www.w3.org/2003/05/xpath-functions"

import module namespace c = "com.marklogic.xqzone.cq.controller"
  at "lib-controller.xqy"

define variable $g-nbsp as xs:string { codepoints-to-string(160) }
define variable $g-nl { fn:codepoints-to-string((10)) }

define function v:get-xml($x) {
  if (count($x) = 1
    and ($x instance of element() or $x instance of document-node())
  ) then $x
  else element results {
    attribute warning {
      if (empty($x)) then "empty list"
      else if (count($x) = 1) then "non-element node"
      else "more than one node"
    },
    for $i in $x
    return
      if ($i instance of document-node())
      then $i/node()
      else $i
  }
}

define function v:get-html($x) as element() {
  let $body :=
    for $i in $x
    return if ($i instance of document-node()) then $i/node() else $i
  return
    if (count($body) eq 1
      and ($body instance of element())
      and local-name($body) eq 'html')
    then $body
    else
<html xmlns="http://www.w3.org/1999/xhtml">
  <head><title/></head>
  <body bgcolor="white">
{
  if (exists($body)) then $body
  else <i>your query returned an empty sequence</i>
}
  </body>
</html>
}

define function v:get-text($x) { $x }

define function v:get-error-frame-html
($f as element(err:frame), $query as xs:string) as node()* {
  if (exists($f/err:uri))
  then concat("in ", string($f/err:uri))
  else (),
  if (exists($f/err:line))
  then (
    concat("line ", string($f/err:line), ": "),
    (: display the error lines, if it's in a main module :)
    if (exists($f/err:uri)) then ()
    else <div id="error-lines"><code>
    {
      let $line-no := xs:integer($f/err:line)
      for $l at $x in tokenize($query, "\r\n|\r|\n", "m")
      where $x gt ($line-no - 3) and $x lt (3 + $line-no)
      return (
        concat(string($x), ": "),
        element span {
          if ($x eq $line-no) then attribute style { "color: red" } else (),
          $l
        },
        <br/>
      )
    }
    </code></div>,
    <br/>
  )
  else (),

  $f/err:operation/text(),
  <br/>,

  if (exists($f/err:format-string/text()))
  then $f/err:format-string/text()
  else $f/err:code/text(),
  <br/>,

  text { $f/err:data/err:datum },

  (: this may be empty :)
  for $v in $f/err:variables/err:variable
  return (
    element code { concat("$", string($v/err:name)), ":=", data($v/err:value) },
    <br/>
  ),
  <br/>
}

define function v:get-error-html
($db as xs:unsignedLong, $modules as xs:unsignedLong,
 $root as xs:string, $ex as element(err:error),
 $query as xs:string)
 as element()
{
<html xmlns="http://www.w3.org/1999/xhtml">
  <body bgcolor="white">
    <div>
  <b>
  <code>{
    (: display eval-in information :)
    "ERROR: eval-in",
    xdmp:database-name($db), "at",
    concat(
      if ($modules eq 0) then "file" else xdmp:database-name($modules),
      ":", $root
    ),
    <br/>,
    <br/>,
    if (exists($ex/err:format-string/text()))
    then ($ex/err:format-string/text(), <br/>)
    else if (exists($ex/err:code/text()))
    then ($ex/err:code/text(), <br/>)
    else (),
    <br/>,
    <i>Stack trace:</i>, <br/>, <br/>,
    for $f in $ex/err:stack/err:frame
    return v:get-error-frame-html($f, $query),
    <br/>,
    (: for debugging :)
    comment { xdmp:quote($ex) }
  }</code>
  </b>
    </div>
  </body>
</html>
}

define function v:get-eval-label
($db as xs:unsignedLong, $modules as xs:unsignedLong?,
 $root as xs:string?, $name as xs:string?)
 as xs:string
{
  concat(
    xdmp:database-name($db),
    " (",
    if (exists($name)) then $name
    else if ($modules eq 0) then "file:"
    else concat(xdmp:database-name($modules), ":"),
    $root,
    ")"
  )
}


(: lib-view.xqy :)