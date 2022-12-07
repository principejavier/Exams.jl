module Exams

using CSV
using DataFrames
import Mustache: render
import Latexify: latexify
import StatsBase: sample
using Unitful
import Unitful:
    rad, °,        # Angles
    s, minute, hr, Hz, # Time and frequency
    mm, cm, m, km, # Length
    inch, ft,      # Imperial units of length
    l,             # Liter...be careful with conflicts
    kg,            # Not importing g as it conflicts with gravity...be careful
    N, kN,         # Mass
    lb, oz, slug,  # Imperial units of mass
    lbf,           # Imperial units of force
    J, kJ,         # Energy
    Pa, kPa, bar, atm, # Pressure
    psi,               # Imperial units of pressure
    mol, kmol,     # Amount
    Ra, °F, °C, K, # Temperature
    mW, W, kW, MW

#const m=Unitful.m
const rpm = minute^-1
const h = hr
const gal = 231inch^3

export latexify

export StandardTemplate
export StandardHeadings
export PrintedExam
export add_problem!
export generate_pdf_files
export generate_tex_files
export compile_tex_files

export var2out
export question
export figure
export Format
export FloatingFigure
export WrappedFigure
export NoFigure
export Unformatted
export ALL2ALL
export ONE2ONE
export SPA
export CAT
export ENG
export MUTE

export rad, °,        # Angles
    s, minute, hr, Hz, # Time and frequency
    mm, cm, m, km, # Length
    inch, ft,      # Imperial units of length
    l,             # Liter...be careful with conflicts
    kg,            # Not exporting g as it conflicts with gravity...be careful
    N, kN,         # Mass
    lb, oz, slug,  # Imperial units of mass
    lbf,           # Imperial units of force
    J, kJ,         # Energy
    Pa, kPa, bar, atm, # Pressure
    psi,               # Imperial units of pressure
    mol, kmol,     # Amount
    Ra, °F, °C, K, # Temperature
    mW, W, kW, MW,
    rpm, h, gal

const StandardTemplate="""
\\documentclass[11pt]{article}
\\usepackage{amssymb,amsmath}
\\usepackage[utf8]{inputenc}  % handle accents in pdf, using it causes errors in xml
\\usepackage{unicode-math}    % Correctly handles unicode characters (degree) in pdf, only with lualatex
\\usepackage[catalan]{babel} % hyphentation
\\usepackage{wrapfig}
\\usepackage{graphics}
\\usepackage{pgf}
\\usepackage{tikz}
\\usepackage{hyperref}
\\usepackage[top=1.5cm,bottom=2cm,right=2cm,left=2cm]{geometry}
\\usepackage{enumitem}
\\setlist[enumerate]{left=0pt,topsep=0pt,label={\\bf \\arabic*},resume}

\\renewcommand{\\figurename}{Figura}
\\renewcommand{\\tablename}{Tabla}
\\linespread{1.3}
\\parindent 0mm
\\parskip 3mm
\\textfloatsep 6pt
\\floatsep  6pt
\\intextsep 6pt
\\graphicspath{ {{{GraphicsPath}}} }

\\begin{document}
\\pagestyle{empty}

\\begin{table}[t]
  \\begin{center}
    \\begin{tabular}{|l|l|l|}
      \\hline
      {\\bf {{{CourseTitle}}} } \\quad & {{{ExamTitle}}} {{{ExamDate}}} \\quad \\quad \\quad \\quad \\quad & {{{PermutationName}}} {{{PermutationNum}}} \\\\
      \\hline
      {{StudentID}}: & \\multicolumn{2}{|l|}{ {{StudentName}}: } \\\\ \\hline
      \\multicolumn{3}{|l|}{
      \\begin{minipage}{\\textwidth}
      \\vspace{2mm} {{{ExamRules}}} \\vspace{2mm} 
      \\end{minipage}}
      \\\\ \\hline
    \\end{tabular}
  \\end{center}
\\end{table}

\\end{document}
"""

const latex_tail = "\n\\end{document}\n"

const CAT="catalan"
const ENG="english"
const SPA="spanish"
const MUTE="mute"

default_max_questions = 50 # can be changed from API
default_max_permutations = 10 # can be changed from API
right_names = ["A","B","C","D","E"]
examio_head1 = ["1","2","3","4","5","6","7","8","9","10"]  # permutacio
examio_head2 = ["1","1","1","1","1","1","1","1","1","1"]  # grup

