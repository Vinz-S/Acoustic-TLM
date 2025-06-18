include("/home/vinzenz/Documents/Master/Acoustic-TLM//mesh-generator.jl")
using GLMakie
using GeometryBasics
###Testing the modules
nodes, tree = Generator.nodes((5.5, 5.5, 5.5), transmission_line_length = sqrt(3));
for key in keys(nodes)
    if nodes[key].neighbours == [0, 0, 0, 0]
        delete!(nodes, key)
    end
end
az = 0.15
green = Makie.wong_colors()[3]
pink = Makie.wong_colors()[4]
#Visually seeing that the coordinates are correct:
fig = Figure(fontsize = 18)
ax3d = Axis3(fig[1,1], title = "Tetraheder crystal", aspect = (1,1,1))
scatter!(ax3d, [node.x for node in values(nodes)], [node.y for node in values(nodes)], [node.z for node in values(nodes)], markersize = 20, color = pink, label = "nodes")
display(fig)
inside = [2 for i = 1:1, j = 1:1, k = 1:1]
outside = [1 for i = 1:1, j = 1:1, k = 1:1]
colours = [Makie.wong_colors()[5], Makie.wong_colors()[7]]
for i = 0:2:2, j = 0:2:2, k = 0:2:2
    volume!(ax3d, i+0.866025 .. i+2.866025, j+0.866025 .. j+2.866025, k+0.866025 .. k+2.866025, (iseven((i/2)+(j/2)+(k/2)) ? inside : outside); transparency = true, colormap = colours, colorrange = (1, 2), alpha = 0.3)
end

transmission_lines = [(node.x, node.y, node.z, nodes[neighbour].x, nodes[neighbour].y, nodes[neighbour].z) for node in values(nodes) for neighbour in filter!(v->v!=0, node.neighbours)]
for line in transmission_lines
    lines!(ax3d, [line[1], line[4]], [line[2], line[5]], [line[3], line[6]], color = green, label = "transmission lines")
end
axislegend(merge = true, unique = true)

ax3d.azimuth = az*pi
hidedecorations!(ax3d)
nodes, tree = Generator.nodes((1.5,1.5,1.5), crystal = "Cartesian");
ax2 = Axis3(fig[1,2], title = "Cartesian crystal", aspect = (1,1,1))
scatter!(ax2, [node.x for node in values(nodes)], [node.y for node in values(nodes)], [node.z for node in values(nodes)], markersize = 20, color = pink)
display(fig)
transmission_lines = [(node.x, node.y, node.z, nodes[neighbour].x, nodes[neighbour].y, nodes[neighbour].z) for node in values(nodes) for neighbour in filter!(v->v!=0, node.neighbours)]
for line in transmission_lines
    lines!(ax2, [line[1], line[4]], [line[2], line[5]], [line[3], line[6]], color = green)
end
ax2.azimuth = az*pi
hidedecorations!(ax2)
save("illustrations/crystal_plots.png", fig, resolution = (1200, 600))