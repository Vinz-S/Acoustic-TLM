include("/home/vinzenz/Documents/Master/Acoustic-TLM//mesh-generator.jl")
include("/home/vinzenz/Documents/Master/Acoustic-TLM//post.jl")
using GLMakie

#Visually seeing that the coordinates are correct:
nodes, tree = Generator.sphere(4.3);
fig = Visualization.show_mesh(nodes; title = "Sphere mesh, tetrahedral", hidedecorations = true, azi = 0.66*pi, elev = 0.05*pi, fontsize = 32)
# save("illustrations/sphere tetraheder mesh.png", fig, resolution = (600, 600))
#= nodes, tree = Generator.sphere(4.5, crystal ="Cartesian");
fig = Visualization.show_mesh(nodes; title = "Sphere mesh, cartesian", hidedecorations = true, azi = 0.66*pi, elev = 0.05*pi, fontsize = 32)
save("illustrations/sphere cartesian mesh.png", fig, resolution = (600, 600)) =#