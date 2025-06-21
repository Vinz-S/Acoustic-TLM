codepath = "/home/vinzenz/Documents/Master/Acoustic-TLM/"
include(codepath*"post.jl"); import .Colours: blue, orange, green, pink, lightblue, redish, yellow
include(codepath*"TLM-solver.jl")
include(codepath*"mesh-generator.jl")
using GLMakie
GLMakie.activate!(inline=false)
using TOML
using JLD2
using FileIO
using GLMakie
#= freqs, F = Analysis.signal_frequencies(Vector{Float64}(measurements[1]), 1/it_time) #test with the first measurement point
fig = Figure()
ax = Axis(fig[1, 1], title = "FFT of measurement point 1")#, xscale = log10)
stem!(ax, freqs, abs.(F), markersize = 10) =#

###First resonance test
config_name = "FR setups/C_shoe_sweep_5"
configs = TOML.parsefile("configs/"*config_name*".toml")
dimensions = configs["mesh"]["dimensions"]["x"], configs["mesh"]["dimensions"]["y"], configs["mesh"]["dimensions"]["z"]

measurements = load("results/"*configs["measurements"]["filename"]*".jld2", "measurements")
c = configs["c"]*sqrt(3) #speed of sound in the medium
it_time = (configs["mesh"]["dimensions"]["tll"]/c) #time per iteration
fs = 1/it_time #sampling frequency
fig = Figure()
faxs = [] #Frequency response amlitudes
iaxs = [] #Impulse response amplitudes
tax = 0:it_time:(length(measurements[1])-1)*it_time #time axis for the measurements
Fs = [[], 1:2]
modes = []
for (i, f) in enumerate(Analysis.analytic_cubic_resonance(dimensions[1], dimensions[2], dimensions[3], configs["c"]))
    f = f[1]
    i > 10 ? break : push!(modes, f)
end
#modes = modes.*1.15 #correction to adjust lines
for i in eachindex(measurements)
    push!(iaxs, Axis(fig[i, 2], title = "Measurement point $(i)", #xscale = log10,
    xminorticksvisible = true, xminorgridvisible = true,
    xminorticks = IntervalsBetween(5)))
    stairs!(iaxs[i], tax, measurements[i], step=:center)
    push!(faxs, Axis(fig[i, 1], title = "FFT of measurement point $(i)", xscale = log10,
    xminorticksvisible = true, xminorgridvisible = true,
    xminorticks = IntervalsBetween(5), ylabel = "Amplitude"))
    # I might want to inspect the impulse response and limit the lengths before calculating the frequency response.
    freqs, F = Analysis.signal_frequencies(Vector{Float64}(measurements[i]), fs, 20, 150) #test with the first measurement point
    push!(Fs[1], F/maximum(F)) #average frequency response
    stairs!(faxs[i], freqs, F, step=:center)#, markersize = 10)
    vlines!(faxs[i], modes, color = redish)
    # xlims!(faxs[i], 0, 250)
    Fs[2] = freqs
end

avg_f = zeros(length(Fs[1][1]))
for i in eachindex(Fs[1])
    avg_f .+= Fs[1][i]./length(Fs[1])
end

i = length(iaxs) + 1
    source = load("results/"*configs["measurements"]["filename"]*".jld2", "source output")[3][1]
    push!(iaxs, Axis(fig[i, 2], title = "source", #xscale = log10,
    xminorticksvisible = true, xminorgridvisible = true,
    xminorticks = IntervalsBetween(5), xlabel = "Time [s]"))
    stairs!(iaxs[i], [source[i][1] for i in eachindex(source)], [source[i][2] for i in eachindex(source)], step=:center)
    push!(faxs, Axis(fig[i, 1], title = "FFT source", xscale = log10,
    xminorticksvisible = true, xminorgridvisible = true,
    xminorticks = IntervalsBetween(5), xlabel = "Frequency [Hz]", ylabel = "Amplitude"))
    # I might want to inspect the impulse response and limit the lengths before calculating the frequency response.
    freqs, F = Analysis.signal_frequencies(Vector{Float64}([source[i][2] for i in eachindex(source)]), fs,20, 150) #test with the first measurement point
    stairs!(faxs[i], freqs, F/maximum(F), step=:center)#, markersize = 10)
    # xlims!(faxs[i], 0, 250)
    display(fig)


i = length(iaxs) + 1
    push!(iaxs, Axis(fig[i, 2]))
    hidespines!(iaxs[i])
    hidedecorations!(iaxs[i])
    push!(faxs, Axis(fig[i, 1], title = "Average normalized FFT of measurements", xscale = log10,
    xminorticksvisible = true, xminorgridvisible = true,
    xminorticks = IntervalsBetween(5), ylabel = "Amplitude"))
    stairs!(faxs[i], Fs[2], avg_f, step=:center)#, markersize = 10)
    vlines!(faxs[i], modes, color = redish)

#save("results/rooom frequencies2.png", fig)
