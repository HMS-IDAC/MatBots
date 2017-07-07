A bot to view a stack (an image with multiple planes) one plane at a time.

Includes lower and upper thresholds for quick simple image equalization.

To run, call stackViewBot(S), where S is a MxNxL stack of type double.

Not appropriate for stacks where L is too large, because planes are accessed via
a popup menu, not a slider.

Example:
stackViewBot(double(imread('ngc6543a.jpg'))/255);