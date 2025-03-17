include("mesh-generator.jl")
include("TLM-solver.jl")

###Testing the modules
@time n=Generator.nodes((10,10,6), "Tetraheder", 2.0);
# saving_dicts.to_text(n, "demo")
# saving_dicts.to_jld2(n, "demo") #tested in console using display(load("demo.jld2", "nodes"))
#Visually seeing that the coordinates are correct:
function show_mesh(nodes) #This function is very slow on anything more than a few crystals
    fig = Figure()
    ax3d = Axis3(fig[1,1], title = "Tetraheder points")
    scatter!(ax3d, [key[1] for key in keys(nodes)], [key[2] for key in keys(nodes)], [key[3] for key in keys(nodes)], markersize = 10)
    display(fig)
    transmission_lines = [(key[1], key[2], key[3], neighbour[1], neighbour[2], neighbour[3]) for key in keys(nodes) for neighbour in nodes[key].neighbours]
    for line in transmission_lines
        lines!(ax3d, [line[1], line[4]], [line[2], line[5]], [line[3], line[6]], color = :blue)
    end
    return fig
end

f = show_mesh(n)
