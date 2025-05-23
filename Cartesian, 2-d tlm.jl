#Prosjektoppgave 2024, non-cartesian dictionary based TLM method by Vinzenz Schöberle

#  using GLMakie
#  GLMakie.activate!(inline=false)
using CairoMakie
# using JLD2
# using FileIO
using GeometryBasics

print("Hello World \n")
#At least 10 points per wavelength, more for accurate resonances

mutable struct Node     #The node 
    address::Int64
    inbound ::Vector{Float64} #Inboundpressure, on form [above right below left]
    outbound::Vector{Float64} #Outbound pressure, on form [above right below left]
    pressure::Float64 #Pressure at node
    neighbouring::Vector{Int64} #Vector containing address of neighbouring nodes on form [above right below left]
    reflection::Vector{Float64} #Vector containing reflection coefficients of neighbouring nodes on form [above right below left]
    position::Vector #When put into coordinate system a position is defined here on form [x, y].
    #The vector type for position is not defined to avoid starting a new Julia instance to run the non-cartesian code
end;

function numberOfnodes(x::Int64,y::Int64)
    return x*y #Very simple for the cartesian model
end;

function nodeCreator() #Initializes the node structs for all nodes and puts them in a vector
    #Creates the list of nodes and links the nodes together
    #Geometry is simple now for the cartesien matrix, might get more complex later:

    node_vector = Dict() #A dictonary, not a vector to keep constant keys knstead of variable indexes
    for i = 1:numberOfnodes(grid_x, grid_y)
        node_vector[i] = Node(i, zeros(4), zeros(4), 0.0, zeros(4), zeros(4), [])
    end

    #this is very basic but will create a complete network, additional boundaries are the easiest to create by modifying the node vector later.
    for node in node_vector
        #filling the middle nodes
        if node[2].address > grid_x && node[2].address <= grid_x*(grid_y-1) && node[2].address%grid_x > 1# Checks that the node is not in first or last row, or first or last coloumn.
            node[2].neighbouring = [node[2].address+grid_x, node[2].address+1, node[2].address-grid_x, node[2].address-1]

        #filling the corner nodes
        elseif node[2].address == 1 #bottom left corner
            node[2].neighbouring = [node[2].address + grid_x, node[2].address+1, 0, 0]  
        elseif node[2].address == grid_x #bottom right corner
            node[2].neighbouring = [node[2].address+grid_x, 0, 0, node[2].address-1]
        elseif node[2].address == grid_x*(grid_y-1)+1 # top left corner
            node[2].neighbouring = [0, node[2].address+1, node[2].address-grid_x, 0]
        elseif node[2].address == grid_x*grid_y #top right corner
            node[2].neighbouring = [0, 0, node[2].address-grid_x, node[2].address-1]

        #filling the bottom row nodes
        elseif node[2].address < grid_x
            node[2].neighbouring = [node[2].address+grid_x, node[2].address+1, 0, node[2].address-1]

        #filling the top row nodes
        elseif node[2].address > grid_x*(grid_y-1)
            node[2].neighbouring = [0, node[2].address+1, node[2].address-grid_x, node[2].address-1]

        #filling the left coloumn nodes
        elseif node[2].address%grid_x == 1
            node[2].neighbouring = [node[2].address+grid_x, node[2].address+1, node[2].address-grid_x, 0]

        #filling the right coloumn nodes
        elseif node[2].address%grid_x == 0
            node[2].neighbouring = [node[2].address+grid_x, 0, node[2].address-grid_x, node[2].address-1]
        end
    end
    return node_vector
end;

function findIndex(vector::Vector, value::Real)
    for i in 1:size(vector)[1]
        if vector[i] == value
            return i
        end
    end

    print("value ")
    print(value)
    print(" not found in ")
    println(vector)
    return 0
end

