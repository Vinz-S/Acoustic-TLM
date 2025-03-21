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
            pressures = []
            for (index, neighbour) in enumerate(nodes[key].neighbours)
                if neighbour != 0
                    push!(pressures, nodes[neighbour].outbound[findfirst(isequal(key), nodes[neighbour].neighbours)])
                elseif neighbour == 0
                    #Currently a 100 percent reflection factor in branches without a neighbour
                    push!(pressures, nodes[key].outbound[index])
                end
            end
            nodes[key].inbound = [nodes[neighbour].outbound[findfirst(isequal(key), nodes[neighbour].neighbours)] for neighbour in nodes[key].neighbours]
        end
    end
    ##The following have not been tested:
    function at_node(nodes, sines)
        no_branches = length(nodes[1].neighbours)
        for key in keys(nodes)
            nodes[key].on_node = 2/no_branches*sum(nodes[key].inbound)
        end
        #Sound sources won't work properly without an iterator controlling the amplitude
        for source in sound_sources
            nodes[source[1]].on_node += source[2]*sin(2*pi*source[3])
        end
    end
    function outbound(nodes)
        for key in keys(nodes)
            nodes[key].outbound = [nodes[key].at_node - inbound for inbound in nodes[key].inbound]
        end
    end
    function update_tlm(nodes, no_branches)
        inbound(nodes)
        at_node(nodes, sine_sources)
        outbound(nodes)
    end
end
