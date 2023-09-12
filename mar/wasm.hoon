::
::::  /hoon/atom/mar
  ::
/?    310
::
::::  wasm - just an atom
  ::
=,  mimes:html
|_  wasm=@
++  grab  |%
          ++  noun  @
          ++  mime  |=([* p=octs] q.p)
          --
++  grow  |%
          ++  mime  [/application/x-urb-unknown (as-octs wasm)]
          --
++  grad  %mime
--
