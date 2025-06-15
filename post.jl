module Visualization
    using GLMakie
    using NearestNeighbors
    using StaticArrays
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
        return sum([nodes[idxs[i]].on_node for i = eachindex(dists)])/length(dists)
            #calculate average here, trilinear interpolation? https://en.wikipedia.org/wiki/Multivariate_interpolation#Irregular_grid_(scattered_data)
            #use average as it shold be sufficient for fine grids
    end

   function cross_section(nodes::Dict{Any, Any}, tll, mesh_dimensions, axis::String, cross_height, tree = nothing)
        #Choose cross_section along x, y or z axis, and get the interpolated values in a matrix
        #cross_height is how far along the axis the cross section is
        if tree === nothing
            sorted_keys = sort([node[1] for node in nodes])
            tree = KDTree([SVector{3, Float64}(nodes[key].x, nodes[key].y, nodes[key].z) for key in sorted_keys])
        end

        lattice_dims = []
        if axis == "x" || axis == "X"
            cross_height > mesh_dimensions[1] ? throw(ErrorException("The cross section height is higher than the meshes axis length")) : nothing
            lattice_dims = (ceil(mesh_dimensions[2]/tll), ceil(mesh_dimensions[3]/tll))
            lattice = zeros(lattice_dims[1], lattice_dims[2])
            for i in 1:lattice_dims[1], j in 1:lattice_dims[2]
                #Adding a multiplication factor to only use the one node if there is one really close
                lattice[i, j] = point_avg(nodes, (cross_height-tll/2, i-tll/2, j-tll/2), tll*0.95, tree)
            end
        elseif axis == "y" || axis == "Y"
            cross_height > mesh_dimensions[2] ? throw(ErrorException("The cross section height is higher than the meshes axis length")) : nothing
            lattice_dims = (ceil(mesh_dimensions[1]/tll), ceil(mesh_dimensions[3]/tll))
            lattice = zeros(lattice_dims[1], lattice_dims[2])
            for i in 1:lattice_dims[1], j in 1:lattice_dims[2]
                lattice[i, j] = point_avg(nodes, (i-tll/2, cross_height-tll/2, j-tll/2), tll*0.95, tree)
            end
        elseif axis == "z" || axis == "Z"
            cross_height > mesh_dimensions[3] ? throw(ErrorException("The cross section height is higher than the meshes axis length")) : nothing
            lattice_dims = (ceil(mesh_dimensions[1]/tll), ceil(mesh_dimensions[2]/tll))
            lattice = zeros(Int(lattice_dims[1]), Int(lattice_dims[2]))
            for i in 1:Int(lattice_dims[1]), j in 1:Int(lattice_dims[2])
                lattice[i, j] = point_avg(nodes, (i-tll/2, j-tll/2, cross_height-tll/2), tll*0.95, tree)
            end
        else
            throw(ErrorException("Unknown axis: "*axis))
        end
        lattice_borders = [i*tll for i in 0:lattice_dims[1]], [i*tll for i in 0:lattice_dims[2]]
        return lattice, lattice_borders
    end
end

module Analysis
    using DataStructures
    using FFTW
    using SpecialFunctions
    using Peaks
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
        delete!(resonances, 0.0) #remove the zero frequency resonance
        return resonances #have them in a dataframe?
    end

    function analytic_spherical_resonance(r, c)
        function findextrema(y)
            extremai = []
            extremah = []
            display(y[2])#y[1] The besselfunction always outputs NaN as the first value
            y[2] > 0.99 ? (push!(extremai, 2); push!(extremah, y[2])) : nothing
            maxi, maxh = findmaxima(y)
            mini, minh = findminima(y)
            order = maxi[1] < mini[1] ? true : false #looking if the first extrema is a maxima
            for i in eachindex(order ? maxi : mini)
                if order
                    push!(extremai, maxi[i])
                    push!(extremah, maxh[i])
                    if i <= length(mini)
                        push!(extremai, mini[i])
                        push!(extremah, minh[i])
                    end
                else
                    push!(extremai, mini[i])
                    push!(extremah, minh[i])
                    if i <= length(maxi)
                        push!(extremai, maxi[i])
                        push!(extremah, maxh[i])
                    end
                end
            end
            return extremai, extremah
        end
        SphericalBesselJ(nu, x) = sqrt(π/(2*x)) * besseljx(nu + 0.5, x)
        function znl(n,l) #calculates a matrix of z up to the given dimensions
            z = []
            interval = 0.0001
            x = 0:interval:50
            for i in 0:l
                y = [SphericalBesselJ(i, x) for x in x]
                indices, heights = findextrema(y)
                zs = indices.*interval;
                push!(z, [zs[i] for i in 1:n+1])
            end
            return z  #accessed i as z[l+1][n+1]
        end
        resonances = SortedDict{Float64, Vector{String}}()
        z = znl(7,7)
        for l = 0:7, n = 0:7
            mode = "$(l)$(n)" # The modes do not seem to be entirely correct, frequencies however are
            f = round((z[l+1][n+1]*c)/(2*pi*r), digits = 2)
            haskey(resonances, f) ? (push!(resonances[f], mode)) : push!(resonances, f => [mode])
        end
        return resonances #have them in a dataframe?
    end

    function signal_frequencies(signal, fs, from = nothing, to = nothing)
        n = 2*2^(ceil(Int, log2(length(signal)))+5) # Calculate the next power of 2
        padded_signal = vcat(signal, zeros(n - length(signal))) # Zero pad the signal
        F = (fftshift(abs.(fft(padded_signal))))
        freqs = fftshift(fftfreq(length(padded_signal), fs))
        pos_i_0 = findfirst(>=(0),freqs) #finding the indices of the positive frequencies
        posi_i_n = length(freqs)
        from === nothing ? nothing : pos_i_0 = findfirst(>=(from), freqs)
        to === nothing ? nothing : posi_i_n = findlast(<=(to), freqs)
        return freqs[pos_i_0:posi_i_n], F[pos_i_0:posi_i_n]
    end
end
