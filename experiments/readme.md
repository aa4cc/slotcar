# Experiments folder

Basic guidelines for working with the project

## About

The experiments folder is excluded from source control
and is intended for concrete use of the project. That is
* Defining your board environment and experiment
* Initializing and editing Simulink models
* Generating and distributing code

## Getting started
The intended structure is

experiments
+-- readme.md
+-- experiment_one
|   +-- prepare.m
|   +-- slprj/
|   +-- car_system_*
+-- experiment_two
|   +-- prepare.m
|   +-- slprj/
|   +-- car_system_*
+-- ...

Start by copying the experiment_template folder as 
experiment_one and work from there. PWD should be inside
the specific experiment directory.


