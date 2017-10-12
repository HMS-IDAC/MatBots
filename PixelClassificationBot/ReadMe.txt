To run, execute 'pixelClassificationBot' from Matlab's prompt.
Click on one of the three options (label, train, classify), and follow the instructions.
They don't need to be called sequentially: you can, for example, label in one section,
continue labeling in another, train in yet another, and so on.

To close, close the window.

pixelClassificationBot contains all tools necessary to train a model
to classify the pixels on an image (a task also know as image segmentation).
There are, however, a few guidelines to follow, as described below.

--------------------------------------------------
LABEL
--------------------------------------------------

The images to be labeled should be in an independent folder.
They don't need to be square, but they do need to have the same dimensions
(that is, all the same width, and all the same height).

Data images of 3 channels (e.g. RGB images) are converted to grayscale by the algorithm.
This means the classifier does not use color information, just pixel intensity information.

Each image should have the same number of corresponding annotation images.
That is, if you label one image with 2 classes, than all other images should
be labeled with two classes as well.

Label masks for a particular image are saved in the same folder
with the addition of the term '_ClassX', where X is an integer (1,2,3,...).

For example, if there are three data images, I001.tif, I002.tif, and I003.tif,
and they are labeled with 2 classes (i.e. there are 2 classes of pixels per image),
then after annotation the folder will contain the following files:

I001.tif
I001_Class1.png
I001_Class2.png
I002.tif
I002_Class1.png
I002_Class2.png
I003.tif
I003_Class1.png
I003_Class2.png

You can re-label an image, in which case the corresponding label maps will be overwritten.

--------------------------------------------------
TRAIN
--------------------------------------------------

If you decide to save the trained model (there'll be a prompt after training), it
will be located in the same folder as the labeled images, as rfModel.mat.

The training process might take a long time (several minutes) if there are a lot
of training images, or if the training images are large.

--------------------------------------------------
CLASSIFY
--------------------------------------------------

The images to be classified should be in an independent folder.
They don't need to have the same dimensions, or be square.

The classifier will create label maps for each image, analogously to label maps
annotated manually. That is, for each image there'll appear corresponding
images with _Class in the name, for as many classes as there were for labeled images.

The classifier will ignore images with _Class in the name. This means you can
re-classify a folder, without having to delete the _Class images. They'll be
over-written. Notice, however, that _Class images are not deleted before classification.
This means that if you had 3 classes and decided to re-classify using only 2 classes,
the labels for the remaining class remain in the folder. Thus, if you decide to re-classify with
a different number of classes, it's recommended to delete the _Class images beforehand.

-----

Video tutorial: https://youtu.be/QS1ak-Xwu04
Sample data: https://www.dropbox.com/s/mg3rxhqznp1shs7/SmallNuclei.zip?dl=0