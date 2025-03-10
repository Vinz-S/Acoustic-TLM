###This file is supposed to conatain the module for the pre-processo
#using JLD2
#using FileIO
using GLMakie
using NearestNeighbors
using FileIO

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

    function nodes(dimensions::Tuple{Int64, Int64, Int64}, crystal::String = "Tetraheder", transmission_line_length::Float64 = 1.0)
        scale = transmission_line_length/Blocks.transmission_line_length[crystal]
        transmission_line_length = scale*Blocks.transmission_line_length[crystal]
        crystal = Blocks.crystal[crystal]
        coordinates = Set()
        crystal_size = findmax(crystal[findmax(crystal)[2]])[1]
        for x = 1:ceil(dimensions[1]/crystal_size)
            for y = 1:ceil(dimensions[2]/crystal_size)
                for z = 1:ceil(dimensions[3]/crystal_size)
                    for i = eachindex(crystal)
                        push!(coordinates, (scale*(crystal[i][1]+(x-1)*crystal_size), scale*(crystal[i][2]+(y-1)*crystal_size), scale*(crystal[i][3]+(z-1)*crystal_size)))
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


###Testing the modules
n=Generator.nodes((10,10,6), "Tetraheder", 15.0);

#Visually seeing that the coordinates are correct:
function show_mesh(nodes) #This function is very slow on anything more than a few crystals
    fig = Figure()
    ax3d = Axis3(fig[1,1], title = "Tetraheder points")
    scatter!(ax3d, [key[1] for key in keys(nodes)], [key[2] for key in keys(nodes)], [key[3] for key in keys(nodes)], markersize = 10)
    display(fig)
    transmission_lines = [(key[1], key[2], key[3], neighbour[1], neighbour[2], neighbour[3]) for key in keys(nodes) for neighbour in nodes[key].neighbours]
    for line in transmission_lines
        lines!(ax3d, [line[1], line[4]], [line[2], line[5]], [line[3], line[6]], color = :blue)
    end
    return fig
end
f = show_mesh(n)

