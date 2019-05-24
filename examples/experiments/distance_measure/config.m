%% define experiment 

conf = Configuration;
conf.Folder = pwd;
conf.RootModel = 'distance_measure';
conf.MatlabIpv4 = '192.168.88.253';
conf.CommsBackend = comms.udt.UdtBackend;
conf.CommsBackend.SampleTime = 0.10;
conf.ParallelCompilation = false;

%% define used boards 

conf.Boards(1).Ipv4 = '192.168.88.249';
conf.Boards(1).ModelName = 'M1';
conf.Boards(1).External = true;
conf.Boards(1).Crucial = true;