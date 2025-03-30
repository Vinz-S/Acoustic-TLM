include("mesh-generator.jl")
include("TLM-solver.jl")

###Testing the modules
@time n, tree = Generator.nodes((50,50,40), "Tetraheder", 1.0);
Saving_dicts.to_text(n, "demo")
Saving_dicts.to_jld2(n, "demo") #tested in console using display(load("demo.jld2", "nodes"))
#Visually seeing that the coordinates are correct:
#= function show_mesh(nodes) #This function is very slow on anything more than a few crystals
    fig = Figure()
    ax3d = Axis3(fig[1,1], title = "Tetraheder points")
    scatter!(ax3d, [node.x for node in values(nodes)], [node.y for node in values(nodes)], [node.z for node in values(nodes)], markersize = 10)
    display(fig)
    transmission_lines = [(node.x, node.y, node.z, nodes[neighbour].x, nodes[neighbour].y, nodes[neighbour].z) for node in values(nodes) for neighbour in filter!(v->v!=0, node.neighbours)]
    for line in transmission_lines
        lines!(ax3d, [line[1], line[4]], [line[2], line[5]], [line[3], line[6]], color = :blue)
    end
    return fig
end

f = show_mesh(n) =#

#= for key in keys(n)
    n[key].outbound = [i[1] for i = enumerate(n[key].neighbours)]
    display(n[key].outbound)
end=#
#Solver.inbound(n, 4)

### Visually checking wave propagation
using GLMakie
Solver.generate_sine(n, (25, 25, 20), amplitude = 1, frequency = 1)

points = [Point3f(node.x, node.y, node.z) for node in values(n)]
pressures = Observable([node.on_node for node in values(n)])

fig, ax, l = scatter(points, color = pressures,
    colormap = :bluesreds,colorrange = (-1, 1),
    axis = (; type = Axis3, protrusions = (0, 0, 0, 0),
              viewmode = :fit), markersize = 10)

iterations = 240
record(fig, "lorenz.mp4", 1:iterations) do frame #default frame rate is 24 fps
    Solver.update_tlm!(n, frame/24) #might want to get a variable for the frame rate
    pressures[] = [node.on_node for node in values(n)]
    ax.azimuth[] = 1.7pi + 0.3 * sin(2pi * frame / 120)
end