function createGrid(node_vector::Dict{Int, Node}) #Creates a grid of node adresses in a coordinate system and gives nodes positions
    #dimensions for cartesian, more complex for other tilings
    grid = zeros(grid_x, grid_y)
    grid[1,1] = 1 #establishing a startingpoint in the grid
    for address in 1:numberOfnodes(grid_x, grid_y)
        node = node_vector[address]
        index = findfirst(isequal(address), grid) #This assumes that this node's address already is in the grid
        for i in 1:size(node.neighbouring)[1]
            if node.neighbouring[i] > 0
                neighbouring_index = [index[1],index[2]]; #Easier to work with a vector than a tuple.
                dimension = (i%2 == 0 ? 1 : 2) #Finds what axis the neighbour is on(up/down or left/right)
                neighbouring_index[dimension] += (i > 2 ? -1 : 1) #checks if the neighbour is in + or - direction
                grid[neighbouring_index[1], neighbouring_index[2]] = node.neighbouring[i] #adds address to grid
                node_vector[node.neighbouring[i]].position = [neighbouring_index[1], neighbouring_index[2]]
            end
        end
        address % 10000 == 0 ? println("node "*string(address)*" out of "*string(length(node_vector))) : nothing
    end
    println("gridsize: " * string(size(grid)))
    return grid
end

function lineEquation(p1, p2)
    p = p1[1] < p2[1] ? [p1, p2] : [p2, p1] #sorting points
    slope = (p[1][2]-p[2][2])/(p[1][1] - p[2][1])
    y = [slope, p[2][2]-slope*p[2][1]]
    x = [1/slope, p[2][1]-(1/slope)*p[2][2]]
    return y, x #returns the line equations on form [n, c] for y = n*x + c and x = n*y + c
end

function rangeDecider(val1, val2) #decides the range of values to iterate through (round down largest, round up smallest)
    return ceil(val1 < val2 ? val1 : val2):floor(val1 > val2 ? val1 : val2)
end

function deleteNode(address::Int64)
    try 
        nodes[address]
    catch
        return
    end

    for neighbour in nodes[address].neighbouring
        neighbour == 0 ? continue : nothing
        nodes[neighbour].neighbouring[findIndex(nodes[neighbour].neighbouring, address)] = 0
    end
    delete!(nodes, address)
    grid[findfirst(isequal(address), grid)] = 0
    #filter!(x -> x != address, active_addresses) #Outdated code from when a vector contained active adresses
end

