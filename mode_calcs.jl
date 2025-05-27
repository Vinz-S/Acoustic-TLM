#Calculating time spent for 4 reflections between the longest apart walls.
(4*4)/343

function Sabines(x,y,z,α)
    #Calculating the reverberation time using Sabine's formula
    #x,y,z are the dimensions of the room in m
    #α is the absorption coefficient
    V = x*y*z
    S = 2*(x*y + y*z + z*x)
    ΡT = 0.161*V/(S*α)
    return ΡT
end
Sabines(3,4,2.5,1-0.25)
Sabines(3,4,2.5,1-0.8)

Analysis.analytic_cubic_resonance(3,4,2.5,343)

SetupCalculations.tllByResolution(10, 343, 150)

