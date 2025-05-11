using GLMakie
using JLD2
using FileIO
using TOML  
codepath = "/home/vinzenz/Documents/Master/Acoustic-TLM/"
include(codepath*"post.jl")
configs = TOML.parsefile(codepath*"configs/prop_test_cart_20.toml")
c = configs["c"]
f = configs["sources"]["freq"][1]
tll = configs["mesh"]["dimensions"]["tll"] #transmission line length
it_time = tll/c #time per iteration
data = load(codepath*"results/cart_propagation_20.jld2", "measurements")
λ = c/f #wavelength
distances = [1, 3, 6] #in wavelengths

ys = 0:it_time:(length(data[1])-1)*it_time
per = 1/f #wave period
intervals =  [[i*per-per , i*per+2*per] for i in distances]

fig = Figure()
ax1a = Axis(fig[1, 1], title = "On-axis, 1λ")
lines!(ax1a, ys, data[1], color = :blue)
xlims!(ax1a, intervals[1][1], intervals[1][2])

ax2a = Axis(fig[1, 2], title = "On-axis, 3λ")
lines!(ax2a, ys, data[2], color = :blue)
xlims!(ax2a, intervals[2][1], intervals[2][2])

ax3a = Axis(fig[1, 3], title = "On-axis, 6λ")
lines!(ax3a, ys, data[3], color = :blue)
xlims!(ax3a, intervals[3][1], intervals[3][2])

ax1b = Axis(fig[2, 1], title = "On-plane, 1λ")
lines!(ax1b, ys, data[4], color = :blue)
xlims!(ax1b, intervals[1][1], intervals[1][2])

ax2b = Axis(fig[2, 2], title = "On-plane, 3λ")
lines!(ax2b, ys, data[5], color = :blue)
xlims!(ax2b, intervals[2][1], intervals[2][2])

ax3b = Axis(fig[2, 3], title = "On-plane, 6λ")
lines!(ax3b, ys, data[6], color = :blue)
xlims!(ax3b, intervals[3][1], intervals[3][2])
ax1c = Axis(fig[3, 1], title = "Off-axis, 1λ")
lines!(ax1c, ys, data[7], color = :blue)
xlims!(ax1c, intervals[1][1], intervals[1][2])

ax2c = Axis(fig[3, 2], title = "Off-axis, 3λ")
lines!(ax2c, ys, data[8], color = :blue)
xlims!(ax2c, intervals[2][1], intervals[2][2])

ax3c = Axis(fig[3, 3], title = "Off-axis, 6λ")
lines!(ax3c, ys, data[9], color = :blue)
xlims!(ax3c, intervals[3][1], intervals[3][2])

display(fig)