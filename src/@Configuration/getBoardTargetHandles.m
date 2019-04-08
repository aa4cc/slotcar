function targetHandles = getBoardTargetHandles(obj)
%GETBOARDTARGETHANDLES Returns handles of board subsystems in top system

    nd = length(obj.Boards);
    targetHandles = ones(1, nd);
    for i = 1:nd
        targetHandles(i) = getSimulinkBlockHandle( ...
            strcat(obj.TopModel, '/', obj.Boards(i).ModelName));
    end
end

