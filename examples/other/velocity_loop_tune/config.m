%% define experiment

conf = Configuration;
conf.Folder = pwd;
conf.RootModel = 'drive';
conf.MatlabIpv4 = '192.168.88.11';
conf.CommsBackend = comms.nng.NngBackend;
conf.CommsBackend.SampleTime = 0.005;
conf.ParallelCompilation = false;

%% define used boards

conf.Boards(1).Ipv4 = '192.168.88.18';
conf.Boards(1).ModelName = 'M1';
conf.Boards(1).External = true;
conf.Boards(1).Crucial = true;