function setConnextEnv

arch = computer('arch');
switch arch
    case 'win64'
        setenv('NDDSHOME','C:\Program Files\rti_connext_dds-5.3.1');
        CurrentPath = getenv('PATH');
        setenv('PATH',[CurrentPath, ...
            ';C:\Program Files\rti_connext_dds-5.2.0\lib\x64Win64VS2012']);
    otherwise
        warning(['Architecture %s does not have' ...
                 'default DDS env variables set up.\n'], arch);
        return;
end
DDS.import('BusObject.idl');

end