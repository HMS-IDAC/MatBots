function S = stackRead(stackPath)
    BFData = bfopen(stackPath);
    nPlanes = size(BFData{1},1);
    [nr,nc] = size(BFData{1}{1,1});
    S = zeros(nr,nc,nPlanes);
    for k = 1:nPlanes
        fprintf('.')
        SK = BFData{1}{k,1};
        if isa(SK,'uint8')
            SK = double(SK)/255;
        elseif isa(SK,'uint16')
            SK = double(SK)/65535;
        else
            error('unidentified stack class')
        end
        S(:,:,k) = SK;
    end
    fprintf('\n')
end