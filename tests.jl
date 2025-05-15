#This file is written with the intention of testing different modules and functions
include("mesh-generator.jl")
include("TLM-solver.jl")
include("post.jl")
###Testing the modules
#@time n, tree = Generator.nodes((8.0,8.0,6.0); crystal = "Tetraheder", transmission_line_length = sqrt(3));
#@time n, tree = Generator.sphere(3.5; crystal = "Tetraheder", transmission_line_length = 0.1);

#Saving_dicts.to_text(n, "spherenodes")
#Saving_dicts.to_jld2(n, tree, "demo") #tested in console using display(load("demo.jld2", "nodes"))
#Visually seeing that the coordinates are correct:
# idxs = [39319;14544;65787;13163;64911]
# nodes = (n[i] for i in idxs)
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
using JLD2
using FileIO
using NearestNeighbors
using StaticArrays
using Statistics
#n, tree = load("demo.jld2", "nodes")
@time n, tree = Generator.nodes((80.0,80.0,60.0), crystal = "Tetraheder");
Solver.generate_dirac(n, (2, 2, 2), tree, amplitude = 2000)

points = [Point3f(node.x, node.y, node.z) for node in values(n)]
pressures = Observable([node.on_node for node in values(n)])
absolute_sum = zeros(length(n))

fig, ax, l = scatter(points, color = pressures,
    colormap = :bluesreds,colorrange = (-1, 1),
    axis = (; type = Axis3, protrusions = (0, 0, 0, 0),
              viewmode = :fit), markersize = 10)

iterations = 60
record(fig, "lorenz.mp4", 0:iterations) do frame #default frame rate is 24 fps
    Solver.update_tlm!(n, frame/24, reflection_factor = 0) #might want to get a variable for the frame rate
    pressures[] = [node.on_node for node in values(n)]
    # ax.azimuth[] = (pi*frame/120)%2pi
    # ax.elevation[] = (pi*frame/120)%2pi
    ax.azimuth[] = 1.7pi + 0.3 * sin(2pi * frame / 120)
    frame > 4*iterations/5 ? absolute_sum .+= abs.([n[i].on_node for i in 1:length(n)]) : nothing
end

#inrange(tree,SVector(50,0,0),2.0)
println("mean absolute sum: ", mean(absolute_sum))
println("max absolute sum: ", maximum(absolute_sum))
println("min absolute sum: ", minimum(absolute_sum))
println("median absolute sum: ", median(absolute_sum))
for i in eachindex(absolute_sum)
    absolute_sum[i] == 8.912279018801708 ? println(i) : nothing
end
56.43040344862393

#= function show_mesh(nodes) #This function is very slow on anything more than a few crystals
    fig = Figure()
    ax3d = Axis3(fig[1,1], title = "Tetraheder points")
    points = [Point3f(nodes[i].x, nodes[i].y, nodes[i].z) for i in 1:length(nodes)]
    scatter!(ax3d, points, color = absolute_sum, colorrange = (minimum(absolute_sum), maximum(absolute_sum)), markersize = 10)
    #scatter!(ax3d, [node.x for node in values(nodes)], [node.y for node in values(nodes)], [node.z for node in values(nodes)], markersize = 10)
    display(fig)
    transmission_lines = [(node.x, node.y, node.z, nodes[neighbour].x, nodes[neighbour].y, nodes[neighbour].z) for node in values(nodes) for neighbour in filter!(v->v!=0, node.neighbours)]
    for line in transmission_lines
        lines!(ax3d, [line[1], line[4]], [line[2], line[5]], [line[3], line[6]], color = (:black, 0.1))
    end
    return fig
end

f = show_mesh(n) =#