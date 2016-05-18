function BarPlot(data,field,ylab,varargin)

% BarPlot
%
% Description:
%
% Syntax: BarPlot
%
% In:
%
% Out:
%
% Updated: 2015-03-13
% Scottie Alexander
%
% Please report bugs to: scottiealexander11@gmail.com

opt = ParseOpts(varargin,...
    'thresh' , 1 ...
    );

if isfield(data,'res_norm')
    b = [data(:).res_norm];
    b =  b > 0 & b < opt.thresh;
    if isfield(data,'peak')
        b = b & (abs([data(:).peak]) > 4);
    end
    fprintf('UNITS: %d / %d\n',sum(b),numel(data));
    dat = data(b);
else
    dat = data;    
end
grp = [dat(:).group];

egrp = [dat(grp==1).(field)];
cgrp = [dat(grp==0).(field)];

if strcmpi(field,'on_off_ratio')
    egrp = abs(egrp);
    cgrp = abs(cgrp);
end

if any(strcmpi(field,{'csf','surround_csf'}))
    % Movshon et al. 2005, p.2714: "the characteristic spatial frequency is
    % reciprocally related to the receptive field center radius"
    % egrp = 1./(egrp*pi);
    % cgrp = 1./(cgrp*pi);
    % egrp = pi*((1./egrp).^2);
    % cgrp = pi*((1./cgrp).^2);
end

me = nanmean(egrp);
mc = nanmean(cgrp);
fprintf('ME: %.03f | MC: %.03f\n',me,mc);
ee = nanstderr(egrp,[],2);
ec = nanstderr(cgrp,[],2);

h = figure('NumberTitle','off','Name','BarPlot','MenuBar','figure',...
    'Position',[100 100 800 600],'Color',[1 1 1]);

ax = axes('Units','normalized','OuterPosition',[0 0 1 1],'Parent',h);

hb = bar(ax,[1; 2],diag([me; mc]),'stacked');
shading(ax,'Flat');

set(hb(1),'FaceColor',[1 0 0]);
set(hb(2),'FaceColor',[0 0 1]);

set(ax,'Box','off','LineWidth',4);

set(ax,'XTickLabel',{'Rear','Control'},'FontSize',18);
set(get(ax,'YLabel'),'String',ylab,'FontSize',22);
set(get(ax,'XLabel'),'String','Group','FontSize',22);

AddError(1,me,ee);
AddError(2,mc,ec);

[~,p,~,stat] = ttest2(egrp,cgrp,'alpha',.05,'tail','both');

% yval = (me+ee)*1.05;
% text(.6,yval,sprintf('\\itt\\rm(%d) = %.03f, \\itp\\rm = %.03f',stat.df,stat.tstat,p),'FontSize',16);

if p < .05
    mx = max([me+ee mc+ec]);
    line([1 2],[mx mx]*1.05,'Color',[0 0 0],'LineWidth',2);
    text(1.465,mx*1.1,'*','FontSize',52);
end

%-----------------------------------------------------------------------------%
function AddError(x,mn,er)
    he = line([x x],[mn-er mn+er],'Color',[0 0 0],'LineWidth',4);
    hc = line([x-.05 x+.05],[mn-er mn+er; mn-er mn+er],'Color',[0 0 0],'LineWidth',4);    
end
%-----------------------------------------------------------------------------%
end