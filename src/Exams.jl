module Exams

using CSV
using DataFrames
using FileIO
using BSON
import Mustache: render
import Latexify: latexify
import StatsBase: sample
using Unitful
import Unitful:
    uconvert,      # Needed for explicit conversion (degrees)
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

using CoolProp

export latexify

export StandardTemplate
export StandardHeadings
export PrintedExam
export PrintedQuestion
export OnlineExam
export OnlineQuestion
export OnlineHeadings

export add_problem!
export add_pagebreak!
export add_vspace!
export generate_pdf_files
export generate_tex_files
export compile_tex_files

export var2out
export question
export figure
export Format
export FloatingFigure
export WrappedFigure
export InlinedFigure
export NoFigure
export ALL2ALL
export ONE2ONE
export SPA
export CAT
export ENG
export MUTE

export uconvert,
    rad, °,        # Angles
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

export PropsSI

const MoodleTemplate="""
\\documentclass[11pt]{article}
\\usepackage{amssymb,amsmath}
\\usepackage{moodle}          % generate xml
\\usepackage[catalan]{babel} % hyphentation
\\usepackage{graphics}
\\usepackage{pgf}
\\usepackage{tikz}
\\usepackage{hyperref}
\\graphicspath{ {{{GraphicsPath}}} }
\\begin{document}

"""

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
\\parskip 2mm
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
head1 = ["1","2","3","4","5","6","7","8","9","10"]  # permutacio
head2 = ["1","1","1","1","1","1","1","1","1","1"]  # grup (not used right now)

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

OnlineHeadings = Dict{String,Dict{String, String}}()
OnlineHeadings[SPA]=Dict{String,String}()
OnlineHeadings[CAT]=Dict{String,String}()
OnlineHeadings[ENG]=Dict{String,String}()

function add_defaults!(headings)
    for (key,val) in StandardHeadings
      if !haskey(headings,key)
        headings[key] = val
      end
    end
end

abstract type LatexFigure end
struct FloatingFigure <: LatexFigure
    width::Float64
end
struct InlinedFigure <: LatexFigure
    width::Float64
end
struct WrappedFigure <: LatexFigure
    width::Float64
    width_fig::Float64
    #vshift::Any
    vshift::Unitful.Quantity{T,Unitful.𝐋,U} where {T<:Real,U<:Unitful.Units}
    lines::Integer
    hang::Unitful.Quantity{T, Unitful.𝐋, U} where {T<:Real,U<:Unitful.Units}
    function WrappedFigure(w,v::Quantity{T, Unitful.𝐋, U} where {T<:Real,U<:Unitful.Units};lines::Integer=-1,hang::Quantity{T, Unitful.𝐋, U} where {T<:Real,U<:Unitful.Units}=0.0cm,width_fig=w)
        # @assert isa(v,Unitful.Length) "vshift must be given with length units"
        new(w,width_fig,v,lines,hang)
    end
end
struct NoFigure<:LatexFigure end

abstract type ArgCombination end
struct ALL2ALL <: ArgCombination end
struct ONE2ONE <: ArgCombination end

abstract type QuestionFormat end
struct PrintedQuestion <: QuestionFormat
    num_rows    :: Vector{Int}
    num_options :: Vector{Int}
    width       :: Vector{Quantity{T, Unitful.𝐋, U} where {T<:Real,U<:Unitful.Units}}
    int_params  :: Vector{Int}
    right       :: Vector{Vector{Int}}
end
function PrintedQuestion(
    num_rows=[1 for i in 1:default_max_questions],
    width=[2.0cm for i in 1:default_max_questions],
    num_options=[5 for i in 1:length(num_rows)])
    max_questions = length(num_rows)
    @assert length(num_options) == max_questions
    @assert length(width) == max_questions
    @assert num_options == [5 for i=1:max_questions] "The number of options is currently hard-coded to 5"
    int_params = Vector{Int}(undef,2)
    right = Vector{Vector{Int}}(undef,default_max_questions)
    PrintedQuestion(num_rows,num_options,width,int_params,right)
end
struct OnlineQuestion <: QuestionFormat
    num_options :: Vector{Int}
    int_params  :: Vector{Int}
end
function OnlineQuestion(num_options=[5 for i in 1:default_max_questions])
    max_questions = length(num_options)
    @assert num_options == [5 for i=1:max_questions] "The number of options is currently hard-coded to 5"
    int_params = Vector{Int}(undef,2)
    OnlineQuestion(num_options,int_params)
