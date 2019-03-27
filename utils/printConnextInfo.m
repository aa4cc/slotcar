function printConnextInfo

version = DDS.version;
profiles = DDS.getProfiles;

disp('@@@ DDS version:')
details(version)
disp('@@@ DDS available QoS profiles:')
details(profiles)

end