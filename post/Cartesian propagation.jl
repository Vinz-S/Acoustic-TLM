codepath = "/home/vinzenz/Documents/Master/Acoustic-TLM/"
include(codepath*"post.jl"); import .Colours: blue, orange, green, pink, lightblue, redish, yellow
using GLMakie
GLMakie.activate!(inline=false)
#using CairoMakie
using JLD2
using FileIO
using TOML 

configs = TOML.parsefile(codepath*"configs/prop_test_cart_20.toml")
c = configs["c"]
f = configs["sources"]["freq"][1]
tll = configs["mesh"]["dimensions"]["tll"] #transmission line length
it_time = (tll/c)/sqrt(3) #time per iteration
data = load(codepath*"results/"*configs["measurements"]["filename"]*".jld2", "measurements")
source = load(codepath*"results/"*configs["measurements"]["filename"]*".jld2", "source output")[1][1]
λ = c/f #wavelength
distances = [1, 3, 6] #in wavelengths
xs = (0:it_time:(length(data[1])-1)*it_time)
per = 1/f #wave period
RMS0 =  [round(Int, i*per/it_time) for i in distances]
RMS1 =  [round(Int, (i*per+3*per)/it_time) for i in distances]
xs = xs.*1000; per = per*1000 #convert to ms
intervals =  [[i*per-per , i*per+4*per] for i in distances]


#Plotting signals
fig = Figure(size = (1400,700), fontsize = 20)
#supertitle = Label(fig[0,:], "Tetrahedral", fontsize = 20) #This really distorts the figure
ax1a = Axis(fig[1, 1], title = "On-axis, 1λ")
stairs!(ax1a, xs, data[1]; step=:center, color = blue)
xlims!(ax1a, intervals[1][1], intervals[1][2])
ax1a.ylabel = "Amplitude"

ax2a = Axis(fig[1, 2], title = "On-axis, 3λ")
stairs!(ax2a, xs, data[2]; step=:center, color = blue)
xlims!(ax2a, intervals[2][1], intervals[2][2])

ax3a = Axis(fig[1, 3], title = "On-axis, 6λ")
stairs!(ax3a, xs, data[3]; step=:center, color = blue)
xlims!(ax3a, intervals[3][1], intervals[3][2])

ax1b = Axis(fig[2, 1], title = "On-plane, 1λ")
stairs!(ax1b, xs, data[4]; step=:center, color = blue)
xlims!(ax1b, intervals[1][1], intervals[1][2])
ax1b.ylabel = "Amplitude"

ax2b = Axis(fig[2, 2], title = "On-plane, 3λ")
stairs!(ax2b, xs, data[5]; step=:center, color = blue)
xlims!(ax2b, intervals[2][1], intervals[2][2])

ax3b = Axis(fig[2, 3], title = "On-plane, 6λ")
stairs!(ax3b, xs, data[6]; step=:center, color = blue)
xlims!(ax3b, intervals[3][1], intervals[3][2])

ax1c = Axis(fig[3, 1], title = "Off-axis, 1λ")
stairs!(ax1c, xs, data[7]; step=:center, color = blue)
xlims!(ax1c, intervals[1][1], intervals[1][2])
ax1c.ylabel = "Amplitude"
ax1c.xlabel = "Time (ms)"

ax2c = Axis(fig[3, 2], title = "Off-axis, 3λ")
stairs!(ax2c, xs, data[8]; step=:center, color = blue)
xlims!(ax2c, intervals[2][1], intervals[2][2])
ax2c.xlabel = "Time (ms)"

ax3c = Axis(fig[3, 3], title = "Off-axis, 6λ")
stairs!(ax3c, xs, data[9]; step=:center, color = blue)
xlims!(ax3c, intervals[3][1], intervals[3][2])
ax3c.xlabel = "Time (ms)"

ax4a = Axis(fig[1, 4], title = "source output")
stairs!(ax4a, [point[1] for point in source].*1000, [point[2] for point in source]; step=:center, color = redish)
ax4a.xlabel = "Time (ms)"

# save("results/cart_prop_signals.png", fig)
display(fig)

println("On-axis, 1λ RMS: "*string(round(Analysis.RMS(data[1][RMS0[1]:RMS1[1]]), digits = 3)))
println("On-axis, 3λ RMS: "*string(round(Analysis.RMS(data[2][RMS0[2]:RMS1[2]]), digits = 3)))
println("On-axis, 6λ RMS: "*string(round(Analysis.RMS(data[3][RMS0[3]:RMS1[3]]), digits = 3)))
println("On-plane, 1λ RMS: "*string(round(Analysis.RMS(data[4][RMS0[1]:RMS1[1]]), digits = 3)))
println("On-plane, 3λ RMS: "*string(round(Analysis.RMS(data[5][RMS0[2]:RMS1[2]]), digits = 3)))
println("On-plane, 6λ RMS: "*string(round(Analysis.RMS(data[6][RMS0[3]:RMS1[3]]), digits = 3)))
println("Off-axis, 1λ RMS: "*string(round(Analysis.RMS(data[7][RMS0[1]:RMS1[1]]), digits = 3)))
println("Off-axis, 3λ RMS: "*string(round(Analysis.RMS(data[8][RMS0[2]:RMS1[2]]), digits = 3)))
println("Off-axis, 6λ RMS: "*string(round(Analysis.RMS(data[9][RMS0[3]:RMS1[3]]), digits = 3)))
