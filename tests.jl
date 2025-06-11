#This file is written with the intention of testing different modules and functions
include("mesh-generator.jl")
include("TLM-solver.jl")
include("post.jl")
using GLMakie
###Testing the modules
@time n, tree = Generator.nodes((3.0,3.0,2.0))#; crystal = "Cartesian", transmission_line_length = 1.0)# sqrt(3));
#@time n, tree = Generator.sphere(3.5; crystal = "Tetraheder", transmission_line_length = 0.1);

Saving_dicts.to_text(n, "results/small_mesh") #Saving the nodes to a text file
#Saving_dicts.to_jld2(n, tree, "demo") #tested in console using display(load("demo.jld2", "nodes"))

#=
#Visually seeing that the coordinates are correct:
function show_mesh(nodes) #This function is very slow on anything more than a few crystals
    fig = Figure()
    ax3d = Axis3(fig[1,1], title = "Tetraheder points")
    scatter!(ax3d, [node.x for node in values(nodes)], [node.y for node in values(nodes)], [node.z for node in values(nodes)], markersize = 10)
    display(fig)
    transmission_lines = [(node.x, node.y, node.z, nodes[neighbour].x, nodes[neighbour].y, nodes[neighbour].z) for node in values(nodes) for neighbour in filter!(v->v!=0, node.neighbours)]
    for line in transmission_lines
        lines!(ax3d, [line[1], line[4]], [line[2], line[5]], [line[3], line[6]], color = :blue)
    end
    return fig
end

f = show_mesh(n)
=#

#= for key in keys(n)
    n[key].outbound = [i[1] for i = enumerate(n[key].neighbours)]
    display(n[key].outbound)
end=#
#Solver.inbound(n, 4)

#= 
### Visually checking wave propagation using a cross section
using GLMakie
using JLD2
using FileIO
using NearestNeighbors
using StaticArrays
using Statistics
@time n, tree = Generator.nodes((80.0,80.0,60.0), crystal = "Tetraheder");
Solver.generate_sine(n, (40,40, 30), tree, frequency = 1.0, periods = 1, amplitude = 50)
lattice = Visualization.cross_section(n, 1, (80.0, 80.0, 60), "z", 30, tree)
intensity = Observable(lattice[1])
borders = lattice[2]
fig, ax, hmap = heatmap(borders[1], borders[2], intensity, colorrange = (-1, 1))

iterations = 180
record(fig, "vid_results/tet_prop_check.mp4", 0:iterations, framerate = 24) do frame #default frame rate is 24 fps
    Solver.update_tlm!(n, frame/24, reflection_factor = 0.5) #might want to get a variable for the frame rate
    lattice = Visualization.cross_section(n, 1, (80.0, 80.0, 60.0), "z", 30, tree)
    intensity[] = lattice[1]
    borders = lattice[2]
end =#

#= 
### Visually checking wave propagation with dirac pulse
using GLMakie
using JLD2
using FileIO
using NearestNeighbors
using StaticArrays
using Statistics
#n, tree = load("demo.jld2", "nodes")
@time n, tree = Generator.nodes((10.0,10.0,8.0), crystal = "Tetraheder");
Solver.generate_dirac(n, (2, 2, 2), tree, amplitude = 2)

points = [Point3f(node.x, node.y, node.z) for node in values(n)]
pressures = Observable([node.on_node for node in values(n)])
absolute_sum = zeros(length(n))

fig, ax, l = scatter(points, color = pressures,
    colormap = :bluesreds,colorrange = (-1, 1),
    axis = (; type = Axis3, protrusions = (0, 0, 0, 0),
              viewmode = :fit), markersize = 10)

iterations = 840
record(fig, "lorenz.mp4", 0:iterations) do frame #default frame rate is 24 fps
    Solver.update_tlm!(n, frame/24, reflection_factor = 1) #might want to get a variable for the frame rate
    pressures[] = [node.on_node for node in values(n)]
    # ax.azimuth[] = (pi*frame/120)%2pi
    # ax.elevation[] = (pi*frame/120)%2pi
    ax.azimuth[] = 1.7pi + 0.3 * sin(2pi * frame / 120)
    frame > 4*iterations/5 ? absolute_sum .+= abs.([n[i].on_node for i in 1:length(n)]) : nothing
end