StandardHeadings = Dict{String,Dict{String, String}}()
StandardHeadings[SPA]=Dict{String,String}()
StandardHeadings[CAT]=Dict{String,String}()
StandardHeadings[ENG]=Dict{String,String}()

StandardHeadings[SPA]["ExamRules"]="Sólo hay una respuesta correcta para cada pregunta que debe ser marcada en la hoja de respuestas {\\bf llenando completamente el rectángulo correspondiente}. Cada respuesta incorrecta {\\bf resta un 25\\%} del valor de una correcta. En la hoja de respuestas es necesario marcar el DNI (o NIE o pasaporte) y la permutación."
StandardHeadings[CAT]["ExamRules"]="Només hi ha una resposta correcta per a cada pregunta, marcar-la en la fulla de respostes {\\bf emplenant completament el rectangle corresponent}.  Cada resposta incorrecta {\\bf resta un 25\\%} del valor d'una correcta. En la fulla de respostes cal marcar el DNI (o NIE o passaport) i la permutació."
StandardHeadings[ENG]["ExamRules"]="There is only one correct answer and answers need to be inputted into the provided answer sheet by {\\bf completely filling in the rectangle}. Each incorrect answer {\\bf subtracts 25\\%} of the value of a correct answer. On the answer sheet fill your ID (DNI, NIE or passport) and exam permutation. "

StandardHeadings[SPA]["StudentID"]="DNI"
StandardHeadings[CAT]["StudentID"]="DNI"
StandardHeadings[ENG]["StudentID"]="ID"

StandardHeadings[SPA]["StudentName"]="Nombre"
StandardHeadings[CAT]["StudentName"]="Nom"
StandardHeadings[ENG]["StudentName"]="Name"

StandardHeadings[SPA]["PermutationName"]="Permutación"
StandardHeadings[CAT]["PermutationName"]="Permutació"
StandardHeadings[ENG]["PermutationName"]="Permutation"

StandardHeadings[SPA]["PermutationNum"]="1"
StandardHeadings[CAT]["PermutationNum"]="1"
StandardHeadings[ENG]["PermutationNum"]="1"

StandardHeadings[SPA]["ProblemName"]="Problema"
StandardHeadings[CAT]["ProblemName"]="Problema"
StandardHeadings[ENG]["ProblemName"]="Problem"

abstract type FormatFigure end
struct FloatingFigure <: FormatFigure
    width::Float64
end
struct WrappedFigure <: FormatFigure
    width::Float64
    vshift::Any
    # vshift::Unitful.Quantity{Float64,Unitful.𝐋,U} where {U}
end
struct NoFigure<:FormatFigure end

abstract type ArgCombination end
struct ALL2ALL <: ArgCombination end
struct ONE2ONE <: ArgCombination end

abstract type FormatQuestion end
struct PrintedQuestion <: FormatQuestion
    num_options :: Vector{Int}
    num_rows    :: Vector{Int}
    int_params  :: Vector{Int}
    right       :: Matrix{Int64}
end
struct Unformatted <: FormatQuestion end

const PrintedExamType=1::Int
const MoodleExamType=2::Int
struct Format
    num_rows    :: Vector{Int}
    num_options :: Vector{Int}
    function Format(num_rows=[1 for i in 1:default_max_questions],num_options=[5 for i in 1:default_max_questions])
        new(num_rows,num_options)
    end
end

abstract type Exam end
struct PrintedExam <: Exam
    name::String
    num_permutations::Int
    max_permutations::Int
    max_questions::Int
    languages::Vector{String}
    headings::Dict{String,Dict{String, String}}
    template::String
    figures::Vector{FormatFigure}
    functions::Vector{Function}
    arguments::Vector{Vector{Tuple}}
    format::FormatQuestion
    function PrintedExam(num_permutations;languages=[ENG],headings=StandardHeadings,name="exam",max_permutations=default_max_permutations,max_questions=default_max_questions,template=StandardTemplate,format=Format([1 for i in 1:max_questions],[5 for i in 1:max_questions]))
        form=PrintedQuestion(format.num_options,format.num_rows,Vector{Int}(undef,2),Matrix{Int64}(undef,max_questions, max_permutations))
        # format.right[:,:]=define_correct_answers(name)
        new(name,num_permutations,max_permutations,max_questions,languages,headings,template,Vector{FormatFigure}(undef,0),Vector{Function}(undef,0),Vector{Vector{Tuple}}(undef,0),form)
    end
end

