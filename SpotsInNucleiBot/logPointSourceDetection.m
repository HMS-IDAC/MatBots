function imgLoG  = logPointSourceDetection(img, mask, sigma, alpha)

% possible alternative: /home/mc457/matlab/Danuser/common/detectionAlgorithms/detectSpotsWT.m

if ~isa(img, 'double')
    img = double(img);
end

% Gaussian kernel
w = ceil(4*sigma);
x = -w:w;
g = exp(-x.^2/(2*sigma^2));

% convolutions
imgXT = padarrayXT(img, [w w], 'symmetric');
fg = conv2(g', g, imgXT, 'valid');

% Laplacian of Gaussian
gx2 = g.*x.^2;
imgLoG = 2*fg/sigma^2 - (conv2(g, gx2, imgXT, 'valid')+conv2(gx2, g, imgXT, 'valid'))/sigma^4;
imgLoG = imgLoG / (2*pi*sigma^2);

% select by robust statistics
PSMags = imregionalmax(imgLoG).*imgLoG;

BgMask = not(mask);

PSMagsB = PSMags.*BgMask;
psmagsB = PSMagsB(PSMagsB > 0);
psmagsB = psmagsB(:);

rmB = median(psmagsB); % robust mean
rsB = mad(psmagsB,1);
sigma = 1.4826*rsB; % robust std

imgLoG = PSMags.*(PSMags > rmB+alpha*sigma);

end