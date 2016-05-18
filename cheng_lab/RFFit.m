function [kf,ifo,hf] = RFFit(kernel)

% RFFit
%
% Description:
%
% Syntax: [kf,ifo,hf] = RFFit(kernel,dot,pixel,fpt)
%
% In:
%       kernel - STA kernel 
%       dot    - dot size
%       pixel  - pixel size
%       fpt    - frames per term
%
% Out:
%
% Updated: 2015-03-11
% Scottie Alexander
%
% Please report bugs to: scottiealexander11@gmail.com

%get pixel with max and min dev from each frame
tmp = kernel - mean(kernel(:));
fmx = reshape(max(reshape(tmp,[],1,16),[],1),[],1);
fmn = reshape(min(reshape(tmp,[],1,16),[],1),[],1);

%extract max and min frame
[~,kmx] = max(fmx);
[~,kmn] = min(fmn);

%use the first max/min response
kuse = min([kmx kmn]);
frame = kernel(:,:,kuse);

%x,y location grid
[x,y] = meshgrid(1:size(kernel,1),1:size(kernel,2));
xdat = cat(3,x,y);

mn = mean(frame(:));

%row,column index location of the peak / max
[~,kmx] = max(abs(frame(:)-mn));
[r0,c0] = ind2sub(size(frame),kmx);
amp = frame(r0,c0) - mn;

%initial parameters for fit
p0 = [amp r0 c0 0 1 1 mn];
os = optimset('Display','off');
[prm,resn,~,flag] = lsqcurvefit(@Gaus2D,p0,xdat,frame,[],[],os);

kf = Gaus2D(prm,xdat);

hf = spk.sta.Plot(kf);
DrawEllipse(prm(4),prm(5),prm(6),prm(2),prm(3));

peak = (frame(r0,c0) - mean(kernel(:))) / std(kernel(:));
ifo = struct('ori',prm(4),'sigma_x',prm(5),'sigma_y',prm(6),...
    'peak',peak,'peak_frame',kuse,'res_norm',resn,'fit_flag',flag);

%-----------------------------------------------------------------------------%
function DrawEllipse(ori,sigx,sigy,cx,cy)
    t = 0:0.001:2*pi;
    ct = cos(t)*sigx;
    st = sin(t)*sigy;
    co = cos(-ori);
    so  = sin(-ori);
    x = cy + ct*co - st*so;
    y = cx + ct*so + st*co;
    
    ha = findobj(get(hf,'Children'),'Type','axes');
    line(x,y,'LineWidth',4,'Color',[1 1 0],'Parent',ha(1));
end
%-----------------------------------------------------------------------------%
function yo = Gaus2D(p,x)
%p(1): amplitude
%p(2): row location of peak
%p(3): column location of peak
%p(4): orientation (rad)
%p(5): sigmaX
%p(6): sigmaY
%p(7): baseline
    ct = cos(p(4));
    st = sin(p(4));
    y = x(:,:,2)-p(2);
    x = x(:,:,1)-p(3);    
    t_x = ((x*ct - y*st)/p(5)).^2;
    t_y = ((y*ct + x*st)/p(6)).^2;
    yo = p(1) * exp(-.5*(t_x + t_y)) + p(7);
end
%-----------------------------------------------------------------------------%
end