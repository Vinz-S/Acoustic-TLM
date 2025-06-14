include("mesh-generator.jl")
include("TLM-solver.jl")
include("post.jl")
using TOML
using JLD2
using FileIO
using StaticArrays
using ProgressBars
#flow:
#extract data from config filegp
config_name = "prop_test_cart_20" #"exampleconfig" #NEEDS TO BE UPDATED BETWEEN DIFFERENT SIMULATIONS
configs = TOML.parsefile("configs/"*config_name*".toml")
c = configs["c"] #speed of sound, multiplied by sqrt(3) to account for the 3D mesh

#creating/loading mesh_file
#mesh_file = configs["mesh"]["filename"]
tll = configs["mesh"]["dimensions"]["tll"] #transmission line length
it_time = tll/c #time per iteration
#This implementation might be prone to human error if different setups keep the same filenames
# if isfile("meshes/"*mesh_file*".jld2")
#     println("Loading mesh from file: ", "meshes/"*mesh_file*".jld2")
#     mesh, tree = load("meshes/"*mesh_file*".jld2", "nodes")
# else
#     println("Generating new mesh and saving to file: ", "meshes/"*mesh_file*".jld2")
    #generate mesh
    mconf = configs["mesh"]
    if haskey(mconf["dimensions"], "r")
        mesh, tree = Generator.spheres(mconf["dimensions"]["r"],
                            crystal = mconf["type"], transmission_line_length = tll)
    else
        mesh, tree = Generator.nodes((mconf["dimensions"]["x"], mconf["dimensions"]["y"], mconf["dimensions"]["z"]),
                            crystal = mconf["type"], transmission_line_length = tll)
    end
#                         #save mesh
#     println("Saving mesh to file")
#     Saving_dicts.to_jld2(mesh, tree, "meshes/"*mesh_file)
#     mesh, tree = load("meshes/"*mesh_file*".jld2", "nodes")
# end
println("Mesh loaded, size: ", length(mesh), " nodes")

#generate sources
sources = configs["sources"]
iter = ProgressBar(eachindex(sources["x"]))
for i in iter
    if sources["type"][i] == "sine"
        if haskey(sources, "periods")
            display("Generating sine source with periods")
            Solver.generate_sine(mesh, (sources["x"][i], sources["y"][i], sources["z"][i]), tree, 
                         amplitude = sources["amp"][i], frequency = sources["freq"][i], periods = sources["periods"][i])
        else
            display("Generating continuous sine source")
            Solver.generate_sine(mesh, (sources["x"][i], sources["y"][i], sources["z"][i]), tree, 
                         amplitude = sources["amp"][i], frequency = sources["freq"][i])
        end
    elseif sources["type"][i] == "dirac"
        display("Generating dirac source")
        Solver.generate_dirac(mesh, (sources["x"][i], sources["y"][i], sources["z"][i]), tree, 
                         amplitude = sources["amp"][i])
    elseif sources["type"][i] == "chirp"
        display("Generating chirp source")
        Solver.generate_chirp(mesh, (sources["x"][i], sources["y"][i], sources["z"][i]), 1/it_time, sources["fl"], sources["fh"], sources["T"], tree,
                         amplitude = sources["amp"][i],)
    else
        error("Unknown source type: "*sources["type"][i])
    end
    set_description(iter, "Generating sources: ")
end

#set up measurenents
mic_configs = configs["measurements"]["microphones"]
measurement_points = [SVector{3,Float64}(mic_configs["x"][i], mic_configs["y"][i], mic_configs["z"][i]) for i in eachindex(mic_configs["x"])]
pbar = ProgressBar(length(measurement_points))
for point in measurement_points
    if point[1] > configs["mesh"]["dimensions"]["x"] || point[2] > configs["mesh"]["dimensions"]["y"] || point[3] > configs["mesh"]["dimensions"]["z"]
        println("Measurement point out of bounds: "*string(point))
        filter!(v->v!=point, measurement_points)
    end
    update(pbar)
    set_description(pbar, "Setting up measurement points: ")
end
measurement_points = [i[1] for i in knn(tree, measurement_points, 1)[1]] #finds the closest node to the measurement point
measurements = [[] for i in eachindex(measurement_points)] # The pressure values are saved here
#run simulation
#Beginning from 0 creates an adittional bugged progressbar, workaround not found so far
its = ProgressBar(0:ceil(configs["duration"]/it_time)+1) #iterations
#wavelengths = [c/freq for freq in sources["freq"]] #wavelength
#wtll = (wavelengths.^-1).*tll #tll in wavelengths
#@time begin
for i in its
    Solver.update_tlm!(mesh, i*it_time, reflection_factor = configs["surfaces"]["r_factor"])
    for j in eachindex(measurement_points)
        push!(measurements[j], mesh[measurement_points[j]].on_node)
    end
    set_description(its, "Running simulation: ")
end
#end
#save results
save("results/"*configs["measurements"]["filename"]*".jld2", "measurements", measurements, "source output", Solver.source_outputs)
#further analysis done after importing data in a new script
