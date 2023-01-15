# GUI System

The GUI uses a model/view/control paradigm:

* `zapit.pointer` is the model. It is the API that the user can deploy within their own code. Zapit's features can be run at the command line via the API. In principle it can be done without the GUI, but of course visualization is needed for certain things, like the calibration steps.
* `zapit.gui.main.view` is the view associated with the API. It is a class that builds the main GUI. The view is made using MATLAB's App Designer and is exported to an `.m` file. Please note: Do **not** manually edit the `view.m` file: it must be generated from the App Designer. The binary file that generates the view is not currently in the repo to avoid bloat. In future it will either be added on placed into its own repo. 
* `zapit.gui.main.controller` is the controller associated with the main GUI. It is a class that inherits `zapit.gui.main.view` and so builds the GUI when instantiated. However, the controller contains additional logic to actually run the GUI and interface with the model. For example, it defines the callback functions for the UI elements, it modifies settings for UI elements, etc. 

