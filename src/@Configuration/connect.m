function [beaglebones, isRunnable] = connect(obj)
%OPENCONNECTION Attemps to open a ssh connection to boards.
%   Sequentially connect to development boards defined in the experiment 
%   and return the connected devices as an array. The second output value
%   indicates for other scripts that a crucial board cannot be connected
%   and experiment should be interrupted.

[B, ok] = arrayfun(@(b) b.connect, obj.Boards, 'UniformOutput', false);
beaglebones = B(~cellfun('isempty',B));
isRunnable = all([ok{:}]);
end

