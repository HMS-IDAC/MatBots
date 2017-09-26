To run, execute 'nucleiSegmentationBot' from Matlab's prompt.
After setting the resize factor, click on one of the four options
(label, train, setup post-processing, segment), and follow the instructions.
They don't need to be called sequentially: you can, for example, label in one section,
continue labeling in another, train in yet another, and so on.

To close, close the window.

nucleiSegmentationBot contains all tools necessary to train a model
to segment nuclei. There are, however, a few guidelines to follow, as described below.

Note: if you're using this bot to train a model for spotsInNucleiBot,
you only need to perform the steps Label and Train.

--------------------------------------------------
LABEL
--------------------------------------------------

The images to be labeled should be in an independent folder.
They don't need to be square, but they do need to have the same dimensions
(that is, all the same width, and all the same height).

Data images of 3 channels (e.g. RGB images) are converted to grayscale by the algorithm.
This means the segmenter does not use color information, just pixel intensity information.

Label masks for a particular image are saved in the same folder
with the addition of the term '_ClassX', where X is an integer (1 for background,
2 for contour, 3 for nuclei).

For example, if there are two data images, I001.tif and I002.tif, in folder Examples,
after proper annotation the folder will contain the following files:

I001.tif
I001_Class1.png
I001_Class2.png
I001_Class3.png
I002.tif
I002_Class1.png
I002_Class2.png
I002_Class3.png

You can re-label an image, in which case the corresponding label maps will be overwritten.

--------------------------------------------------
TRAIN
--------------------------------------------------

If you decide to save the trained model (there'll be a prompt after training), it
will be located in the same folder as the labeled images, as rfModel.mat.

The training process might take a long time (several minutes) if there are a lot
of training images, or if the training images are large.

--------------------------------------------------
SETUP POST-PROCESSING
--------------------------------------------------

After training the pixel classification model, these steps
help split touching nuclei (via watershed segmentation),
filter out objects based on area and eccentricity, and
change size via morphological thickening or erosion.

--------------------------------------------------
SEGMENT
--------------------------------------------------

The images to be segmented should be in an independent folder.
They don't need to have the same dimensions, or be square.

The segmenter will create a nuclei map for each image, with _Nuclei
added to the name.

The segmenter will ignore images with _Nuclei in the name. This means you can
re-classify a folder, without having to delete the _Nuclei images. They'll be
over-written.


-----
Video Tutorial: https://www.youtube.com/watch?v=pMjHfrK13RU