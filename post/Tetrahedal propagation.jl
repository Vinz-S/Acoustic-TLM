using GLMakie
using JLD2
using FileIO
using TOML  
codepath = "/home/vinzenz/Documents/Master/Acoustic-TLM/"
include(codepath*"post.jl")
configs = TOML.parsefile(codepath*"configs/prop_test_tetra_20 retry.toml")
c = configs["c"]
f = configs["sources"]["freq"][1]
tll = configs["mesh"]["dimensions"]["tll"] #transmission line length
it_time = tll/c #time per iteration
data = load(codepath*"results/"*configs["measurements"]["filename"]*".jld2", "measurements")
λ = c/f #wavelength
distances = [1, 3, 6] #in wavelengths

ys = 0:it_time:(length(data[1])-1)*it_time
per = 1/f #wave period
intervals =  [[i*per-per , i*per+2*per].*sqrt(3) for i in distances]

fig = Figure()
ax1a = Axis(fig[1, 1], title = "On-axis, 1λ")
stairs!(ax1a, ys, data[1]; step=:center, color = :blue)
xlims!(ax1a, intervals[1][1], intervals[1][2])

ax2a = Axis(fig[1, 2], title = "On-axis, 3λ")
stairs!(ax2a, ys, data[2]; step=:center, color = :blue)
xlims!(ax2a, intervals[2][1], intervals[2][2])

ax3a = Axis(fig[1, 3], title = "On-axis, 6λ")
stairs!(ax3a, ys, data[3]; step=:center, color = :blue)
xlims!(ax3a, intervals[3][1], intervals[3][2])

ax1b = Axis(fig[2, 1], title = "On-plane, 1λ")
stairs!(ax1b, ys, data[4]; step=:center, color = :blue)
xlims!(ax1b, intervals[1][1], intervals[1][2])

ax2b = Axis(fig[2, 2], title = "On-plane, 3λ")
stairs!(ax2b, ys, data[5]; step=:center, color = :blue)
xlims!(ax2b, intervals[2][1], intervals[2][2])

ax3b = Axis(fig[2, 3], title = "On-plane, 6λ")
stairs!(ax3b, ys, data[6]; step=:center, color = :blue)
xlims!(ax3b, intervals[3][1], intervals[3][2])
ax1c = Axis(fig[3, 1], title = "Off-axis, 1λ")
stairs!(ax1c, ys, data[7]; step=:center, color = :blue)
xlims!(ax1c, intervals[1][1], intervals[1][2])

ax2c = Axis(fig[3, 2], title = "Off-axis, 3λ")
stairs!(ax2c, ys, data[8]; step=:center, color = :blue)
xlims!(ax2c, intervals[2][1], intervals[2][2])

ax3c = Axis(fig[3, 3], title = "Off-axis, 6λ")
stairs!(ax3c, ys, data[9]; step=:center, color = :blue)
xlims!(ax3c, intervals[3][1], intervals[3][2])

ax1d = Axis(fig[4, 1], title = "source output")
source = load(codepath*"results/"*configs["measurements"]["filename"]*".jld2", "source output")[1][1]
stairs!(ax1d, [point[1] for point in source], [point[2] for point in source]; step=:center, color = :red)

display(fig)