function drawWall(defining_points::Vector{Vector{Float64}}, reflection_factor::Float64, node_vector::Dict{Int64, Node}) #defining points on format[ [x1,y1],[x2,y2],[x3,y3],[xn,yn]]
    searchmargin = 2.01 ## how far away from line to look for next node
    on_line = [] #Vector containing the nodes which the shape goes over
    for point = 1:size(defining_points)[1]-1
        #neighbours = [] #Vector containing the nodes neighbouring the shape
        line_equations = lineEquation(defining_points[point], defining_points[point+1])
        #catching neighboJuring nodes in y axis
        for x = rangeDecider(defining_points[point][1], defining_points[point+1][1]) #Determining the x-values to go through
            x = Int(x)
            x > grid_x ? continue : nothing #Checking that the x-coordinate is within the grid
            y = line_equations[1][1]*x+line_equations[1][2]
            y > grid_y ? continue : nothing

            if abs(y%1) == 0 && grid[x, Int(y)] != 0
                push!(on_line, grid[x, Int(y)]);
                continue
            end

            line_neighbours = [0, 0] #The nodes having a transmissionline crossing the boundary on form [+ direction, - direction]

            #This is the case for a vertical line
            abs(line_equations[1][1]) == Inf && abs(line_equations[1][2]) == Inf ? break : (abs(line_equations[1][1]) == Inf || abs(line_equations[1][2]) == Inf ? println("???? bør ta en nøye titt her") : nothing ) 

            #Finding next node in poitive dirction from boundary
            for i = 1:(searchmargin+y%1)
                grid_y >= floor(y)+i ? nothing : continue #checks that the search stays within the grid
                grid[x, Int(floor(y)+i)] != 0 ? line_neighbours[1] = grid[x, Int(floor(y)+i)] : line_neighbours[1] = 0
                break
            end
            #Finding next node in negative direction
            for i = 0:(searchmargin+y%1)
                1 <= floor(y)-i ? nothing : continue #checks that the search stays within the grid
                grid[x, Int(floor(y)-i)] != 0 ? line_neighbours[2] = grid[x, Int(floor(y)-i)] : line_neighbours[2] = 0
                break
            end

            #Finding the transmissionline and adding reflection reflection_factor
            if line_neighbours[1] > 0 && line_neighbours[2] > 0
                for i in 1:2
                    node_vector[line_neighbours[i]].address == line_neighbours[i] ? nothing : println("addressing error?")
                    node_vector[line_neighbours[i]].reflection[findIndex(node_vector[line_neighbours[i]].neighbouring, line_neighbours[i%2+1])] = reflection_factor
                end

            elseif line_neighbours[1] > 0
                node_vector[line_neighbours[1]].address == line_neighbours[1] ? nothing : println("addressing error?")
                node_vector[line_neighbours[1]].reflection[3] = reflection_factor #The boundary is known to be in the negative y direction, which is below the node

            elseif line_neighbours[2] > 0
                node_vector[line_neighbours[2]].address == line_neighbours[2] ? nothing : println("addressing error?")
                node_vector[line_neighbours[2]].reflection[1] = reflection_factor #The boundary is known to be in the positive y direction, which is above the node
            end 

        end

        #catching neighbouring nodes in x axis
        for y = rangeDecider(defining_points[point][2], defining_points[point+1][2])
            y = Int(y)
            y > grid_y ? continue : nothing #Checking that the y-coordinate is within the grid
            x = line_equations[2][1]*y+line_equations[2][2]
            x > grid_x ? continue : nothing

            if abs(x%1) == 0 && grid[Int(x), y] != 0
                exists = 0
                for point = (on_line)
                    point == grid[Int(x), y] ? exists = 1 : nothing
                end
                if exists == 0
                    push!(on_line, grid[Int(x), y]);
                end
                continue
            end

            line_neighbours = [0, 0] #The nodes having a transmissionline crossing the boundary on form [+ direction, - direction]

            #This is the case for a horizontal line
            abs(line_equations[2][1]) == Inf && abs(line_equations[2][2]) == Inf ? break : (abs(line_equations[2][1]) == Inf || abs(line_equations[2][2]) == Inf ? println("???? bør ta en nøye titt her") : nothing ) 

            #Finding next node in poitive dirction from boundary
            for i = 1:(searchmargin+x%1)
                grid_x >= floor(x)+i ? nothing : continue #checks that the search stays within the grid
                grid[Int(floor(x)+i), y] != 0 ? line_neighbours[1] = grid[Int(floor(x)+i), y] : line_neighbours[1] = 0
                break
            end

            #Finding next node in negative direction
            for i = 0:(searchmargin+x%1)
                1 <= floor(x)-i ? nothing : continue #checks that the search stays within the grid
                grid[Int(floor(x)-i), y] != 0 ? line_neighbours[2] = grid[Int(floor(x)-i), y] : line_neighbours[2] = 0
                break
            end

            #Finding the transmissionline and adding reflection reflection_factor
            if line_neighbours[1] > 0 && line_neighbours[2] > 0
                for i in 1:2
                    node_vector[line_neighbours[i]].address == line_neighbours[i] ? nothing : println("addressing error?")
                    node_vector[line_neighbours[i]].reflection[findIndex(node_vector[line_neighbours[i]].neighbouring, line_neighbours[i%2+1])] = reflection_factor
                end

            elseif line_neighbours[1] > 0
                node_vector[line_neighbours[1]].address == line_neighbours[1] ? nothing : println("addressing error?")
                node_vector[line_neighbours[1]].reflection[4] = reflection_factor #The boundary is known to be in the negative x direction, which is left of  the node

            elseif line_neighbours[2] > 0
                node_vector[line_neighbours[2]].address == line_neighbours[2] ? nothing : println("addressing error?")
                node_vector[line_neighbours[2]].reflection[2] = reflection_factor #The boundary is known to be in the positive x direction, which is right of the node
            end 
        end

        on_line = Int.(on_line)
        for i = on_line
            i = Int(i); !haskey(node_vector, i) ? continue : nothing
            node_vector[i].address == i ? nothing : println("addressing error?")
            node = node_vector[i]
                for address = node.neighbouring
                    address == 0 ? continue : nothing
                    neighbour = node_vector[address]
                    neighbour.reflection[findIndex(neighbour.neighbouring, node.address)] = reflection_factor
                end
        end
    end
    for address in on_line
        deleteNode(address)
    end
    #lines!([p[1] for p in defining_points],[p[2] for p in defining_points]; linewidth = 10)
