|%
+$  valtype
  $?  %f64
      %i64
      %f32
      %i32
  ==
::
+$  module
  $:
    type-section=(unit type-section)
    code-section=(unit code-section)
    function-section=(unit function-section)
    export-section=(unit export-section)
  ==
::  Type section
::
+$  type-section
  $+  type-section
  $:  num-types=@
      types=(list func-type)
  ==
::
+$  func-type
  $:  num-params=@
      params=(list valtype)
      num-results=@
      results=(list valtype)
  ==
::  Code section
::
+$  code-section
  $+  code-section
  $:  num-functions=@
      functions=(list function-body)
  ==
+$  function-body
  $:  locals=(list valtype)
      expressions=(list expression)
  ==
::
+$  expression
  $%
    [%local-get @]
    [%local-set @]
    [%i32-add ~]
    [%end ~]
  ==  
::  Function section
::
+$  function-section
  $+  function-section
  $:  num-functions=@
      function-types=(list @)
  ==
::  Export section
::
+$  export-section
  $+  export-section
  $:  num-exports=@
      exports=(map @t export-desc)
  ==
::
+$  export-desc
  $%  [%func i=@]
      [%table i=@]
      [%memory i=@]
      [%global i=@]
  ==
--