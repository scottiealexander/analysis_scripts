function p = GetFigPosition(w,h,varargin)

% GetFigPosition
%
% Description: calculate a position vector in pixels given width and height of
%              the figure
%
% Syntax: p = GetFigPosition(width,height,<options>)
%
% In: 
%       width  - the width of the figure in pixels
%       height - the hight of the figure in pixels
%   options:
%       xoffset - (0) horizontal offset in pixels relative to the center of the
%                     screen (positive moves right, negative moves left)
%       yoffset - (0) vertical offset in pixels relative to the center of the
%                     screen (positive move up, negative moves down)
%
% Out: 
%       p - the position of the figure as a 1x4 position vector in the order:
%           [left,bottom,width,height]
%
% Updated: 2014-08-14
% Scottie Alexander
%
% Please report bugs to: scottiealexander11@gmail.com
persistent SCREEN_SIZE

opt = ParseOpts(varargin,...
    'xoffset' , 0 ,...
    'yoffset' , 0  ...
    );

%get the size of the screen in pixels
if isempty(SCREEN_SIZE)
    ROOT_UNITS = get(0,'Units');
    set(0,'Units','pixels');
    SCREEN_SIZE = get(0,'ScreenSize');
    set(0,'Units',ROOT_UNITS);
end

if w > SCREEN_SIZE(3) 
    w = SCREEN_SIZE(3);
elseif h > SCREEN_SIZE(4)
    h = SCREEN_SIZE(4);
end

%make the position vector
p = zeros(1,4);
p(1) = (SCREEN_SIZE(3)/2)-(w/2)+opt.xoffset; %left
p(2) = (SCREEN_SIZE(4)/2)-(h/2)+opt.yoffset; %bottom
p(3:4) = [w,h];                              %width and height

%move the figure left so that it stays onscreen
if p(1) + p(3) > SCREEN_SIZE(3)
    p(1) = p(1) - (p(1)+p(3)-SCREEN_SIZE(3));
end

if p(1) < 1
    p(1) = 1;
end

%move the figure down so that it stays onscreen
if p(2) + p(4) > SCREEN_SIZE(4)
    p(2) = p(2) - (p(2)+p(4)-SCREEN_SIZE(4));
end

if p(2) < 1
    p(2) = 1;
end