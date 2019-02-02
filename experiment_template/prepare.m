%% define experiment ======================================================
conf.root = 'experiment_template';
conf.models = [];
conf.commSampleTime = 0.1; % (seconds)
conf.parallelCompilation = false;
conf.port = 25500;
conf.debug = true;

%% define used boards =====================================================
conf.models(1).name = 'M1';
conf.models(1).ip = '192.168.1.101';

conf.models(2).name = 'M2';
conf.models(2).ip = '192.168.2.111';

conf.models(3).name = 'M3';
conf.models(3).ip = '192.168.1.103';

conf.models(4).name = 'M4';
conf.models(4).ip = '192.168.1.104';

%% for each board prepare a controller ====================================


%help beagleboneblue
%help slbuild