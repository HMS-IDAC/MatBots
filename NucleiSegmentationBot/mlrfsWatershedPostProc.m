function M = mlrfsWatershedPostProc(FGProbMap,BGMask,thrImhmin)

Surf = 1-FGProbMap;
Surf = imhmin(Surf,thrImhmin);
Surf(BGMask) = -Inf;
Surf(:,1) = -Inf; Surf(:,end) = -Inf; Surf(1,:) = -Inf; Surf(end,:) = -Inf;
M = watershed(Surf) > 1;
M = filterByContact(M,BGMask);

end