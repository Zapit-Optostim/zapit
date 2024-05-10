function r=getFWHM(hZP)


% TODO -- this code is duplicated from some in getLaserPosAccuracy.
% This is currently a throwaway function


im = hZP.returnCurrentFrame;

mpix = hZP.settings.camera.micronsPerPixel;

bw = im > max(im(:))*0.9;

c = regionprops(bw,'Centroid');
c = c.Centroid;

% Cut it along rows and columns
r = im(:,round(c(1)));
c = im(round(c(2)),:);


zapit.utils.focusNamedFig(mfilename);
clf

subplot(2,1,1)
x = 1:length(r);
r = r-min(r);
[~,ind]=max(r);
x = x-x(ind);
x = x*mpix;
plot(x,r)

%tFit = fitG(x,r);plot(x,tFit,'--')
xlim([-500,500])

subplot(2,1,2)
x = 1:length(c);
[~,ind]=max(c);
x = x-x(ind);
x = x*mpix;

plot(x,c)
xlim([-500,500])



function c = fitG(x,y)

    y = double(y);

    y = y(:);
    x = x(:);

    norm_fun = @(mu, sd, x) 1/(sqrt(2*pi)*sd)*exp(-(x-mu).^2/(2*sd^2));
    [sol, f] = lsqcurvefit(@(p, x) norm_fun(p(1), p(2), x), rand(1,2), x, y);

    mu = sol(1);
    sd = sol(2);
    c = norm_fun(mu, sd, x);
