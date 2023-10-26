# UWasm
Repository for presenting the work of our team on the Web Assembly interpreter on Urbit.

## Usage
The repo contains two main parts: `wasm` desk for Urbit and jet testbed.

### `wasm` desk
To use `wasm` desk:
1. Make a new desk (e.g. `|new-desk %wasm`) and mount it;
2. Clone the repo and copy the contents to your new desk;
3. `|commit` the desk
4. Run `-test /=wasm=/tests ~` to run the unit tests.

The interpreter includes:
 - `.wasm` binary file parser `wasm-to-ast.hoon`
 - Main interpreter engine `ast-interpreter.hoon`
 - Structure file `sur/wasm.hoon` with type definitions
 - and other files, like a library for a subset of operators and `.wasm` files for the unit tests

The tests include both simple functions for numerical arithmetics and a bit more elaborated one for string manipulations. The interpreter is still a work in progress, so some instruction definitions might be missing in the interpreter, nor do the modules get parsed completely (imports are ignored)

### Jet testbed
The jet testbed includes our Vere build that imports [wasm3](https://github.com/wasm3/wasm3) Web Assembly interpreter in C. It also has its own `base` and `wasm` desks. We use `++was` function defined in `hoon.hoon` for jet testing purposes. We haven't had enough time to turn it into a full jet, but some tests still could be run to verify that the interface between Vere and wasm3 works.

To use the jet testbed:
1. Checkout branch `add-wasm3` and build Vere: `bazel build :urbit`
2. Boot a fakezod: `./vere/bazel-bin/pkg/vere/urbit -F dev`
3. Mount `%base` desk. Make and mount `%wasm` desk
4. Copy the contents from respective directories and `|commit` them

Now you can run the tests with `-test`, and you can test the performance by evaluating Ackermann function in UWasm, the jet and in native Hoon (without caching).
