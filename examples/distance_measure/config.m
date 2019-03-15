%% define experiment ======================================================

conf = Configuration;
conf.Folder = pwd;
conf.RootModel = 'distance_measure';
conf.MatlabIpv4 = '192.168.0.107';
conf.CommSampleTime = 0.10; % (seconds)
conf.ParallelCompilation = false;
conf.Port = 25500;
conf.Debug = false;

%% define used boards =====================================================

conf.Boards(1).Ipv4 = '192.168.0.130';
conf.Boards(1).ModelName = 'M1';
conf.Boards(1).External = true;
