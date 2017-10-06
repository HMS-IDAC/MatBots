# MatBots

MatBots are primitive AIs, 'assistants' if you will,
that use minimalistic GUI dialogs to guide the user through a
data processing pipeline in Matlab.
 
Isn't that an 'app'?
Bots are much more restrictive than apps.
Users are, to a greater extent than in an app,
guided through the correct steps to perform a task.
A bot usually performs a much more limited task than an app.

When possible, bots have a 'headless' mode,
which allows them to execute a processing pipeline as a typical
Matlab function, either on an image or a folder of images.

Each directory (except 'docs' and 'Tools') contains a bot for the task
suggested by the directory's name. For more details, see ReadMe.txt inside.

The directory 'Tools' contains stand-alone tools that may be used by different
bots (though each bot's folder is self-contained).

Note: different bots sometimes use functions with the same name but slightly
different implementations. For that reason, to avoid errors use the bot from inside
that bot's directory. For example, call nucleiSegmentationBot from the folder
NucleiSegmentationBot, spotsInNucleiBot from SpotsInNucleiBot, and so on.
Also, do not add a bot's folder to the Matlab path, because that might make
functions of the current folder lose higher priority status.

For references and video tutorials, see https://hms-idac.github.io/MatBots/
