# Grammar Tests

To run the regression tests use:
```
make -C .. test
```

## Tests
- A `.pass` test is expected to parse successfully. 
- A `.fail` test is expected to fail parsing.

### Trace tests
Testing that a file parses correctly is often not enough. It's important to also test expression precedence. To do that, you can write a `.trace` file for any test. The `--trace` output of the `.trace` file must match that of the test. (The parser is instrumented with trace statements that ignore `(…)` grouping productions, which makes comparing trace output easier.)

#### Example
```
# expression.pass
func $foo() : () {
  1 + 2 * 3
}

# expression.pass.trace
func $foo() : () {
  1 + (2 * 3)
}
```
Notice that running:
```
../was expression.pass --trace
```
and
```
../was expression.pass.trace --trace
```
will both print:
```
...
multiplicative_expression
additive_expression
function_declaration
...
```