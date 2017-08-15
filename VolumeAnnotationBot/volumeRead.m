function V = volumeRead(volumePath)
    BFData = bfopen(volumePath);
    nPlanes = size(BFData{1},1);
    [nr,nc] = size(BFData{1}{1,1});
    V = zeros(nr,nc,nPlanes);
    for k = 1:nPlanes
        fprintf('.')
        VK = BFData{1}{k,1};
        if isa(VK,'uint8')
            VK = double(VK)/255;
        elseif isa(VK,'uint16')
            VK = double(VK)/65535;
        else
            error('unidentified stack class')
        end
        V(:,:,k) = VK;
    end
    fprintf('\n')
end