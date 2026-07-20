function [controlValues, sensorValues] = generateSigmoidData(varargin)
    % Generate a synthetic sigmoidal laser power curve for testing
    %
    % function [controlValues, sensorValues] = generateSigmoidData(varargin)
    %
    % Purpose
    % Produce a synthetic laser calibration curve that follows a logistic sigmoid. This
    % mimics a laser with a saturating response, such as an EOM operated over a truncated
    % sigmoid. The returned vectors can be fed straight into zapit.utils.fitLaserPowerCurve
    % for testing without hardware. The random seed is clamped so the output is reproducible.
    %
    % Inputs (optional param/val pairs)
    % coefs - [a, b, c, d] sigmoid coefficients: the sensor signal is
    %         a + b ./ (1 + exp(-c*(V - d))). a is the lower asymptote, b the range, c the
    %         steepness, and d the midpoint. Default [0, 10, 1.8, 2.5].
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
    % generatePoly3Data
    % zapit.utils.fitLaserPowerCurve

    params = inputParser;
    params.CaseSensitive = false;
    params.addParameter('coefs', [0, 10, 1.8, 2.5], @(x) isnumeric(x) && numel(x)==4);
    params.addParameter('controlVoltRange', [0, 5], @(x) isnumeric(x) && numel(x)==2);
    params.addParameter('numPoints', 200, @(x) isnumeric(x) && isscalar(x));
    params.addParameter('noise', 0.1, @(x) isnumeric(x) && isscalar(x));
    params.addParameter('seed', 42, @(x) isnumeric(x) && isscalar(x));
    params.parse(varargin{:});

    coefs = params.Results.coefs;
    controlVoltRange = params.Results.controlVoltRange;
    numPoints = params.Results.numPoints;
    noise = params.Results.noise;
    seed = params.Results.seed;

    a = coefs(1);
    b = coefs(2);
    c = coefs(3);
    d = coefs(4);

    % Control voltages to test over
    controlValues = linspace(controlVoltRange(1), controlVoltRange(2), numPoints)';

    % The noiseless sigmoid curve
    sensorValues = a + b ./ (1 + exp(-c*(controlValues - d)));

    % Add reproducible noise using a local stream so the global RNG is not disturbed
    stream = RandStream('mt19937ar', 'Seed', seed);
    sensorValues = sensorValues + noise * randn(stream, size(sensorValues));

end % generateSigmoidData
