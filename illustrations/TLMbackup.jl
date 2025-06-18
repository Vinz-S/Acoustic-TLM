using GLMakie
GLMakie.activate!(inline=false)

function draw_grid!(ax)
    for x in (-1.1:1:0.9)
        for y_interval in [[1.5, 1.1], [0.9,0.1]]
            lines!(ax, [x, x], y_interval, color = :black)
            lines!(ax, [x, x], -y_interval, color = :black)  
        end  
    end
    for x in (-0.9:1:1.1)
        for y_interval in [[1.5, 1.1], [0.9,0.1]]
            lines!(ax, [x, x], y_interval, color = :black)
            lines!(ax, [x, x], -y_interval, color = :black)  
        end  
    end
    for y in (-1.1:1:0.9)
        for x_interval in [[1.5, 1.1], [0.9,0.1]]
            lines!(ax, x_interval, [y, y], color = :black)
            lines!(ax, -x_interval, [y, y], color = :black)  
        end  
    end
    for y in (-0.9:1:1.1)
        for x_interval in [[1.5, 1.1], [0.9,0.1]]
            lines!(ax, x_interval, [y, y], color = :black)
            lines!(ax, -x_interval, [y, y], color = :black)  
        end  
    end
end

function draw_nodes!(ax)
    x_nodes = [-1,0,1,-1,0,1,-1,0,1]
    y_nodes = [1,1,1,0,0,0,-1,-1,-1]
    scatter!(ax, x_nodes, y_nodes , color = Makie.wong_colors()[4])
end

function arrow!(axis, point, direction, colour)
    cls = 0.04
    if direction == "up"
        lines!(axis, [point[1], point[1]], [point[2]-0.15, point[2]+0.15], color = colour)
        lines!(axis, [point[1]-0.04, point[1]+0.04],[point[2]+cls, point[2]+cls], color = colour)
        lines!(axis, [point[1]-0.04, point[1]+0.04],[point[2]-cls, point[2]-cls], color = colour)
        lines!(axis, [point[1]-0.04, point[1]+0.04],[point[2], point[2]], color = colour)
        lines!(axis, [point[1]-0.04, point[1]], [point[2]+0.075, point[2]+0.15], color = colour)
        lines!(axis, [point[1]+0.04, point[1]], [point[2]+0.075, point[2]+0.15], color = colour)
    elseif direction == "down"
        lines!(axis, [point[1], point[1]], [point[2]-0.15, point[2]+0.15], color = colour)
        lines!(axis, [point[1]-0.04, point[1]+0.04],[point[2]+cls, point[2]+cls], color = colour)
        lines!(axis, [point[1]-0.04, point[1]+0.04],[point[2]-cls, point[2]-cls], color = colour)
        lines!(axis, [point[1]-0.04, point[1]+0.04],[point[2], point[2]], color = colour)
        lines!(axis, [point[1]-0.04, point[1]], [point[2]-0.075, point[2]-0.15], color = colour)
        lines!(axis, [point[1]+0.04, point[1]], [point[2]-0.075, point[2]-0.15], color = colour)
    elseif direction == "left"
        lines!(axis, [point[1]-0.15, point[1]+0.15], [point[2], point[2]], color = colour)
        lines!(axis,[point[1]+cls, point[1]+cls], [point[2]-0.04, point[2]+0.04], color = colour)
        lines!(axis,[point[1]-cls, point[1]-cls], [point[2]-0.04, point[2]+0.04], color = colour)
        lines!(axis,[point[1], point[1]], [point[2]-0.04, point[2]+0.04], color = colour)
        lines!(axis, [point[1]-0.075, point[1]-0.15], [point[2]-0.04, point[2]], color = colour)
        lines!(axis, [point[1]-0.075, point[1]-0.15], [point[2]+0.04, point[2]], color = colour)
    elseif direction == "right"
        lines!(axis, [point[1]-0.15, point[1]+0.15], [point[2], point[2]], color = colour)
        lines!(axis, [point[1]+cls, point[1]+cls], [point[2]-0.04, point[2]+0.04], color = colour)
        lines!(axis, [point[1]-cls, point[1]-cls], [point[2]-0.04, point[2]+0.04], color = colour)
        lines!(axis, [point[1], point[1]], [point[2]-0.04, point[2]+0.04], color = colour)
        lines!(axis, [point[1]+0.075, point[1]+0.15], [point[2]-0.04, point[2]], color = colour)
        lines!(axis, [point[1]+0.075, point[1]+0.15], [point[2]+0.04, point[2]], color = colour)
    end
end

function draw_arrows_and_labels!(ax, step)
    # Only central node for all steps
    x, y = 0, 0
    color1 = Makie.wong_colors()[3]
    color2 = Makie.wong_colors()[2]
    color_txt = Makie.wong_colors()[1]
    if step == 1
        # Only right arrow, label "p"
        arrow!(ax, [x, y], "right", color1)
        text!(ax, Point2f(x+0.3, y-0.1), text = "p", align=(:left,:top), color = color_txt, font = :italic, fontsize = 22)
    elseif step == 2
        # Up, down, right, left arrows, label "p/2" and "-p/2"
        arrow!(ax, [x, y], "right", color1)
        arrow!(ax, [x, y], "left", color2)
        arrow!(ax, [x, y], "up", color1)
        arrow!(ax, [x, y], "down", color2)
        text!(ax, Point2f(x+0.3, y-0.1), text = "p/2", align=(:left,:top), color = color_txt, font = :italic, fontsize = 18)
        text!(ax, Point2f(x-0.3, y-0.1), text = "-p/2", align=(:right,:top), color = color_txt, font = :italic, fontsize = 18)
        text!(ax, Point2f(x-0.1, y+0.3), text = "p/2", align=(:left,:bottom), color = color_txt, font = :italic, fontsize = 18)
        text!(ax, Point2f(x-0.1, y-0.3), text = "p/2", align=(:left,:top), color = color_txt, font = :italic, fontsize = 18)
    elseif step == 3
        # All neighbors, label "p/4" and "-p/4"
        for dx in [-1,0,1], dy in [-1,0,1]
            if dx == 0 && dy == 0
                continue
            end
            px, py = x+dx, y+dy
            if abs(dx)+abs(dy) == 1
                # direct neighbors: p/4
                arrow!(ax, [px, py], dx == 1 ? "right" : dx == -1 ? "left" : dy == 1 ? "up" : "down", color1)
                text!(ax, Point2f(px+0.25*dx, py+0.25*dy), text = "p/4", align=(:center,:center), color = color_txt, font = :italic, fontsize = 16)
            else
                # diagonal: -p/4
                arrow!(ax, [px, py], dx == 1 ? "right" : dx == -1 ? "left" : dy == 1 ? "up" : "down", color2)
                text!(ax, Point2f(px+0.25*dx, py+0.25*dy), text = "-p/4", align=(:center,:center), color = color_txt, font = :italic, fontsize = 16)
            end
        end
    end
end

f = Figure(size = (1500, 500))
for i in 1:3
    ax = Axis(f[1, i])
    draw_grid!(ax)
    draw_nodes!(ax)
    draw_arrows_and_labels!(ax, i)
    hidespines!(ax)
    xlims!(ax, -2, 2)
    ylims!(ax, -2, 2)
end

display(f)