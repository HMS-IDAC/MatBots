A bot to count point sources (spots) in nuclei.

Dependency: this bot requires Bioformats to read tiff stacks. Download it from
https://www.openmicroscopy.org/site/support/bio-formats5.3/users/matlab/index.html
and add it to Matlab's path.

To use this bot, execute 'spotsInNucleiBot' from Matlab's prompt, and follow the options/instructions.

Input format: image stacks, that is, images with multiple channels. One of the channels
is used to detect nuclei, and the others contain diffraction limited spots (point sources).

Output format: for each stack analized, a table containing counts of point sources per nuclei.

Two algorithms are available to detect nuclei (Simple Threshold, and Machine Learning),
and two to detect spots (LoG, and Advanced LoG).

The Machine Learning algorithm requires a model trained to segment nuclei.
To train such model, use the nucleiSegmentationBot (under NucleiSegmentationBot).

Acknowledgements:

fmgaussfit.m was developed by Nathan Orloff:
https://www.mathworks.com/matlabcentral/fileexchange/41938-fit-2d-gaussian-with-optimization-toolbox

advPointSourceDetection.m is based on code developed by Francois Aguet:
http://www.sciencedirect.com/science/article/pii/S1534580713003821

For a video tutorial, see https://www.youtube.com/watch?v=63Ybf4IPYXo