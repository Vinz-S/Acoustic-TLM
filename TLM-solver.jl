module Solver
include("mesh-generator.jl")
    sine_sources::Vector{Any} = [] #[[node_index, amplitude, frequency]]
    using NearestNeighbors
    using StaticArrays
    function generate_sine(nodes, position, kdtree = nothing; amplitude = 1, frequency = 1)
        if kdtree === nothing
            kdtree = KDTree([SVector{3, Float64}(node.x, node.y, node.z) for node in values(nodes)])
        end
        indexes, distances = knn(kdtree, [position[1], position[2], position[3]], 1, true)
        println("Position: "*string(position)*" Indexes: "*string(indexes)*" Distances: "*string(distances))
        push!(sine_sources, [indexes[1], amplitude, frequency])
    end
    function inbound!(nodes; reflection_factor = 1.0)
        for key in keys(nodes)
            pressures = []
            for (index, neighbour) in enumerate(nodes[key].neighbours)
                if neighbour != 0
                    push!(pressures, nodes[neighbour].outbound[findfirst(isequal(key), nodes[neighbour].neighbours)])
                elseif neighbour == 0
                    push!(pressures, nodes[key].outbound[index]*reflection_factor)
                end
            end
            nodes[key].inbound = pressures
        end
    end
    ##The following have not been tested:
    function on_node!(nodes, timestamp)
        no_branches = length(nodes[1].neighbours)
        for key in keys(nodes)
            nodes[key].on_node = 2/no_branches*sum(nodes[key].inbound)
        end
        #Sound sources won't work properly without an iterator controlling the amplitude
        for source in sine_sources
            nodes[source[1]].on_node += source[2]*sin(2*pi*source[3]*timestamp)
        end
    end
    function outbound!(nodes)
        for key in keys(nodes)
            nodes[key].outbound = [nodes[key].on_node - inbound for inbound in nodes[key].inbound]
        end
    end
    function update_tlm!(nodes, timestamp; reflection_factor = 1.0)
        inbound!(nodes, reflection_factor = reflection_factor)
        on_node!(nodes, timestamp)
        outbound!(nodes)
    end
end
