::  %say generator without arguments, used for testing
::
/-  *wasm
/+  ast-interpreter-2
/+  wasm-to-ast
/*  bin-wasm  %wasm  /fac/wasm
:: /*  bin-wasm  %wasm  /two-functions/wasm
:-  %say  |=  *  :-  %noun  ::  %say generator with no arguments
::  end-to-end Wasm module interpretation pipeline
:: 
:: %^    call-name.ast-interpreter-2
::     'addTwo'
::   (main:wasm-to-ast bin-wasm) ::  .wasm -> AST parser
:: :~
::   [%i32 1.000]
::   [%i32 50]
:: ==
~>  %bout
%^    call-name.ast-interpreter-2
    'fac'
  (main:wasm-to-ast bin-wasm) ::  .wasm -> AST parser
~[[%f64 .~100]]





