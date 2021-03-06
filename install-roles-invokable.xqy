xquery version "1.0-ml";
(:
 : cq
 :
 : Copyright (c) 2002-2011 MarkLogic Corporation. All Rights Reserved.
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
 :)

import module namespace sec="http://marklogic.com/xdmp/security"
 at "/MarkLogic/security.xqy";

declare option xdmp:mapping "false";

declare variable $ROLE as element(role) external;

(: check environment :)
if (xdmp:database() eq xdmp:security-database()) then ()
else error(
  (), 'CQ-NOTSECURITY',
  ('Current database', xdmp:database-name(xdmp:database()),
    'is not the security database'))
,
(: ensure existence, but do not configure :)
try {
  let $id := sec:create-role(
    $ROLE/@name,
    $ROLE/@name,
    (),
    (),
    ()
  )
  return text { 'role', $ROLE/@name, 'installed', current-dateTime() }
} catch ($ex) {
  if ($ex/error:code eq "SEC-ROLEEXISTS") then ()
  else xdmp:rethrow()
}
,
(: ensure that any uri privileges also exist :)
for $priv in $ROLE/uri-privilege
return try {
  let $id := sec:create-privilege(
    $priv/@name,
    $priv,
    'uri',
    ()
  )
  return text { 'URI privilege', $priv, 'installed', current-dateTime() }
} catch ($ex) {
  if ($ex/error:code eq "SEC-PRIVEXISTS") then ()
  else xdmp:rethrow()
}

(: install-roles-invokable.xqy :)
