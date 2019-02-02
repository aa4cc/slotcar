function new_models (conf)
% WILL HAVE TO LOOK DIFFERENT

load_system('basic_controller.slx');
% tempConfigObj = getActiveConfigSet('basic_controller');
for enum = 1:length(conf.models)
    str = ['model_', num2str(enum)];
    if ~isfile(str)
        copyfile('basic_controller.slx', [str , '.slx']);
    end
end
clear str carnum platoonstr
end

