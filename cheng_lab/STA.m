function ifo = STA(ifile,varargin)

% STA
%
% Description:
%
% Syntax: STA(ifile,<options>)
%
% In:
%
% Out:
%
% Updated: 2015-03-18
% Scottie Alexander
%
% Please report bugs to: scottiealexander11@gmail.com

opt = ParseOpts(varargin,...
    'channel' , 'Cortex',...
    'ts'      , []      ,...
    'im_dir'  , ''       ...
    );

%MEAMseq line 104, .046 centimeters per pixel for Cheng lab ephys monitor
ppm = 1/.00046;  %pixels per meter
monitor_distance = .57; %distance to monitor in meters

mon_file = fullfile(Path(ifile).parent,'.txt');
if exist(mon_file,'file') == 2
    monitor_distance = str2double(fget(mon_file))*1e-2;
end

if isempty(opt.im_dir)
    opt.im_dir = Path(ifile).parent;
end

if isempty(opt.ts)
    switch Path(ifile).ext
    case 'smr'
        spk_ts = spk.Preprocess(ifile,opt.channel);
    case 'ts'
        spk_ts = spk.load.TS(ifile);
    otherwise
        error('Input file is of unknow type');
    end
else
    spk_ts = opt.ts;
end

evt_ts = spk.load.Events(ifile,'name','Trigger');

if ~iscell(spk_ts)
    spk_ts = {spk_ts};
end

ifo = cell(numel(spk_ts),1);

for k = 1:numel(spk_ts)
    kernel = spk.sta.Run(spk_ts{k},evt_ts);

    h = spk.sta.Plot(kernel,...
        'smooth' , false ,...
        'size'   , [4,4] ,...
        'sigma'  , .5     ...
        );

    ofile = fullfile(opt.im_dir,sprintf('%02d_kernel.png',k));

    print(h,'-dpng','-r150',ofile);
    close(h);

    [rf,ifo{k},h] = RFFit(kernel);
    ifo{k}.kernel = kernel;
    ifo{k}.rf = rf;

    ofile = fullfile(opt.im_dir,sprintf('%02d_rf.png',k));
    print(h,'-dpng','-r150',ofile);
    close(h);
end

ifo = cat(1,ifo{:});

pm = spk.ParameterMap(ifile,'format','daniel');

%dot size is really the side length of each mseq box
% i.e. the sqrt of the area of each box in PIXELS
dt = Px2Vis(pm.Get('dot size'))^2;
fpt = pm.Get('frames per term');

for k = 1:numel(ifo)
    % RF area in mseq box units * area of each box in dva
    ifo(k).area = ifo(k).sigma_x*ifo(k).sigma_y*pi*dt;
    ifo(k).fpt = fpt;
end

%-----------------------------------------------------------------------------%
function vis = Px2Vis(px)    
    vis = 360*atan(px/(2*monitor_distance*ppm))/pi;
end
%-----------------------------------------------------------------------------%
end