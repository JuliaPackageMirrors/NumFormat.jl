module NumFormat

export sprintf1, generate_formatter, format

formatters = Dict{ ASCIIString, Function }()

function sprintf1( fmt::ASCIIString, x )
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
    if zeropadding && !leftjustified && width != nothing
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
        zeropadding=false, # when right-justified, use 0 instead of space to fill
        commas=false,
        signed=false,
        positivespace=false,
        stripzeros=(precision==nothing),
        parens=false, # use (1.00) instead of -1.00. Used in finance
        alternative=false,
        conversion="")
    checkwidth = commas
    if conversion == ""
        if T <: FloatingPoint
            actualconv = "f"
        elseif T <: Unsigned
            actualconv = "x"
        elseif T <: Integer
            actualconv = "d"
        else
            actualconv = "s"
        end
    else
        actualconv = conversion
    end
    if signed && commas
        error( "You cannot use signed (+/-) AND commas at the same time")
    end
    nonneg = x >= 0
    if parens && !in( actualconv[1], "xX" )
        actualx = abs(x)
    else
        actualx = x
    end
    s = sprintf1( generate_format_string( width=width,
        precision=precision,
        leftjustified=leftjustified,
        zeropadding=zeropadding,
        commas=commas,
        signed=signed,
        positivespace=positivespace,
        alternative=alternative,
        conversion=actualconv
    ),actualx)

    if stripzeros && in( actualconv[1], "fFeEs" )
        dpos = findfirst( s, '.')
        if in( actualconv[1], "eEs" )
            if in( actualconv[1], "es" )
                epos = findfirst( s, 'e' )
            else
                epos = findfirst( s, 'E' )
            end
            if epos == 0
                rpos = length( s )
            else
                rpos = epos-1
            end
        else
            rpos = length(s)
        end
        # rpos at this point is the rightmost possible char to start
        # stripping
        stripfrom = rpos+1
        for i = rpos:-1:dpos+1
            if s[i] == '0'
                stripfrom = i
            elseif s[i] ==' '
                continue
            else
                break
            end
        end
        if stripfrom <= rpos
            if stripfrom == dpos+1 # everything after decimal is 0, so strip the decimal too
                stripfrom = dpos
            end
            s = s[1:stripfrom-1] * s[rpos+1:end]
            checkwidth = true
        end
    end

    if parens && !in( actualconv[1], "xX" )
        # if zero or positive, we still need 1 white space on the right
        if nonneg
            s = " " * strip(s) * " "
        else
            s = "(" * strip(s) * ")"
        end

        checkwidth = true
    end

    if checkwidth && width != nothing
        if length(s) > width
            s = replace( s, " ", "", length(s)-width )
            if length(s) > width && endswith( s, " " )
                s = reverse( replace( reverse(s), " ", "", length(s)-width ) )
            end
            if length(s) > width
                s = replace( s, ",", "", length(s)-width )
            end
        elseif length(s) < width
            if leftjustified
                s = s * repeat( " ", width - length(s) )
            else
                s = repeat( " ", width - length(s) ) * s
            end
        end
    end

    s
end

end # module