end

abstract type Exam end
function add_arguments!(exam::Exam,v::Vector{T} where T)
    @assert false
end
function add_function!(exam::Exam,f::Function)
    @assert false
end
function add_figure!(exam::Exam,fig::LatexFigure)
    @assert false
end
function add_new_problem!(exam::Exam)
    @assert false
end

function add_problem!(exam::Exam,fig::LatexFigure,c::Type{<:ArgCombination},f::Function,args...)
    add_new_problem!(exam)
    add_function!(exam,f)
    add_figure!(exam,fig)

    for v in args
        @assert isa(v,Vector) "To add a function provide its arguments as vectors (components of which are used to generate combinations)"
    end
    if length(args)==0 # function without args
        add_arguments!(exam,[() for i in 1:exam.num_permutations])
    else
        if c===ALL2ALL
            @assert length(Iterators.product(args...))>=exam.num_permutations "Not enough arguments for problem $f"
            add_arguments!(exam,collect(Iterators.take(Iterators.product(args...),exam.num_permutations)))
        elseif c===ONE2ONE
            # @assert length(Iterators.product(args...))>=exam.num_permutations^2 "Not enough arguments for problem $f"
            # push!(exam.arguments,takediag(Iterators.product(args...),exam.num_permutations))
            for (i,a) in enumerate(args)
                @assert length(a)>= get_num_permutations(exam) "Argument $i is not of the required size"
            end
            add_arguments!(exam,collect(zip(args...)))
        end
    end
end

"""
    struct PrintedExam <: Exam
        # private fields
    end

This struct holds data needed to create an exam to be printed on paper. The constructor is

    PrintedExam(num_permutations;languages=[ENG],headings=StandardHeadings,name="exam",
                max_permutations=10,max_questions=50,template=StandardTemplate,
                format=Format([1 for i=1:50],[5 for i=1:50]))

Tipically the number of permutations, languages and headings are defined while other arguments
keep default values. See `example.jl` in test that ilustrates the use. After creation, some
problems are added calling

    - [`add_problem!(e::Exam,...)`](@ref)

Finally, the exam is generated calling appropriate methods, namely 
        
    - [`generate_tex_files(e::Exam)`](@ref)
    - [`compile_tex_files(e::Exam)`](@ref)

or directly

    - [`generate_pdf_files(e::Exam)`](@ref)

"""
struct PrintedExam <: Exam
    name::String
    num_permutations::Int
    languages::Vector{String}
    headings::Dict{String,Dict{String, String}}
    template::String
    figures::Vector{LatexFigure}
    functions::Vector{Function}
    arguments::Vector{Vector{Tuple}}
    vspace::Vector{Quantity{T, Unitful.𝐋, U} where {T<:Real,U<:Unitful.Units}}
    pagebreak::Vector{Bool}
    format::QuestionFormat
    function PrintedExam(num_permutations;languages=[ENG],headings=StandardHeadings,name="exam",template=StandardTemplate,format=PrintedQuestion())
        define_correct_answers!(format,name,num_permutations)
        add_defaults!(headings)
        new(name,num_permutations,languages,headings,template,Vector{LatexFigure}(undef,0),Vector{Function}(undef,0),Vector{Vector{Tuple}}(undef,0),Vector{Quantity{T, Unitful.𝐋, U} where {T<:Real,U<:Unitful.Units}}(undef,0),Vector{Bool}(undef,0),format)
    end
end

function add_pagebreak!(exam::PrintedExam)
    exam.pagebreak[end]=true
end

function add_vspace!(exam::PrintedExam,s::Quantity{T, Unitful.𝐋, U} where {T<:Real,U<:Unitful.Units})
    exam.vspace[end]=s
end

function add_arguments!(exam::PrintedExam,v::Vector{T} where T)
    push!(exam.arguments,v)
end

function add_function!(exam::PrintedExam,f::Function)
    push!(exam.functions,f)
end

function add_figure!(exam::PrintedExam,fig::LatexFigure)
    push!(exam.figures,fig)
end
function add_new_problem!(exam::PrintedExam)
    push!(exam.vspace,0.0cm)
    push!(exam.pagebreak,false)
end
function get_languages(exam::PrintedExam)
    exam.languages
end
function get_num_permutations(exam::PrintedExam)
    exam.num_permutations
end

