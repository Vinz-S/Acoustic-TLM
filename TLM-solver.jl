module Solver
include("mesh-generator.jl")
    sine_sources::Vector{Any} = [] #[[node_index, amplitude, frequency, periods]]
    dirac_sources::Vector{Any} = [] #[[node_index, amplitude]]
    chirp_sources::Vector{Any} = [] #[[node_index, amplitude, frequency, periods]]
    source_outputs::Vector{Any} = [[],[],[]] #[[[(timestamp, amplitude)...]],[[[(timestamp, amplitude)]...]]
    using NearestNeighbors
    using StaticArrays
    using ChirpSignal
    function generate_sine(nodes, position, kdtree = nothing; amplitude = 1, frequency = 1, periods = Inf)
        if kdtree === nothing
            sorted_keys = sort([node[1] for node in nodes])
            kdtree = KDTree([SVector{3, Float64}(nodes[key].x, nodes[key].y, nodes[key].z) for key in sorted_keys])
        end
        indexes, distances = knn(kdtree, [position[1], position[2], position[3]], 1, true)
        #println("Position: "*string(position)*" Indexes: "*string(indexes)*" Distances: "*string(distances))
        push!(sine_sources, [indexes[1], amplitude, frequency, periods])
        push!(source_outputs[1], [])
    end
    function generate_dirac(nodes, position, kdtree = nothing; amplitude = 1)
        if kdtree === nothing
            sorted_keys = sort([node[1] for node in nodes])
            kdtree = KDTree([SVector{3, Float64}(nodes[key].x, nodes[key].y, nodes[key].z) for key in sorted_keys])
        end
        indexes, distances = knn(kdtree, [position[1], position[2], position[3]], 1, true)
        println("Position: "*string(position)*" Indexes: "*string(indexes)*" Distances: "*string(distances))
        push!(dirac_sources, [indexes[1], amplitude])
        push!(source_outputs[2], [])
    end
    function generate_chirp(nodes, position, fs, f1, fh, T, kdtree = nothing; amplitude = 1, method = "logarithmic")
        if kdtree === nothing
            sorted_keys = sort([node[1] for node in nodes])
            kdtree = KDTree([SVector{3, Float64}(nodes[key].x, nodes[key].y, nodes[key].z) for key in sorted_keys])
        end
        indexes, distances = knn(kdtree, [position[1], position[2], position[3]], 1, true)
        #println("Position: "*string(position)*" Indexes: "*string(indexes)*" Distances: "*string(distances))
        push!(chirp_sources, [indexes[1], fs, T, chirp(T, fs, fl, fh; method = method)])
        push!(source_outputs[3], [])
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
    function on_node!(nodes, timestamp)
        no_branches = length(nodes[1].neighbours)
        for key in keys(nodes)
            nodes[key].on_node = 2/no_branches*sum(nodes[key].inbound)
        end
        for (i, source) in enumerate(sine_sources)
            source[4] != Inf ? (timestamp > source[4]*source[3]^-1 ? continue : nothing) : nothing
            output = source[2]*sin(2*pi*source[3]*timestamp)
            nodes[source[1]].on_node += output
            push!(source_outputs[1][i],[timestamp, output])
        end
        timestamp != 0 ? nothing : for (i, source) in enumerate(dirac_sources)
            nodes[source[1]].on_node += source[2]
            push!(source_outputs[2][i],[timestamp, source[2]])
            println("Iteration 0 run")
        end
        for (i, source) in enumerate(chirp_sources)
            if timestamp <= source[3]
                output = source[4][Int(round(timestamp*source[2]))+1] #+1 as the first timestamp is expected to be 0
                nodes[source[1]].on_node += output
                push!(source_outputs[3][i],[timestamp, output])
            end
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


