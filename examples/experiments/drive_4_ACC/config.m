%% define experiment

conf = Configuration;
conf.Folder = pwd;
conf.RootModel = 'drive4ACC';
conf.MatlabIpv4 = '192.168.88.11';
conf.CommsBackend = comms.nng.NngBackend;
conf.CommsBackend.SampleTime = 0.01;
conf.ParallelCompilation = false;

%% define used boards

conf.Boards(1).Ipv4 = '192.168.88.19';
conf.Boards(1).ModelName = 'M1';
conf.Boards(1).External = false;
conf.Boards(1).Crucial = true;

conf.Boards(2).Ipv4 = '192.168.88.18';
conf.Boards(2).ModelName = 'M2';
conf.Boards(2).External = false;
conf.Boards(2).Crucial = true;

conf.Boards(3).Ipv4 = '192.168.88.20';
conf.Boards(3).ModelName = 'M3';
conf.Boards(3).External = false;
conf.Boards(3).Crucial = true;

conf.Boards(4).Ipv4 = '192.168.88.15';
conf.Boards(4).ModelName = 'M4';
conf.Boards(4).External = false;
conf.Boards(4).Crucial = true;