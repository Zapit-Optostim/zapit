# Zapit
[![View zapit on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://uk.mathworks.com/matlabcentral/fileexchange/122142-zapit)

Zapit is software that runs a scanning opto-stim system for head-fixed mouse behavior.

## How it works
A pair of scan mirrors deflect an incoming laser beam, which is focused onto the exposed skull with a lens.
This lens is also used to image the sample onto a camera in order to visualise where the beam is pointing.
Zapit registers the scanners to the camera, allowing the user to place the beam in any desired location by clicking there on a live image feed.
Zapit then registers stereotaxic coordinates into the camera space, allowing the user to point the beam to coordinates defined with respect to bregma. 
A graphical tool builds experiment coordinate files using a top-down view of the Allen Atlas.
There is a simple MATLAB API for integrating stimulation into existing behavioral code and a Python version of the API [is also provided](https://github.com/Zapit-Optostim/zapit-Python-Bridge).


## Install & Usage
See the [Installation & User Manual](https://zapit.gitbook.io/user-guide/).
Please see the [list of known obvious bugs and issues](https://github.com/Zapit-Optostim/zapit/issues?q=is%3Aissue+is%3Aopen+label%3A%22Known+obvious+issue%22).
There is a [Change Log](CHANGELOG.md) if you are concerned about applying updates.


## Requirements
* [Image Processing Toolbox](https://www.mathworks.com/help/images/index.html)
* [Image Acquisition Toolbox](https://www.mathworks.com/products/image-acquisition.html)
* [DAQmx](https://www.ni.com/en-gb/support/downloads/drivers/download.ni-daqmx.html) installed with .NET support (tested versions: 19.0 to 21.8).
* [Curve Fittting Toolbox](https://www.mathworks.com/help/curvefit/) (Desirable but perhaps not needed)
* [Instrument Control Toolbox](https://uk.mathworks.com/products/instrument.html) (Optional)
* Currently only Basler cameras are supported but in principle others can be incorporated. File an Issue if you need this. 

If any of the above Toolboxes are included in your licence but not installed, you may install them using the Add On Manager.

## Contributing
Code was written by Maja Skretowska and Rob Campbell at the Sainsbury Wellcome Centre (UCL) in 2021/2022.
Contributions and collaborations are welcome.
Please see the [CONTRIBUTING.md](CONTRIBUTING.md) file for more information.


## Related Projects
* [laserGalvoControl](https://github.com/BrainCOGS/laserGalvoControl)


## Inspiration
This project was inspired by studies from [Svoboda](https://www.cell.com/neuron/fulltext/S0896-6273(13)00924-0) and [Tank and Brody](https://elifesciences.org/articles/70263). 

