------------------
imageAnnotationBot
------------------

A bot to annotate images for machine learning training.

Usage: call 'imageAnnotationBot' (without quotes) from Matlab's prompt.

-------------------
imageAnnotationTool
-------------------

A standalone tool to annotate a grayscale, double image. Example:

I = imread('rice.png');
I = double(I)/255;
IAT = imageAnnotationTool(I,2); % the second parameter is the number of labels
% annotate, then click 'Done'
subplot(1,2,1), imshow(IAT.LabelMasks(:,:,1)), title('label 1')
subplot(1,2,2), imshow(IAT.LabelMasks(:,:,2)), title('label 2')