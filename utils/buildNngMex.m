function buildNngMex(varargin)

if (nargin > 1)
    warning("Too many arguments to buildCommsMex.\n")
    return;
elseif (nargin == 1)
    nngdir = varargin{1};
else
    arch = computer('arch');
    switch arch
        case 'win'
            nngdir = 'C:\Program Files\nng'; 
        case 'win64'
            nngdir = 'C:\Program Files (x86)\nng';
        case 'glnxa64'
            nngdir = '/usr/local/lib';
        otherwise
            warning(['NNG directory not specified and architecture' ...
                     ' %s does not have a default.\n'], arch);
            return;
    end
end
    buildWithNNG(nngdir);
end

function buildWithNNG(nngdir)

    if (~isfolder(nngdir))
        warning(['NNG directory not found in %s.\n' ...
                'Please install NNG and specify its root location.\n'], ...
                nngdir);
        return;
    end
    
    % build
    p = simulinkproject;
    oldFolder = cd(fullfile(p.RootFolder, 'mex', 'nng'));
    
    try
        
    disp('## Building nng_sf_sub');
    mex( '-g',...
        ['-I' fullfile(nngdir,'include')],...
        ['-L' fullfile(nngdir,'lib')],...
        '-lnng',...
        fullfile(p.RootFolder,'src','+comms','+nng','sfun','nng_sub.c'));

    disp('## Building nng_sf_pub');
    mex( '-g',...
        ['-I' fullfile(nngdir,'include')],...
        ['-L' fullfile(nngdir,'lib')],...
        '-lnng',...
        fullfile(p.RootFolder,'src','+comms','+nng','sfun','nng_pub.c'));
    
    catch ME
       cd(oldFolder) 
       rethrow(ME)
    end
    cd(oldFolder);

end