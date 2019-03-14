function makecfg(info)

p = simulinkproject;
nngdir = fullfile(p.RootFolder, 'nng');
disp(['Running makecfg from folder: ',pwd]);

addIncludePaths(info, { ...
    fullfile(p.RootFolder,'lib','comms','include') ...
    fullfile(nngdir, 'include') ...
    });

addLinkFlags(info, '-L/usr/local/lib -lnng');
end