end

function addSource(point::Vector{Float64}, amplitude::Real, freq::Real, phase::Real) #Adding point source to node at coordinate
    point[1] <= grid_x && point[2] <= grid_y ?
        (grid[Int(round(point[1])), Int(round(point[2]))] != 0 ?
            push!(point_sources, [grid[Int(round(point[1])), Int(round(point[2]))], [amplitude, freq, phase]]) : 
                println("addSource: No node found at requested position") ) : println("addSource: position outside of grid")
    2*pi*freq > 2/it_time ? (println("Aliasing might occur"); println(2*pi*freq); println(1/it_time)) : nothing
end

function pressureupdate(node_vector::Dict{Int, Node}, iteration::Int64)
    #update incoming transmission line for each node
    for node in node_vector
        node[2].inbound = zeros(size(node[2].neighbouring)[1]) #create a vector of length(neighbouring) of zeroes here.
        for i in 1:size(node[2].neighbouring)[1]
            node[2].neighbouring[i] == 0 ? continue : "1<";
            neighbour = node_vector[node[2].neighbouring[i]] # creating a binding or a copy? of the node. doesn't matter as the node won't be changed here anyways
            node_neighbour_index = findIndex(neighbour.neighbouring, node[2].address) #The nodes index in the neighbours neighbour array
            node[2].inbound[i] = neighbour.outbound[node_neighbour_index]*(1-neighbour.reflection[node_neighbour_index]) #putting the from the neighbour transmitted pressure into the incoming array
        end
        node[2].inbound += node[2].outbound.*node[2].reflection # adds reflections if the transmissionline is hitting a reflecting surface.
    end

    #Update pressure at node
    for node in node_vector
        node[2].pressure = sum(node[2].inbound)/2
        pressure_matrix[node[2].position[1], node[2].position[2]] = node[2].pressure
    end

    #update outgoing transmission line for each node
    for node in node_vector
        for i in 1:size(node[2].inbound)[1]
            node[2].outbound[i] = (1/2)*sum(node[2].inbound)-node[2].inbound[i] # -1 for from the outbound direction as 1/2-1 = -1/2 which correct for this direction
        end
    end

    #adding point source
    for source in point_sources
        node_vector[Int(source[1])].outbound .+= source[2][1]*sin(2*pi*source[2][2]*iteration*it_time + source[2][3]) #adding source pressure to outgoing transmission lines
    end
end

function OutOfBounds(boundary_points::Vector{Vector{Float64}}, direction::AbstractString) #Takes "inside" and "outside" as arguments for direction, returns vector of addresses out of bounds
    (M, N) = size(grid)
    # Create a polygon from boundary points
    rectangle = Rect2d(Point2.(boundary_points))
    # Initialize an empty array to store addresses
    outside = []
    # Iterate over all points in the MxN rectangle
    for x in 1:M
        for y in 1:N
            point = Point2(x, y)
            # Check if the point is outside/inside the boundary
            direction == "outside" ? (!GeometryBasics.in(point, rectangle) ? push!(outside, grid[x, y]) : nothing) : (direction == "inside" ? (GeometryBasics.in(point, rectangle) ? push!(outside, grid[x, y]) : nothing) : throw(ArgumentError(direction, "Only 'outside' and 'inside are valid'")))
        end
    end
    return outside
end

function SetBounds(boundary_points::Vector{Vector{Float64}}, reflection_factor::Float64)
    #Delete nodes outside of boundary:
    for address in OutOfBounds(boundary_points, "outside")
        deleteNode(address)
    end
    #Set the boundary:
    drawWall(boundary_points, reflection_factor, nodes)
