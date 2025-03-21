include("mesh-generator.jl")
include("TLM-solver.jl")

###Testing the modules
@time n, tree = Generator.nodes((10,10,6), "Tetraheder", 2.0);
Saving_dicts.to_text(n, "demo")
Saving_dicts.to_jld2(n, "demo") #tested in console using display(load("demo.jld2", "nodes"))
#= #Visually seeing that the coordinates are correct:
function show_mesh(nodes) #This function is very slow on anything more than a few crystals
    fig = Figure()
    ax3d = Axis3(fig[1,1], title = "Tetraheder points")
    scatter!(ax3d, [node.x for node in values(nodes)], [node.y for node in values(nodes)], [node.z for node in values(nodes)], markersize = 10)
    display(fig)
    transmission_lines = [(node.x, node.y, node.z, nodes[neighbour].x, nodes[neighbour].y, nodes[neighbour].z) for node in values(nodes) for neighbour in node.neighbours]
    for line in transmission_lines
        lines!(ax3d, [line[1], line[4]], [line[2], line[5]], [line[3], line[6]], color = :blue)
    end
    return fig
end

f = show_mesh(n)
 =#
for key in keys(n)
    n[key].outbound = [i[1] for i = enumerate(n[key].neighbours)]
    display(n[key].outbound)
end

Solver.inbound(n, 4)
