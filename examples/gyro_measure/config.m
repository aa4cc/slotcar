%% define experiment

conf = Configuration;
conf.Folder = pwd;
conf.RootModel = 'gyro_measure';
conf.MatlabIpv4 = '192.168.7.1';
conf.CommsBackend = comms.nng.NngBackend;
conf.CommsBackend.SampleTime = 0.10;
conf.ParallelCompilation = false;

%% define used boards

conf.Boards(1).Ipv4 = '192.168.7.2';
conf.Boards(1).ModelName = 'M1';
conf.Boards(1).External = true;