end

function windowSize(maxwidth::Int64, maxheight::Int64)
    window_ratio = grid_x/grid_y 
    display_ratio = maxwidth/maxheight
    window_ratio > display_ratio ? (return maxwidth, maxwidth/window_ratio) : (return maxheight*window_ratio, maxheight)
end

function sineImpulse(position::Vector{Int64}, amplitude::Int64, iteration::Int64)
    if frequency*iteration*it_time<=1
        output = amplitude*sin(2*pi*frequency*iteration*it_time)
    else output = 0
    end
    #nodes[grid[position[1], position[2]]].outbound[2]+= output
    nodes[grid[position[1], position[2]]].outbound .+= output
    return output
end

function singlePulse(position::Vector{Int64}, amplitude::Int64)
    nodes[grid[position[1], position[2]]].outbound .+= amplitude
end

#Global values which functions rely on:
const c = 20 #Speed of sound in m/s
const tll = 1 #Transmission line length in m
const it_time = tll/c #iteration time in seconds
const frequency = 1 #in Hz
const ppwl = (c/frequency)/tll #points per wavelength
const iterations = 300 #ppwl*20 #how many iterations of the loop
const grid_x = 600 #Int(ppwl*18) # size in x direction
const grid_y = 300 #Int(ppwl*24) # size in y direction
#const rm = ppwl*7 # reflection margin

@time begin

#Global containers which functions rely on:
point_sources::Vector{Any} = [] #Vector with source Nodes on form [address, [amplitude, frequency, phase]]
println("Creates nodes")
nodes::Dict{Int, Node} = nodeCreator() #load("cartesian360x480.jld2","nodes") #nodeCreator() #Vector containing the node structs
println("Organizes nodes")
grid::Matrix{Int64} = createGrid(nodes) #load("cartesian360x480.jld2","grid") #load("cartesian280x440.jld2","grid") #createGrid(nodes) #
#save("cartesian"*string(grid_x)*"x"*string(grid_y)*".jld2", "nodes", nodes,"grid", grid)
pressure_matrix::Matrix{Float64} = zeros(size(grid)[1], size(grid)[2]) #only used for visualization
println("points per wavelength: " * string(ppwl))

end

#Boundary:
#@time SetBounds([[0, 0],[120, 0],[120, 20],[0 , 20],[0 ,0]], 0.0)

#= sorted_keys = sort([node[1] for node in nodes])
kdtree = KDTree([SVector{3, Float64}(nodes[key].x, nodes[key].y, nodes[key].z) for key in sorted_keys]) =#

n_followed = 10
followed_nodes = [grid[300+12*i, 150] for i in 0:n_followed-1] #øker til 12*i etter å ha sjekket at adressene stemmer
on_nodes = [[] for i in 1:length(followed_nodes)]

@time begin
    #running the animation
    ite::Int64 = 0 
    while ite < iterations
        sineImpulse([300, 150], 1, ite)
        pressureupdate(nodes, ite)
        for (i, node) in enumerate(followed_nodes)
            push!(on_nodes[i], nodes[node].pressure)
        end
        global ite += 1
    end
end

positions = []
for node in followed_nodes
    push!(positions, nodes[node].position)
end
fig = Figure(size = (1200, 800), resolution = (1200, 800))
range1 = 1:ceil(Int64, n_followed/2)
range2 = ceil(Int64, n_followed/2)+1:n_followed
ax1 = [Axis(fig[i, 1], title = "On_node "*string(positions[i])) for i in range1]
ax2 = [Axis(fig[i-ceil(Int64, n_followed/2), 2], title = "On_node "*string(positions[i])) for i in range2]
for i in 1:Int(length(followed_nodes)/2)
    lines!(ax1[i], on_nodes[range1[i]], color = :red)
    try lines!(ax2[i], on_nodes[range2[i]], color = :red)
    catch
    end   
end
#save("On_axis.pdf", fig)
display(fig)

try
    throw(DomainError(nothing))
catch
    nothing
end
