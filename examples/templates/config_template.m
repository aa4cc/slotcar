%% define experiment
conf = Configuration;
conf.Folder = pwd;
conf.RootModel = 'experiment_template';
conf.MatlabIpv4 = '192.168.0.2';
conf.CommsBackend = comms.udt.UdtBackend;
conf.CommsBackend.SampleTime = 0.10;
conf.ParallelCompilation = false;

%% define used boards
conf.models(1).name = 'M1';
conf.models(1).ip = '192.168.0.3';

conf.models(2).name = 'M2';
conf.models(2).ip = '192.168.0.4';

conf.models(3).name = 'M3';
conf.models(3).ip = '192.168.0.5';

conf.models(4).name = 'M4';
conf.models(4).ip = '192.168.0.6';