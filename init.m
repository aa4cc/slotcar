function init(varargin)
%INIT Summary of this function goes here
%   Detailed explanation goes here

if size( varargin ) > 2
    fprintf ("Too many arguments.");
    return;
end

addpath ./CoderPlatform
addpath ./CoderPlatform/templates

if size(varargin) == 1
    cd( join( ["experiments/" varargin{1}] ) );
end

