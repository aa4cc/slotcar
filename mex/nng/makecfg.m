function makecfg(info)
addLinkFlags(info,' -lnng');
p = simulinkproject;
srcpath = fullfile(p.RootFolder, 'src', 'sfunctions', 'nng');
addSourceFiles(info, {'nng_pub.c', 'nng_sub.c'}, srcpath);
end
