module NumFormat

export sprintf1, generate_formatter, format

formatters = Dict{ ASCIIString, Function }()

function sprintf1{T<:Real}( fmt::ASCIIString, x::T )
    global formatters
    f = generate_formatter( fmt )
    f( x )
end

function generate_formatter( fmt::ASCIIString )
    global formatters
    if haskey( formatters, fmt )
        return formatters[fmt]
    end
    func = symbol( "sprintf_" * replace( base64( fmt ), "=", "!" ) )

    if !contains( fmt, "'" )
        test = Base.Printf.parse( fmt )
        if length( test ) != 1 || !( typeof( test[1] ) <: Tuple )
            error( "Only one AND undecorated format string is allowed")
        end

        code = quote
            function $func( x )
                @sprintf( $fmt, x )
            end
        end
    else
        conversion = fmt[end]
        if !in( conversion, "sduifF" )
            error( "thousand separator not defined for " * string( conversion ) * " conversion")
        end
        fmtactual = replace( fmt, "'", "", 1 )
        test = Base.Printf.parse( fmtactual )
        if length( test ) != 1 || !( typeof( test[1] ) <: Tuple )
            error( "Only one AND undecorated format string is allowed")
        end
        if in( conversion, "sfF" )
            code = quote
                function $func( x )
                    s = @sprintf( $fmtactual, x )
                    dpos = findfirst( s, '.' )
                    if dpos != 0
                        s = addcommas( s[1:dpos-1] ) * s[ dpos:end ]
                    else # find the rightmost digit
                        for i in length( s ):-1:1
                            if isdigit( s[i] )
                                s = addcommas( s[1:i] ) * s[i+1:end]
                                break
                            end
                        end
                    end
                    s
                end
            end
        else
            code = quote
                function $func( x )
                    s = @sprintf( $fmtactual, x )
                    for i in length( s ):-1:1
                        if isdigit( s[i] )
                            s = addcommas( s[1:i] ) * s[i+1:end]
                            break
                        end
                    end
                    s
                end
            end
        end
    end
    f = eval( code )
    formatters[ fmt ] = f
    f
end

function addcommas( s::ASCIIString )
    len = length(s)
    t = ""
    for i in 1:3:len
        subs = s[max(1,len-i-1):len-i+1]
        if i == 1
            t = subs
        else
            if match( r"[0-9]", subs ) != nothing
                t = subs * "," * t
            else
                t = subs * t
            end
        end
    end
    return t
end

function generate_format_string(;
        width=nothing,
        precision=nothing,
        leftjustified=false,
        zeropadding=false,
        commas=false,
        signed=false,
        positivespace=false,
        alternative=false,
        conversion="f" #aAdecEfFiosxX
        )
    s = "%"
    if commas
        s *= "'"
    end
    if alternative && in( conversion[1], "aAeEfFoxX" )
        s *= "#"
    end
    if zeropadding
        s *= "0"
    end

    if signed
        s *= "+"
    elseif positivespace
        s *= " "
    end

    if width != nothing
        if leftjustified
            s *= "-" * string( width )
        else
            s *= string( width )
        end
    end
    if precision != nothing
        s *= "." * string( precision )
    end
    s * conversion
end

function format{T<:Real}( x::T;
        width=nothing,
        precision=nothing,
        leftjustified=false,
        zeropadding=false,
        commas=false,
        signed=false,
        positivespace=false,
        alternative=false,
        conversion="")
    if conversion == ""
        if T <: FloatingPoint
            sprintf1( generate_format_string( width=width,
                precision=precision,
                leftjustified=leftjustified,
                zeropadding=zeropadding,
                commas=commas,
                signed=signed,
                positivespace=positivespace,
                alternative=alternative,
                conversion="f"
            ),x)
        elseif T <: Integer
            sprintf1( generate_format_string( width=width,
                precision=precision,
                leftjustified=leftjustified,
                zeropadding=zeropadding,
                commas=commas,
                signed=signed,
                positivespace=positivespace,
                alternative=alternative,
                conversion="d"
            ),x)
        else
            sprintf1( generate_format_string( width=width,
                precision=precision,
                leftjustified=leftjustified,
                zeropadding=zeropadding,
                commas=commas,
                signed=signed,
                positivespace=positivespace,
                alternative=alternative,
                conversion="s"
            ),x)
        end
    else
        sprintf1( generate_format_string( width=width,
            precision=precision,
            leftjustified=leftjustified,
            zeropadding=zeropadding,
            commas=commas,
            signed=signed,
            positivespace=positivespace,
            alternative=alternative,
            conversion=conversion
        ), x )
    end
end

end # module
