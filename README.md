![Car platooning](images/car-platoon-1.png)
# Distributed Platform for Slotcar Platooning 
Slotcar Platooning is a platform for demonstration of vehicular longitudinal control with strings of vehicles. 
The slotcars combine the BeagleBone Blue boards, encoders, and proximity sensors inside a slotcar chassis. 
The chassis is part custom printed, part universal slotcar racing starter kit. 
This repository combines two parts:
* Scripts for generating code for multiple distributed systems and control of code execution.
* Design files, drivers and Simulink libraries for the slotcars.
The first part serves a general purpose and could be used with any distributed project based on the BeagleBone Blue. 
The other builds a low-cost experimental platform of controllable slotcars.
* [_cad_/](cad/) folder contains the slotcar design files, that is the custom bodywork chassis and a list of used parts
* [_examples/_](examples/) folder contains templates and shared experiments to demonstrate the use of the project
* [_models/_](models/) folder contains Simulink libraries of slotcar control building blocks
* [_src/_](src/) folder contains important scripts for the purpose of code generation for distributed systems and other code such as _C/C++_ s-functions
* [_util/_](util/) folder contains helper scripts for generating mex files and setting up the Simulink project