function add_problem!(exam::PrintedExam,fmt::FormatFigure,c::Type{<:ArgCombination},f::Function,args...)
    push!(exam.functions,f)
    push!(exam.figures,fmt)
    for v in args
        @assert isa(v,Vector) "To add a function provide its arguments as vectors (used to generate combinations)"
    end
    if length(args)==0 # function without args
        push!(exam.arguments,[() for i in 1:exam.num_permutations])
    else
        if c===ALL2ALL
            @assert length(Iterators.product(args...))>=exam.num_permutations "Not enough arguments for problem $f"
            push!(exam.arguments,collect(Iterators.take(Iterators.product(args...),exam.num_permutations)))
        elseif c===ONE2ONE
            @assert length(Iterators.product(args...))>=exam.num_permutations^2 "Not enough arguments for problem $f"
            push!(exam.arguments,takediag(Iterators.product(args...),exam.num_permutations))
        end
    end
end

function generate_pdf_files(exam::PrintedExam)
    generate_tex_files(exam)
    compile_tex_files(exam)
end

function generate_tex_files(exam::PrintedExam)

    define_correct_answers!(exam)
    num_prob = length(exam.functions)

    for lang in exam.languages
        for i = 1:exam.num_permutations
            exam.format.int_params[1] = i
            exam.format.int_params[2] = 0
            filename = exam.name*"_"*lang*"_$i"
            io_tex = open(filename*".tex","w");
            exam.headings[lang]["PermutationNum"]="$i"
            render(io_tex,replace(exam.template,"\\end{document}"=>""),exam.headings[lang])
            # Loop over problems
            last_page=""
            for k = 1:num_prob
                render(io_tex, begin_problem(k),exam.headings[lang])
                problem_slices=exam.functions[k](exam.arguments[k][i]...,lang,exam.format)
                last_page=last_page*format_figure!(exam.figures[k],problem_slices)
                problem=prod(problem_slices)
                write(io_tex, problem);
                write(io_tex, end_problem())
            end
            write(io_tex, last_page)
            write(io_tex, latex_tail);
            close(io_tex);
        end
    end
    np=exam.format.int_params[1]
    nq=exam.format.int_params[2]
    CSV.write("results_examio.csv", Tables.table(hcat(examio_head1[1:np],examio_head2[1:np],right_names[transpose(exam.format.right[1:nq,1:np])])), header=false, delim=";")

    return nothing

end

function compile_tex_files(exam::PrintedExam)

    for lang in exam.languages
        for i = 1:exam.num_permutations
            filename = exam.name*"_"*lang*"_$i"
            pdflatex = `lualatex $(filename)`
            run(pdflatex)
            run(pdflatex)
            rm(filename*".aux")
            rm(filename*".log")
            rm(filename*".out")
        end
    end
    return nothing

end

function takediag(prod::Iterators.ProductIterator,n)
    @assert length(prod)>=n^2
    vars=[]
    for i in range(1,n)
        var, prod = Iterators.peel(prod)
        prod = Iterators.drop(prod,n)
        push!(vars,var)
    end
    return vars
end

function define_correct_answers!(exam::PrintedExam)
    # global right
    filename=exam.name*"_results.csv"
    if isfile(filename)
        df = CSV.read(filename, DataFrame, header=0)
        exam.format.right[:,:] = Matrix{Int}(df)
    else
        exam.format.right[:,:] = rand((1:5), exam.max_questions, exam.max_permutations)
        CSV.write(filename, Tables.table(exam.format.right), writeheader=false)
    end
    return nothing
end

# function define_correct_answers(name::String)
#     # global right
#     filename=name*"_results.csv"
#     if isfile(filename)
#         df = CSV.read(filename, DataFrame, header=0)
#         right = Matrix{Int}(df)
#     else
#         right = rand((1:5), max_questions, max_permutations)
#         CSV.write(filename, Tables.table(right), writeheader=false)
#     end
#     return right
# end

function figure(name, label="", caption="")
    figure = """
    \\centering
    \\includegraphics[width]{$name}
    """
    (label   > "")  && ( figure = figure*"\\label{$label} \n" )
    (caption > "")  && ( figure = figure*"\\caption{$caption} \n" )
    return figure
end

