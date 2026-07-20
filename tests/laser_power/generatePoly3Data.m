function [controlValues, sensorValues] = generatePoly3Data(varargin)
    % Generate a synthetic "semi-linear" laser power curve for testing
    %
    % function [controlValues, sensorValues] = generatePoly3Data(varargin)
    %
    % Purpose
    % Produce a synthetic laser calibration curve that follows a third order polynomial.
    % This mimics a cheap laser with an approximately linear response that has some mild
    % nonlinear deviation. The returned vectors can be fed straight into
    % zapit.utils.fitLaserPowerCurve for testing without hardware. The random seed is
    % clamped so the output is reproducible.
    %
    % Inputs (optional param/val pairs)
    % coefs - [c3, c2, c1, c0] polynomial coefficients (as used by polyval): the sensor
    %         signal is c3*V^3 + c2*V^2 + c1*V + c0. Default [-0.1, 0.8, 2, 0], which is
    %         mostly linear with a gentle curve.
    % controlVoltRange - [min, max] control voltages to test over. Default [0, 5].
    % numPoints - number of points in the curve. Default 200.
    % noise - standard deviation of the additive Gaussian noise. Default 0.1.
    % seed - random seed used to make the noise reproducible. Default 42.
    %
    % Outputs
    % controlValues - column vector of control voltages.
    % sensorValues - column vector of simulated photodiode signals.
    %
    %
    % Rob Campbell - SWC 2026
    %
    % See also:
    % generateSigmoidData
    % zapit.utils.fitLaserPowerCurve

    params = inputParser;
    params.CaseSensitive = false;
    params.addParameter('coefs', [-0.1, 0.8, 2, 0], @(x) isnumeric(x) && numel(x)==4);
    params.addParameter('controlVoltRange', [0, 5], @(x) isnumeric(x) && numel(x)==2);
    params.addParameter('numPoints', 200, @(x) isnumeric(x) && isscalar(x));
    params.addParameter('noise', 0.25, @(x) isnumeric(x) && isscalar(x));
    params.addParameter('seed', 42, @(x) isnumeric(x) && isscalar(x));
    params.parse(varargin{:});

    coefs = params.Results.coefs;
    controlVoltRange = params.Results.controlVoltRange;
    numPoints = params.Results.numPoints;
    noise = params.Results.noise;
    seed = params.Results.seed;

    % Control voltages to test over
    controlValues = linspace(controlVoltRange(1), controlVoltRange(2), numPoints)';

    % The noiseless polynomial curve
    sensorValues = polyval(coefs, controlValues);

    % Add reproducible noise using a local stream so the global RNG is not disturbed
    stream = RandStream('mt19937ar', 'Seed', seed);
    sensorValues = sensorValues + noise * randn(stream, size(sensorValues));

end % generatePoly3Data
