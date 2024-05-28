function free_fall(mass,h0,v0,language=nothing,format=nothing)

    mass_out=var2out(mass)
    h0_out=var2out(h0)
    v0_out=var2out(v0,"","m/s")
    g=9.81m/s^2
    g_out=var2out(g,"","m/s^2")

    #h=h0+v0*t-0.5*g*t^2
    t=2*v0/g+sqrt(v0^2+2*g*h0)/g
    v=v0-g*t

    problem=Vector{String}(undef,0)
    if language==SPA 
        push!(problem,"Un cuerpo de masa $mass_out es lanzado hacia arriba desde una altura $h0_out a una velocidad $v0_out como se muestra en la figura~\\ref{fig:caidalibre}. La aceleración local de la gravedad es $g_out. Determinar:")
        push!(problem,figure("ball","fig:caidalibre","Cuerpo en caída libre");)
        push!(problem,question(format,"el tiempo que tarda en caer al suelo (en unitname),", t,"s");)
        push!(problem,question(format,"la velocidad que alcanza al tocar el suelo (en unitname),", v,"km/h");)
    elseif language==CAT
        push!(problem,"Un cos de massa $mass_out és llançat cap amunt des d'una alçada $h0_out a una velocitat $v0_out, com es mostra a la figura~\\ref{fig:caidalibre}. L'acceleració local de la gravetat és $g_out. Determinar:")
        push!(problem,figure("ball","fig:caidalibre","Cos en caiguda lliure");)
        push!(problem,question(format,"el temps que triga a caure a terra (en unitname),", t,"s");)
        push!(problem,question(format,"la velocitat que arriba a tenir al tocar a terra (en unitname),", v,"km/h");)
    elseif language==ENG
    else
        println("mass = ",mass)
        println("h0 = ",h0)
        println("v0 = ",v0)
        println("v = ",v)
        println("t = ",t)
        return nothing
    end
    return problem

end

function inclined_plane(mass,α,language=nothing,format=Unformatted)

    mass_out=var2out(mass)
    α_out=var2out(α,"\\alpha","°")
    g=9.81m/s^2
    g_out=var2out(g,"m/s^2")

    Fx=mass*g*sin(α)
    Fy=mass*g*cos(α)
    a=g*sin(α)

    problem=Vector{String}(undef,0)
    if language==SPA 
        push!(problem,"Un bloque de $mass_out desliza sobre un plano cuyo ángulo de inclinación es $α_out. Considerando $g_out, determinar:")
        push!(problem,question(format,"la componente paralela de la fuerza debida a la gravedad en unitname",Fx,"N"))
        push!(problem,question(format,"la componente normal de la fuerza debida a la gravedad en unitname",Fy,"N"))
        push!(problem,question(format,"la aceleración del bloque suponiendo una superficie sin fricción en unitname.",a,"m/s^2"))
    elseif language==CAT
        push!(problem,"Un bloc de $mass_out llisca sobre un pla que té un angle d'inclinació de $α_out. Considerant $g_out, determinar:")
        push!(problem,question(format,"la component paral·lela de la força deguda a la gravetat en unitname",Fx,"N"))
        push!(problem,question(format,"la component normal de la força deguda a la gravetat en unitname",Fy,"N"))
        push!(problem,question(format,"l'acceleració del bloc suposant una superfície sense fricció en unitname.",a,"m/s^2"))
    elseif language==ENG
        push!(problem,"A $mass_out block is sitting on an incline plane whose angle of inclination is $α_out. Considering $g_out, determine:")
        push!(problem,question(format,"the parallel component of the force due to gravity in unitname,",Fx,"N"))
        push!(problem,question(format,"the normal component of the force due to gravity in unitname,",Fy,"N"))
        push!(problem,question(format,"the block’s acceleration assuming a frictionless surface in unitname.",a,"m/s^2"))
    else
        println(mass,α)
    end
    return problem

end

function theory_questions(language=nothing,format=Unformatted)

    eq = Vector{String}(undef,5);
    eq[1]=latexify("F=m*a")    # this the correct one, it will be shuffled when generating permutations
    eq[2]=latexify("F=m*a^2")
    eq[3]=latexify("F=m*g")
    eq[4]=latexify("F=m/a")
    eq[5]=latexify("F=m^2*a")

    as = Vector{String}(undef,5);
    problem=Vector{String}(undef,0)
    if language==SPA 
        as[1]="la fuerza con la masa y la aceleración"
        as[2]="la fuerza con la aceleración"
        as[3]="la fuerza con la masa"
        as[4]="la aceleración con la masa"
        as[5]="ninguna de las otras"
        push!(problem,"Teoría de la mecànica clàssica.")
        push!(problem,question(format,"La ley de Newton se puede escribir como:",eq))
        push!(problem,question(format,"La ley de Newton relaciona:",as))
    elseif language==CAT
        as[1]="la força amb la massa i l'acceleració"
        as[2]="la força amb l'acceleració"
        as[3]="la força amb la massa"
        as[4]="l'acceleració amb la massa"
        as[5]="cap de les altres"
        push!(problem,"Teoria de la mecànica clàssica.")
        push!(problem,question(format,"La llei de Newton es pot escriure com:",eq))
        push!(problem,question(format,"La llei de Newton relaciona:",as))
    elseif language==ENG
        as[1]="force with mass and acceleration"
        as[2]="force with acceleration"
        as[3]="force with mass"
        as[4]="acceleration with mass"
        as[5]="none of the others"        
        push!(problem,"Theory of classical mechanics.")
        push!(problem,question(format,"The Newton law can be written as,",eq))
        push!(problem,question(format,"The Newton law relates,",eq))
    end
    return problem

end