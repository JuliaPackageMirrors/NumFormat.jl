# NumFormat

A way to get around the limitation that `@sprintf` has to take a literal string argument.

Alternatives:
```julia
fmt = "%10d"
n = 1234
s = eval( Expr( :macrocall, symbol( "@sprintf" ), fmt, n ) ) # VERY slow
```

```julia
fmt = "%10d"
n = 1234

l = :( x -> x ) # placeholder lambda
l.args[2].args[2] = Expr( :macrocall, symbol( "@sprintf" ), fmt, :x )
mfmtr = eval(l)

s = mfmtr( n ) # quite fast, but the definition is clunky
```

The idea here is that the package compiles a function for each unique format string within
the `NumFormat.` name space, so repeated use is faster. To avoid the proliferation of
functions, we limit the usage to only 1 argument. Practical consideration
would suggest that only dozens of functions would be created in a session, which
seems manageable.

```julia
using NumFormat

fmt = "%10.3f"
s = sprintf1( fmt, 3.14159 )

fmtrfunc = generate_formatter( fmt ) # this bypass repeated lookup of cached function
s = fmtrfunc( 3.14159 )
```

## Speed

Speed penalty is about 20% for floating point and 30% for integers.

If the formatter is stored and used instead (see the example using `generate_formatter` above),
the speed penalty reduces to 10% for floating point and 15% for integers.

## Commas

If it is just the speed, the lambda solution demonstrated earlier would have sufficed.
This package also supplements the lack of thousand separator e.g. `"%'d"`, `"%'f"`, `"%'s"`.

Note: `"%'s"` behavior is that for small enough floating point (but not too small),
thousand separator would be used. If the number needs to be represented by `"%e"`, no
separator is used.

## Flexible `format` function

This package contains a run-time number formatter `format` function. The keyword arguments
are

* width. Integer
* precision. Integer
* leftjustified. Boolean
* zeropadding. Boolean
* commas. Boolean
* signed. Boolean. Always show +/- sign?
* positivespace. Boolean. Prepend an extra space for positive numbers? (so they align nicely with negative numbers)
* alternative. Boolean. See `#` alternative form explanation in standard printf documentation
* conversion. length=1 string. Default is type dependent. It can be one of `aAeEfFoxX`. See standard
  printf documentation.
