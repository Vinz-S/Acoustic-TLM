include("/home/vinzenz/Documents/Master/Acoustic-TLM/post.jl")
include("/home/vinzenz/Documents/Master/Acoustic-TLM/TLM-solver.jl")
include("/home/vinzenz/Documents/Master/Acoustic-TLM/mesh-generator.jl")
using TOML
using JLD2
using FileIO
using GLMakie
#= freqs, F = Analysis.signal_frequencies(Vector{Float64}(measurements[1]), 1/it_time) #test with the first measurement point
fig = Figure()
ax = Axis(fig[1, 1], title = "FFT of measurement point 1")#, xscale = log10)
stem!(ax, freqs, abs.(F), markersize = 10) =#

###First resonance test
config_name = "Chirp resonances"
configs = TOML.parsefile("configs/"*config_name*".toml")
dimensions = configs["mesh"]["dimensions"]["x"], configs["mesh"]["dimensions"]["y"], configs["mesh"]["dimensions"]["z"]

modes = Analysis.analytic_cubic_resonance(dimensions[1], dimensions[2], dimensions[3], configs["c"])

measurements = load("results/"*configs["measurements"]["filename"]*".jld2", "measurements")
it_time = configs["mesh"]["dimensions"]["tll"]/configs["c"] #time per iteration
fs = 1/it_time #sampling frequency
nyquist = fs/2
fig = Figure()
faxs = []
taxs = []
for i in eachindex(measurements)
    push!(taxs, Axis(fig[i, 2], title = "Measurement point $(i)", #xscale = log10,
    xminorticksvisible = true, xminorgridvisible = true,
    xminorticks = IntervalsBetween(5)))
    stairs!(taxs[i], measurements[i], step=:center)
    push!(faxs, Axis(fig[i, 1], title = "FFT of measurement point $(i)", #xscale = log10,
    xminorticksvisible = true, xminorgridvisible = true,
    xminorticks = IntervalsBetween(5)))
    # I might want to inspect the impulse response and limit the lengths before calculating the frequency response.
    freqs, F = Analysis.signal_frequencies(Vector{Float64}(measurements[i]), 2*nyquist) #test with the first measurement point
    stairs!(faxs[i], freqs, F, step=:center)#, markersize = 10)
    xlims!(faxs[i], 0, 350)
end
source = load("results/"*configs["measurements"]["filename"]*".jld2", "source output")[3][1]
    push!(taxs, Axis(fig[4, 2], title = "source", #xscale = log10,
    xminorticksvisible = true, xminorgridvisible = true,
    xminorticks = IntervalsBetween(5)))
    stairs!(taxs[4], [source[i][2] for i in eachindex(source)], step=:center)
    push!(faxs, Axis(fig[4, 1], title = "FFT source", #xscale = log10,
    xminorticksvisible = true, xminorgridvisible = true,
    xminorticks = IntervalsBetween(5)))
    # I might want to inspect the impulse response and limit the lengths before calculating the frequency response.
    freqs, F = Analysis.signal_frequencies(Vector{Float64}([source[i][2] for i in eachindex(source)]), 2*nyquist) #test with the first measurement point
    stairs!(faxs[4], freqs, F, step=:center)#, markersize = 10)
    xlims!(faxs[4], 0, 350)
display(fig)

#= @time n, tree = Generator.nodes(dimensions, crystal = "Cartesian", transmission_line_length = configs["mesh"]["dimensions"]["tll"]);
n[knn(tree, [0.3,0.3,0.3], 1, true)[1][1]].on_node = 1000 # Manual dirac source
Solver.outbound!(n)

#Solver.generate_dirac(n, (3.0,4,2.5), tree, amplitude = 500)
points = [Point3f(node.x, node.y, node.z) for node in values(n)]
pressures = Observable([node.on_node for node in values(n)])
absolute_sum = zeros(length(n))

fig, ax, s = scatter(points, color = pressures,
    colormap = :bluesreds,colorrange = (-1, 1),
    axis = (; type = Axis3, protrusions = (0, 0, 0, 0),
              viewmode = :fit), markersize = 10)
scatter!(ax, dirac["x"], dirac["y"], dirac["z"], markersize = 20, color = :black)
mics = configs["measurements"]["microphones"]

scatter!(ax, mics["x"], mics["y"], mics["z"], markersize = 20, color = :green)
fps = fs
iterations = Int(ceil(0.33*fs))
record(fig, "lorenz.mp4", 0:iterations, framerate = fps) do frame #default frame rate is 24 fps
    Solver.update_tlm!(n, frame/24, reflection_factor = 0) #might want to get a variable for the frame rate
    pressures[] = [node.on_node for node in values(n)]
    # ax.azimuth[] = (pi*frame/120)%2pi
    # ax.elevation[] = (pi*frame/120)%2pi
    #ax.azimuth[] = 1.7pi + 0.3 * sin(2pi * frame / 120)
end =#