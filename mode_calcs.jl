include("post.jl")
include("mesh-generator.jl")
using SpecialFunctions
using Peaks
using GLMakie
GLMakie.activate!(inline=false)
#Calculating time spent for 4 reflections between the longest apart walls.
(4*4)/343

function Sabines(x,y,z,α) #shoe-box reverberation time calculation
    #Calculating the reverberation time using Sabine's formula
    #x,y,z are the dimensions of the room in m
    #α is the absorption coefficient
    V = x*y*z
    S = 2*(x*y + y*z + z*x)
    RT = 0.161*V/(S*α)
    return RT
end
function Sabines(r, α) #sphere reverberation time calculation
    #Calculating the reverberation time using Sabine's formula
    #r is the radius of the room in m
    #α is the absorption coefficient
    V = (4/3)*π*r^3
    S = 4*π*r^2
    RT = 0.161*V/(S*α)
    return RT
end

#Analysis.analytic_cubic_resonance(3,4,2.5,343)

println(SetupCalculations.tllFromResolution(5, 343, 115))
println(SetupCalculations.tllFromResolution(10, 343, 115))
println(SetupCalculations.tllFromResolution(20, 343, 115))

fs = Analysis.analytic_spherical_resonance(2,343)
f = [f[1] for f in fs]
m = [m[2] for m in fs]
display(fs)

fs = Analysis.analytic_cubic_resonance(3,4,2.5,343)
f = [f[1] for f in fs]
m = [m[2] for m in fs]
display(fs)

fig = Figure()
ax = Axis(fig[1,1])
stem!(ax, f, [1 for i in f])
fig

println(SetupCalculations.tllFromResolution(5, 343, 215))
println(SetupCalculations.tllFromResolution(10, 343, 215))
println(SetupCalculations.tllFromResolution(20, 343, 215))

r_factors = [0.9, 0.8, 0.5, 0.3, 0.2]
for r in r_factors
    cRT = Sabines(3,4,2.5,1-r)
    sRT = Sabines(2, 1-r)
    println("Reverberation time for a room with dimensions 3x4x2.5 m and absorption coefficient $(r): $(cRT) s")
    println("Reverberation time for a sphere with radius 2 m and absorption coefficient $(r): $(sRT) s")
end