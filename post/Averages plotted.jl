codepath = "/home/vinzenz/Documents/Master/Acoustic-TLM/"
include(codepath*"post.jl"); import .Colours: blue, orange, green, pink, lightblue, redish, yellow
include(codepath*"TLM-solver.jl")
include(codepath*"mesh-generator.jl")
# using GLMakie
# GLMakie.activate!(inline=false)
using CairoMakie
using TOML
using JLD2
using FileIO

data_files = ["average fft C_shoe_dirac.jld2";
        "average fft T_shoe_dirac.jld2";
        "average fft C_shoe_sweep.jld2";
        "average fft T_shoe_sweep.jld2";
        "average fft C_sphere_dirac.jld2";
        "average fft T_sphere_dirac.jld2";
        "average fft C_sphere_sweep.jld2";
        "average fft T_sphere_sweep.jld2"]
colours = [blue, green, pink]
resolutions = ["5", "10", "20"]

width = 1050; height = 800
fig = Figure(size = (width, height), fontsize = 20)
    supertitle = Label(fig[0, 1:1], "Shoe-box frequency responses", fontsize = 30, tellwidth = false)

for (i, file) in enumerate(data_files[1:4])
    data = load("results/fft averages/" * file)
    Fs = data["Fs"]
    modes = data["modes"]
    avg_f = data["avg_f"]
    
    crystal = (i%2 == 0 ? "tetrahedral" : "cartesian")
    signal = (i <= 2 ? "dirac" : "sine sweep")
    ax = Axis(fig[i, 1],
    title = "Signal: $signal\t Cavity: shoe-box\t Crystal: $crystal\t ",
    xscale = log10, xminorticksvisible = true, xminorgridvisible = true,
    xminorticks = IntervalsBetween(5), ylabel = "Amplitude", xlabel = (i == 4 ? "Frequency [Hz]" : ""))
    plots = []
    for j in eachindex(Fs)
        push!(plots, stairs!(ax, Fs[j][2], avg_f[j], step=:center, color=colours[j]))
    end
    mode = vlines!(ax, modes, color = redish)
    if i == 4
        Legend(fig[5, 1:1], [plots;[mode]],
        [["TLLs per Wavelength: $(resolutions[j])" for j in eachindex(Fs)];["Analytical mode"]], tellwidth = false, orientation = :horizontal)
    end
end
# display(fig)
save("results/plots/shoe_averages_plotted.pdf", fig, resolution = (width, height))

fig = Figure(size = (width, height), fontsize = 20)
    supertitle = Label(fig[0, 1:1], "Spherical frequency responses", fontsize = 30, tellwidth = false)
for (i, file) in enumerate(data_files[5:8])
    data = load("results/fft averages/" * file)
    Fs = data["Fs"]
    modes = data["modes"]
    avg_f = data["avg_f"]
    
    crystal = (i%2 == 0 ? "tetrahedral" : "cartesian")
    signal = (i <= 6 ? "dirac" : "sine sweep")
    ax = Axis(fig[i, 1],
    title = "Signal: $signal\t Cavity: shoe-box\t Crystal: $crystal\t ",
    xscale = log10, xminorticksvisible = true, xminorgridvisible = true,
    xminorticks = IntervalsBetween(5), ylabel = "Amplitude", xlabel = (i == 8 ? "Frequency [Hz]" : ""))
    plots = []
    for j in eachindex(Fs)
        push!(plots, stairs!(ax, Fs[j][2], avg_f[j], step=:center, color=colours[j]))
    end
    mode = vlines!(ax, modes, color = redish)
    if i == 4
        Legend(fig[5, 1:1], [plots;[mode]],
        [["TLLs per Wavelength: $(resolutions[j])" for j in eachindex(Fs)];["Analytical mode"]], tellwidth = false, orientation = :horizontal)
    end
end


save("results/plots/sphere_averages_plotted.pdf", fig, resolution = (width, height))