function format_figure!(format::WrappedFigure,str::Vector{String})
    
    @assert length(str)>0 "Empty string vector in format_figure!(WrappedFigure,...)"

    w=format.width
    v=format.vshift

    t=str[1]
    for (i,s) in enumerate(str)
        if occursin("includegraphics",s) 
            str[1]=replace(s,"width"=>"width=$w\\textwidth")
            str[i]=t
            break
        end
    end

    str[1]="\\begin{wrapfigure}{r}{$w\\textwidth}\n\\vspace{$v}\n"*str[1]*"\\end{wrapfigure}\n"
    return "\n"
end

function format_figure!(format::FloatingFigure,str::Vector{String})

    @assert length(str)>0 "Empty string vector in format_figure!(FloatingFigure,...)"
    w=format.width
    for (i,s) in enumerate(str)
        if occursin("includegraphics",s) 
            str[i]="\n\\begin{figure}[h!]\n"*replace(s,"width"=>"width=$w\\textwidth")*"\\end{figure}\n\n"
            break
        end
    end
    return "\n"
end

function format_figure!(format::NoFigure,str::Vector{String})
    @assert length(str)>0 "Empty string vector in format_figure!(NoFigure,...)"
    return "\n"
end

function begin_quiz(name)
    str = "\\begin{quiz}{Probs/$language/$name}\n"
    return str
end
function begin_cloze(name)
    str = "\\begin{cloze}{$name}\n"
    return str
end

function begin_problem(prob)
    str = "\n\\noindent \\textbf{ {{{ProblemName}}} $prob} \n\n"
    return str
end
function end_problem()
    str = "\n "
    return str
end

function unit2latex(str)
    str = replace(str, r"\^(?<exp>-?\d+)" => s"$^{\g<exp>}$") # add brackets around exponents
    str = replace(str, r"\s" => s"$\\cdot$")                  # replace spaces with cdot (unicode cdot does not compile)
    # str = replace(str, r"\s" => s" ")                        # replace spaces with unicode small spaces
    # str = replace(str, r"\s" => s"\\,")                      # replace spaces with small spaces (not working in xml)
    # str = replace(str, r"\s" => s"")                         # delete spaces
    str = replace(str, r"\*" => s"$\\cdot$")                  # replace * with cdot
    # str = replace(str, r"\*" => s" ")                        # replace * with unicode small spaces
    return str
end

function val2latex(val)
    str = replace("$val", r"e(?<exp>-?\d+)" => s"\\cdot 10^{\g<exp>}") # add brackets around exponents
    # str = replace(str, "." => ",")
    # str = replace("$val", "." => ",")
    return str
end

function var2out(var, varname="", unitname=""; num_digits=4)

    if dimension(var) == NoDims # unit(var) == unit(1) 
        varval = val2latex(var)
        # Name of the variable (optional)
        if varname > ""
            str = "\$$varname =" * "$varval" * "\$"
        else
            str = "\$" * "$varval" * "\$"
        end
    else
        # Unit
        if unitname > "" # write it as given and pick the value using this string
            str = unit2latex(unitname)
            out_unit = eval(Meta.parse(unitname))
        else # pick the unit from the variable
            str = string(unit(var))
            str = unit2latex(str)
            out_unit = unit(var)
        end
        # Value
        val = ustrip(Float64, out_unit, var)
        val = round(val, sigdigits=num_digits)
        varval = val2latex(val)
        # Name of the variable (optional)
        if varname > ""
            str = "\$$varname =" * "$varval" * "\$~" * str
        else
            str = "\$" * "$varval" * "\$~" * str
        end
    end
    return str
end

function def2latex(str)
    beg = findfirst(isequal('='), str)
    str1 = latexify(env=:raw, str[1:beg - 1])
    str2 = replace(str[beg + 1:end], r"(?<un>[m,cm,mm,kg,s,°C,K,Pa]+)" => s"\\text{\g<un>}")
    str2 = replace(str2, r"(?<num>[\d.]+)" => s"\g<num>\\,")
    # str2 = replace(str2, r"\*" => s"\\cdot") 
    str2 = replace(str2, r"\*" => s"\\,") 
    str = "\$" * str1 * "=\\," * str2 * "\$"
    return str
end 

function rand2()
    if rand() > 0.5 
        rand2 = 2.0
    else
        rand2 = 0.5
    end
end

