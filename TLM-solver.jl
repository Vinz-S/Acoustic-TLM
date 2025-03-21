module Solver
include("mesh-generator.jl")
    sine_sources::Vector{Any} = [] #[[node_index, amplitude, frequency]]
    using NearestNeighbors
    using StaticArrays
    function generate_sine(nodes, position, kdtree = none; amplitude = 1, frequency = 1)
        if kdtree == none
            kdtree = KDTree([[node.x, node.y, node.z]::Vector{SVector{3, Float64}} for node in values(nodes)])
        end
        indexes, distances = knn(kdtree, [position[1], position[2], position[3]], 1, true)
        println("Position: "*string(position)*" Indexes: "*string(indexes)*" Distances: "*string(distances))
        push!(sine_sources, [indexes[1], amplitude, frequency])
    end

    function inbound(nodes)
        for key in keys(nodes)
            nodes[key].inbound = [nodes[neighbour].outbound[findfirst(isequal(key), nodes[neighbour].neighbours)] for neighbour in nodes[key].neighbours]
        end
    end
    ##The following have not been tested:
    function at_node(nodes, no_branches, sines)
        for key in keys(nodes)
            nodes[key].on_node = 2/no_branches*sum(nodes[key].inbound)
        end
        for source in sound_sources
            nodes[source[1]].on_node += source[2]*sin(2*pi*source[3])
        end
    end
    function outbound(nodes)
        for key in keys(nodes)
            nodes[key].outbound = [nodes[key].at_node - inbound for inbound in nodes[key].inbound]
        end
    end
end
