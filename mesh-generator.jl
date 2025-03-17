###This file is supposed to conatain the module for the pre-processo
using GLMakie
using NearestNeighbors

module Blocks #Coordinates of a base block x,y,z
    # export Cartesian, Tetraheder
    Cartesian = [(x,y,z) for x = 0:1, y = 0:1, z = 0:1]
    Cartesian = [Cartesian[i] for i = eachindex(Cartesian)]
    #Originally used half as big coordinates for the tetahedal, but scaled up so all values can be integers
    #This might need to be adjusted later on with regards to transmission line lengths
    Tetraheder = [(0,0,0); (2,2,0); (1,1,1); (2,0,2); (0,2,2)]
    Tetraheder = [Tetraheder;[(Tetraheder[i][1]+2,Tetraheder[i][2]+2,Tetraheder[i][3]) for i = eachindex(Tetraheder)];
    [(Tetraheder[i][1],Tetraheder[i][2]+2,Tetraheder[i][3]+2) for i = eachindex(Tetraheder)];
    [(Tetraheder[i][1]+2,Tetraheder[i][2],Tetraheder[i][3]+2) for i = eachindex(Tetraheder)];]
    unique!(Tetraheder) #clears duplicates
    transmission_line_length = Dict("Cartesian"=>(1), "Tetraheder"=>(sqrt(1^2+1^2+1^2)))
    crystal = Dict("Cartesian"=>Cartesian, "Tetraheder"=>Tetraheder)
end

module Generator
    using NearestNeighbors: KDTree, inrange
    using StaticArrays
    import ..Blocks
    #Multithreading the process of multiplying the blocks?
    #Finding the neigbours by checkings what nodes are within a set radius
    mutable struct Node     #The node
        neighbours::Vector{SVector{3, Float64}}
        incoming::Vector{Any}#The indexes of the vectors correspond to the neighbours indexes
        outgoing::Vector{Any}
        on_node::Float64
    end;
    function scale_crystal(crystal::Vector{Tuple{Int64, Int64, Int64}}, scale::Float64)
        return [(scale*crystal[i][1], scale*crystal[i][2], scale*crystal[i][3]) for i = eachindex(crystal)]
    end
    
    function nodes(dimensions::Tuple{Int64, Int64, Int64}, crystal::String = "Tetraheder", transmission_line_length::Float64 = 1.0)
        scale = transmission_line_length/Blocks.transmission_line_length[crystal]
        transmission_line_length = scale*Blocks.transmission_line_length[crystal]
        crystal = scale_crystal(Blocks.crystal[crystal], scale)
        coordinates = Set()
        crystal_size = findmax(crystal[findmax(crystal)[2]])[1]
        for x = 1:ceil(dimensions[1]/crystal_size)
            for y = 1:ceil(dimensions[2]/crystal_size)
                for z = 1:ceil(dimensions[3]/crystal_size)
                    for i = eachindex(crystal)
                        push!(coordinates, ((crystal[i][1]+(x-1)*crystal_size), (crystal[i][2]+(y-1)*crystal_size), (crystal[i][3]+(z-1)*crystal_size)))
                    end
                end
            end
        end
        nodes = Dict()
        data::Vector{SVector{3, Float64}} = [[coord[1], coord[2], coord[3]] for coord in coordinates]
        for coord in data
            nodes[coord] = Node([], [], [], 0.0)
        end
        #The indexes of the nodes in the KDTree are the same as the indexes of the coordinates in the data vector
        kdtree = KDTree(data)
        for key in keys(nodes) #0.01 margin added to the transmission line length to make up for rounding errors
            neighbours = [data[index] for index in inrange(kdtree, key, transmission_line_length+0.01)]
            nodes[key].neighbours = filter!(v->v!=key,neighbours)
        end
        return nodes
    end
end

module saving_dicts
    using JLD2
    using FileIO
    function to_text(dictionary::Dict{Any, Any}, filename::String)
        f = open(filename*".txt", "w")
        print(f, typeof(dictionary), "\n")
        for key in keys(dictionary)
            print(f, key, "=>", dictionary[key], "\n")
        end
        close(f)
    end

    function to_jld2(dictionary::Dict{Any, Any}, filename::String) #Is loaded using load("filename.jld2", "nodes")
        save(filename*".jld2", "nodes", dictionary)
    end
end

