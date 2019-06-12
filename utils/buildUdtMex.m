function buildUdtMex(varargin)

if (nargin > 1)
    warning("Too many arguments to buildCommsMex.\n")
    return;
elseif (nargin == 1)
    udtdir = varargin{1};
else
    arch = computer('arch');
    switch arch
        case 'win'
            udtdir = 'C:\Program Files\UDT4'; 
        case 'win64'
            udtdir = 'C:\Program Files (x86)\UDT4';
        case 'glnxa64'
            udtdir = '/usr/local/lib';
        otherwise
            warning(['NNG directory not specified and architecture' ...
                     ' %s does not have a default.\n'], arch);
            return;
    end
end
    buildWithUdt(udtdir);
end

function buildWithUdt(udtdir)

    if (~isfolder(udtdir))
        warning(['UDT directory not found in %s.\n' ...
                'Please install UDT and specify its root location.\n'], ...
                udtdir);
        return;
    end
    
    % build
    p = simulinkproject;
    oldFolder = cd(fullfile(p.RootFolder, 'mex', 'udt'));

    try
    
    if ispc
    disp('## Building udt_sf_sub');
    mex( '-g',...
        ['-I' fullfile(p.RootFolder,'lib','udt-arm','udt4','src')],...
        ['-L' udtdir],...
        '-ludt',...
        '-lws2_32',...
        '-DWIN32',...
        fullfile(p.RootFolder,'src','sfunctions','udt','udt_sub.cpp'));

    disp('## Building udt_sf_pub');
    mex( '-g',...
        ['-I' fullfile(p.RootFolder,'lib','udt-arm','udt4','src')],...
        ['-L' udtdir],...
        '-ludt',...
        '-lws2_32',...
        '-DWIN32',...
        fullfile(p.RootFolder,'src','sfunctions','udt','udt_pub.cpp'));
    else
    disp('## Building udt_sf_sub');
    mex( '-g',...
        ['-I' fullfile(p.RootFolder,'lib','udt-arm','udt4','src')],...
        ['-L' udtdir],...
        '-ludt',...
        fullfile(p.RootFolder,'src','sfunctions','udt','udt_sub.cpp'));

    disp('## Building udt_sf_pub');
    mex( '-g',...
        ['-I' fullfile(p.RootFolder,'lib','udt-arm','udt4','src')],...
        ['-L' udtdir],...
        '-ludt',...
        fullfile(p.RootFolder,'src','sfunctions','udt','udt_pub.cpp'));
    end
    catch ME
       cd(oldFolder) 
       rethrow(ME)
    end

    cd(oldFolder);

end