include("mesh-generator.jl")
include("TLM-solver.jl")

# using CairoMakie
using GLMakie

function find_nearest_node(tree, position)
    indexes, distances = knn(tree, position, 1, true)
    return indexes[1]
end
### Cartesian implementation ###
n, tree = Generator.nodes((20.0,20.0,20.0), crystal = "Cartesian", transmission_line_length = 1.0)
n_followed = 3
followed_nodes = [Int(find_nearest_node(tree, [5.5, 5.5+i, 5.5])) for i in 0:n_followed-1]
#inbounds = [[] for i in 1:length(followed_nodes)]
on_nodes = [[] for i in 1:length(followed_nodes)]
#outbounds = [[] for i in 1:length(followed_nodes)]
iterations = 2
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
    #println("b")
    Solver.on_node!(n, timestamp)
    i <= 0 ? n[followed_nodes[1]].on_node += 1 : nothing
    # for i in followed_nodes
    #     display(n[i])
    # end
    println("Iteration: ", i)
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

### Tetrahedral implementation ###
#= n, tree = Generator.nodes((20.0,20.0,20.0))
n_followed = 3
followed_nodes = [Int(find_nearest_node(tree, [5.5+i*1/sqrt(3), 5.5+i/sqrt(3), 5.5])) for i in 0:n_followed-1]
#inbounds = [[] for i in 1:length(followed_nodes)]
on_nodes = [[] for i in 1:length(followed_nodes)]
#outbounds = [[] for i in 1:length(followed_nodes)]
iterations = 2
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
    #println("b")
    Solver.on_node!(n, timestamp)
    i <= 0 ? n[followed_nodes[1]].on_node += 1 : nothing
    # for i in followed_nodes
    #     display(n[i])
    # end
    println("Iteration: ", i)
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
end =#