# Change Log
Code was initially written by Maja Skretowska and Rob Campbell at the Sainsbury Wellcome Centre (UCL) in 2021/2022.
Early work was not version controlled.
Proof of principle was done by RC and this was developed into a functioning piece of code capable of running experiments by MS.
This in turn was converted into a polished project with a GUI by RC.

### Versioning Approach
The project largely adheres to [semantic versioning](http://semver.org) guidelines, meaning it has a version number denoted as `MAJOR.MINOR.PATCH`

* The MAJOR version is incremented when there are incompatible API changes, or changes in functionality which might carry important caveats. You should review the nature of a MAJOR version change before upgrading a production system. An example of a MAJOR change might be that the API commands running the experiments change. 
* The MINOR version is incremented when functionality is added in a backwards compatible manner. This might mean significant new features that do not break existing functionality, or it might mean existing features are significantly improved. For example, addition of a rat atlas, or improvements in the way stimulus conditions are overlaid in the main GUI. 
* The PATCH version is incremented when there are backwards compatible bug fixes. It will also be incremented by the addition of new example code snippets, addition of tests, or by code changes which result in no functionality change. 

### NOTE ON CONVENTIONS IN THIS FILE
The function zapit.updater.getVersionFromChangeLog extracts the software version number
from this file. For this to work the version must be written out in this format:
YEAR/MONTH/DAY -- vMAJOR.MINOR.PATCH
For example, the following are valid


### Upgrade Notifications
The Zapit main window will print a notification in the title bar when a new version is available.
NOTE: the version number of the software is taken from the last version number in the version history in this file!

## Version History


2023/10/31 v1.0.1
  * Minor: improve message at CLI if beam power is clipped.  


2023/10/31 v1.0.0
  * BREAKING: The laser power defined in the settings file is now time-averaged power! 
    So asking for 4 mW and one point will set the laser to 8 mW of power since the duty 
    cycle is 50%. Previously the laser would be at 4 mW at time-averaged power would be 
    2 mW. This did not make much sense. 
  * MAJOR: Significantly changes to code that generates stimuli to allow for >2 points 
    per trial. This is a new feature and should be treated carefully. In particular, you
    should verify that the system can generate sufficient power to handle your chosen
    number of points. 
  * Remove stimulus pulse duration attribute of stimulus config yaml file. User can no 
    longer specify pulses shorter than the duty cycle. Allowing this would make things
    tricky given that we now allow >2 points per trial. 


2023/08/23 -- v0.13.1
  * BUGFIX: Zap all coords works with fewer than three locations.
  * BUGFIX: Gracefully handle lack of Instrument Control Toolbox. 
  * Overlaid stim points are created as soon as a new stim config is loaded. They are
    disabled automatically when a new sample calib is initiated and refreshed after the
    calib is complete. 


2023/08/23 -- v0.13.0
  * MAJOR: Add ability to set a fixed stimulus duration with `sendSamples`. 
  * MAJOR: Add a stimulus delay parameter to `sendSamples` for use with stimulus duration.
  * MAJOR: Make it possible to set laser power at the CLI with a sendSamples param/val pair. 
  * Update TCPserver to handle the stimulus duration, stimulus delay, and laser power arguments.
  * Remove tests associated with the TCP/IP comms as Zapit on its own can no longer run these. 
  * When choosing random stimuli, sendSamples will not choose the same stimulus twice. 
  NOTE: The changes in this version breaks compatibility with the Vidrio DAQmx wrapper. 
       We will only maintain the .NET wrapper in future will work now. This will make no
       difference to end users.
  * TEST FEATURE: "ephysWaveform" Attribute to stimConfig makes a smoothed waveform to help with ephys.
      This waveform is *UNTESTED* as of now and may not get rid of photoelectric transient.


2023/08/17 -- v0.12.1
  * Add an "external trigger" example showing how to use the .NET NI DAQmx wrapper to generate a TTL pulse from a DAQ.
  * BUGFIX: Fix TCP/IP server code. Was parsing a cell array as a vector.
  * BUGFIX: pointer.sendSamples not switching correctly between triggered and untriggered modes.


2023/08/10 -- v0.12.0
  * Get version information from CHANGELOG.md not hardcoded numbers in zapit.version
  * Move TCP/IP client out of Zapit and to standalone repo.
  * Update TCP/IP server to handle the new protocols.
  * IMPROVEMENT: Scanners are marked as calibrated when starting in simulated mode.
  * IMPROVEMENT: Added hZP.applyUnityStereotaxicCalib so user doesn't have to remember hZP.refPointsSample = hZP.refPointsStereotaxic;
  * BUGFIX: stopOptoStim can not be run if no stim config loaded.
  * zapit.pointer.sendSamples returns -1 if it failed to run.
  * zapit.interfaces.getIPaddress is new function to return IP address of Zapit Windows PC.
  * zapit.interfaces.tcpServer.isClientConnected reports if a client is connected.

2023/05/26 -- v0.11.1
  * BUGFIX: Stop hanging on start if install does not contain a .git directory


2023/05/26 -- v0.11.0
 * MAJOR: Add a command line stim config editor for generating patterns of points like grids, squares,
   and lines.
 * MAJOR: Add a simple TCP/IP server for external control. Zapit has a new property: state, that reports
     whether it is idle, stimulating, or ramping down.
 * MAJOR: Shortening the stimulus duration correctly increases beam intensity.
 * MAJOR: Add `experiment.blankOnsetShift_ms` and `experiment.blankOffsetShift_ms` to allow precise
   control of when the beam is blanking to take into account scanner motion.
 * Revert stimDutyCycleHz name change.
 * BUGFIX: Ensure ROI is flipped when it is made.
 * BUGFIX: Calibration points follow ROI.
 * BUGFIX: add new tests and bugfixes to tests
 * BUGFIX: stimulus generator was producing files that do not work. 
 * Various behind the scenes improvements to how settings are handled. 
 * IMPROVEMENT: Cat & mouse runs much faster
 * IMPROVEMENT: Report positioning errors to figure title in Point Mode


2023/02/14 -- v0.10.6
 * Small bugfixes
 * Paint brain area runs more quietly and blanks the beam between areas.
 * Zap all points runs more quietly and blanks the beam between points
 * Listeners are now in a structure instead of a cell array, so it's easy to disable specific ones by name.
 * Beam blanking time (time taken to move between positions) is now a setting.
 * Overhaul how the user settings are processed: code is far more streamlined. There are now associated tests.
 * Rename defaultLaserFrequencyHz to defaultDutyCycleHz in default user settings. Renaming of settings now can be done automatically.
 * Rename stimFreqInHz to stimDutyCycleHz in the user stimulus settings file.


2023/02/03 -- v0.10.4
 * BUGFIX: Support report could not be generated from the menu and the command itself failed.
 * More data are saved with the waveforms and this is used in the minimal example code.
 * Add a menu option for the user-guide.
 * Checks for updates at 4am every day.
 * Improve quality of scanner calibration beam detection.


2023/02/02 -- v0.10.3
 * Bugfix: under some condition laser remained on after trial ended.
 * Add custom icon to window.
 * With no laser calibration file we employ a linear fit and ditch the error message.
   In practice the fit is pretty good after tweaking.
 * Remove Tools menu.
 * Fix AI code in dotNETwrapper.


2023/02/01 -- v0.10.2
 * Remove AOrange from settings
 * Bugfix: missing setting from camera


2023/02/01 -- v0.10.0
 * Wipe scanner calib if user applies a ROI or resets image zoom.
 * Do not disable plotStimCoords when sample calib not done
 * Fix bug in camera class that sometimes blocked startup of Zapit.
 * Refactor some of the DAQ routines.
 * Switch to .NET for NI DAQmx.
 * Get the fourth channel working for the masking light.
 * Recently loaded files now saved in settings file not a separate .mat file.
 * Make stim config YML format more flexible with extra field names and allow stim-specific settings
   for the rep rate, laser power, rampdown. Confirm that we can have different powers and
   different ranpdowns on different trials. Have not tried different rep rates.


### Beta Versions

2023/01/29 -- v0.9.0-beta
 * Galvo waveforms are shaped to make them quieter: they are no almost inaudible even with the the galvo enclosure open.
 * Reset ROI disabled if field is full. Last ROI is re-applied on startup.
 * Laser rampdown time appears as a spinner in the stim config editor.
 * Update GUI with more buttons and tool-tips. Tidied it.
 * Validated that Zapit can correctly set laser power in mW. Tweaks so this works a little better. More work needed for calibration to be optimized and easy.
 * Button states are now linked via a listener.
 * Laser power calibration spinner removed. We use just the slider.
 * Add a current exposure setting for the camera.
 * Paint brain area onto brain.
 * Write trial log file if user has defined an experiment directory.
 * Standalone start of the stim config editor with zapit.stimConfigEditor
 * Add button that plots the currently loaded stim config so the user knows which stim index is where.

2023/01/19 -- v0.8.0-beta
 * Settings file updates with calibrate sample spinboxes
 * Switch to 1E5 samples/s and one cycle buffered. In stress test this went 1000 trials without a hitch.
 * Add settings and verify.
 * Bugfixes, including GUI locking up when stim config saved or loaded by the new tool.
 * Minimal DAQ examples with .NET and Vidrio.


### Alpha Versions


2023/01/19 -- v0.8.0-beta
 * Settings file updates with calibrate sample spinboxes
 * Switch to 1E5 samples/s and one cycle buffered. In stress test this went 1000 trials without a hitch.
 * Add settings and verify.
 * Bugfixes, including GUI locking up when stim config saved or loaded by the new tool.
 * Minimal DAQ examples with .NET and Vidrio.


2023/01/16 -- v0.7.0-alpha
 * Substantial refactoring and renaming.
 * New format for stim config files.
 * UI elements that do not work in simulated mode are disabled.
 * A lot of documentation changes.
 * Functions to monitor for new version (partially working)
 * Update README


2023/01/12 -- v0.6.0-alpha
 * Move relevant methods into zapit.stimConfig
 * zapit.stimConfig.makeChanSamples is now turned into a getter of chanSamples
 * Recent files updates when files are missing. The list is cached and re-appears on reload.
 * Move Vidrio wrapper into the project (thanks to Vidrio for granting permission).
 * Make a GUI to build stim config files. This is the last version that will use the existing stim config format!


2023/01/12 -- v0.5.1-alpha
 * Add the atlas_data.mat file to the code directory.


2023/01/12 -- v0.5.0-alpha
 * Convert the working units of everything from pixels to mm.
 * Sample calibration achieved by placing and scaling/rotating a brain outline.
 * Add ability to draw brain outline on sample with the beam.
 * stimConfig loading and recents menu works.
 * Add ability to do test presentations of the stimuli via the GUI.
 * Create an example showing how to use the API to present stimuli for fixed time periods.
 * Various bugfixes.


2023/01/05 -- v0.4.0-alpha
 * All UI elements in scanner calibration tab working as expected.
 * Improvements to startup and GUI.
 * Bugfixes.
 * Simulated mode partially working
 * Fix trivial bug that was causing scanner calibration transform to behave erratically. 
 * Begin work on sample calibration, including several demo files in the development directory. 


2022/12/21 -- v0.3.0-alpha
 * Have a working model/view/controller system. 
 * Basic GUI working.
 * Refactored everything up to the scanner calibration stage to the MVC system and GUI. 
 * The program can now be started by running `start_zapit`.


2022/12/19 -- v0.2.0-alpha
 * Add a system (partially working) for converting the control signal voltage to mW.
 * Code all now uses mW instead of a voltage value when setting laser power.


2022/12/19 -- v0.1.3-alpha
 * Major refactoring
 * The stopOptoStim method implements a rampdown
 * Fix bugs that were causing waveforms to not be what were expected
 * Laser is disabled for a fixed number of ms when location switching. Before it was 1 sample.


2022/12/15 -- v0.1.2-alpha
Minor bug fixes


2022/12/15 -- v0.1.1-alpha
Software is now refactored and likely working as intended bar the laser power. The laser
power was originally being set via an Arduino and there was no facility to specify a power
in mW. We next need to add the ability to set power in mW. The Arduino was being use to
implement a ramp-down following stim offset. We will now implement this via the NI DAQ.
Development now switches to the Dev branch.



