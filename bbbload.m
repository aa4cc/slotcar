% load car models into the cars
for i = 1:1
    car = cars{i};
    str = ['car_system_' num2str(i)];
    slbuild(str);
    car.loadModel(str);
end
clear str carnum platoonstr