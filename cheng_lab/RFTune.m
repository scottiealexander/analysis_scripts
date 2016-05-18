function [res,ts] = RFTune(ifile,varargin)

% RFTune
%
% Description: run spatial, temporal, contrast, or orientation/direction tuning
%
% Syntax: [s,h] = RFTune(ifile,<options>)
%
% In:
%       ifile - the path to the original .smr file
%   options:
%       channel - ('Cortex') the channel name to load
%       ts      - ([]) a vector of pre-loaded spike timestamps
%       f1      - (false) true to return f1 fit, false to return f0
%
% Out:
%       res - a struct with the results of the fitting
%       ts  - a TSPlot object of the resulting plot
%
% Updated: 2016-05-13
% Scottie Alexander
%
% Please report bugs to: scottiealexander11@gmail.com

opt = ParseOpts(varargin,...
    'channel' , 'Cortex',...
    'ts'      , []      ,...
    'f1'      , false     ...
    );

if isempty(opt.ts)
    spk_ts = spk.Preprocess(ifile,opt.channel);
else
    spk_ts = opt.ts;
end

pm = spk.ParameterMap(ifile);

type = lower(regexp(pm.title,'\w+ \w+','match','once'));

blog = false;
opts = {'normalize', true};

switch lower(type)
case {'sf','spaital','spatial frequency'}
    type = 'SpatialFrequency';

    %monitor distance is required for sf2dva calculation
    mon_file = fullfile(Path(ifile).parent,'monitor.txt');
    if exist(mon_file,'file') == 2
        monitor_distance = str2double(fget(mon_file));
    else
        msg = 'No monitor.txt file could be found, assuming a distance of 57cm';
        warning('RFTune:NoMonitorDistance',msg);
        monitor_distance = 57;
    end

    % will allow auto conversion of labels to degrees visual angle
    % with a call to spk.Tune.SpatialFrequency.ConvertLabels in
    % spk.Tune.Base.RunProc
    opts = [opts, {...
        'monitor_distance', monitor_distance ,...
        'log', true                           ...
        }];
        blog = true;

case {'tf','temporal','temporal frequency'}
    type = 'TemporalFrequency';

case {'con','contrast','contrast tuning'}
    type = 'Contrast';
    opts = [opts, {'log', true}];
    blog = true;

case {'ori','orientation','orientation tuning'}
    type = 'Orientation';

otherwise
    error('%s is not a valid tuning type',type);
end

% construct the appropriate tuning object for the tuning type
obj = spk.tune.(type)(ifile, 'ts', spk_ts, opts{:});

% run the fitting procedure
[f0, f1] = obj.RunProc();

if opt.f1
    res = f1;
else
    res = f0;
end

if blog
    x = log10(res.data.x);
    xfit = log10(res.fit.x);
else
    x = res.data.x;
    xfit = res.fit.x;
end

ts = TSPlot(x, res.data.y,...
    'lstyle' , 'none'                ,...
    'mrk'    , '.'                   ,...
    'mrksize', 20                    ,...
    'xlabel' , type                  ,...
    'ylabel' , 'Normalized Response' ,...
    'zeros'  , false                  ...
    );

hf = line(xfit, res.fit.y, 'Color',[0 0 1],'LineWidth',3,'Parent',ts.hA);

xf  = .01*(max(res.data.x) - min(res.data.x));
ymn = min([min(res.data.y) min(res.fit.y)]);
ymx = max([max(res.data.y) max(res.fit.y)]);
yf  = .01*(ymx - ymn);

ts.ResetLimits(...
    'xlim', [min(res.data.x)-xf max(res.data.x)+xf] ,...
    'ylim', [ymn-yf ymx+yf]                          ...
    );

hl = legend([ts.hL hf],'data','fit');
set(hl,'Box','off');

if blog
    xtl = 10.^str2double(cellstr(get(ts.hA,'XTickLabel')));
    xtl = arrayfun(@num2str,roundn(xtl,-2),'uni',false);
    set(ts.hA,'XTickLabel',xtl);
end

%------------------------------------------------------------------------------%
% NOTE: this function now resides in spk.Tune.SpatialFrequency.ConvertLabels
% function deg = sf2deg(sf)
%     %sf labels are in cycles/cm, assuming a monitor distance of 57cm
%     %was used to calculate the labels (where 1 cm == 1 dva)
%     deg = 360*atan(sf./(2*monitor_distance))/pi;
% end
%------------------------------------------------------------------------------%
end
