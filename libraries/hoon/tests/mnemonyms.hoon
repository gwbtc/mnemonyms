/+  *test, *mnemonyms, ju=json-utils
/*  english  %txt  /fil/wordlists/english/txt
/*  test-vectors  %json  /fil/test-vectors/json
::
=>
|%
++  mock-hex   0xaa00.da3a.78a5.e2b7.ca84.5ad3.2c2f.339e
++  mock-ship  `@p`mock-hex
++  mock-four-word-nym
  '..offend.adapt..rejects.concludes'
++  mock-two-word-nym
  '..offend...concludes'
++  mock-incomplete-nym
  '..offend.adapt.forsworn.unchained.desire.deprives.bemused.forba'
++  mock-partial-nym
  '..offend.adapt.forsworn.unchained.desire.deprives.bemused.forbade'
++  mock-tweaked-nym
  '.offend.adapt.forsworn.unchained.desire.deprives.bemused.forbade.repay.dethroned.rejects.concludes'
++  mock-untweaked-nym
  '..offend.adapt.forsworn.unchained.desire.deprives.bemused.forbade.repay.dethroned.rejects.concludes'
--
::
|%
++  test-bad-config-tweak
  %-  expect-fail
  |.((~(validate me [.n 128 english]) mock-tweaked-nym))
::
++  test-bad-config-width
  %-  expect-fail
  |.((~(validate me [.n 256 english]) mock-untweaked-nym))
::
++  test-ship
  %+  expect-eq
    !>  mock-ship
    !>  (~(ship me [.n 128 english]) mock-untweaked-nym)
::
++  test-name
  %+  expect-eq
    !>  mock-untweaked-nym
    !>  (~(name me [.n 128 english]) mock-ship)
::
++  test-four-word
  %+  expect-eq
    !>  mock-four-word-nym
    !>  (~(foreshorten me [.n 128 english]) mock-untweaked-nym)
::
++  test-two-word
  %+  expect-eq
    !>  mock-two-word-nym
    !>  (~(abridge me [.n 128 english]) mock-untweaked-nym)
::
++  test-decode
  %+  expect-eq
    !>  mock-untweaked-nym
    !>  (~(decode me [.n 128 english]) mock-hex)
::
++  test-encode
  %+  expect-eq
    !>  mock-hex
    !>  (~(encode me [.n 128 english]) mock-untweaked-nym)
::
++  test-complete-nym
  %+  expect-eq
    !>  `mock-untweaked-nym
    !>  (~(complete me [.n 128 english]) mock-incomplete-nym [mock-untweaked-nym]~)
::
++  test-grow-nym
  %+  expect-eq
    !>  `mock-partial-nym
    !>  (~(grow me [.n 128 english]) mock-incomplete-nym)
::
++  test-validate-nym
  %+  expect-eq
    !>  .y
    !>  (~(validate me [.n 128 english]) mock-untweaked-nym)
::
++  test-vectors-round-trip
  ^-  tang
  ?>  ?=([%o *] test-vectors)
  =/  lang-json=json
    (need (~(get by p.test-vectors) 'english'))
  ?>  ?=([%a *] lang-json)
  %-  zing
  %+  turn  p.lang-json
  |=  pair=json
  ^-  tang
  ?>  ?=([%a *] pair)
  ?>  ?=(^ p.pair)
  ?>  ?=(^ t.p.pair)
  ?>  ?=([%s *] i.p.pair)
  ?>  ?=([%s *] i.t.p.pair)
  =/  hex-cord=@t    p.i.p.pair
  =/  nym-cord=@t    p.i.t.p.pair
  =/  width=@ud      (mul 4 (lent (trip hex-cord)))
  =/  hex-num=@ux
    =/  tep  (trip hex-cord)
    =|  acc=@ux
    |-  ^-  @ux
    ?~  tep  acc
    =/  d=@ux  ?.((gth i.tep '9') (sub i.tep '0') (sub i.tep 87))
    $(tep t.tep, acc (add (lsh [2 1] acc) d))
  =/  nymer          ~(. me [.n width english])
  =/  nym-from-hex=nym  (decode:nymer hex-num)
  =/  hex-from-nym=hex  (encode:nymer nym-cord)
  ;:  weld
    (expect-eq !>(nym-cord) !>(nym-from-hex))
    (expect-eq !>(hex-num) !>(hex-from-nym))
  ==
--
