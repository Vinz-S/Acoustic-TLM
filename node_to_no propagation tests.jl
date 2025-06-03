include("mesh-generator.jl")
include("TLM-solver.jl")

# using CairoMakie
using GLMakie

n, tree = Generator.nodes((20.0,20.0,20.0), crystal = "Cartesian", transmission_line_length = 1.0)

function find_nearest_node(tree, position)
    indexes, distances = knn(tree, position, 1, true)
    return indexes[1]
end

n_followed = 3
followed_nodes = [Int(find_nearest_node(tree, [5.5, 5.5+i, 5.5])) for i in 0:n_followed-1]
#inbounds = [[] for i in 1:length(followed_nodes)]
on_nodes = [[] for i in 1:length(followed_nodes)]
#outbounds = [[] for i in 1:length(followed_nodes)]

iterations = 3
for i in 0:iterations
    timestamp = i/60
    # println("\n Iteration: "*string(i))
    # for i in followed_nodes
    #     display(n[i])
    # end
    # println("a")
    Solver.inbound!(n, reflection_factor = 0)
    # for i in followed_nodes
    #     display(n[i])
    # end
    println("b")
    Solver.on_node!(n, timestamp)
    i <= 0 ? n[followed_nodes[1]].on_node += 1 : nothing
    for i in followed_nodes
        display(n[i])
    end
    println("c")
    #i <= 120 ? n[followed_nodes[1]].on_node += sin(2*pi*timestamp) : nothing
    Solver.outbound!(n)
    #i <= 120 ? n[followed_nodes[1]].outbound[4] += sin(2*pi*timestamp) : nothing
    # i <= 60 ? n[followed_nodes[1]].outbound .+= sin(2*pi*timestamp) : nothing
    for i in followed_nodes
        display(n[i])
    end
    # for (i, node) in enumerate(followed_nodes)
    #     push!(on_nodes[i], n[node].on_node)
    #     display(n[i])
    # end
end

# positions = []
# for node in followed_nodes
#     push!(positions, (n[node].x, n[node].y, n[node].z))
# end
# fig = Figure(size = (1200, 800), resolution = (1200, 800))
# range1 = [i for i in 1:ceil(Int64, n_followed/2)]
# range2 = [i for i in ceil(Int64, n_followed/2)+1:n_followed]
# ax1 = [Axis(fig[i, 1], title = "On_node "*string(positions[i])) for i in range1]
# ax2 = [Axis(fig[i-ceil(Int64, n_followed/2), 2], title = "On_node "*string(positions[i])) for i in range2]
# for i in 1:Int(length(followed_nodes)/2)
#     lines!(ax1[i], on_nodes[range1[i]], color = :red)
#     try lines!(ax2[i], on_nodes[range2[i]], color = :red)
#     catch
#     end   
#     #lines!(axo[i], outbounds[i], color = :green)
# end
# #save("On_axis.pdf", fig)
# fig

# fig = Figure(size = (1200, 800), resolution = (1200, 800))
# source = Solver.source_outputs[1][1]
# stairs!(fig[1, 1], [point[1] for point in source], [point[2] for point in source]; step=:center, color = :red, label = "On_node 1")