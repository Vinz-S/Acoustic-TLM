# Acoustic-TLM
This repository contains the main julia files used for my masters thesis.

The main files for the TLM-method are the mesh-generator.jl and TLM-solver.jl scripts which contain modules used by the main.jl script.
main.jl also imports a configuration file containing the simulation parameters, these are stored in the configs folder.
The results folder is where plotted results are stored, and the post folder contains scripts for analyizing the results from the simulation. However not everything generated is saved to the repository, as seen in the .gitignore several file types are omitted.

The tests.jl scripts contains many tests used to test different functions implemented in other scritps.
Post.jl contains functions used for visualizations and in post processing scripts.
Other minor scripts not mentioned are used for different setup calculations.
The 2-D TLM scripts were written to check functionality using two differnt TLM implemntations.

The .ggb files are geogebra files which contain the calculations for the mesh dimensions used in some of the prop_test configs.
