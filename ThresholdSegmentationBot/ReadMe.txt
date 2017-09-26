A bot to segment foreground from background using a basic three-step algorithm:
> blurring
> thresholding
> watershed to split touching objects

Usage: call 'thresholdSegmentationBot' and follow the instructions.

If you have image data already loaded as a double, grayscale, range [0,1] image I,
use thresholdSegmentationTool as in the example below:

I = imread('rice.png');
I = double(I)/255;
I = imtophat(I,strel('disk',12,0')); % background subtraction
TST = thresholdSegmentationTool(I);
% use tool, then click 'Done Setting Parameters'

The final segmentation mask can then be accessed at TST.FinalMask,
and the segmentation model at TST.ThrModel.

The threshold models can be passed to
thresholdSegmentationHeadlessBot for batch processing.

call siameseThresholdSegmentationBot for a version that admits two images side by side.
This can be used to test the same set of parameters in two images simultaneously.
siameseThresholdSegmentationHeadlessBot is the corresponding function for batch processing.