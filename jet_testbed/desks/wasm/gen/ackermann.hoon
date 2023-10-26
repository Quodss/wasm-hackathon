::  %say generator without arguments, used for testing
::
/-  *wasm
/+  ast-interpreter
/+  wasm-to-ast
/+  handle=handle-operators
/*  bin-wasm  %wasm  /acker/wasm
:: /*  bin-wasm  %wasm  /two-functions/wasm
:-  %say  |=  *  :-  %noun  ::  %say generator with no arguments
::  end-to-end Wasm module interpretation pipeline
::
!.
=>
|%
++  wasl  :: was with bin len calculated for you
  =+
  |%
  ++  module-length
    |=  module=@
    ?:  =(module '\00asm\01\00\00\00')
      8
    %+  add  8
    =/  section-lens=(list @)  (rash (rsh [3 8] module) count-bytes)
    (roll section-lens add)
  ::
  ++  count-bytes
    %+  knee  *(list @)
    |.  ~+
    ;~  pose
      ;~(plug ;~(pfix next vec-len) count-bytes)
      ;~(plug ;~(pfix next partial-vec-len) (easy ~))
    ==
  ::
  ++  vec-len
    %+  cook  |=([a=@ b=@] :(add a b 1))
    ;~  size
      (u-n-len 32)
      |=  n=@
      (stun [n n] next)
    ==
  ::
  ++  size
    |*  [vex=edge gat=_=>(rule |*(* *rule))]
    ?~  q.vex
      vex
    %.  [vex (gat +.p.u.q.vex)]
    (comp |*([a=* b=*] a))
  ::
  ++  partial-vec-len
    %+  cook  |=([a=@ b=@] :(add a b 1))
    ;~  size
      (u-n-len 32)
      |=  n=@
      (stun [0 n] next)
    ==
  ::
  ++  u-n-len
    |=  n-bits=@
    =*  this  $
    %+  knee  [`@`0 `@`0]
    |.  ~+
    ;~  pose
      ::  multiple byte case
      ::
      ?:  (lte n-bits 7)  fail
      %+  cook
        |=  [n=@ m=[@ @]]
        ^-  [@ @]
        :-  +(-.m)
        %+  add
          (mul 128 +.m)
        (sub n 128)
      ;~  plug
        (shim 128 255)
        this(n-bits (sub n-bits 7))
      ==
      ::  single byte case
      ::
      ;~(plug (easy 1) (cook ,@ (shim 0 (dec (bex (min n-bits 7))))))
    ==
  --
  |=  [bin=@ fun-id=@ i-args=@ args=@ i-ret=@]
  (was bin (module-length bin) fun-id i-args args i-ret)
::
::::
  ::
--
=+
  =>  (instantiate:ast-interpreter (main:wasm-to-ast bin-wasm))
  ~&  "HWasm (patience please, takes about 1 min...)"
  ~>  %bout
  =-  ~&(- -)
  -:(call-id (find-func-id 'ackermann' module) ~[[%i64 3] [%i64 7]])
=>  +  =+
  =/  funcid=@
    =>  (instantiate:ast-interpreter (main:wasm-to-ast bin-wasm))
    (find-func-id 'ackermann' module)
  ~&  "CWasm"
  ~>  %bout
  =-  ~&(- -)
  =/  [m=@ n=@]  [3 7]
  (wasl bin-wasm funcid 2 (add (lsh [3 8] n) m) 1)
=>  +
~&  "Hoon (no caching)"
~>  %bout
=-  ~&(- -)
%.  [3 7]
|=  [m=@ n=@]
^-  @
:: ~+  no caching for a more fair comparison
?:  =(m 0)  +(n)
?:  =(n 0)  $(m (dec m), n 1)
$(m (dec m), n $(n (dec n)))
