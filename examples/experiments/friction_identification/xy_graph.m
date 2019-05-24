data = load('measurement.mat');
data = data.simout.Data;
plot(data(:,1), data(:,2), '+');
hold on
avarages = [];

d = data(:,2);
u = unique(data(:,1));
u = u(u ~= 0 & u ~= 1);
a = zeros(2,length(u));
for i = 1:length(u)
    a(1,i) = u(i);
    a(2,i) = mean(d(data(:,1) == u(i)));
end

scatter(a(1,:),a(2,:))

c = polyfit(a(1,:),a(2,:),1);
y_est = polyval(c,a(1,:));
% Add trend line to plot
hold on
plot(a(1,:),y_est,'r--','LineWidth',2)
hold off

bd = (c(1)-1.73/11.55)*1.73*11.55/5
bs = c(2)*1.73*11.55/5
