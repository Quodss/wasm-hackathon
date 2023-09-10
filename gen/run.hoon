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
    type-section=`[1 ~[[2 ~[%i32 %i32] 1 ~[%i32]]]]
    code-section=`[1 ~[function-body]]
    function-section=`[0 ~[0]]
    export-section=`(my ~[['add-two-numbers' %func 0]])
  ==
(draft-interpret-module.wasm 'add-two-numbers' module-test ~[10 2])