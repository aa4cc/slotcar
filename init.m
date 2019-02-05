function init(varargin)
%INIT Add CoderPlatform to the path and move to the experiment,
%   if it was specified as parameter to the function.

if size( varargin ) > 2
    fprintf ("Too many arguments.");
    return;
end

addpath ./CoderPlatform
addpath ./CoderPlatform/templates
addpath ./CoderPlatform/drivers/IMU
addpath "./CoderPlatform/drivers/I2C distance sensor"

if size(varargin) == 1
    cd( join( ["experiments/" varargin{1}] ) );
end

