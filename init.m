function init(varargin)
%INIT Add CoderPlatform to the path and move to the experiment,
%   if it was specified as parameter to the function.

if size( varargin ) > 2
    fprintf ("Too many arguments.");
    return;
end

addpath ./CoderPlatform
addpath ./CoderPlatform/drivers/IMU
addpath './CoderPlatform/drivers/I2C distance sensor'

mfilename('fullpath')

if size(varargin) == 1
    cd( strcat("experiments/", varargin{1} ) );
end