struct OnlineExam <: Exam
    name::String
    num_permutations::Int
    languages::Vector{String}
    headings::Dict{String,Dict{String, String}}
    template::String
    figures::Vector{LatexFigure}
    functions::Vector{Function}
    arguments::Vector{Vector{Tuple}}
    format::QuestionFormat
    figfiles::Vector{String}
    function OnlineExam(num_permutations;languages=[ENG],headings=MoodleHeadings,name="exam",template=MoodleTemplate,format=OnlineQuestion())
        new(name,num_permutations,languages,headings,template,Vector{LatexFigure}(undef,0),Vector{Function}(undef,0),Vector{Vector{Tuple}}(undef,0),format,Vector{String}(undef,0))
    end
end

function add_arguments!(exam::OnlineExam,v::Vector{T} where T)
    push!(exam.arguments,v)
end

function add_function!(exam::OnlineExam,f::Function)
    push!(exam.functions,f)
end

function add_figure!(exam::OnlineExam,fig::LatexFigure)
    @assert isa(fig,InlinedFigure) "Only InlinedFigure is valid for OnlineExam"
    push!(exam.figures,fig)
end
function add_new_problem!(exam::OnlineExam)
end
function get_languages(exam::OnlineExam)
    exam.languages
end
function get_num_permutations(exam::OnlineExam)
    exam.num_permutations
end

function generate_pdf_files(exam::Exam)
    generate_tex_files(exam)
    compile_tex_files(exam)
end

function generate_tex_files(exam::PrintedExam)

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
                write(io_tex,vspace(exam.vspace[k]))
                exam.pagebreak[k] && write(io_tex,pagebreak())
            end
            write(io_tex, last_page)
            write(io_tex, latex_tail);
            close(io_tex);
        end
    end
    np=exam.format.int_params[1]
    nq=exam.format.int_params[2]
    CSV.write(exam.name*"_results.csv", Tables.table(hcat(head1[1:np],head2[1:np],right_names[hcat(exam.format.right[1:nq]...)])), header=false, delim=";")

    return nothing

end

function generate_tex_files(exam::OnlineExam)

    num_prob = length(exam.functions)
    process_images=true
    for lang in get_languages(exam)
        for i = 1:get_num_permutations(exam)
            exam.format.int_params[1] = i
            exam.format.int_params[2] = 0
            filename = exam.name*"_"*lang*"_$i"
            io_tex = open(filename*".tex","w");
            render(io_tex,replace(exam.template,"\\end{document}"=>""),exam.headings[lang])
            # Loop over problems
            write(io_tex,begin_quiz(lang,exam.name))
            last_page=""
            for k = 1:num_prob
                write(io_tex,begin_cloze(exam.name))
                problem_slices=exam.functions[k](exam.arguments[k][i]...,lang,exam.format)
                last_page=last_page*format_figure!(exam.figures[k],problem_slices)
                problem=prod(problem_slices)
                write(io_tex, problem);
                write(io_tex, end_cloze())
            end
            write(io_tex, end_quiz())
            write(io_tex, last_page)
            write(io_tex, latex_tail);
            close(io_tex);
            if process_images
                io_tex = open(filename*".tex","r");
                st=read(io_tex,String)
                st=replace(replace(st,"{ {"=>"{"),"} }"=>"}")
                mf=match(r"includegraphics.*{(.*)}",st)
                mp=match(r"graphicspath{(.*)}",st)
                push!(exam.figfiles,mf.captures...) # To delete them after compile
                for s in mf.captures
                    run(`openssl enc -base64 -A -in $(mp.captures[1])/$s.png -out $s.enc`)
                end
                process_images = false
            end
        end
    end

    return nothing

end

function compile_tex_files(exam::Exam)

    # if isa(exam,PrintedExam)
    #     compiler="lualatex"
    # elseif isa(exam,OnlineExam)
    #     compiler="pdflatex"
    # end
    compiler="lualatex"
    for lang in get_languages(exam)
        for i = 1:get_num_permutations(exam)
            filename = exam.name*"_"*lang*"_$i"
            pdflatex = `$compiler $(filename)`
            run(pdflatex)
            run(pdflatex)
            rm(filename*".aux")
            rm(filename*".log")
            rm(filename*".out")
        end
    end
    postcompile!(exam)
    return nothing
end

