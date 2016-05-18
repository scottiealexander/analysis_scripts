function BarPlot2(data,field,ylab,varargin)

% BarPlot2
%
% Description:
%
% Syntax: BarPlot2
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
    'thresh' , 1 ...
    );

if isfield(data,'res_norm')
    b = [data(:).res_norm];
    b =  b > 0 & b < opt.thresh;
    if isfield(data,'peak')
        b = b & (abs([data(:).peak]) > 4);
    end
    fprintf('UNITS: %d / %d\n',sum(b),numel(data));
    data = data(b);
end

age = [data(:).age];
lab = unique(age);
for k = 1:numel(lab)    
    d{k} = [data(age==lab(k)).(field)];
end
mn = cellfun(@nanmean,d);
er = cellfun(@(x) nanstderr(x,[],2),d);

h = figure('NumberTitle','off','Name','BarPlot','MenuBar','figure',...
    'Position',[100 100 800 600],'Color',[1 1 1]);

ax = axes('Units','normalized','OuterPosition',[0 0 1 1],'Parent',h);

% hb = bar(ax,(1:4)',diag(mn'),'stacked');
hb = bar(ax,reshape(lab,[],1),diag(reshape(mn,[],1)),'stacked');

shading(ax,'Flat');

set(hb(1:2:end),'FaceColor',[1 0 0]);
set(hb(2:2:end),'FaceColor',[0 0 1]);
legend([hb(1),hb(2)],{'Rear','Control'});
set(legend,'Box','off','Location','NorthEast');
% set(hb(2),'FaceColor',[0 0 1]);

set(ax,'Box','off','LineWidth',4);

set(ax,'FontSize',18);
set(get(ax,'YLabel'),'String',ylab,'FontSize',22);
set(get(ax,'XLabel'),'String','Age (days)','FontSize',22);

for k = 1:numel(hb)
    AddError(lab(k),mn(k),er(k));
    str = sprintf('%d',sum(age==lab(k)));
    text(lab(k),(mn(k)+er(k))+.001,str,'HorizontalAlignment','center',...
        'VerticalAlignment','bottom','FontSize',18);
end

%-----------------------------------------------------------------------------%
function AddError(x,mn,er)
    he = line([x x],[mn-er mn+er],'Color',[0 0 0],'LineWidth',4);
    hc = line([x-.05 x+.05],[mn-er mn+er; mn-er mn+er],'Color',[0 0 0],'LineWidth',4);    
end
%-----------------------------------------------------------------------------%
end