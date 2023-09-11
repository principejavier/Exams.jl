using Exams
include("problems.jl")

function generate_quiz(nump)

    headings=OnlineHeadings

    headings[SPA]["GraphicsPath"] = "{../assets/}"
    headings[CAT]["GraphicsPath"] = "{../assets/}"
    headings[ENG]["GraphicsPath"] = "{../assets/}"

    quiz = OnlineExam(nump,languages=[SPA],headings=headings,name="OnlineExamTest")
    mass=[1kg,2kg];
    h0=[1m,2m];
    v0=[1m/s,2m/s];
    add_problem!(quiz,InlinedFigure(0.4),ONE2ONE,free_fall,mass,h0,v0)

    # generate_pdf_files(exam)
    generate_tex_files(quiz)
    compile_tex_files(quiz)
    cleanup_files(quiz)
    return nothing

end