function postcompile!(exam::PrintedExam) end
function postcompile!(exam::OnlineExam)
    for f in exam.figfiles
        rm(f*".enc")
    end
    for lang in get_languages(exam)
        for i = 1:get_num_permutations(exam)
            filename = exam.name*"_"*lang*"_$i-moodle.xml"
            run(`sed -i.backup 's/MULTICHOICE/MULTICHOICE_VS/g' $filename`)
            run(`sed -i 's/PENALTY/%-25%/g' $filename`)
        end
    end
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

# function define_correct_answers!(exam::PrintedExam)
#     filename=exam.name*".bson"
#     if isfile(filename)
#         d = load(filename)
#         exam.format.right[:,:] = d[:right]
#     else
#         exam.format.right[:,:] = rand((1:5), exam.max_questions, exam.max_permutations)
#         save(filename,Dict(:right=>exam.format.right))
#     end
#     return nothing
# end

function define_correct_answers!(format::PrintedQuestion,name::String,np::Int)
    filename=name*".bson"
    if isfile(filename)
        d = load(filename)
        format.right[:] = d[:right]
    else
        nq = length(format.right)
        format.right[:] = [rand((1:5),np) for i=1:nq]
        save(filename,Dict(:right=>format.right))
    end
end

function figure(name, label="", caption="")
    figure = """
    \\includegraphics[width]{$name}
    """
    (caption > "")  && ( figure = figure*"\\caption{$caption}\n" )
    (label   > "")  && ( figure = figure*"\\label{$label}\n" )
    return figure
end

function format_figure!(format::WrappedFigure,str::Vector{String})
    
    @assert length(str)>0 "Empty string vector in format_figure!(WrappedFigure,...)"

    w=format.width
    wfig=format.width_fig
    t=format.vshift
    h=format.hang
    v=replace("$t",r"\s"=>"")

    t=str[1]
    for (i,s) in enumerate(str)
        if occursin("includegraphics",s) 
            str[1]=replace(s,"width"=>"width=$wfig\\textwidth")
            str[i]=t
            break
        end
    end
    if format.lines>0
        nlines=format.lines
        str[1]="\n\n\\begin{wrapfigure}[$nlines]{r}[$h]{$w\\textwidth}\n\\vspace{$v}\n"*str[1]*"\\end{wrapfigure}\n\n"
    else
        str[1]="\n\n\\begin{wrapfigure}{r}[$h]{$w\\textwidth}\n\\vspace{$v}\n"*str[1]*"\\end{wrapfigure}\n\n"
    end
    return "\n"
end

function format_figure!(format::FloatingFigure,str::Vector{String})

    @assert length(str)>0 "Empty string vector in format_figure!(FloatingFigure,...)"
    w=format.width
    for (i,s) in enumerate(str)
        if occursin("includegraphics",s) 
            str[i]="\n\n\\begin{figure}[h!]\n\\begin{center}\n"*replace(s,"width"=>"width=$w\\textwidth")*"\\end{center}\n\\end{figure}\n\n"
            break
        end
    end
    return "\n"
end

function format_figure!(format::InlinedFigure,str::Vector{String})

    @assert length(str)>0 "Empty string vector in format_figure!(FloatingFigure,...)"
    w=format.width
    for (i,s) in enumerate(str)
        if occursin("includegraphics",s) 
            # t=replace(s,"\\centering"=>"\n")
            t=replace(s,r"\\caption{.*}\n"=>"")
            t=replace(t,r"\\label{.*}\n"=>"")
            str[i]="\n\n\\begin{center}\n"*replace(t,"width"=>"width=$w\\textwidth")*"\\end{center}\n\n"
            break
        end
    end
    return "\n"
end

function format_figure!(format::NoFigure,str::Vector{String})
    @assert length(str)>0 "Empty string vector in format_figure!(NoFigure,...)"
    return "\n"
end

function begin_quiz(language,name)
    str = "\\begin{quiz}{Probs/$language/$name}\n"
    return str
end
function begin_cloze(name)
    str = "\\begin{cloze}{$name}\n"
    return str
end

function end_cloze()
    "\\end{cloze}\n\n"
end
function end_quiz()
    "\\end{quiz}\n"
end


function begin_problem(prob)
    str = "\n\\noindent {\\bfseries {{{ProblemName}}} $prob} \n\n"
    return str
end
function end_problem()
    str = "\n \n"
    return str
end
function pagebreak()
    str="\\pagebreak \n"
    return str
end
function vspace(s)
    t=replace("$s",r"\s"=>"")
    str="\\vspace{$t} \n"
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

function get_value(var,unitname,num_digits)
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
    return val, latex_unit