function question(::Type{Unformatted}, msg, var, unitname=""; factor1=rand2(), factor2=1.2 + 0.2 * rand(), factor3=0.6 + 0.2 * rand(), factor4=1.6 + 0.2 * rand(),num_digits=4)

    # Next lines are in common with other methods, could be wrapped into
    # another function
    if unitname > "" # write it as given and pick the value parsing it
        latex_unit = unit2latex(unitname)
        out_unit   = eval(Meta.parse(unitname))
    else # pick the unit from the variable
        out_unit   = unit(var)
        unitname   = string(out_unit)
        latex_unit = unit2latex(unitname)
    end
   
    val = ustrip(Float64, out_unit, var)
    val = round(val, sigdigits=num_digits)
    res = val2latex(val)

    msg = replace(msg, "unitname" => latex_unit)
    println(msg*" Result: $res")

end

function question(format::PrintedQuestion, msg, var, unitname=""; factor1=rand2(), factor2=1.2 + 0.2 * rand(), factor3=0.6 + 0.2 * rand(), factor4=1.6 + 0.2 * rand(),num_digits=4)

    # Unit
    if unitname > "" # write it as given and pick the value parsing it
        latex_unit = unit2latex(unitname)
        out_unit   = eval(Meta.parse(unitname))
    else # pick the unit from the variable
        out_unit   = unit(var)
        unitname   = string(out_unit)
        latex_unit = unit2latex(unitname)
    end
   
    val = ustrip(Float64, out_unit, var)
#    tol = round(tolerance * abs(val), sigdigits=2)
    val = round(val, sigdigits=num_digits)

    msg = replace(msg, "unitname" => latex_unit)

    val1 = round(factor1 * val, sigdigits=num_digits); # 0.0 
    val2 = round(factor2 * val, sigdigits=num_digits); # 0.0 
    val3 = round(factor3 * val, sigdigits=num_digits); # 0.0 
    val4 = round(factor4 * val, sigdigits=num_digits); # 0.0 

    format.int_params[2]=format.int_params[2]+1
    num_question = format.int_params[2]
    pos = format.right[format.int_params[2],format.int_params[1]]
    res = Array{String}(undef,5);
    #res = zeros(5);
    res[mod(pos, 5) + 1] = val2latex(val1)
    res[mod(pos + 1, 5) + 1] = val2latex(val2)
    res[mod(pos + 2, 5) + 1] = val2latex(val3)
    res[mod(pos + 3, 5) + 1] = val2latex(val4)
    res[mod(pos + 4, 5) + 1] = val2latex(val)

    # str = """\\textbf{$num_question} $msg \\\\
    # \\begin{tabular}{*{3}{p{2.5cm}}}
    # a) $(res[1]) & b) $(res[2]) & c) $(res[3]) \\\\ d) $(res[4]) & e) $(res[5]) & f) \\rule[0pt]{1cm}{0.75pt} \\\\
    # \\end{tabular}

    # """
    str = """\\textbf{$num_question} $msg \\\\
    \\begin{tabular}{*{5}{p{2.cm}}}
    a) \$$(res[1])\$ & b) \$$(res[2])\$ & c) \$$(res[3])\$ & d) \$$(res[4])\$ & e) \$$(res[5])\$ \\\\
    \\end{tabular}

    """
    return str

end

function question(format::PrintedQuestion, msg, eqs::Vector{String})

    format.int_params[2]=format.int_params[2]+1
    num_question = format.int_params[2]
    pos = format.right[format.int_params[2],format.int_params[1]]
    res = Vector{String}(undef,5);
    perm = sample(2:5, 4, replace = false)
    res[mod(pos    , 5) + 1] = latexify(eqs[perm[1]])
    res[mod(pos + 1, 5) + 1] = latexify(eqs[perm[2]])
    res[mod(pos + 2, 5) + 1] = latexify(eqs[perm[3]])
    res[mod(pos + 3, 5) + 1] = latexify(eqs[perm[4]])
    res[mod(pos + 4, 5) + 1] = latexify(eqs[1]) # same as res[pos] = eqs[1]

    str=""
    if format.num_rows[num_question]==1
        str = """\\textbf{$num_question} $msg \\\\
        \\begin{tabular}{*{5}{p{0.18\\textwidth}}}
        a) $(res[1]) & b) $(res[2]) & c) $(res[3]) & d) $(res[4]) & e) $(res[5]) \\\\
        \\end{tabular}

    """
    elseif format.num_rows[num_question]==2
        str = """\\textbf{$num_question} $msg \\\\
        \\begin{tabular}{*{3}{p{0.18\\textwidth}}}
        a) $(res[1]) & b) $(res[2]) & c) $(res[3]) \\\\ 
        d) $(res[4]) & e) $(res[5]) & \\\\
        \\end{tabular}
    
        """
    end

    return str

end



end
