/+  *test
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
|%
++  test-fake-wasm  ^-  tang
  ;:  weld
    %+  expect-eq  :: adds the two given integers
      !>  85
      !>  %:  wasl
            ::  (binary as an atom)
              668.826.888.689.520.551.499.115.249.026.664.429.
              225.980.899.322.267.383.540.489.242.412.696.785.
              995.089.807.682.356.787.400.333.713.709.242.838.
              468.989.172.277.504   
            ::
            0  ::  function id
            2  ::  two input values
            774.763.251.095.801.167.915  ::  42 concatenated with 43, 8 bytes each; (add (lsh [3 8] 42) 43)
            1  ::  one output value
          ==
    %+  expect-eq  :: factorial
      !>  3.628.800
      !>  %:  wasl
            ::  (binary as an atom)
              6.762.702.815.395.916.052.031.821.602.802.434.071.
              305.113.807.817.234.344.284.679.086.223.412.621.769.
              846.261.324.830.398.786.592.063.791.334.038.350.671.
              990.878.228.250.565.321.661.662.458.799.470.725.059.
              435.131.609.069.463.048.106.578.155.174.055.624.996.
              986.836.669.520.727.302.128.912.940.439.710.800.446.
              374.065.128.477.836.845.956.581.334.792.012.941.189.
              376
            ::
            0  ::  function id
            1  ::  one input value
            10
            1  ::  one output value
          ==
    %+  expect-eq  :: swaps the two given arguments
      !>  92.233.720.368.547.758.090  :: 5 concatenated with 10; (add (lsh [3 8] 5) 10)
      !>  %:  wasl
            ::  (binary as an atom)
              668.826.888.689.520.551.499.115.022.869.686.990.065.517.759.162.085.995.
              136.111.632.584.837.688.210.227.142.364.495.444.649.482.235.372.166.582.
              795.071.122.530.560
            ::
            0  ::  function id
            2  ::  two input values
            184.467.440.737.095.516.165 :: 10 concatenated with 5; (add (lsh [3 8] 10) 5)
            2  ::  two output value
          ==      
    %+  expect-eq  :: swaps the two given arguments
      !>  10  :: 0 concatenated with 10... which is just 10
      !>  %:  wasl
            ::  (binary as an atom)
              668.826.888.689.520.551.499.115.022.869.686.990.065.517.759.162.085.995.136.
              111.632.584.837.688.210.227.142.364.495.444.649.482.235.372.166.582.795.071.
              122.530.560
            ::
            0  ::  function id
            2  ::  two input values
            184.467.440.737.095.516.160 :: 10 concatenated with 0; (add (lsh [3 8] 10) 0)
            2  ::  two output value
          ==   
    %+  expect-eq  :: the third function swaps the two given arguments
      !>  10  :: 0 concatenated with 10... which is just 10
      !>  %:  wasl
            ::  (binary as an atom)
              71.069.361.211.483.351.775.326.927.971.172.037.215.480.315.275.578.160.524.
              250.188.789.246.872.543.037.099.561.961.643.642.685.600.228.182.364.567.472.
              229.126.803.387.580.181.640.146.859.103.922.869.871.140.742.251.097.062.839.
              798.657.097.751.455.860.871.489.675.514.039.923.390.405.842.079.797.436.672
            ::
            2  ::  function id
            2  ::  two input values
            184.467.440.737.095.516.160 :: 10 concatenated with 0; (add (lsh [3 8] 10) 0)
            2  ::  two output value
          ==   
  ==
--