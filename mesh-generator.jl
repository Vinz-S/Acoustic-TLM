###This file is supposed to conatain the module for the pre-processo
using GLMakie
using NearestNeighbors

module Blocks #Coordinates of a base block x,y,z
    # export Cartesian, Tetraheder
    Cartesian = [(x,y,z) for x = 0:1, y = 0:1, z = 0:1]
    Cartesian = [Cartesian[i] for i = eachindex(Cartesian)]
    #Originally used half as big coordinates for the tetahedal, but scaled up so all values can be integers
    #This might need to be adjusted later on with regards to transmission line lengths
    Tetraheder = [(0,0,0); (2,2,0); (1,1,1); (2,0,2); (0,2,2)]
    Tetraheder = [Tetraheder;[(Tetraheder[i][1]+2,Tetraheder[i][2]+2,Tetraheder[i][3]) for i = eachindex(Tetraheder)];
    [(Tetraheder[i][1],Tetraheder[i][2]+2,Tetraheder[i][3]+2) for i = eachindex(Tetraheder)];
    [(Tetraheder[i][1]+2,Tetraheder[i][2],Tetraheder[i][3]+2) for i = eachindex(Tetraheder)];]
    unique!(Tetraheder) #clears duplicates
    transmission_line_length = Dict("Cartesian"=>(1), "Tetraheder"=>(sqrt(1^2+1^2+1^2)))
    crystal = Dict("Cartesian"=>Cartesian, "Tetraheder"=>Tetraheder)
    no_branches = Dict("Cartesian"=>6, "Tetraheder"=>4) #number of branches on each node
end

