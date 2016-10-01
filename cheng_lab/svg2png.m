function b = svg2png(ifile,varargin)

% svg2png
%
% Description: convert a svg file to a png using InkScape, obviously requires Inkscape
%
% Syntax: svg2png(ifile,<options>)
%
% In:
%       ifile - input svg file path
%   options:
%       dpi    - (300) dpi of output png file
%       output - (<auto>) output file path 
%
% Out:
%       b - a logical indicating success
%
% Updated: 2015-01-06
% Scottie Alexander
%
% Please report bugs to: scottiealexander11@gmail.com

opt = ParseOpts(varargin,...
    'dpi'    , 300 ,...
    'output' , ''   ...
    );

if isempty(opt.output)
    opt.output = Path(ifile).swap('ext','png');
else
    opt.output = Path(opt.output).swap('ext','png');
end

cmd = sprintf('inkscape -z -e %s -d %d %s',opt.output,opt.dpi,ifile);
[b,msg] = system(cmd);

if b
    fprintf(2,'[ERROR]: %s\n',msg);
end

b = ~b;