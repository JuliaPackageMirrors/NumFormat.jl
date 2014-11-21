using NumFormat
using Base.Test

function test_equality()
    println( "test equality...")
    srand(10)
    fmts = ASCIIString[ "%10.4f", "%f", "%e", "%10f", "%.3f", "%.3e" ]
    for fmt in fmts
        l = :( x-> x )
        l.args[2].args[2] = Expr( :macrocall, symbol( "@sprintf" ), fmt, :x )
        mfmtr = eval( l )
        for i in 1:10000
            n = erfinv( rand() * 1.99 - 1.99/2.0 )
            expect = mfmtr( n )
            actual = sprintf1( fmt, n )
            @test expect == actual
        end
    end

    fmts = ASCIIString[ "%d", "%10d", "%010d", "%-10d" ]
    for fmt in fmts
        l = :( x-> x )
        l.args[2].args[2] = Expr( :macrocall, symbol( "@sprintf" ), fmt, :x )
        mfmtr = eval( l )
        for i in 1:10000
            j = int( erfinv( rand() * 1.99 - 1.99/2.0 ) * 100000 )
            expect = mfmtr( j )
            actual = sprintf1( fmt, j )
            @test expect == actual
        end
    end
    println( "...Done" )
end

@time test_equality()

println( "\nTest speed" )

function native_int()
    for i in 1:200000
        @sprintf( "%10d", i )
    end
end
function runtime_int()
    for i in 1:200000
        sprintf1( "%10d", i )
    end
end
function runtime_int_bypass()
    f = generate_formatter( "%10d" )
    for i in 1:200000
        f( i )
    end
end

println( "integer @sprintf speed")
@time native_int()
println( "integer sprintf speed")
@time runtime_int()
println( "integer sprintf speed, bypass repeated lookup")
@time runtime_int_bypass()

function native_float()
    srand( 10 )
    for i in 1:200000
        @sprintf( "%10.4f", erfinv( rand() ) )
    end
end
function runtime_float()
    srand( 10 )
    for i in 1:200000
        sprintf1( "%10.4f", erfinv( rand() ) )
    end
end
function runtime_float_bypass()
    f = generate_formatter( "%10.4f" )
    srand( 10 )
    for i in 1:200000
        f( erfinv( rand() ) )
    end
end

println()
println( "float64 @sprintf speed")
@time native_float()
println( "float64 sprintf speed")
@time runtime_float()
println( "float64 sprintf speed, bypass repeated lookup")
@time runtime_float_bypass()

function test_commas()
    println( "\ntest commas..." )
    @test sprintf1( "%'d", 1000 ) == "1,000"
    @test sprintf1( "%'d", -1000 ) == "-1,000"
    @test sprintf1( "%'d", 100 ) == "100"
    @test sprintf1( "%'d", -100 ) == "-100"
    @test sprintf1( "%'f", Inf ) == "Inf"
    @test sprintf1( "%'f", -Inf ) == "-Inf"
    @test sprintf1( "%'s", 1000.0 ) == "1,000.0"
    @test sprintf1( "%'s", 1234567.0 ) == "1.234567e6"
end

function test_format()
    println( "test format...")
    @test format( 10 ) == "10"
    @test format( 10.0 ) == @sprintf( "%f", 10.0 )
    @test format( 1123, conversion="x" ) == "463"
    @test format( 1123, alternative=true, conversion="x" ) == "0x463"
end

test_commas()
test_format()
println( "done")