module Generator
    using NearestNeighbors: KDTree, inrange
    using StaticArrays
    using ProgressBars
    import ..Blocks
    #Multithreading the process of multiplying the blocks?
    #Finding the neigbours by checkings what nodes are within a set radius
    mutable struct Node     #The node
        x::Float64 #Coordinates of the node
        y::Float64
        z::Float64
        neighbours::Vector{Int64}
        inbound::Vector{Float64} #The indexes of the vectors correspond to the neighbours indexes
        outbound::Vector{Float64}
        on_node::Float64
    end;
    function scale_crystal(crystal::Vector{Tuple{Int64, Int64, Int64}}, scale::Float64)
        return [(scale*crystal[i][1], scale*crystal[i][2], scale*crystal[i][3]) for i = eachindex(crystal)]
    end
    
    function nodes(dimensions::Tuple{Float64, Float64, Float64}; crystal::String = "Tetraheder", transmission_line_length::Float64 = 1.0)
        #The largest possible rectangle within the chosen dimensions will be generated
        scale = transmission_line_length/Blocks.transmission_line_length[crystal]
        transmission_line_length = scale*Blocks.transmission_line_length[crystal]
        no_branches = Blocks.no_branches[crystal]
        crystal = scale_crystal(Blocks.crystal[crystal], scale)
        coordinates = Set()
        crystal_size = findmax(crystal[findmax(crystal)[2]])[1]
        accuracy = 14
        iter = ProgressBar(1:ceil(dimensions[1]/crystal_size))
        for x = iter
            for y = 1:ceil(dimensions[2]/crystal_size)
                for z = 1:ceil(dimensions[3]/crystal_size)
                    for i = eachindex(crystal)
                        #Accuracy is reduced to mitigate rounding errors, earlier prints showed an original accuracy of 17 digits
                        push!(coordinates, (round(crystal[i][1]+(x-1)*crystal_size, sigdigits=accuracy), 
                                            round(crystal[i][2]+(y-1)*crystal_size, sigdigits=accuracy), 
                                            round(crystal[i][3]+(z-1)*crystal_size, sigdigits=accuracy)))
                    end
                end
            end
            set_description(iter, "Generating node coordinates: ")
        end
        pbar = ProgressBar(total = length(coordinates))
        for coord in coordinates
            if coord[1] > dimensions[1] || coord[2] > dimensions[2] || coord[3] > dimensions[3]
                pop!(coordinates, coord)
            end
            update(pbar)
            set_description(pbar, "Filtering coordinate duplicates: ")
        end
        nodes = Dict()
        println("Restructuring coordinates")
        data::Vector{SVector{3, Float64}} = [[coord[1], coord[2], coord[3]] for coord in coordinates]
        pbar = ProgressBar(total = length(coordinates))
        for (i, coord) in enumerate(coordinates)
            nodes[i] = Node(coord[1], coord[2], coord[3], zeros(Int64, no_branches), zeros(no_branches), zeros(no_branches), 0.0)
            update(pbar)
            set_description(pbar, "Generating nodes: ")
        end
        #The indexes of the nodes in the KDTree are the same as the indexes of the coordinates in the data vector
        kdtree = KDTree(data)
        pbar = ProgressBar(total = length(nodes))
        for key in keys(nodes) #0.01 margin added to the transmission line length to make up for rounding errors
            neighbours = [index for index in inrange(kdtree, data[key], transmission_line_length*1.01)]
            nodes[key].neighbours = filter!(v->v!=key, neighbours)
            update(pbar)
            set_description(pbar, "Finding node neighbours: ")
        end
        pbar = ProgressBar(total = length(nodes))
        for key in keys(nodes)
            if length(nodes[key].neighbours) > no_branches
                display(nodes[key])
                throw(ErrorException("The number of neighbours is larger than the number of branches, adjusting the rounding in lines 52-54 might help, current: "*string(accuracy)))
            end
            if length(nodes[key].neighbours) < no_branches
                for i = (length(nodes[key].neighbours)+1):no_branches
                    #uses 0 as placeholders to create the correct number of branches where neighbours are missing
                    push!(nodes[key].neighbours, 0)
                end
            end
            update(pbar)
            set_description(pbar, "Filling boundaries into nodes: ")
        end
        return nodes, kdtree
    end

    function sphere(radius::Float64; crystal::String = "Tetraheder", transmission_line_length::Float64 = 1.0)
        tll = transmission_line_length #saving line space; VV Two tlls used as margin in each axis VV
        nodes, tree = Generator.nodes((2*(radius+tll), 2*(radius+tll), 2*(radius+tll)); crystal = crystal, transmission_line_length = tll)
        center = SVector(radius+tll, radius+tll, radius+tll)
        within = inrange(tree, center, radius)
        outside = []
        sort!(within)
        previous = 0
        last_key = length(nodes)
        pbar = ProgressBar(total = length(within))
        for key in within 
            if key-previous > 1
                for key in (previous+1):(key-1)
                    delete!(nodes, key)
                    push!(outside, key)
                end
            end
            previous = key
            update(pbar)
            set_description(pbar, "Removing nodes outside the sphere: ")
        end
        if previous < last_key
            for i in previous+1:last_key
                push!(outside, i)
                delete!(nodes, i)
            end
        end
        new_keys = Dict()
        pbar = ProgressBar(total = length(within))
        for (new, old) in enumerate(within)
            new_keys[old] = new
            update(pbar)
            set_description(pbar, "Generating new node numbers: ")
        end
        no_branches = Blocks.no_branches[crystal] 
        pbar = ProgressBar(total = length(within))
        for key in within
            for i in 1:no_branches
                if nodes[key].neighbours[i] == 0
                    continue
                elseif nodes[key].neighbours[i] in outside 
                    nodes[key].neighbours[i] = 0
                else 
                    nodes[key].neighbours[i] = new_keys[nodes[key].neighbours[i]]
                end
            end
            # relies on each new key already having been iterated past, else a bug might occur
            new_keys[key] == key ? continue : nothing
            nodes[new_keys[key]] = nodes[key]
            delete!(nodes, key)
            update(pbar)
            set_description(pbar, "Replacing nodes with updated keys: ")
        end
        iterations = 1:length(nodes)
        tree = KDTree([(SVector{3, Float64}(nodes[key].x, nodes[key].y, nodes[key].z)) for key in iterations])
        println("The number of nodes in the sphere is: ", length(nodes))
        return nodes, tree
    end
        #=
        Ting å tenke på: 
        -Tenke å bruke radius funksjon for å beholde alle noder som e i radius.
        -lage nytt tre etter å ha fjernet noder? eksisterende tre e ikkje muterbare i denne modulen
            ·Å numerere alle noder på nytt og lage nytt tre e en mulighet,
                men å endre alle noder kan ver komplekst og koste enormt med datakraft.
        -Boundaries må og beregenes på nytt
            ·Kan ver en idé å bruke listen av fjenede noder, så:
                ·Sortere listen
                ·For hver gjenværende node sjekke om de har en fjernet nabo
                ·Så endre naboen(e) til 0
        -Kan muligens ver en ide å splitte ut deler av nodes funksjonen te egne funksjoner som anvendes i denne og
        =#
end

module Saving_dicts
    using JLD2
    using FileIO
    using NearestNeighbors
    function to_text(dictionary::Dict{Any, Any}, filename::String)
        f = open(filename*".txt", "w")
        print(f, typeof(dictionary), "\n")
        for key in keys(dictionary)
            print(f, key, "=>", dictionary[key], "\n")
        end
        close(f)
    end

    function to_jld2(dictionary::Dict{Any, Any}, tree::KDTree, filename::String) #Is loaded using load("filename.jld2", "nodes")
        save(filename*".jld2", "nodes", (dictionary, tree))
    end
end

module SetupCalculations
    #A function to calculate the correct transmssion-line length for a given resolution
    function tllByResolution(Δl, c, frequency)
        #Δl = points per wavelength, how many transmission-line lengths go into one wavelength
        #tll = transmission line length
        #c = speed of sound
        wavelength = c/frequency
        tll = wavelength/Δl
        return tll
    end
end
