|%
+$  hex   @ux
+$  nym   @t
+$  word  @t
--
::
|%
++  split-dots
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
++  me
  |_  [tweaked=? width=@ud wordlist=(list word)]
  ::
  ++  decode
    |=  =hex
    ^-  nym
    =/  n-bytes=@ud      (div width 8)
    =/  cs-bits=@ud      (div width 32)
    =/  total-bits=@ud   (add width cs-bits)
    =/  total-words=@ud  (div total-bits 11)
    ::  sha256 of big-endian entropy bytes; shay returns hash with byte[0] as LSB
    =/  hash=@ux         (shay [n-bytes (rev 3 n-bytes hex)])
    ::  checksum = top cs-bits of sha256 byte[0] (the LSB of the hash atom)
    =/  cs=@ux           `@ux`(rsh [0 (sub 8 cs-bits)] (end [3 1] hash))
    ::  combined = entropy bits followed by checksum bits
    =/  combined=@ux     (add (lsh [0 cs-bits] hex) cs)
    ::  extract total-words 11-bit indices, MSB first
    =/  indices=(list @ud)
      =/  acc=(list @ud)  ~
      =/  k=@ud  0
      |-
      ?:  =(k total-words)  (flop acc)
      =/  shift=@ud  (mul 11 (sub (sub total-words 1) k))
      =/  idx=@ud    (dis (rsh [0 shift] combined) 0x7ff)
      $(k +(k), acc [idx acc])
    ::  drop leading zero indices
    =/  trimmed=(list @ud)
      =/  lst=(list @ud)  indices
      |-
      ?~  lst  lst
      ?:  =(0 i.lst)  $(lst t.lst)
      lst
    =/  words=(list tape)
      %+  turn  trimmed
      |=(idx=@ud (trip (snag idx wordlist)))
    =/  prefix=tape  ?:(tweaked "." "..")
    =/  body=tape
      ?~  words  ""
      %-  zing
      :-  i.words
      (turn t.words |=(w=tape (weld "." w)))
    (crip (weld prefix body))
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
    =/  word-tapes=(list tape)  (split-dots rest)
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
    =/  iparts=(list tape)  (split-dots rest)
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
      =/  cparts=(list tape)  (split-dots cand-rest)
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
    =/  word-tapes=(list tape)  (split-dots rest)
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
    =/  parts=(list tape)  (split-dots rest)
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
