function volumeWrite(V,volumePath)
    [~,~,volumeExtension] = fileparts(volumePath);
    if ~strcmp(volumeExtension,'.tif')
        error('can only write .tif volumes');
    end
    
    if exist(volumePath,'file') == 2
        delete(volumePath);
    end
    
    imwrite(V(:,:,1), volumePath, 'WriteMode', 'append', 'Compression','none');
    for i = 2:size(V,3)
        imwrite(V(:,:,i), volumePath, 'WriteMode', 'append', 'Compression','none');
    end
end