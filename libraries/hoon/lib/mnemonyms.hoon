::
::  helper core
|%
+$  nym    @t
+$  word   @t
+$  hex    @ux
+$  width  @ud
::
++  split-by-dots
  ::  XX refactor to use Hoon's built-in parsing
  |=  t=tape
  ^-  (list tape)
  =|  cur=tape
  =|  acc=(list tape)
  |-
  ?~  t  (flop [(flop cur) acc])
  ?:  =('.' i.t)
    $(t t.t, cur ~, acc [(flop cur) acc])
  $(t t.t, cur [i.t cur])
::
++  count-bytes
  |=  =width
  ^-  @ud
  (div width 8)
::
++  count-cs-lent
  |=  =width
  ^-  @ud
  (div width 32)
::
++  count-total-bits
  |=  =width
  ^-  @ud
  (add width (count-cs-lent width))
::
++  count-total-words
  |=  bits=@ud
  ^-  @ud
  (div bits 11)
::
::  sha256 of big-endian entropy bytes;
::  shay returns hash with byte[0] as LSB
++  sha256-hash
  |=  [=hex =width]
  (shay [(count-bytes width) (rev 3 (count-bytes width) hex)])
::
::  top .cs-lent bits of (sha256-hash (LSB of hex))
++  derive-checksum
  |=  [=hex =width]
  ^-  @ux
  (rsh [0 (sub 8 (count-cs-lent width))] (end [3 1] (sha256-hash hex width)))
::
::  entropy bits followed by checksum bits
++  concat-eny-cs
  |=  [=hex =width]
  ^-  @ux
  (add (lsh [0 (count-cs-lent width)] hex) (derive-checksum hex width))
::
++  get-idx
  |=  [tot=@ud com=@ux k=@ud]
  ^-  @ud
  ::  0x7ff = 2.047
  (dis (rsh [0 (mul 11 (sub (dec tot) k))] com) 0x7ff)
