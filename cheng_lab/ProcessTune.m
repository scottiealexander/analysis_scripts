function data = ProcessTune(base_dir,typ,varargin)

% ProcessTune
%
% Description:
%
% Syntax: ProcessTune(base_dir,typ)
%
% In:
%
% Out:
%
% Updated: 2015-03-11
% Scottie Alexander
%
% Please report bugs to: scottiealexander11@gmail.com

opt = ParseOpts(varargin,...
    'force', false ...
    );

data = [];

cell_dir = FindDirs(base_dir,'\w+_\d+');

hb = waitbar(0,'Processing...');
ndir = numel(cell_dir);

for kD = 1:ndir
    run_dir = FindDirs(cell_dir{kD},['.*_' typ '_\d+']);

    if isempty(run_dir)
        continue;
    end

    %=========================================================================%
    % take only the last mseq run...
    run_dir = run_dir(end);
    %=========================================================================%

    for kC = 1:numel(run_dir)
        ofile = fullfile(run_dir{kC},'res.mat');
        if ~exist(ofile,'file') || opt.force
            ts_files = FindFiles(run_dir{kC},'.*\.ts');
            cts = cellfun(@(x) spk.load.TS(x),ts_files,'Uni',false);
            im_dir = fullfile(run_dir{kC},'fig');
            if ~isdir(im_dir)
                mkdir(im_dir);
            end

            ifo = [];
            for kU = 1:numel(cts)
                [tmp,ts] = RFTune(GetSMRFile(run_dir{kC}),'ts',cts{kU});
                if isempty(ifo)
                    ifo = tmp;
                else
                    ifo(kU,1) = tmp;
                end
                svg_file = fullfile(im_dir,sprintf('%02d_%s.svg',kU,typ));
                ts.ToSvg(svg_file);
                ts.Close();
            end

%             tmp = GetCellInfo(run_dir{kC});
%             for kF = 1:numel(ifo)
%                 ifo(kF).group = tmp.group;
%                 ifo(kF).age = tmp.age;
%                 ifo(kF).k = tmp.k;
%                 ifo(kF).ncell = tmp.ncell;
%             end
            save(ofile,'ifo');
            if isempty(data)
                data = ifo;
            else
                data = [data; ifo];
            end
        else
            ifo = getfield(load(ofile,'ifo'),'ifo');
            if isempty(data)
                data = ifo;
            else
                data = [data; ifo];
            end
        end
    end
    waitbar(kD/ndir,hb);
end

if ishandle(hb)
    close(hb);
end

%-----------------------------------------------------------------------------%
function s = GetCellInfo(x)
    re = regexp(Path(x).name,'(?<grp>[CcRr]{1})[0O]?(?<n>\d+)P(?<age>\d+)_(?<cell>\d+)','names');
    switch lower(re.grp)
    case 'c'
        s.group = false;
    case 'r'
        s.group = true;
    otherwise
        error('invalid group');
    end
    s.age = str2double(re.age);
    s.k = str2double(re.n);
    s.ncell = str2double(re.cell);
end
%-----------------------------------------------------------------------------%
function f = GetSMRFile(x)
    f = [x '.smr'];
    if ~exist(f,'file')
        s = GetCellInfo(f);
        if s.group
            grp = 'R';
            op = 'C';
        else
            grp = 'C';
            op = 'R';
        end

        %WARNING: this is likely not robust...
        str1 = sprintf(['%s%02dP%02d_%d_' typ],grp,s.k,s.age,s.ncell);
        str2 = strrep(str1,grp,op);
        f2 = strrep(f,str1,str2);
        if ~exist(f2,'file')
            error('Failed to find file %s',f);
        end
        f = f2;
    end
end
%-----------------------------------------------------------------------------%
end
