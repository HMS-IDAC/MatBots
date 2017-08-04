A bot to measure the size of spot-like (including diffraction-limited) objects.

Call 'spotMeasureBot' without arguments to select an image with spots.

Call 'spotMeasureBot(pathToImage)' to start bot with image in pathToImage.

Once the image is loaded, draw rectangle around spot.
A 2D gaussian will be fit to the spot, and the approximate standard deviation
(average of the standard deviations corresponding to the principal components)
will be output, along with plots of the spot and fitted gaussian.

The Threshold window contains two sliders to control upper and lower
threshold in the image, which can help visualizing spots if the pixel intensity
is not well equalized.