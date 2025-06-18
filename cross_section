include("mesh-generator.jl")
include("TLM-solver.jl")
include("post.jl")
import .Colours: blue, orange, green, pink, lightblue, redish, yellow

using ProgressBars
using CairoMakie
# using GLMakie

x = 81.0; y =81.0; z = 61.0
# @time n, tree = Generator.nodes((x,y,z), crystal = "Cartesian");
@time n, tree = Generator.nodes((x,y,z));
Solver.generate_sine(n, (x,y,z)./2, tree, frequency = 1.0, periods = 1, amplitude = 50)
lattice = Visualization.cross_section(n, 1, (x, y, z), "z", z/2, tree)
intensity = Observable(lattice[1])
borders = lattice[2]
fig = Figure(;size = (600, 600))
ax = Axis(fig[1, 1])
heatmap!(ax, borders[1], borders[2], intensity, colorrange = (-1, 1));
x1 = [0, x/2, x, x]
x2 = [x, x/2, 0, 0]
y1 = [0, 0, 0, y/2]
y2 = [y, y, y, y/2]
for i in 1:4
    lines!(ax, [x1[i], x2[i]], [y1[i], y2[i]], color = (redish, 0.5), linewidth = 3)
end
fps = 24
iterations = 180 #Number of frames to record
its = ProgressBar(0:iterations-1)
framesOfInterest = [0.5, 1, 2, 4] #In timestamps
framesOfInterest = [round(Int, f*fps) for f in framesOfInterest] #Convert to frames
hidedecorations!(ax)
# record(fig, "vid_results/cart_prop_check.mp4", its, framerate = fps) do frame #default frame rate is 24 fps
record(fig, "vid_results/tet_prop_check.mp4", its, framerate = fps) do frame #default frame rate is 24 fps
    Solver.update_tlm!(n, frame/fps, reflection_factor = 0.5) #might want to get a variable for the frame rate
    lattice = Visualization.cross_section(n, 1, (x, y, z), "z", z/2, tree)
    intensity[] = lattice[1]
    for j in framesOfInterest
        if frame == j
            # save("Cross section frames/cart_prop_check_$(frame).png", fig)
            save("Cross section frames/tet_prop_check_$(frame).png", fig)
        end
    end
    set_description(its, "Running simulation: ")
end 

#= for i in its
    Solver.update_tlm!(n, i/fps, reflection_factor = 0.5) #might want to get a variable for the frame rate
    lattice = Visualization.cross_section(n, 1, (x, y, z), "z", z/2, tree)
    intensity[] = lattice[1]
    for j in framesOfInterest
        if i == j
            save("Cross section frames/cart_prop_check_$(i).png", fig)
        end
    end
    set_description(its, "Running simulation: ")
end =#

#with framerate = 24 and frame/24 as timestamp we get a wavespeed of 24 not adjusted for the mesh speed discrepancy