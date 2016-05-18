classdef TSPlot < handle

% TSPlot
%
% Description: a class for plotting time series data
%
% Syntax: ts = TSPlot(x,y,<options>)
%
% In:
%       x - a array or cell of arrays of x-data
%       y - a array or cell of arrays of y-data
%   options:
%       title   - ('')
%       xlabel  - ('')
%       ylabel  - ('')
%       type    - ('line')
%       zeros   - (true)
%       error   - ([])
%       legend  - ({})
%       color   - ({})
%       lstyle  - ('-')
%       mrk     - ('none')
%       mrksize - (20)
%       xmin    - ([])
%       xmax    - ([])
%       ymin    - ([])
%       ymax    - ([])
%       yflip   - (false)
%       w       - (800)
%       h       - (600)
%       parent  - ([])
%       axes    - ([])
%
% Out: 
%       ts - a TSPlot object
%
% Updated: 2015-02-22
% Scottie Alexander
%
% Please report bugs to: scottiealexander11@gmail.com

%PRIVATE PROPERTIES------------------------------------------------------------%
properties (SetAccess=private)
    opt;
    label = struct('title',[],'xlabel',[],'ylabel',[]);    
    data = struct('x',[],'y',[],'err',[]);
    color;
    hF;
    hA;
    hL = [];
    hP = [];
    hBox;
    hZero;
    hLeg;
end
%PRIVATE PROPERTIES------------------------------------------------------------%

