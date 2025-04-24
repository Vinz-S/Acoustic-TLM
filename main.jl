include("mesh-generator.jl")
include("TLM-solver.jl")
using TOML
using JLD2
using FileIO
#flow:
#extract data from config file
config_name = "exampleconfig"
configs = TOML.parsefile(config_name*".toml")
c = configs["c"]

#creating/loading mesh_file
mesh_file = configs["mesh"]["filename"]
#This implementation might be prone to human error if different setups keep the same filenames
if isfile(mesh_file*".jld2")
    println("Loading mesh from file: ", mesh_file*".jld2")
    mesh, tree = load(mesh_file*".jld2", "nodes")
else
    println("Generating new mesh and saving to file: ", mesh_file*".jld2")
    #generate mesh
    mconf = configs["mesh"]
    tll = mconf["dimensions"]["tll"] #transmission line length
    mesh, tree = Generator.nodes((mconf["dimensions"]["x"], mconf["dimensions"]["y"], mconf["dimensions"]["z"]),
                        crystal = mconf["type"], transmission_line_length = tll)
    #save mesh
    Saving_dicts.to_jld2(mesh, tree, mesh_file)
    mesh, tree = load(mesh_file*".jld2", "nodes")
end

#generate sources
sources = configs["sourcess"]
for i in eachindex(sources["x"])
    display(sources["x"])
    display(i)
    display(sources["type"][i])
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
#set up measuring points
measurement_points = 
#run simulation
it_time = c/tll #time per iteration
its = ceil(configs["duration"]/it_time) #number of iterations
wavelengths = [c/freq for freq in sources["freq"]] #wavelength
wtll = (wavelengths.^-1).*tll #tll in wavelengths
#extract measurements

#fourier transform measurements
#plot results
#save results