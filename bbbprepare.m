%%define set of used cars
cars = {...
        beagleboneblue('192.168.0.11'),...
        beagleboneblue('192.168.0.12'),...
        };

%% for each car prepare a controller file
load_system('templates/basic_controller.slx');
tempConfigObj = getActiveConfigSet('basic_controller');
for carnum = 1:length(cars)
    str = ['car_system_', num2str(carnum)];
    if ~isfile(str)
        copyfile('templates/basic_controller.slx', [str , '.slx']);
    end
end
clear str carnum platoonstr

%help beagleboneblue
%help slbuild