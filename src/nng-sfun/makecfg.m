function makecfg(info)

p = simulinkproject;
nngdir = fullfile(p.RootFolder, 'nng');
disp(['Running makecfg from folder: ',pwd]);

addIncludePaths(info, { ...
    fullfile(p.RootFolder,'src','nng','include') ...
    fullfile(nngdir, 'include') ...
    });

addLinkFlags(info,' -lnng');
end
