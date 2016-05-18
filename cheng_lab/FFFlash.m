function ifo = FFFlash(ifile,varargin)

% FFFlash
%
% Description:
%
% Syntax: FFFlash
%
% In:
%       ifile - the path to the original .smr file
%   options:
%       channel - ('Cortex') the channel name to load
%       ts      - ([]) a vector of pre-loaded spike timestamps
% Out:
%       ifo - a struct containing the results of the fitting
%
% References:
%       Ibbotson, M R et al. (2008) J Neurosci 28(43):10952-10960
%
% Updated: 2015-07-23
% Scottie Alexander
%
% Please report bugs to: scottiealexander11@gmail.com

opt = ParseOpts(varargin,...
    'channel' , 'Cortex',...
    'ts'      , []       ...
    );


if isempty(opt.ts)
    spk_ts = spk.Preprocess(ifile,opt.channel);
else
    spk_ts = opt.ts;
end

evt_ts = spk.load.Events(ifile,'name','Trigger');

pm = spk.ParameterMap(ifile,'format','Daniel');

n = pm.Get('Number of repeats');

[c1,d1] = ParseColorTime(pm.Get('Color/Time 0'));
[c2,d2] = ParseColorTime(pm.Get('Color/Time 1'));

% The ParseColor assigns 'black' to both c1 and c2
% This is a simple fix as all my FFF runs are the same (ANg)
c2 = 'white';

c1_on = evt_ts(1:2:(n*2)-1);
c2_on = evt_ts(2:2:n*2);

dat.(c1) = spk.Segment(spk_ts,c1_on,'pre',0,'post',d1,'bin_size',.001);
dat.(c2) = spk.Segment(spk_ts,c2_on,'pre',0,'post',d2,'bin_size',.001);

sw = sum(dat.white(:));
sb = sum(dat.black(:));

ifo.on_off_ratio = (sw-sb)/(sw+sb);

if ifo.on_off_ratio >= 0
    f = 'white';
    ifo.type = 'on';
else
    f = 'black';
    ifo.type = 'off';
end


sdf = psth2sdf(dat.(f));

%threshold = 99th percentile of rate matched Poisson
thr = poissinv(0.99,mean(sdf));

ifo.latency = find(sdf>thr,1,'first');
ifo.sdf = sdf;

[evt_psth,cgrp] = spk.PSTH(spk_ts,evt_ts,200,-1);
ifo.evt_psth = evt_psth;
ifo.cgrp = cgrp;
%-----------------------------------------------------------------------------%
function [col,dur] = ParseColorTime(str)
    re = regexp(str,'(?<col>[A-Za-z]+)/(?<dur>\d*\.*\d+)','names');
    col = lower(re.col);    
    dur = str2double(re.dur);
end
%-----------------------------------------------------------------------------%
function y = psth2sdf(x)
    kernel = normpdf(-.05:.001:.05,0,.005);
    y = nan(size(x));
    for k = 1:size(x,1)
        y(k,:) = conv(x(k,:),kernel,'same');
    end
    y = mean(y,1);
end
%-----------------------------------------------------------------------------%
end