%PUBLIC METHODS----------------------------------------------------------------%
methods
    %--------------------------------------------------------------------------%
    function ts = TSPlot(x,y,varargin)
    %ts = TSPlot
    %   constructor for TSPlot class
        ts.opt = ParseOpts(varargin,...
            'title'  , ''       ,...
            'xlabel' , ''       ,...
            'ylabel' , ''       ,...
            'type'   , 'line'   ,...
            'zeros'  , true     ,...
            'error'  , []       ,...
            'legend' , {}       ,...
            'color'  , {}       ,...
            'lstyle' , '-'      ,...
            'mrk'    , 'none'   ,...
            'mrksize', 20       ,...
            'xmin'   , []       ,...
            'xmax'   , []       ,...
            'ymin'   , []       ,...
            'ymax'   , []       ,...
            'yflip'  , false    ,...
            'w'      , 800      ,...
            'h'      , 600      ,...
            'parent' , []       ,...
            'axes'   , []        ...
            );        

        ts.data.x = ToCell(x);
        ts.data.y = ToCell(y);
        
        %fill x arrays to match number of y arrays
        if numel(ts.data.x) == 1 && numel(ts.data.y) > 1
            ts.data.x = repmat(ts.data.x,size(ts.data.y));
        end
        
        %allow row-wise matrix plotting: so y can be a NxM matrix where N is the
        %number of variable and M is the number of observation (so x MUST be a
        %1xM or Mx1 array / cell of arrays)
        if numel(ts.data.x) == 1 && numel(ts.data.y) == 1 && ~any(size(ts.data.y{1})==1)
            d = ts.data.y{1};
            ts.data.y = mat2cell(d,ones(size(d,1),1),size(d,2));
            ts.data.x = repmat(ts.data.x,size(ts.data.y));
        end
        
        if ~isempty(ts.opt.error)
            ts.data.err = ToCell(ts.opt.error);
        end
        
        pFig = GetFigPosition(ts.opt.w,ts.opt.h);
        
        if isempty(ts.opt.parent)
            ts.hF = figure('Units','pixels','OuterPosition',pFig,...
               'Name','TS-Plot','NumberTitle','off','MenuBar','none',...
               'Color',[1 1 1],'KeyPressFcn',@KeyPress);        
        elseif ishandle(ts.opt.parent) && strcmpi(get(ts.opt.parent,'type'),'figure')
            ts.hF = ts.opt.parent;
        else
            error('parent options MUST be a figure handle');
        end

        ts.AddAxes;
        ts.SetLimits;
        ts.AddContent;
        ts.AddLabels;
        drawnow;
    end
    %--------------------------------------------------------------------------%
    function display(varargin)
        fprintf('<TSPlot object>\n');
    end    
    %--------------------------------------------------------------------------%
    function Close(ts)
        if ishandle(ts.hF)
            close(ts.hF);
        end
    end
    %--------------------------------------------------------------------------%
    function AddAxes(ts)
        if isempty(ts.opt.axes)
            ts.hA = axes('Parent',ts.hF,'Units','normalized','OuterPosition',[0 0 1 1],...
                'Box','off','LineWidth',4);
        elseif ishandle(ts.opt.axes) && strcmpi(get(ts.opt.axes,'type'),'axes')
            ts.hA = ts.opt.axes;
            set(ts.hA,'Parent',ts.hF,'Units','normalized','Box','off','LineWidth',4);
        else
            error('axes options MUST be an axes handle');
        end
    end
    %--------------------------------------------------------------------------%
    function AddContent(ts)
        if isempty(ts.opt.color)
            col = GetColor(numel(ts.data.x));
        else
            if ischar(ts.opt.color) || iscell(ts.opt.color)
                col = GetColor(ts.opt.color);
            elseif isnumeric(ts.opt.color)
                col = ts.opt.color;
                if size(col,2) ~= 3
                    error('color given is not valid. colors should be a N x 3 matrix');
                end
                ncol = numel(ts.data.x) - size(col,1);
                if ncol > 0
                    col = [col; GetColor(ncol)];
                end
            end
        end
        
        ts.color = col;        
        switch lower(ts.opt.type)
        case 'line'
            for k = 1:numel(ts.data.x)
                tmp = line(ts.data.x{k},ts.data.y{k},...
                        'Color'     , col(k,:) ,...
                        'LineWidth' , 3        ,...
                        'LineStyle' , ts.opt.lstyle,...
                        'Marker'    , ts.opt.mrk,...
                        'MarkerSize', ts.opt.mrksize,...
                        'Parent'    , ts.hA     ...
                        );
                ts.hL = [ts.hL;tmp];
                hleg(1,k) = tmp(1);
            end
            if ~isempty(ts.opt.legend)
                ts.hLeg = legend(hleg,ts.opt.legend{:});
                set(ts.hLeg,'Box','off');
            end
            ts.AddError;
        case 'bar'
            for k = 1:numel(ts.data.x)            
                ts.hL(k,1) = bar(ts.data.x{k},ts.data.y{k},...
                                'FaceColor' , col(k,:) ,...
                                'BarWidth'  , .8       ,...
                                'Parent'    , ts.hA     ...
                                );
            end
            
            %bar auto sets box back on and resets out limits...
            set(ts.hA,'Box','off');
            ts.SetLimits;
        otherwise
            error('Plot type %s is not supported',ts.opt.type);
        end

        ts.AddZero;
    end
    %--------------------------------------------------------------------------%
    function AddZero(ts)
        if ts.opt.zeros
            ts.hZero(1,1) = line([0 0],get(ts.hA,'YLim'),'Color',[0 0 0],...
                'LineWidth',4,'LineStyle','--','Parent',ts.hA);
            ts.hZero(2,1) = line(get(ts.hA,'XLim'),[0 0],'Color',[.5 .5 .5],...
                'LineWidth',4,'LineStyle','--','Parent',ts.hA);
            ts.SendToBack(ts.hZero);
        end
    end
    %--------------------------------------------------------------------------%
    function AddError(ts)
        if ~isempty(ts.data.err)
            if numel(ts.data.err) ~= numel(ts.data.y)
                error('error is missing for one or more input datasets');
            end
            for k = 1:numel(ts.data.x)
                if ~isempty(ts.data.err{k})
                    xD = reshape(ts.data.x{k},[],1);
                    xD = [xD;xD(end:-1:1)];
                    yD = reshape(ts.data.y{k},[],1);
                    eD = reshape(ts.data.err{k},[],1);
                    err = [yD + eD; yD(end:-1:1) - eD(end:-1:1)];
                    [colErr,colEdge] = ts.GetErrCol(ts.color(k,:));                
                    ts.hP(end+1,1) = patch(xD,err,colErr,'EdgeAlpha',1,'EdgeColor',colEdge,'Parent',ts.hA);
                end
            end
            ts.SendToBack(ts.hP);
        end
    end
    %--------------------------------------------------------------------------%
    function AddLabels(ts)
        c = {'title','xlabel','ylabel'};
        for k = 1:numel(c)            
            htmp = get(ts.hA,c{k});
            set(htmp,'String',ts.opt.(c{k}),'FontSize',14);
        end
        ts.PositionLabels;

        if ts.opt.yflip
            yTL = arrayfun(@num2str,-get(ts.hA,'YTick'),'uni',false);
            set(ts.hA,'YTickLabel',yTL);
        end
    end
    %--------------------------------------------------------------------------%
    function PositionLabels(ts,varargin)
        
        if isempty(varargin)
            pad = .2;
        else
            pad = varargin{1};
        end
        pad =  pad * get(0,'ScreenPixelsPerInch');

        units = get(ts.hA,'Units');
        set(ts.hA,'Units','pixels');
        pax = get(ts.hA,'Position');
        set(ts.hA,'Units',units);

        xl = get(ts.hA,'XLim');
        yl = get(ts.hA,'YLim');
        
        xr = diff(xl);
        yr = diff(yl);
        
        %convert pad to data units
        pad = pad * [(xr/pax(3)), (yr/pax(4))];

        xh = get(ts.hA,'XLabel');
        set(xh,'HorizontalAlignment','center',...
            'VerticalAlignment','middle');
        xe = get(xh,'Extent');
        xlft = xl(1) + (xr/2);
        xbtm = yl(1) - xe(4) - pad(2);

        yh = get(ts.hA,'YLabel');        
        set(yh,'HorizontalAlignment','center',...
            'VerticalAlignment','middle');
        ye = get(yh,'Extent');
        ybtm = yl(1) + (yr/2);
        ylft = xl(1) - ye(3) - pad(1);

        yp = get(yh,'Position');
        xp = get(xh,'Position');

        set(yh,'Position',[ylft,ybtm,0]);
        set(xh,'Position',[xlft,xbtm,0]);

        th = get(ts.hA,'Title');
        set(th,'HorizontalAlignment','center');
        te = get(th,'Extent');
        tlft = xl(1) + (xr/2);
        tbtm = yl(2) + te(4);

        set(th,'Position',[tlft,tbtm,0]);

        set([xh,yh,th],'FontSize',14);
    end
    %--------------------------------------------------------------------------%
    function SetLimits(ts)
        if ts.opt.yflip
            ts.data.y = cellfun(@(x) -1*x,ts.data.y,'uni',false);
        end
        if isempty(ts.opt.xmin)
            xMin = min(cellfun(@(x) min(x(:)),ts.data.x));
        else
            xMin = ts.opt.xmin;
        end
        if isempty(ts.opt.xmax)
            xMax = max(cellfun(@(x) max(x(:)),ts.data.x));
        else
            xMax = ts.opt.xmax;
        end
        if isempty(ts.opt.ymin)
            if strcmpi(ts.opt.type,'bar')
                yMin = 0;
            elseif ~isempty(ts.data.err)
                yMin = nanmin(cellfun(@(a,b) nanmin(a-b),ts.data.y,ts.data.err));                   
            else
                yMin = nanmin(cellfun(@(x) nanmin(x(:)),ts.data.y));
            end
        else
            yMin = ts.opt.ymin;
        end
        if isempty(ts.opt.ymax)
            if ~isempty(ts.data.err)
                yMax = nanmax(cellfun(@(a,b) nanmax(a+b),ts.data.y,ts.data.err));                   
            else
                yMax = nanmax(cellfun(@(x) nanmax(x(:)),ts.data.y));
            end
        else
            yMax = ts.opt.ymax;
        end        

        if xMin == xMax
            xMin = xMin-.001;
            xMax = xMax+.001;
        end
        if yMin == yMax
            yMin = yMin-.001;
            yMax = yMax+.001;
        end

        %make room for the fact that bars are centered on their x-values
        %so we have to add half of the bar width plus the space b/t bars
        if strcmpi(ts.opt.type,'bar')
            nBar = min(cellfun(@(x) numel(x),ts.data.y));
            pad = (xMax - xMin) / nBar;
            pad = (pad/2) + .2*pad;
            xMin = xMin - pad;
            xMax = xMax + pad;
        end

        set(ts.hA,'XLim',[xMin,xMax],'YLim',[yMin,yMax]);
        
        xLine = [xMin xMin;
                 xMin xMax];
        yLine = [yMin yMin;
                 yMax yMin];

        ts.AddBox(xLine,yLine);
    end    
    %--------------------------------------------------------------------------%
    function AddBox(ts,xLine,yLine)
        ts.hBox = line(xLine,yLine,...
            'Color',[0 0 0],...
            'LineWidth',4,...
            'Clipping','off',...
            'Parent',ts.hA...
            );
    end
    %--------------------------------------------------------------------------%
    function ResetLimits(ts,varargin)
        s = ParseOpts(varargin,...
            'ylim',[],...
            'xlim',[] ...
            );
        if ts.opt.yflip
            xfm = -1;
        else
            xfm = 1;
        end
        if ~isempty(s.xlim)            
            set(ts.hA,'XLim',s.xlim);
        end
        if ~isempty(s.ylim)            
            set(ts.hA,'YLim',s.ylim*xfm);
        end        

        xlim = get(ts.hA,'XLim');
        ylim = get(ts.hA,'YLim');
        xLine = xlim([1 1; 1 2]);
        yLine = ylim([1 1; 2 1]);
        delete(ts.hBox);
        delete(ts.hZero);
        ts.AddBox(xLine,yLine);
        ts.AddZero;
        ts.AddLabels;
    end
    %--------------------------------------------------------------------------%
    function [colErr,colEdge] = GetErrCol(ts,col)
        fErr = 8;
        fEdge = .25;
        hsv = rgb2hsv(col);
        hsv(2) = hsv(2)/fErr;
        hsv(3) = 1 - abs(1-hsv(2))^fErr/fErr;        
        colErr = hsv2rgb(min(1,hsv));
        colEdge = (1-fEdge)*colErr + fEdge*col;
    end
    %--------------------------------------------------------------------------%
    function SendToBack(ts,h)
        hChild = reshape(get(ts.hA,'Children'),[],1);
        h = reshape(h,[],1);
        hChild(ismember(hChild,h)) = [];
        hChild = [hChild;h];
        set(ts.hA,'Children',hChild);
    end
    %--------------------------------------------------------------------------%
    function ToSvg(ts,filename)
        plot2svg(filename,ts.hF);
    end
    %--------------------------------------------------------------------------%
    function ToPng(ts,filename,varargin)
    %ts.ToPng(filename,'dpi',300)
        ftmp = fullfile(pwd,[num2str(randi(1e10,1,1)) '.svg']);
        ts.ToSvg(ftmp);
        b = svg2png(ftmp,'output',filename,varargin{:});
        delete(ftmp);
        if ~b
            error('Conversion to png failed');
        end
    end
    %--------------------------------------------------------------------------%
end
%PUBLIC METHODS----------------------------------------------------------------%
end