include("/home/vinzenz/Documents/Master/Acoustic-TLM//mesh-generator.jl")
using GLMakie
@time n, tree = Generator.nodes((8.0,8.0,8.0); crystal = "Tetraheder", transmission_line_length = sqrt(3));

function show_meshaxes(nodes) #This function is very slow on anything more than a few crystals
    green = Makie.wong_colors()[3]
    pink = Makie.wong_colors()[4]
    redish = Makie.wong_colors()[6]
    fig = Figure(fontsize = 18)
    az = -0.71
    elv = 0.015
    #############
    #around node#
    #############
    ax3d = Axis3(fig[1,1], title = "Axes centered on the zig-zag lines", aspect = (1,1,1), azimuth = az*pi, elevation = elv*pi)
    scatter!(ax3d, [node.x for node in values(nodes)], [node.y for node in values(nodes)], [node.z for node in values(nodes)], markersize = 10, color = pink)
    display(fig)
    transmission_lines = [(node.x, node.y, node.z, nodes[neighbour].x, nodes[neighbour].y, nodes[neighbour].z) for node in values(nodes) for neighbour in filter!(v->v!=0, node.neighbours)]
    for line in transmission_lines
        lines!(ax3d, [line[1], line[4]], [line[2], line[5]], [line[3], line[6]], color = green)
    end
    tll = sqrt(3) # transmission line length
    mc = tll/(2*sqrt(3)) #margein correction after changes to the generator code
    axes = [
        [[4.5+mc,4.5+mc],[0+mc,6+mc],[0+mc,6+mc]],
        [[5.5+mc,5.5+mc],[6+mc,0+mc],[0+mc,6+mc]],
        [[8+mc,2+mc],[6+mc,0+mc],[2.5+mc,2.5+mc]],
        [[8+mc,2+mc],[0+mc,6+mc],[3.5+mc,3.5+mc]],
        [[8+mc,2+mc],[3.5+mc,3.5+mc],[0+mc,6+mc]],
        [[2+mc,8+mc],[2.5+mc,2.5+mc],[0+mc,6+mc]]
    ]
    for axis in axes
        lines!(ax3d, axis[1], axis[2], axis[3], color = redish)
    end
    scatter!(ax3d, [5+mc], [3+mc], [3+mc], markersize = 20, color = redish)
    hidedecorations!(ax3d)

    ##############
    #Through node#
    ##############
    ax3d = Axis3(fig[1,2], title = "Axes going through node", aspect = (1,1,1), azimuth = az*pi, elevation = elv*pi)
    scatter!(ax3d, [node.x for node in values(nodes)], [node.y for node in values(nodes)], [node.z for node in values(nodes)], markersize = 10, color = pink)
    display(fig)
    transmission_lines = [(node.x, node.y, node.z, nodes[neighbour].x, nodes[neighbour].y, nodes[neighbour].z) for node in values(nodes) for neighbour in filter!(v->v!=0, node.neighbours)]
    for line in transmission_lines
        lines!(ax3d, [line[1], line[4]], [line[2], line[5]], [line[3], line[6]], color = green)
    end
    tll = sqrt(3) # transmission line length
    mc = tll/(2*sqrt(3)) #margein correction after changes to the generator code
    axes = [
        [[5+mc,5+mc],[0+mc,6+mc],[0+mc,6+mc]],
        [[5+mc,5+mc],[6+mc,0+mc],[0+mc,6+mc]],
        [[8+mc,2+mc],[6+mc,0+mc],[3+mc,3+mc]],
        [[8+mc,2+mc],[0+mc,6+mc],[3+mc,3+mc]],
        [[8+mc,2+mc],[3+mc,3+mc],[0+mc,6+mc]],
        [[2+mc,8+mc],[3+mc,3+mc],[0+mc,6+mc]]
    ]
    for axis in axes
        lines!(ax3d, axis[1], axis[2], axis[3], color = redish)
    end
    scatter!(ax3d, [5+mc], [3+mc], [3+mc], markersize = 20, color = redish)
    hidedecorations!(ax3d)

    return fig
end

f = show_meshaxes(n)
save("illustrations/tetrahedal axes.png", f, resolution = (1200, 600))