include("mesh-generator.jl")
include("TLM-solver.jl")
include("post.jl")
using TOML
using JLD2
using FileIO
using StaticArrays
using ProgressBars
#flow:
#extract data from config file
config_name = "exampleconfig"
configs = TOML.parsefile(config_name*".toml")
c = configs["c"]

#creating/loading mesh_file
mesh_file = configs["mesh"]["filename"]
tll = configs["mesh"]["dimensions"]["tll"] #transmission line length
#This implementation might be prone to human error if different setups keep the same filenames
if isfile(mesh_file*".jld2")
    println("Loading mesh from file: ", mesh_file*".jld2")
    mesh, tree = load(mesh_file*".jld2", "nodes")
else
    println("Generating new mesh and saving to file: ", mesh_file*".jld2")
    #generate mesh
    mconf = configs["mesh"]
    mesh, tree = Generator.nodes((mconf["dimensions"]["x"], mconf["dimensions"]["y"], mconf["dimensions"]["z"]),
                        crystal = mconf["type"], transmission_line_length = tll)
    #save mesh
    Saving_dicts.to_jld2(mesh, tree, mesh_file)
    mesh, tree = load(mesh_file*".jld2", "nodes")
end

#generate sources
sources = configs["sources"]
for i in eachindex(sources["x"])
    if sources["type"][i] == "sine"
        Solver.generate_sine(mesh, (sources["x"][i], sources["y"][i], sources["z"][i]), tree, 
                         amplitude = sources["amp"][i], frequency = sources["freq"][i])
    elseif sources["type"][i] == "dirac"
        Solver.generate_dirac(mesh, (sources["x"][i], sources["y"][i], sources["z"][i]), tree, 
                         amplitude = sources["amp"][i])
    else
        error("Unknown source type: "*sources["type"][i])
    end
end

#set up measurenents
mic_configs = configs["measurements"]["microphones"]
measurement_points = [SVector{3,Int64}(mic_configs["x"][i], mic_configs["y"][i], mic_configs["z"][i]) for i in eachindex(mic_configs["x"])]
for point in measurement_points
    if point[1] > configs["mesh"]["dimensions"]["x"] || point[2] > configs["mesh"]["dimensions"]["y"] || point[3] > configs["mesh"]["dimensions"]["z"]
        println("Measurement point out of bounds: "*string(point))
        filter!(v->v!=point, measurement_points)
    end
end
measurement_points = [i[1] for i in knn(tree, measurement_points, 1)[1]] #finds the closest node to the measurement point
measurements = [[] for i in eachindex(measurement_points)] # The pressure values are saved here
#run simulation
it_time = tll/c #time per iteration
its = ProgressBar(0:ceil(configs["duration"]/it_time)) #iterations
wavelengths = [c/freq for freq in sources["freq"]] #wavelength
wtll = (wavelengths.^-1).*tll #tll in wavelengths

for i in its
    Solver.update_tlm!(mesh, i*it_time, reflection_factor = 1) #configs["reflection"]["factor"])
    for j in eachindex(measurement_points)
        push!(measurements[j], mesh[measurement_points[j]].on_node)
    end
end

#save results
save(configs["measurements"]["filename"]*".jld2", "measurements", measurements)
#further analysis done after importing data in a new script