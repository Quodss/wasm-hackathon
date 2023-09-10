::  %say generator without arguments, used for testing
::
/-  *wasm
/+  wasm
:-  %say  |=  *  :-  %noun
::
=/  =function-body
  :-  ~[%i32 %i32 %i32 %f32]
  :~
    [%local-get 0]
    [%local-set 2]
    [%local-get 1]
    [%local-set 3]
    [%local-get 2]
    [%local-get 3]
    [%i32-add ~]
    [%local-set 2]
    [%local-get 2]
  ==
=/  module-test=module
  :*
    `[1 ~[[2 ~[%i32 %i32] 1 ~[%i32]]]]    ::  type section
    `[1 ~[function-body]]                 ::  code section
    `[0 ~[0]]                             ::  function section
    `(my ~[['add-two-numbers' %func 0]])  ::  export section
  ==
(draft-interpret-module.wasm 'add-two-numbers' module-test ~[10 2])