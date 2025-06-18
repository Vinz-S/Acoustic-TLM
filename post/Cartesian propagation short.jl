using GLMakie
using JLD2
using FileIO
using TOML  
codepath = "/home/vinzenz/Documents/Master/Acoustic-TLM/"
include(codepath*"post.jl")
configs = TOML.parsefile(codepath*"configs/prop_test_cart_20 short.toml")
c = configs["c"]
f = configs["sources"]["freq"][1]
tll = configs["mesh"]["dimensions"]["tll"] #transmission line length
it_time = tll/c #time per iteration
data = load(codepath*"results/"*configs["measurements"]["filename"]*".jld2", "measurements")
source = load(codepath*"results/"*configs["measurements"]["filename"]*".jld2", "source output")[1][1]
λ = c/f #wavelength
distances = [0.5, 1] #in wavelengths

xs = 0:it_time/sqrt(3):(length(data[1])-1)*it_time/sqrt(3)
per = 1/f #wave period
intervals =  [[i*per-per , i*per+2*per] for i in distances]

#Plotting signals
fig = Figure()
ax1a = Axis(fig[1, 1], title = "On-axis, 1λ")
stairs!(ax1a, xs, data[1], step=:center, color = :blue)
xlims!(ax1a, intervals[1][1], intervals[1][2])

ax2a = Axis(fig[1, 2], title = "On-axis, 3λ")
stairs!(ax2a, xs, data[2], step=:center, color = :blue)
xlims!(ax2a, intervals[2][1], intervals[2][2])

ax1b = Axis(fig[2, 1], title = "On-plane, 1λ")
stairs!(ax1b, xs, data[3], step=:center, color = :blue)
xlims!(ax1b, intervals[1][1], intervals[1][2])

ax2b = Axis(fig[2, 2], title = "On-plane, 3λ")
stairs!(ax2b, xs, data[4], step=:center, color = :blue)
xlims!(ax2b, intervals[2][1], intervals[2][2])

ax1c = Axis(fig[3, 1], title = "Off-axis, 1λ")
stairs!(ax1c, xs, data[5], step=:center, color = :blue)
xlims!(ax1c, intervals[1][1], intervals[1][2])

ax2c = Axis(fig[3, 2], title = "Off-axis, 3λ")
stairs!(ax2c, xs, data[6], step=:center, color = :blue)
xlims!(ax2c, intervals[2][1], intervals[2][2])


ax4a = Axis(fig[3, 3], title = "On-source")
stairs!(ax4a, xs, data[7], step=:center, color = :blue)
#Plotting source:
ax4 = Axis(fig[2,3], title = "Source output")
stairs!(ax4, [point[1] for point in source], [point[2] for point in source], step=:center, color = :red)

display(fig)