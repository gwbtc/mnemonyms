/+  *test, *mnemonyms, ju=json-utils
/*  english  %txt  /fil/wordlists/english/txt
/*  test-vectors  %json  /fil/test-vectors/json
::
=>
|%
++  mock-hex   0xaa00.da3a.78a5.e2b7.ca84.5ad3.2c2f.339e
++  mock-ship  `@p`mock-hex
::
++  mock-tweaked-nym
  '.motifs.adage.fatigued.unheard.deploys.demure.beheads.explain.relaunch.designs.reduce.compares'
++  mock-untweaked-nym
  '..motifs.adage.fatigued.unheard.deploys.demure.beheads.explain.relaunch.designs.reduce.compares'
::
++  mock-four-word-nym-tweaked
  '.motifs.adage..reduce.compares'
++  mock-two-word-nym-tweaked
  '.motifs...compares'
++  mock-incomplete-nym-tweaked
  '.motifs.adage.fatigued.unheard.deploys.demu'
++  mock-partial-nym-tweaked
  '.motifs.adage.fatigued.unheard.deploys.demure'
::
++  mock-four-word-nym-untweaked
  '..motifs.adage..reduce.compares'
++  mock-two-word-nym-untweaked
  '..motifs...compares'
++  mock-incomplete-nym-untweaked
  '..motifs.adage.fatigued.unheard.deploys.demu'
++  mock-partial-nym-untweaked
  '..motifs.adage.fatigued.unheard.deploys.demure'
--
::
|%
++  test-bad-config-tweak-untweaked
  %-  expect-fail
  |.((~(validate me [.n 128 english]) mock-tweaked-nym))
::
++  test-bad-config-tweak-tweaked
  %-  expect-fail
  |.((~(validate me [.y 128 english]) mock-untweaked-nym))
::
++  test-bad-config-width-untweaked
  %-  expect-fail
  |.((~(validate me [.n 256 english]) mock-untweaked-nym))
::
++  test-bad-config-width-tweaked
  %-  expect-fail
  |.((~(validate me [.y 256 english]) mock-tweaked-nym))
::
++  test-ship-untweaked
  %+  expect-eq
    !>  mock-ship
    !>  (~(ship me [.n 128 english]) mock-untweaked-nym)
::
++  test-ship-tweaked
  %+  expect-eq
    !>  mock-ship
    !>  (~(ship me [.y 128 english]) mock-tweaked-nym)
::
++  test-name-untweaked
  %+  expect-eq
    !>  mock-untweaked-nym
    !>  (~(name me [.n 128 english]) mock-ship)
::
++  test-name-tweaked
  %+  expect-eq
    !>  mock-tweaked-nym
    !>  (~(name me [.y 128 english]) mock-ship)
::
++  test-four-word-untweaked
  %+  expect-eq
    !>  mock-four-word-nym-untweaked
    !>  (~(foreshorten me [.n 128 english]) mock-untweaked-nym)
::
++  test-four-word-tweaked
  %+  expect-eq
    !>  mock-four-word-nym-tweaked
    !>  (~(foreshorten me [.y 128 english]) mock-tweaked-nym)
::
++  test-two-word-untweaked
  %+  expect-eq
    !>  mock-two-word-nym-untweaked
    !>  (~(abridge me [.n 128 english]) mock-untweaked-nym)
::
++  test-two-word-tweaked
  %+  expect-eq
    !>  mock-two-word-nym-tweaked
    !>  (~(abridge me [.y 128 english]) mock-tweaked-nym)
::
++  test-decode-untweaked
  %+  expect-eq
    !>  mock-untweaked-nym
    !>  (~(decode me [.n 128 english]) mock-hex)
::
++  test-decode-tweaked
  %+  expect-eq
    !>  mock-tweaked-nym
    !>  (~(decode me [.y 128 english]) mock-hex)
::
++  test-encode-untweaked
  %+  expect-eq
    !>  mock-hex
    !>  (~(encode me [.n 128 english]) mock-untweaked-nym)
::
++  test-encode-tweaked
  %+  expect-eq
    !>  mock-hex
    !>  (~(encode me [.y 128 english]) mock-tweaked-nym)
::
++  test-complete-nym-untweaked
  %+  expect-eq
    !>  `mock-untweaked-nym
    !>  (~(complete me [.n 128 english]) mock-incomplete-nym-untweaked [mock-untweaked-nym]~)
::
++  test-complete-nym-tweaked
  %+  expect-eq
    !>  `mock-tweaked-nym
    !>  (~(complete me [.y 128 english]) mock-incomplete-nym-tweaked [mock-tweaked-nym]~)
::
++  test-grow-nym-untweaked
  %+  expect-eq
    !>  `mock-partial-nym-untweaked
    !>  (~(grow me [.n 128 english]) mock-incomplete-nym-untweaked)
::
++  test-grow-nym-tweaked
  %+  expect-eq
    !>  `mock-partial-nym-tweaked
    !>  (~(grow me [.y 128 english]) mock-incomplete-nym-tweaked)
::
++  test-validate-nym-untweaked
  %+  expect-eq
    !>  .y
    !>  (~(validate me [.n 128 english]) mock-untweaked-nym)
::
++  test-validate-nym-tweaked
  %+  expect-eq
    !>  .y
    !>  (~(validate me [.y 128 english]) mock-tweaked-nym)
::
++  test-vectors-round-trip-untweaked
  ^-  tang
  ?>  ?=([%o *] test-vectors)
  =/  lang-json=json
    (need (~(get by p.jon.test-vectors) 'english'))
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
::
++  test-vectors-round-trip-tweaked
  ^-  tang
  ?>  ?=([%o *] test-vectors)
  =/  lang-json=json
    (need (~(get by p.jon.test-vectors) 'english'))
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
  =/  nym-tape=tape  (trip nym-cord)
  ?>  ?=(^ nym-tape)
  ?>  ?=(^ t.nym-tape)
  ?>  =('.' i.nym-tape)
  ?>  =('.' i.t.nym-tape)
  =/  tweaked-nym-cord=@t  (crip ['.' t.t.nym-tape])
  =/  width=@ud      (mul 4 (lent (trip hex-cord)))
  =/  hex-num=@ux
    =/  tep  (trip hex-cord)
    =|  acc=@ux
    |-  ^-  @ux
    ?~  tep  acc
    =/  d=@ux  ?.((gth i.tep '9') (sub i.tep '0') (sub i.tep 87))
    $(tep t.tep, acc (add (lsh [2 1] acc) d))
  =/  nymer          ~(. me [.y width english])
  =/  nym-from-hex=nym  (decode:nymer hex-num)
  =/  hex-from-nym=hex  (encode:nymer tweaked-nym-cord)
  ;:  weld
    (expect-eq !>(tweaked-nym-cord) !>(nym-from-hex))
    (expect-eq !>(hex-num) !>(hex-from-nym))
  ==
--
