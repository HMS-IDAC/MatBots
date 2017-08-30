% Inputs :   
%                 img : input image
%               sigma : standard deviation of the Gaussian PSF
%
% Options (as 'specifier'-value pairs): 
%
%              'mode' : parameters to estimate. Default: 'xyAc'.
%             'alpha' : alpha value used in the statistical tests. Default: 0.05.
%                       (probability of selecting a local maxima when it's actually not one)
%              'mask' : mask of pixels (i.e., cell mask) to include in the detection. Default: all.
%       'FitMixtures' : true|{false}. Toggles mixture-model fitting.
%       'MaxMixtures' : maximum number of mixtures to fit. Default: 5.
%   'RemoveRedundant' : {true}|false. Discard localizations that coincide within 'RedundancyRadius'.
%  'RedundancyRadius' : Radius for filtering out redundant localizatios. Default: 0.25
%         'Prefilter' : {true}|false. Prefilter to calculate mask of significant pixels.
%     'RefineMaskLoG' : {true}|false. Apply threshold to LoG-filtered img to refine mask of significant pixels.
%   'RefineMaskValid' : {true}|false. Return only mask regions where a significant signal was localized.
%        'ConfRadius' : Confidence radius for positions, beyond which the fit is rejected. Default: 2*sigma
%        'WindowSize' : Window size for the fit. Default: 4*sigma, i.e., [-4*sigma ... 4*sigma]^2
%
% Outputs:  
%             ptSrcImg: Image with 1s on unsaturated spot locations and NaNs on saturated spots

% Based on:
% François Aguet, Costin N. Antonescu, Marcel Mettlen, Sandra L. Schmid, Gaudenz Danuser,
% Advances in Analysis of Low Signal-to-Noise Images Link Dynamin and AP2 to the Functions of an Endocytic Checkpoint,
% Developmental Cell, Volume 26, Issue 3, 12 August 2013, Pages 279-291, ISSN 1534-5807, http://dx.doi.org/10.1016/j.devcel.2013.06.019.
% (http://www.sciencedirect.com/science/article/pii/S1534580713003821)

function ptSrcImg  = advPointSourceDetection(img, sigma, displayProgressBar, varargin)

% Parse inputs
ip = inputParser;
ip.CaseSensitive = false;
ip.addRequired('img', @isnumeric);
ip.addRequired('sigma', @isscalar);
ip.addParameter('Mode', 'xyAc', @ischar);
ip.addParameter('Alpha', 0.05, @isscalar);
ip.addParameter('Mask', [], @(x) isnumeric(x) || islogical(x));
ip.addParameter('FitMixtures', false, @islogical);
ip.addParameter('MaxMixtures', 5, @isposint);
ip.addParameter('RemoveRedundant', true, @islogical);
ip.addParameter('RedundancyRadius', 0.25, @isscalar);
ip.addParameter('Prefilter', true, @islogical);
ip.addParameter('RefineMaskLoG', true, @islogical);
ip.addParameter('RefineMaskValid', true, @islogical);
ip.addParameter('ConfRadius', []); % Default: 2*sigma, see fitGaussians2D.
ip.addParameter('WindowSize', []); % Default: 4*sigma, see fitGaussians2D.
ip.KeepUnmatched = true;
ip.parse(img, sigma, varargin{:});
% mode = ip.Results.Mode;
alpha = ip.Results.Alpha;

if ~isa(img, 'double')
    img = double(img);
end

if displayProgressBar
    disp('1. gaussian kernel')
    wtBar = waitbar(0,'Detecting spots...');
end
% Gaussian kernel
w = ceil(4*sigma);
x = -w:w;
g = exp(-x.^2/(2*sigma^2));
u = ones(1,length(x));

if displayProgressBar
    disp('2. convolutions')
    waitbar(1/9,wtBar);
end
% convolutions
imgXT = padarrayXT(img, [w w], 'symmetric');
fg = conv2(g', g, imgXT, 'valid');
fu = conv2(u', u, imgXT, 'valid');
fu2 = conv2(u', u, imgXT.^2, 'valid');

if displayProgressBar
    disp('3. LoG')
    waitbar(2/9,wtBar);
end
% Laplacian of Gaussian
gx2 = g.*x.^2;
imgLoG = 2*fg/sigma^2 - (conv2(g, gx2, imgXT, 'valid')+conv2(gx2, g, imgXT, 'valid'))/sigma^4;
imgLoG = imgLoG / (2*pi*sigma^2);

if displayProgressBar
    disp('4. 2-D kernel')
    waitbar(3/9,wtBar);
end
% 2-D kernel
g = g'*g;
n = numel(g);
gsum = sum(g(:));
g2sum = sum(g(:).^2);

if displayProgressBar
    disp('5. solve linear system')
    waitbar(4/9,wtBar);
end
% solution to linear system
A_est = (fg - gsum*fu/n) / (g2sum - gsum^2/n); % amplitude
c_est = (fu - A_est*gsum)/n; % local background

if ip.Results.Prefilter
    if displayProgressBar
        disp('6. prefilter')
        waitbar(5/9,wtBar);
    end
    J = [g(:) ones(n,1)]; % g_dA g_dc
    C = inv(J'*J);
    
    f_c = fu2 - 2*c_est.*fu + n*c_est.^2; % f-c
    RSS = A_est.^2*g2sum - 2*A_est.*(fg - c_est*gsum) + f_c;
    RSS(RSS<0) = 0; % negative numbers may result from machine epsilon/roundoff precision
    sigma_e2 = RSS/(n-3);
    
    sigma_A = sqrt(sigma_e2*C(1,1));
    
    % standard deviation of residuals
    sigma_res = sqrt(RSS/(n-1));
    
    kLevel = norminv(1-alpha/2.0, 0, 1);
    
    SE_sigma_c = sigma_res/sqrt(2*(n-1)) * kLevel;
    df2 = (n-1) * (sigma_A.^2 + SE_sigma_c.^2).^2 ./ (sigma_A.^4 + SE_sigma_c.^4);
    scomb = sqrt((sigma_A.^2 + SE_sigma_c.^2)/n);
    T = (A_est - sigma_res*kLevel) ./ scomb;
    pval = tcdf(-T, df2);
    
    % mask of admissible positions for local maxima
    mask = pval < 0.05;
else
    mask = true(size(img));
end

if displayProgressBar
    disp('7. local max')
    waitbar(6/9,wtBar);
end

% all local max
allMax = locmax2d(imgLoG, 2*ceil(sigma)+1);

% local maxima above threshold in image domain
imgLM = allMax .* mask;

if sum(imgLM(:))~=0 % no local maxima found, likely a background image
    if displayProgressBar
        disp('8. refine mask log')
        waitbar(7/9,wtBar);
    end
    
    if ip.Results.RefineMaskLoG
        % -> set threshold in LoG domain
        logThreshold = min(imgLoG(imgLM~=0));
        logMask = imgLoG >= logThreshold;
        
        % combine masks
        mask = mask | logMask;
    end
    
    % re-select local maxima
    imgLM = allMax .* mask;
    
    % apply exclusion mask
    if ~isempty(ip.Results.Mask)
        imgLM(ip.Results.Mask==0) = 0;
    end
end

if displayProgressBar
    disp('9. saturation mask')
    waitbar(9/9,wtBar);
end

satMask = img == max(max(img));
satMask = imerode(satMask,strel('disk',1,0));
satMask = imdilate(satMask,strel('disk',ceil(3*sigma),0));

ptSrcImg = zeros(size(imgLM));
ptSrcImg(imgLM & not(satMask)) = 1;
ptSrcImg(imgLM & satMask) = NaN;

if displayProgressBar
    close(wtBar)
end

end