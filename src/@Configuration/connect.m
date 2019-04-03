function [beaglebones, ok] = openConnection(obj)
%OPENCONNECTION Summary of this function goes here
%   Detailed explanation goes here

ok = true;
bc = numel(obj.Boards);
beaglebones = cell(bc, 1);
for i = 1:bc
    ip = obj.Boards(i).Ipv4;
    try
        beaglebones{i} = beagleboneblue(ip, 'debian', 'temppwd');
    catch
       fprintf("@@@ Can't connect to %s\n", ip); 
       beaglebones{i} = [];
       if obj.Boards(i).Crucial
          fprintf('@@@ Board is flagged as crucial.\n')
          ok = false;
       end
       continue
    end
end

