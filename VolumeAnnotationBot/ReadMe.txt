Analogous to ImageAnnotationBot for 3D volumes.

Usage: call 'volumeAnnotationBot' and follow the instructions.
This bot requires the bfmatlab toolbox to read stacks.
Download here: http://downloads.openmicroscopy.org/bio-formats/5.3.4/

Label masks are saved in the same folder as the volume.

If you already have a double, range [0,1] 3D volume loaded into Matlab,
call volumeAnnotationTool as in the example below.

load mri
V = double(squeeze(D))/255;
VAT = volumeAnnotationTool(V,2); % the second parameter is the number of labels

The label masks can then be accessed at VAT.LabelMasks