--
::
::  mnemonym core
|%
++  me
  |_  [tweaked=? =width wordlist=(list word)]
  ::
  ++  decode
    |=  =hex
    ^-  nym
    =/  combined=@ux  (concat-eny-cs hex width)
    =/  total=@ud     (count-total-words (count-total-bits width))
    ::  get words
    =/  words=(list tape)
      %-  turn
      :_  ::  get index from wordlist
          |=  idx=@ud
          %-  trip
          %+  snag
            idx
          wordlist
      ^-  (list @ud)
      ::  drop leading zero indices
      =/  indices=(list @ud)
        ::  extract 11-bit indices
        %-  flop
        %+  roll
          (gulf 0 (dec total))
        |=  [k=@ud acc=(list @ud)]
        [(get-idx total combined k) acc]
      |-
      ?~  indices
        indices
      ?:  =(0 i.indices)
        $(indices t.indices)
      indices
    ::
    ::  format string
    %-  crip
    %+  welp
      ?:(tweaked "." "..")
    ?~  words
      ""
    %-  zing
    :-  i.words
    (turn t.words |=(w=tape (weld "." w)))
  ::
  ++  encode
    |=  =nym
    ^-  hex
    =/  nym-tape=tape  (trip nym)
    ::  prove at least two chars exist so type system allows t.t access
    ?.  ?=(^ nym-tape)  !!
    ?.  ?=(^ t.nym-tape)  !!
    =/  is-double=?  ?&(=('.' i.nym-tape) =('.' i.t.nym-tape))
    =/  rest=tape
      ?:  is-double  t.t.nym-tape
      ?.  =('.' i.nym-tape)  !!
      t.nym-tape
    =/  word-tapes=(list tape)  (split-by-dots rest)
    =/  n-bytes=@ud      (div width 8)
    =/  cs-bits=@ud      (div width 32)
    =/  total-bits=@ud   (add width cs-bits)
    =/  total-words=@ud  (div total-bits 11)
    =/  n-words=@ud      (lent word-tapes)
    =/  leading-zeros=@ud  (sub total-words n-words)
    =/  word-indices=(list @ud)
      %+  turn  word-tapes
      |=  wt=tape
      (need (find ~[(crip wt)] wordlist))
    =/  all-indices=(list @ud)
      (weld (reap leading-zeros 0) word-indices)
    ::  rebuild combined atom from indices, MSB first
    =/  combined=@ux
      %+  roll  all-indices
      |=  [idx=@ud acc=@ux]
      (add (lsh [0 11] acc) idx)
    =/  entropy=@ux      `@ux`(rsh [0 cs-bits] combined)
    =/  actual-cs=@ux    `@ux`(dis combined (dec (lsh [0 cs-bits] 1)))
    =/  hash=@ux         (shay [n-bytes (rev 3 n-bytes entropy)])
    =/  expected-cs=@ux  `@ux`(rsh [0 (sub 8 cs-bits)] (end [3 1] hash))
    ?>  =(actual-cs expected-cs)
    entropy
  ::
  ++  complete
    |=  [query=nym nyms=(list nym)]
    ^-  (unit nym)
    =/  nym-tape=tape  (trip query)
    ?.  ?=(^ nym-tape)  ~
    ?.  =('.' i.nym-tape)  ~
    ?.  ?=(^ t.nym-tape)  ~
    =/  is-double=?  =('.' i.t.nym-tape)
    =/  rest=tape  ?:(is-double t.t.nym-tape t.nym-tape)
    =/  iparts=(list tape)  (split-by-dots rest)
    ?.  ?=(^ iparts)  ~
    |-  ^-  (unit nym)
    ?~  nyms  ~
    =/  cand=nym  i.nyms
    =/  cand-tape=tape  (trip cand)
    =/  match=?
      ?.  ?=(^ cand-tape)  .n
      ?.  =('.' i.cand-tape)  .n
      ?.  ?=(^ t.cand-tape)  .n
      =/  cand-is-double=?  =('.' i.t.cand-tape)
      =/  cand-rest=tape  ?:(cand-is-double t.t.cand-tape t.cand-tape)
      =/  cparts=(list tape)  (split-by-dots cand-rest)
      =/  ip=(list tape)  iparts
      =/  cp=(list tape)  cparts
      |-  ^-  ?
      ?~  ip  .y
      ?~  cp  .n
      ?~  t.ip
        ::  last word of incomplete: check it is a prefix of the candidate word
        =/  fl  i.ip
        =/  cl  i.cp
        |-  ^-  ?
        ?~  fl  .y
        ?~  cl  .n
        ?.  =(i.fl i.cl)  .n
        $(fl t.fl, cl t.cl)
      ::  non-last word: must match exactly
      ?.  =(i.ip i.cp)  .n
      $(ip t.ip, cp t.cp)
    ?:  match  `cand
    $(nyms t.nyms)
  ::
  ++  validate
    |=  =nym
    ^-  ?
    =/  nym-tape=tape  (trip nym)
    ?.  ?=(^ nym-tape)  !!
    ?.  ?=(^ t.nym-tape)  !!
    =/  is-double=?  ?&(=('.' i.nym-tape) =('.' i.t.nym-tape))
    =/  nym-tweaked=?  ?&(!is-double =('.' i.nym-tape))
    ?>  =(tweaked nym-tweaked)
    =/  rest=tape
      ?:  is-double  t.t.nym-tape
      ?.  =('.' i.nym-tape)  !!
      t.nym-tape
    =/  word-tapes=(list tape)  (split-by-dots rest)
    =/  n-bytes=@ud      (div width 8)
    =/  cs-bits=@ud      (div width 32)
    =/  total-bits=@ud   (add width cs-bits)
    =/  total-words=@ud  (div total-bits 11)
    =/  n-words=@ud      (lent word-tapes)
    ?>  (lte n-words total-words)
    =/  leading-zeros=@ud  (sub total-words n-words)
    =/  word-indices=(list @ud)
      %+  turn  word-tapes
      |=  wt=tape
      (need (find ~[(crip wt)] wordlist))
    =/  all-indices=(list @ud)
      (weld (reap leading-zeros 0) word-indices)
    =/  combined=@ux
      %+  roll  all-indices
      |=  [idx=@ud acc=@ux]
      (add (lsh [0 11] acc) idx)
    =/  entropy=@ux      `@ux`(rsh [0 cs-bits] combined)
    =/  actual-cs=@ux    `@ux`(dis combined (dec (lsh [0 cs-bits] 1)))
    =/  hash=@ux         (shay [n-bytes (rev 3 n-bytes entropy)])
    =/  expected-cs=@ux  `@ux`(rsh [0 (sub 8 cs-bits)] (end [3 1] hash))
    ?>  =(actual-cs expected-cs)
    .y
  ::
  ++  grow
    |=  =nym
    ^-  (unit ^nym)
    =/  nym-tape=tape  (trip nym)
    ?.  ?=(^ nym-tape)  ~
    ?.  =('.' i.nym-tape)  ~
    ?.  ?=(^ t.nym-tape)  ~
    =/  is-double=?  =('.' i.t.nym-tape)
    =/  prefix=tape  ?:(is-double ".." ".")
    =/  rest=tape    ?:(is-double t.t.nym-tape t.nym-tape)
    =/  parts=(list tape)  (split-by-dots rest)
    ?.  ?=(^ parts)  ~
    =/  n=@ud  (lent parts)
    =/  fragment=tape
      =/  lst  parts
      |-  ^-  tape
      ?~  t.lst  i.lst
      $(lst t.lst)
    =/  matches=(list word)
      %+  skim  wordlist
      |=  w=word
      =/  wt=tape  (trip w)
      ?:  (gth (lent fragment) (lent wt))  .n
      =((scag (lent fragment) wt) fragment)
    ?.  =(1 (lent matches))  ~
    =/  completed=tape  (trip (snag 0 matches))
    =/  new-parts=(list tape)
      =/  lst  parts
      |-  ^-  (list tape)
      ?~  t.lst  ~[completed]
      [i.lst $(lst t.lst)]
    =/  body=tape
      ?~  new-parts  ""
      %-  zing
      :-  i.new-parts
      (turn t.new-parts |=(w=tape (weld "." w)))
    `(crip (weld prefix body))
  --
--
