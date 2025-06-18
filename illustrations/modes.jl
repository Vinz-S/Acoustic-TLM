using CairoMakie

fig = Figure()
h = 6
w = 12
ax = Axis(fig[1,1])
lines!([0, 0, w, w, 0],[0, h, h, 0, 0], color = Makie.wong_colors()[1], linewidth = 5, label = "Boundary")
hidedecorations!(ax)
hidespines!(ax)

heights = [0;1/2;1;3/2;1.99] # range: [0, 2)

function arcsin(height)
    norows = 6
    x_interval = 0:0.001:20
    #the julia arcsin gives errors above 1
    function iarcsin(x)
        x = x%1
        asin(x)
    end
    x = []
    y1 = []
    y2 = []
    for i in x_interval
        #As the julia arcsin doesn't work like the geogebra one,
        #it has artifacts in the plot which need to be removed
        if abs(sin(i)-height) <= 1
            push!(x, i)
            push!(y1, iarcsin(sin(i)-height))
            push!(y2, iarcsin(sin(i+pi)+height)-pi)
        end
    end
    shift = pi
    xs = [x;x]
    ys = [y1;y2]
    for i in 2:norows
        append!(xs, [x;x].+shift*(i-1))
        append!(ys, [y1;y2].+shift*(i-1))
    end
    #shifting the graph to fit the figure
    xs = xs.-11*pi/2
    ys = ys.-pi/2
    #scaling the graph to fit the figure
    xs = xs.*sqrt(2)*(3/pi)
    ys = ys.*sqrt(2)*(3/pi)
    (xs, ys)
end
colourmap = [:yellow, :red] #[Makie.wong_colors()[7], Makie.wong_colors()[6]]
a = scatter!(ax, arcsin(heights[1])..., colormap = colourmap, color = 1, colorrange = (0, length(heights)), label = "Lowest amplitude")
b = scatter!(ax, arcsin(heights[2])..., colormap = colourmap, color = 2, colorrange = (0, length(heights)))
c = scatter!(ax, arcsin(heights[3])..., colormap = colourmap, color = 3, colorrange = (0, length(heights)))
d = scatter!(ax, arcsin(heights[4])..., colormap = colourmap, color = 4, colorrange = (0, length(heights)))
e = scatter!(ax, arcsin(heights[5])..., colormap = colourmap, color = 5, colorrange = (0, length(heights)), label = "Highest amplitude")

Makie.rotate!(a, -pi/4); Makie.rotate!(b, -pi/4); Makie.rotate!(c, -pi/4); Makie.rotate!(d, -pi/4); Makie.rotate!(e, -pi/4)

#lines!([-3,-2],[-3,-2], linestyle=styles[1] , color = Makie.wong_colors()[6], label = "Highest amplitude")
fig[1,2] = Legend(fig, ax)
xlims!(ax, 0-0.01 ,w+0.01)
ylims!(ax, 0-0.01 ,h+0.01)
colsize!(fig.layout, 1, Aspect(1, w/h))
resize_to_layout!(fig)
fig
save("modes.pdf", fig)