#inrange(tree,SVector(50,0,0),2.0)                
println("mean absolute sum: ", mean(absolute_sum))
println("max absolute sum: ", maximum(absolute_sum))
println("min absolute sum: ", minimum(absolute_sum))
println("median absolute sum: ", median(absolute_sum))
for i in eachindex(absolute_sum)
    absolute_sum[i] == 8.912279018801708 ? println(i) : nothing
end

function show_mesh(nodes) #This function is very slow on anything more than a few crystals
    fig = Figure()
    ax3d = Axis3(fig[1,1], title = "Tetraheder points")
    points = [Point3f(nodes[i].x, nodes[i].y, nodes[i].z) for i in 1:length(nodes)]
    scatter!(ax3d, points, color = absolute_sum, colorrange = (minimum(absolute_sum), maximum(absolute_sum)), markersize = 10)
    #scatter!(ax3d, [node.x for node in values(nodes)], [node.y for node in values(nodes)], [node.z for node in values(nodes)], markersize = 10)
    display(fig)
    transmission_lines = [(node.x, node.y, node.z, nodes[neighbour].x, nodes[neighbour].y, nodes[neighbour].z) for node in values(nodes) for neighbour in filter!(v->v!=0, node.neighbours)]
    for line in transmission_lines
        lines!(ax3d, [line[1], line[4]], [line[2], line[5]], [line[3], line[6]], color = (:black, 0.1))
    end
    return fig
end

f = show_mesh(n) =#

#= fig = Figure()
ax = Axis(fig[1, 1], title = "Source output")
data = Solver.source_outputs[1][1]
lines!(ax, [data[i][2] for i in eachindex(data)], [data[i][1] for i in eachindex(data)])
fig =#
#=
#inrange(tree,SVector(50,0,0),2.0)
println("mean absolute sum: ", mean(absolute_sum))
println("max absolute sum: ", maximum(absolute_sum))
println("min absolute sum: ", minimum(absolute_sum))
println("median absolute sum: ", median(absolute_sum))
for i in eachindex(absolute_sum)
    absolute_sum[i] == 8.912279018801708 ? println(i) : nothing
end
56.43040344862393 =#

#= function show_mesh(nodes) #This function is very slow on anything more than a few crystals
    fig = Figure()
    ax3d = Axis3(fig[1,1], title = "Tetraheder points")
    points = [Point3f(nodes[i].x, nodes[i].y, nodes[i].z) for i in 1:length(nodes)]
    scatter!(ax3d, points, color = absolute_sum, colorrange = (minimum(absolute_sum), maximum(absolute_sum)), markersize = 10)
    #scatter!(ax3d, [node.x for node in values(nodes)], [node.y for node in values(nodes)], [node.z for node in values(nodes)], markersize = 10)
    display(fig)
    transmission_lines = [(node.x, node.y, node.z, nodes[neighbour].x, nodes[neighbour].y, nodes[neighbour].z) for node in values(nodes) for neighbour in filter!(v->v!=0, node.neighbours)]
    for line in transmission_lines
        lines!(ax3d, [line[1], line[4]], [line[2], line[5]], [line[3], line[6]], color = (:black, 0.1))
    end
    return fig
end

f = show_mesh(n) =#

#### Testing the frequency analysis 
#= 
using TOML
using JLD2
using FileIO
using GLMakie
#= freqs, F = Analysis.signal_frequencies(Vector{Float64}(measurements[1]), 1/it_time) #test with the first measurement point
fig = Figure()
ax = Axis(fig[1, 1], title = "FFT of measurement point 1")#, xscale = log10)
stem!(ax, freqs, abs.(F), markersize = 10) =#

signal_length = 431
fs = 20 #sampling frequency
signal = [sin(2*pi*0.1*i)+cos(2*pi*0.5*i) for i in range(0, step = 1/fs, length = signal_length)]

nyquist = fs/2
it_time = 1/fs #time per iteration
fig = Figure()
ax1 = Axis(fig[1, 1], title = "Time domain")#, xscale = log10)
ax2 = Axis(fig[2, 1], title = "Frequncy domain")#, xscale = log10)
lines!(ax1, signal)
freqs, F = Analysis.signal_frequencies(Vector{Float64}(signal), fs) #test with the first measurement point
lines!(ax2, freqs, F)#, markersize = 10)
xlims!(ax2, 0, nyquist)

display(fig)
=#
