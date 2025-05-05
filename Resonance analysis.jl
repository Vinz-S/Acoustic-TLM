include("post.jl")
using TOML
using JLD2
using FileIO
using GLMakie
#= freqs, F = Analysis.signal_frequencies(Vector{Float64}(measurements[1]), 1/it_time) #test with the first measurement point
fig = Figure()
ax = Axis(fig[1, 1], title = "FFT of measurement point 1")#, xscale = log10)
stem!(ax, freqs, abs.(F), markersize = 10) =#

###First resonance test
config_name = "Resonances"
configs = TOML.parsefile(config_name*".toml")
dimensions = configs["mesh"]["dimensions"]["x"], configs["mesh"]["dimensions"]["y"], configs["mesh"]["dimensions"]["z"]

modes = Analysis.analytic_cubic_resonance(dimensions[1], dimensions[2], dimensions[3], configs["c"])

measurements = load(configs["measurements"]["filename"]*".jld2", "measurements")
it_time = configs["mesh"]["dimensions"]["tll"]/configs["c"] #time per iteration
nyquist = configs["c"]/(2*configs["mesh"]["dimensions"]["tll"])
freqs, F = Analysis.signal_frequencies(Vector{Float64}(measurements[1][Int(length(measurements[1])/2):Int(length(measurements[1]))]), 2*nyquist) #test with the first measurement point
fig = Figure()
    ax = Axis(fig[1, 1], title = "FFT", #xscale = log10,
    xminorticksvisible = true, xminorgridvisible = true,
    xminorticks = IntervalsBetween(5))
    lines!(ax, freqs, F)#, markersize = 10)
    xlims!(ax, 0, nyquist)
    display(fig)
#= fig = Figure()
ax = Axis(fig[1,1], title = "impulse response")
lines!(ax, 0:it_time:it_time*(length(measurements[1])-1), measurements[1])
display(fig) =#