end

function question(::Nothing, msg, var, unitname=""; factor1=rand2(), factor2=1.2 + 0.2 * rand(), factor3=0.6 + 0.2 * rand(), factor4=1.6 + 0.2 * rand(), num_digits=4)
    val, latex_unit = get_value(var,unitname,num_digits)
    res = val2latex(val)
    msg = replace(msg, "unitname" => latex_unit)
    println(msg*" Result: $res")
end

function question(format::PrintedQuestion, msg, var, unitname=""; factor1=rand2(), factor2=1.2 + 0.2 * rand(), factor3=0.6 + 0.2 * rand(), factor4=1.6 + 0.2 * rand(),num_digits=4)
    val, latex_unit = get_value(var,unitname,num_digits)
    msg = replace(msg, "unitname" => latex_unit)

    val1 = round(factor1 * val, sigdigits=num_digits); # 0.0 
    val2 = round(factor2 * val, sigdigits=num_digits); # 0.0 
    val3 = round(factor3 * val, sigdigits=num_digits); # 0.0 
    val4 = round(factor4 * val, sigdigits=num_digits); # 0.0 

    format.int_params[2]=format.int_params[2]+1
    num_question = format.int_params[2]
    pos = format.right[format.int_params[2]][format.int_params[1]]
    res = Array{String}(undef,5);

    res[mod(pos, 5) + 1] = val2latex(val1)
    res[mod(pos + 1, 5) + 1] = val2latex(val2)
    res[mod(pos + 2, 5) + 1] = val2latex(val3)
    res[mod(pos + 3, 5) + 1] = val2latex(val4)
    res[mod(pos + 4, 5) + 1] = val2latex(val)

    str=print_answers(format.width[num_question],format.num_rows[num_question],num_question,msg,res)
    return str

end

function question(format::PrintedQuestion, msg, eqs::Vector{String})

    format.int_params[2]=format.int_params[2]+1
    num_question = format.int_params[2]
    pos = format.right[format.int_params[2]][format.int_params[1]]
    res = Vector{String}(undef,5);
    perm = sample(2:5, 4, replace = false)
    res[mod(pos    , 5) + 1] = latexify(eqs[perm[1]])
    res[mod(pos + 1, 5) + 1] = latexify(eqs[perm[2]])
    res[mod(pos + 2, 5) + 1] = latexify(eqs[perm[3]])
    res[mod(pos + 3, 5) + 1] = latexify(eqs[perm[4]])
    res[mod(pos + 4, 5) + 1] = latexify(eqs[1]) # same as res[pos] = eqs[1]

    str=print_answers(format.width[num_question],format.num_rows[num_question],num_question,msg,res)

    return str

end

function print_answers(w,k,n,msg,res)
    str=""
    if k==1
        str = """\n
        \\textbf{$n} $msg \\\\
        \\begin{tabular}{*{5}{p{$w}}}
        a) $(res[1]) & b) $(res[2]) & c) $(res[3]) & d) $(res[4]) & e) $(res[5]) \\\\
        \\end{tabular}

        """
    elseif k==2
        str = """\n        
        \\textbf{$n} $msg \\\\
        \\begin{tabular}{*{3}{p{$w}}}
        a) $(res[1]) & b) $(res[2]) & c) $(res[3]) \\\\ 
        d) $(res[4]) & e) $(res[5]) & \\\\
        \\end{tabular}
    
        """
    end
end

function question(format::OnlineQuestion, msg, var, unitname=""; factor1=rand2(), factor2=1.2 + 0.2 * rand(), factor3=0.6 + 0.2 * rand(), factor4=1.6 + 0.2 * rand(),num_digits=4)

    val, latex_unit = get_value(var,unitname,num_digits)
    msg = replace(msg, "unitname" => latex_unit)
    format.int_params[2]=format.int_params[2]+1
    num_question = format.int_params[2]

    val1 = round(factor1*val, sigdigits=num_digits);
    val2 = round(factor2*val, sigdigits=num_digits);
    val3 = round(factor3*val, sigdigits=num_digits);
    val4 = round(factor4*val, sigdigits=num_digits);
    
    str="""
    \\begin{multi}$num_question. $msg \\\\ 
    \\item* $val
    \\item PENALTY$val1
    \\item PENALTY$val2
    \\item PENALTY$val3
    \\item PENALTY$val4
    \\item No contesta
    \\end{multi}

    """

    return str
end

end
