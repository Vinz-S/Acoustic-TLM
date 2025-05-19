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

   function cross_section(nodes::Dict{Any, Any} , configs::Dict{String, Any}, axis::String, cross_height, tree = nothing)
        #Choose cross_section along x, y or z axis, and get the interpolated values in a matrix
        #cross_height is how far along the axis the cross section is
        tll = configs["mesh"]["dimensions"]["tll"]
        if tree === nothing
            sorted_keys = sort([node[1] for node in nodes])
            tree = KDTree([SVector{3, Float64}(nodes[key].x, nodes[key].y, nodes[key].z) for key in sorted_keys])
        end
        idxs, dists = knn(tree, [height[1], height[2], height[3]], 10)
        filter!(d->d<transmission_line_length*1.001, dists)
        #Generate a lattice of points
        dimensions = configs["mesh"]["dimensions"]["x"], configs["mesh"]["dimensions"]["y"], configs["mesh"]["dimensions"]["z"]
        crossheight > dimensions[axis] ? throw(ErrorException("The cross section height is higher than the meshes axis length")) : nothing
        lattice_dims;
        if axis == "x" || axis == "X"
            lattice_dims = (ceil(dimensions[2]/tll), ceil(dimensions[3]/tll))
        elseif axis == "y" || axis == "Y"
            lattice_dims = (ceil(dimensions[1]/tll), ceil(dimensions[3]/tll))
        elseif axis == "z" || axis == "Z"
            lattice_dims = (ceil(dimensions[1]/tll), ceil(dimensions[2]/tll))
        else
            throw(ErrorException("Unknown axis: "*axis))
        end
        lattice = zeros(lattice_dims[1], lattice_dims[2])

        #Calculate the point_avg for each point in the lattice
        for i in 1:dimensions[2], j in 1:dimensions[3]
            lattice[i, j] = point_avg(nodes, (cross_height, i, j), tll)
        end
        #return the completed lattice
            #In some way add a scale for the distances
        return lattice, lattice_dims
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
        n = 2^(ceil(Int, log2(length(signal)))+5) # Calculate the next power of 2
        padded_signal = vcat(signal, zeros(n - length(signal))) # Zero pad the signal
        F = (fftshift(abs.(fft(padded_signal))))
        freqs = fftshift(fftfreq(length(padded_signal), fs))
        return freqs, F
    end
end
