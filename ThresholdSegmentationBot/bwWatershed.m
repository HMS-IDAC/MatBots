function W = bwWatershed(BW,paramImhmin)

bg = not(BW);
D = -bwdist(bg);
D = D-min(D(:));
D = D/max(D(:));
D = imhmin(D,paramImhmin);
D(bg) = 0;
W = watershed(D) > 1;
W = filterByContact(W,bg);

end