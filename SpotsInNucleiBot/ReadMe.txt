A bot to count point sources (spots) in nuclei.

Dependency: this bot requires Bioformats to read tiff stacks. Download it from
http://downloads.openmicroscopy.org/bio-formats/5.3.4/
and add it to Matlab's path.

To use this bot, execute 'spotsInNucleiBot' from Matlab's prompt, and follow the options/instructions.

Input format: image stacks, that is, images with multiple channels. One of the channels
is used to detect nuclei, and the others contain diffraction limited spots (point sources).

Output format: for each stack analized, a table containing counts of point sources per nuclei.

Two algorithms are available to detect nuclei (Simple Threshold, and Machine Learning),
and two to detect spots (LoG, and Advanced LoG).

The Machine Learning algorithm requires a model trained to segment nuclei.
To train such model, use the nucleiSegmentationBot (under NucleiSegmentationBot).

-----

On the parameters of the 'LoG' and 'Advanced LoG' spot detetion options:

'sigma' is the estimated sigma of a gaussian that fits the puncta;
an estimation can be done by drawing a box around a point source, as shown in 6:20-6:50 here:
https://www.youtube.com/watch?v=63Ybf4IPYXo

'alpha' in 'Advanced LoG' is roughly the probability of wrongly selecting a local maxima from the LoG-filtered image as a spot;
in low signal-to-noise ratio conditions you'd want to increase this since
you'd want to be more permissive with respect to the spots that are selected;
for high signal-to-noise ratio you can set alpha very small (say 0.000001)

If signal to noise-ration is high, the basic 'LoG' option should work well though.
In this case, sigma is as above, and 'threshold' is as follows:

After finding local maxima from the LoG-filtered image, compute the robust mean m and standard deviation s
of the distribution of local-maxima intensities for spots that fall in the background mask (i.e., outside the nuclei mask).
Selected puncta will be the ones for which the intensity is above m+ts, where t is your threshold.

-----

Note: of you used NucleiSegmentationBot to train a machine learning model to segment nuclei, make sure
to change your current folder to SpotsInNucleiBot before calling 'spotsInNucleiBot', otherwise
an error will occurr due to the fact these bots use functions with the same name but slightly different implementations.

-----

For a video tutorial, see https://www.youtube.com/watch?v=63Ybf4IPYXo

-----

Acknowledgements:

fmgaussfit.m was developed by Nathan Orloff:
https://www.mathworks.com/matlabcentral/fileexchange/41938-fit-2d-gaussian-with-optimization-toolbox

advPointSourceDetection.m is based on code developed by Francois Aguet:
http://www.sciencedirect.com/science/article/pii/S1534580713003821