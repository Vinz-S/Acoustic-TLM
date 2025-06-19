codepath = "/home/vinzenz/Documents/Master/Acoustic-TLM/"
include(codepath*"post.jl"); import .Colours: blue, orange, green, pink, lightblue, redish, yellow
using GLMakie
GLMakie.activate!(inline=false)
#using CairoMakie
using JLD2
using FileIO
using TOML 

configs = TOML.parsefile(codepath*"configs/signal_test_cart_20.toml")
tet_config = TOML.parsefile(codepath*"configs/signal_test_tetra_20.toml")
c = configs["c"]
f = configs["sources"]["freq"][1]
tll = configs["mesh"]["dimensions"]["tll"] #transmission line length
it_time = (tll/c)/sqrt(3) #time per iteration
data_c = load(codepath*"results/"*configs["measurements"]["filename"]*".jld2", "measurements")
source_c = load(codepath*"results/"*configs["measurements"]["filename"]*".jld2", "source output")[1][1]
data_t = load(codepath*"results/"*tet_config["measurements"]["filename"]*".jld2", "measurements")
source_t = load(codepath*"results/"*tet_config["measurements"]["filename"]*".jld2", "source output")[1][1]
xs_c = (0:it_time:(length(data_c[1])-1)*it_time)
xs_t = (0:it_time:(length(data_t[1])-1)*it_time)
per = 1/f #wave period
xs_c = xs_c.*1000; xs_t = xs_t.*1000; per = per*1000 #convert to ms
# intervals =  [[i*per-per , i*per+4*per] for i in distances]

#Plotting signals
fig = Figure(size = (1200, 400), fontsize = 20)
#supertitle = Label(fig[0,:], "Tetrahedral", fontsize = 20) #This really distorts the figure
ax1 = Axis(fig[1, 1], title = "Sine, Cartesian mesh")
stairs!(ax1, xs_c, data_c[1]; step=:center, color = blue)
ax1.xlabel = "Time (ms)"
ax1.ylabel = "Amplitude"

ax2 = Axis(fig[1, 2], title = "Sine, Tetrahedral mesh")
stairs!(ax2, xs_t, data_t[1]; step=:center, color = blue)
ax2.xlabel = "Time (ms)"
ax2.ylabel = "Amplitude"

ax3 = Axis(fig[1, 3], title = "Source output")
stairs!(ax3, [point[1] for point in source_c].*1000, [point[2] for point in source_c]; step=:center, color = redish)
ax3.xlabel = "Time (ms)"
ax3.ylabel = "Amplitude"


 
display(fig)
save("results/single_sine.png", fig)
