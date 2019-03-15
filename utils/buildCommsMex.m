function buildCommsMex(varargin)

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
    olddir = cd(fullfile(p.RootFolder,'src','comms'));

    disp('## Building sfun_sub');
    mex( '-g',...
        ['-I' fullfile(p.RootFolder,'src','comms','include')],...
        ['-I' fullfile(nngdir,'include')],...
        ['-L' fullfile(nngdir,'lib')],...
        '-lnng',...
        fullfile('src','sfun_sub.c'));

    disp('## Building sfun_pub');
    mex( '-g',...
        ['-I' fullfile(p.RootFolder,'src','comms','include')],...
        ['-I' fullfile(nngdir,'include')],...
        ['-L' fullfile(nngdir,'lib')],...
        '-lnng',...
        fullfile('src','sfun_pub.c'));

    cd(olddir);

end