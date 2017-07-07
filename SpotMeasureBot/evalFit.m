function evalFit(x,y,z,zfit,fitresult)

scsz = get(0,'ScreenSize'); % scsz = [left botton width height]
figure('Position',[scsz(3)/4 scsz(4)/4 scsz(3)/2 scsz(4)/2],'NumberTitle','off','Name','Gauss Fit')

zmin = min(min(z(:)),min(zfit(:)));
zmax = max(max(z(:)),max(zfit(:)));

ax1 = subplot(1,2,1);
surf(x,y,z), title('spot')
axis([min(x(:)) max(x(:)) min(y(:)) max(y(:)) zmin zmax])

ax2 = subplot(1,2,2);
surf(x,y,zfit), title(sprintf('gauss fit | estimated sigma: %.02f', 0.5*(fitresult(3)+fitresult(4))))
axis([min(x(:)) max(x(:)) min(y(:)) max(y(:)) zmin zmax])

Link = linkprop([ax1, ax2], ...
       {'CameraUpVector', 'CameraPosition', 'CameraTarget'});
setappdata(gcf, 'StoreTheLink', Link);

rotate3d on

end