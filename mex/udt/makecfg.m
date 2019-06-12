function makecfg(info)
addLinkFlags(info, '-ludt');
p = simulinkproject;
srcpath = fullfile(p.RootFolder, 'src', 'sfunctions', 'udt');
addSourceFiles(info, {'udt_pub.cpp', 'udt_sub.cpp'}, srcpath);
end
