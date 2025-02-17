###This file is supposed to conatain the module for the pre-processo
#using JLD2
#using FileIO
using GLMakie

module Blocks #Coordinates of a base block x,y,z
    Cartesian = [(x,y,z) for x = 0:1, y = 0:1, z = 0:1]
    Cartesian = [Cartesian[i] for i = eachindex(Cartesian)]
    #Originally used half as big coordinates for the tetahedal, but scaled up so all values can be integers
    #This might need to be adjusted later on with regards to transmission line lengths
    Tetraheder = [(0,0,0); (2,2,0); (1,1,1); (2,0,2); (0,2,2)]
    Tetraheder = [Tetraheder;[(Tetraheder[i][1]+2,Tetraheder[i][2]+2,Tetraheder[i][3]) for i = eachindex(Tetraheder)];
    [(Tetraheder[i][1],Tetraheder[i][2]+2,Tetraheder[i][3]+2) for i = eachindex(Tetraheder)];
    [(Tetraheder[i][1]+2,Tetraheder[i][2],Tetraheder[i][3]+2) for i = eachindex(Tetraheder)];]
    unique!(Tetraheder) #clears duplicates
end

module Generator
    #Multithreading the process of multiplying the blocks?
    #Finding the neigbours by checkings what nodes are within a set radius
    mutable struct Node     #The node 
        ID::UInt64
        x::UInt64 #Coordinates of the node
        y::UInt64
        z::UInt64
        #Neigbouring stuff, outgoing pressures, neighbouring nodes, etc. Might just be a placeholder
        neighbours::Vector{}
    end;

    function mesh(dimensions::Tuple{Int64, Int64, Int64}, crystal::Vector{Tuple{Int64, Int64, Int64}})
        coordinates = Set()
        crystal_size = findmax(crystal[findmax(crystal)[2]])[1]
        for x = 1:ceil(dimensions[1]/crystal_size)
            for y = 1:ceil(dimensions[2]/crystal_size)
                for z = 1:ceil(dimensions[3]/crystal_size)
                    for i = eachindex(crystal)
                        push!(coordinates, (crystal[i][1]+(x-1)*crystal_size, crystal[i][2]+(y-1)*crystal_size, crystal[i][3]+(z-1)*crystal_size))
                    end
                end
            end
        end
        return coordinates
    end
end


#Visually seeing that the coordinates are correct:
#= f = Figure()
ax3d = Axis3(f[1,1], title = "Tetraheder points")
scatter!(ax3d, [i for i = Generator.mesh((8,8,4), Blocks.Tetraheder)], markersize = 10)
f =#