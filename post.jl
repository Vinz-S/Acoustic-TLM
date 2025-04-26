module Visualization
    using GLMakie
    using NearestNeighbors
    function show_mesh(nodes) #This function is very slow on anything more than a few crystals
        fig = Figure()
        ax3d = Axis3(fig[1,1], title = "grid Visualization")
        scatter!(ax3d, [node.x for node in values(nodes)], [node.y for node in values(nodes)], [node.z for node in values(nodes)], markersize = 10)
        display(fig)
        transmission_lines = [(node.x, node.y, node.z, nodes[neighbour].x, nodes[neighbour].y, nodes[neighbour].z) for node in values(nodes) for neighbour in filter!(v->v!=0, node.neighbours)]
        for line in transmission_lines
            lines!(ax3d, [line[1], line[4]], [line[2], line[5]], [line[3], line[6]], color = :blue)
        end
        return fig
    end
    function point_avg(nodes, point, tll, tree = nothing) #gives the average of the nodes within a certain distance from the point
        if tree === nothing
            sorted_keys = sort([node[1] for node in nodes])
            tree = KDTree([SVector{3, Float64}(nodes[key].x, nodes[key].y, nodes[key].z) for key in sorted_keys])
        end
        idxs, dists = knn(tree, [point[1], point[2], point[3]], 10)
        filter!(d->d<tll*1.001, dists)
        return sum([nodes[idxs[i] for i = eachindex(dists)]])/length(dists)
            #calculate average here, trilinear interpolation? https://en.wikipedia.org/wiki/Multivariate_interpolation#Irregular_grid_(scattered_data)
            #use average as it shold be sufficient for fine grids
    end
end

module Analysis
    using DataStructures
    using FFTW
    function analytic_cubic_resonance(x, y, z, c)
        resonances =  SortedDict{Float64, Vector{String}}()
        for l = 0:3, m = 0:3, n = 0:3
            mode = "$(l)$(m)$(n)"
            f = round(c/2 * sqrt((l/x)^2 + (m/y)^2 + (n/z)^2), digits = 2)
            haskey(resonances, f) ? (push!(resonances[f], mode)) : push!(resonances, f => [mode])
        end
#=         fig = Figure()
        ax = Axis(fig[1, 1], title = "Number of resonances", xscale = log10,
        xminorticksvisible = true, xminorgridvisible = true,
        xminorticks = IntervalsBetween(5))
        xs, ys = [r[1] for r in resonances], [length(r[2]) for r in resonances]
        stem!(ax, xs, ys, markersize = 10)
        display(fig) =#
        return resonances #have them in a dataframe?
    end
    function signal_frequencies(signal, fs)
        N = length(signal)
        F = 2/N*abs.(fftshift(fft(signal))) #frequency axis
        freqs = fftshift(fftfreq(N,fs)) #amplitude axis
        return F, freqs
    end
end
rs = Analysis.analytic_cubic_resonance(2, 2.5, 6, 343)
