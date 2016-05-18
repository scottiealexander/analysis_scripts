function PreprocessCell(exp_dir)

% PreprocessCell
%
% Description:
%
% Syntax: PreprocessCell(exp_dir)
%
% In:
%
% Out:
%
% Updated: 2015-03-03
% Scottie Alexander
%
% Please report bugs to: scottiealexander11@gmail.com

cfiles = FindFiles(exp_dir,'.*\.smr');

c = { ...
     {'text','string','What would you like to do?'},...
     {};...
     {'pushbutton','string','Next','tag','next'},...
     {'pushbutton','string','Exit'}
    };

% p = Path(fullfile(exp_dir,'raw'));
% if ~p.isdir
%     mkdir(char(p));
% end

n = 0;

for k = 1:numel(cfiles)    
    name = regexp(cfiles{k},'[A-Za-z0-9]+_\d+','match','once');
    p = Path(fullfile(exp_dir,strrep(name,'O','0')));
    if ~p.isdir
        mkdir(char(p));
    end

    ofile = MoveAllFiles(cfiles{k},char(p));

    if strfind(ofile,'chap')
        chan = 'Chan 1';
    else
        chan = 'Cortex';
    end
    
    fprintf('[FILE]: %s\n',ofile);    
    spk.Preprocess(ofile,chan);

    w = Win(c,'focus','next');
    w.Wait;
    if strcmpi(w.res.btn,'exit')
        break;
    else
        close('all');
    end
end

%-----------------------------------------------------------------------------%
function dest = MoveAllFiles(ifile,ddir)
    dest = Path(ifile).swap('dir',ddir);
    
    if ~movefile(ifile,dest)
        error('Filed to move file: %s',ifile);
    end

    ext = {'par','S2R'};
    for ke= 1:numel(ext)
        from = Path(ifile).swap('ext',ext{ke});
        if exist(from,'file')
            to = Path(from).swap('dir',ddir);
            if ~movefile(from,to)
                error('Filed to move file: %s',from);
            end
        end
    end
end
%-----------------------------------------------------------------------------%
end