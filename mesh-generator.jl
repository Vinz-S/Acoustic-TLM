###This file is supposed to conatain the module for the pre-processo
using JLD2
using FileIO
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
end

module Generator
    tll = 1 #transmissionlinelength
    # The geometries which are used:
    #Tetrahdal = 
    #Cartesian = 

    function mesh()
        
    end
end

#= 
#Visually seeing that the coordinates are correct:
f = Figure()
ax3d = Axis3(f[1,1], title = "Tetraheder points")
scatter!(ax3d, Blocks.Tetraheder)
f =#