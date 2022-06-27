module Exams

# Write your package code here.

using CSV
using DataFrames
using Mustache
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

export generate_permutations
export var2latex
export unit
export printfig
export printfig_wrapped
export quest2latex
export language
export set_prefix
export set_language
export headings

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

const latex_head="""
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
\\renewcommand{\\figurename}{Figura}
\\renewcommand{\\tablename}{Tabla}
\\linespread{1.3}
\\parindent 0mm
\\parskip 3mm
\\textfloatsep 6pt
\\floatsep  6pt
\\intextsep 6pt
\\graphicspath{ {{{graphics_path}}} }

\\begin{document}
\\pagestyle{empty}

\\begin{table}[t]
  \\begin{center}
    \\begin{tabular}{|l|l|l|}
      \\hline
      {\\bf {{{course_title}}} } \\quad & {{{exam_title}}} {{{exam_date}}} \\quad \\quad \\quad \\quad \\quad & {{{permutation_name}}} {{{permutation_num}}} \\\\
      \\hline
      {{student_id}}: & \\multicolumn{2}{|l|}{ {{student_name}}: } \\\\ \\hline
      \\multicolumn{3}{|l|}{
      \\begin{minipage}{\\textwidth}
      \\vspace{2mm}
      {{{rules}}}
      \\end{minipage}}
      \\\\ \\hline
    \\end{tabular}
  \\end{center}
\\end{table}

"""

const latex_tail = "\n\\end{document}\n"

language = "spanish"
prefix = "exam"
num_question = 0
num_problem = 0
num_permutation = 0
max_questions = 50
max_permutations = 12
right_names = ["A","B","C","D","E"]
examio_head1 = ["1","2","3","4","5","6","7","8","9","10","11","12"]  # permutacio
examio_head2 = ["1","1","1","1","1","1","1","1","1","1","1","1"]  # grup

headings = Dict{String,Dict{String, String}}()
headings["spanish"]=Dict{String,String}()
headings["catalan"]=Dict{String,String}()
headings["english"]=Dict{String,String}()

headings["spanish"]["rules"]="Sólo hay una respuesta correcta para cada pregunta que debe ser marcada en la hoja de respuestas {\\bf llenando completamente el rectángulo correspondiente}. Cada respuesta incorrecta {\\bf resta un 25\\%} del valor de una correcta. En la hoja de respuestas es necesario marcar el DNI (o NIE o pasaporte) y la permutación."
headings["catalan"]["rules"]="Només hi ha una resposta correcta per a cada pregunta, marcar-la en la fulla de respostes {\\bf emplenant completament el rectangle corresponent}.  Cada resposta incorrecta {\\bf resta un 25\\%} del valor d'una correcta. En la fulla de respostes cal marcar el DNI (o NIE o passaport) i la permutació."
headings["english"]["rules"]="There is only one correct answer and answers need to be inputted into the provided answer sheet by {\\bf completely filling in the rectangle}. Each incorrect answer {\\bf subtracts 25\\%} of the value of a correct answer. On the answer sheet fill your ID (DNI, NIE or passport) and exam permutation. "

headings["spanish"]["language"]="spanish"
headings["catalan"]["language"]="catalan"
headings["english"]["language"]="english"

headings["spanish"]["student_id"]="DNI"
headings["catalan"]["student_id"]="DNI"
headings["english"]["student_id"]="ID"

headings["spanish"]["student_name"]="Nombre"
headings["catalan"]["student_name"]="Nom"
headings["english"]["student_name"]="Name"

headings["spanish"]["permutation_name"]="Permutación"
headings["catalan"]["permutation_name"]="Permutació"
headings["english"]["permutation_name"]="Permutation"

headings["spanish"]["permutation_num"]="1"
headings["catalan"]["permutation_num"]="1"
headings["english"]["permutation_num"]="1"

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

function set_prefix(name)
    global prefix
    prefix = name
end
function set_language(lang)
    global language
    language = lang
end

function define_correct_answers()
    global right
    if isfile("results.csv")
        df = CSV.read("results.csv", DataFrame, header=0)
        right = Matrix{Int}(df)
    else
        right = rand((1:5), max_questions, max_permutations)
        CSV.write("results.csv", Tables.table(right), writeheader=false)
    end
end

function generate_permutations(all_args, sols)

    define_correct_answers()

    # all_args is tuple of arrays{tuple}
    @assert length(sols) == length(all_args)
    num_perm = size(all_args[1], 1) # size of the first array
    num_prob = length(all_args)
    filename = prefix*"_"*language

    # Loop on permutations
    for i = 1:num_perm
        global num_permutation, num_question
        num_permutation = i
        num_question = 0

        filename = prefix*"_"*language*"_$i"
        io_tex = open(filename*".tex","w");
        headings[language]["permutation_num"]="$i"
        render(io_tex,latex_head,headings[language])

        # Loop over problems
        for k = 1:num_prob
            args = all_args[k] # k-th array
            p = args[i] # ith problem
            q = Vector{String}(undef, size(p, 1));
            for j = 1:size(p, 1)
                q[j] = var2latex(p[j])
            end
            write(io_tex, begin_problem(k))
            problem = sols[k](p, q)
            write(io_tex, problem);
            write(io_tex, end_problem())
        end
        write(io_tex, latex_tail);
        close(io_tex);
        pdflatex = `lualatex $(filename)`
        run(pdflatex)
        run(pdflatex)
        rm(filename*".aux")
        rm(filename*".log")
        rm(filename*".out")
    end

    CSV.write("results_examio.csv", Tables.table(hcat(examio_head1[1:num_perm],examio_head2[1:num_perm],right_names[transpose(right[1:num_question,1:num_perm])])), header=false, delim=";")

    return nothing

end

function printfig_wrapped(width, label, caption, name; vshift=0.0)
    figure = """
    \\begin{wrapfigure}{r}{$width\\textwidth}
    \\vspace{-$vshift cm}
    \\centering
    \\includegraphics[width=$width\\textwidth]{$name}
    \\end{wrapfigure}
    """
    return figure
end
function printfig(width, label, caption, name)
    figure = """
    \\begin{figure}[h!]
    \\centering
    \\includegraphics[width=$width\\textwidth]{$name}
    \\end{figure}

    """
    return figure
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
    if language == "spanish" 
        str = "\n \\noindent \\textbf{Problema $prob} \n\n"
    elseif language == "catalan"
      str = "\n \\noindent \\textbf{Problema $prob} \n\n"
    elseif language == "english"
      str = "\n \\noindent \\textbf{Problem $prob} \n\n "
    end
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

function var2latex(var, varname="", unitname=""; num_digits=4)

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

function quest2latex(msg, var, unitname=""; factor1=rand2(), factor2=1.2 + 0.2 * rand(), factor3=0.6 + 0.2 * rand(), factor4=1.6 + 0.2 * rand(),num_digits=4)

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

    global num_question,num_permutation
    num_question = num_question + 1
    pos = right[num_question,num_permutation]
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

end
