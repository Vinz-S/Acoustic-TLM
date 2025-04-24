include("mesh-generator.jl")
include("TLM-solver.jl")
using TOML
#flow:
#extract data from config file
filename = "exampleconfig"
configs = TOML.parsefile(filename*".toml")
c = configs["c"]
#generate mesh
mconf = configs["mesh"]
tll = mconf["dimensions"]["tll"] #transmission line length
mesh, tree = Generator.nodes((mconf["dimensions"]["x"], mconf["dimensions"]["y"], mconf["dimensions"]["z"]),
                      crystal = mconf["type"], transmission_line_length = tll)
#generate sources
source = configs["sources"]
for i in enumerate(source["x"])
    if source["type"][i] == "sine"
        Solver.generate_sine(mesh, (source["x"][i], source["y"][i], source["z"][i]), tree, 
                         amplitude = source["amp"][i], frequency = source["freq"][i])
    elseif source["type"][i] == "dirac"
        Solver.generate_dirac(mesh, (source["x"][i], source["y"][i], source["z"][i]), tree, 
                         amplitude = source["amp"][i])
    else
        error("Unknown source type: "*source["type"][i])
    end
end
#set up measuring points
measurement_points = 
#run simulation
it_time = c/tll #time per iteration
its = ceil(configs["duration"]/it_time) #number of iterations
wavelengths = [c/freq for freq in sconf["freq"]] #wavelength
wtll = (wavelengths.^-1).*tll #tll in wavelengths
#extract measurements

#fourier transform measurements
#plot results
#save results