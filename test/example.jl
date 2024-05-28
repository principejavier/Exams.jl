using Exams
include("problems.jl")

function generate_exam(nump)

    headings=StandardHeadings

    headings[SPA]["CourseTitle"] = "Mecánica 1 (M1)"
    headings[CAT]["CourseTitle"] = "Mecànica 1 (M1)"
    headings[ENG]["CourseTitle"] = "Mechanics 1 (M1)"

    headings[SPA]["ExamTitle"] = "Primer parcial"
    headings[CAT]["ExamTitle"] = "Primer parcial"
    headings[ENG]["ExamTitle"] = "First test"
    
    headings[SPA]["ExamDate"] = "01/01/2000"
    headings[CAT]["ExamDate"] = "01/01/2000"
    headings[ENG]["ExamDate"] = "01/01/2000"

    headings[SPA]["GraphicsPath"] = "{../assets/}"
    headings[CAT]["GraphicsPath"] = "{../assets/}"
    headings[ENG]["GraphicsPath"] = "{../assets/}"

    #exam = PrintedExam(nump,languages=[SPA],headings=headings)
    exam = PrintedExam(nump,languages=[SPA,CAT],headings=headings,name="PrintedExamTest",format=PrintedQuestion([1,2,1,1,1,2,5],[2cm,2cm,2cm,2cm,2cm,2.5cm,15cm]))

    mass=[1kg,2kg];
    h0=[1m,2m];
    v0=[1m/s,2m/s];
    add_problem!(exam,WrappedFigure(0.25,-5mm),ONE2ONE,free_fall,mass,h0,v0)

    add_vspace!(exam,5cm)

    mass=[1kg,2kg];
    α=[40°,50°]
    add_problem!(exam,NoFigure(),ALL2ALL,inclined_plane,mass,α)

    add_pagebreak!(exam)

    add_problem!(exam,NoFigure(),ALL2ALL,theory_questions)

    # generate_pdf_files(exam)
    generate_tex_files(exam)
    compile_tex_files(exam)
    cleanup_files(exam)
    return nothing
end
