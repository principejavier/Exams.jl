function generate_exam(nump)

    set_graphics_path("../assets/")
    # Optionally select the language and the basename of the output file
    # set_language("spanish")
    # set_basename("exam")

    mass=[1kg,2kg];
    h0=[1m,2m];
    v0=[1m/s,2m/s];
    vars_free_fall=collect(Iterators.take(Iterators.product(mass,h0,v0),nump))

    vars=(vars_free_fall,)
    sols=(free_fall,)

    generate_permutations(vars,sols)

end

function free_fall(vars,vars_out)

    (mass,h0,v0)=vars
    (mass_out,h0_out,v0_out)=vars_out
    g=9.81m/s^2
    g_out=var2latex(g,"m/s^2")

    #h=h0+v0*t-0.5*g*t^2
    t=2*v0/g+sqrt(v0^2+2*g*h0)/g
    v=v0-g*t
    P=mass*g

    if language=="spanish" 
        problem = "Un cuerpo de masa $mass_out es lanzado hacia arriba desde una altura $h0_out a una velocidad $v0_out. La aceleración local de la gravedad es $g_out. Determinar: \\\\ \n"
        question1, result1 = quest2latex("el tiempo que tarda en caer al suelo (en unitname),", t,"s");
        question2, result2 = quest2latex("la velocidad que alcanza al tocar el suelo (en unitname),", v,"km/h");
        question3, result3 = quest2latex("el peso del cuerpo (en unitname).", P,"N");
    elseif language=="catalan"
    elseif language=="english"
    end
    #figure = printfig(0.3,"fig:caidalibre","Cuerpo en caída libre","ball");
    figure = printfig_wrapped(0.3,"fig:caidalibre","Cuerpo en caída libre","ball");
    problem = problem*figure*question1*question2*question3
    results = result1*"; "*result2*"; "*"\n"
    return problem, results

end

