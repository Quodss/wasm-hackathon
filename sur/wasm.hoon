|%
+$  valtype
  $?  %f64
      %i64
      %f32
      %i32
  ==
::
+$  module  (map section-name section)
::
+$  section
  $+  section
  $%  type-section
      function-section
      code-section
      export-section
  ==
::
+$  section-name
  $+  section-name
  $?  %type-section
      %code-section
      %function-section
      %export-section
  ==
::  Type section
::
+$  type-section
  $+  type-section
  $:  %type-section
      num-types=@
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
  $:  %code-section
      num-functions=@
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
  ==  
::  Function section
::
+$  function-section
  $+  function-section
  $:  %function-section
      num-functions=@
      function-types=(list @)
  ==
::  Export section
::
+$  export-section
  $+  export-section
  $:  %export-section
      exports=(map @tas export-desc)
  ==
::
+$  export-desc
  $%  [%func i=@]
      [%table i=@]
      [%memory i=@]
      [%global i=@]
  ==
--