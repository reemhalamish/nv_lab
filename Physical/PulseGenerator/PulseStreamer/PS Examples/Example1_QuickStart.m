clear
fprintf('Example to show the main functionallity of the PulseStreamer\n\n');
% experiment settings 
% the durations/names are just examples
SHUTTER = 0;
LASER = 1;
CAMERA = 2;
FIXED_FREQUENCY = 7;

preopenTimeShutter = 1000; %ns
laserPulseDuration = 2000; %ns
delayBeforeCameraTrigger = 1000; % ns
cameraExposureTime = 3000; % ns
totalCycleDuration = 10 * 1000; % ns

fprintf('Connect to the Pulse Streamer\n\n');
% DHCP is activated in factory settings of the Pulse Streamer. The hostname
% of the Pulse Streamer is Pulse Streamer
ipAddress = '132.64.56.49';
% connect to the pulse streamer
ps = PulseStreamer(ipAddress);

fprintf('A typical sequence is generated on channel 0:2\n\n');
%%% successive programming of the output channels
% this sections shows how to program a sequence with pulses defined one
% after the next one
% The class P is the class to define pulses
sequenceExperiment = [];
sequenceExperiment = sequenceExperiment + P(preopenTimeShutter, SHUTTER);
sequenceExperiment = sequenceExperiment + P(laserPulseDuration, [LASER, SHUTTER]);
sequenceExperiment = sequenceExperiment + P(delayBeforeCameraTrigger, []);
sequenceExperiment = sequenceExperiment + P(cameraExposureTime, CAMERA);
durationWithoutPadding = P.duration(sequenceExperiment);
fprintf('Duration without padding:   %d ns\n', durationWithoutPadding);
sequenceExperiment = sequenceExperiment + P(totalCycleDuration - durationWithoutPadding, []);
durationWithPadding = P.duration(sequenceExperiment);
fprintf('Duration with padding:     %d ns\n', durationWithPadding);

fprintf('\nAn aligned but independent fixed frequency is applied on channel 7.\n\n');
%%% independent programming of the output channels
% Sometimes it is more conveniant to program the channels independently.
% For example, we want to have a fixed frequency applied on channel FIXED_FREQUENCY
period = 1000; % 100 kHz
sequenceFrequency = P(period / 2, FIXED_FREQUENCY) + P(period / 2, []);
% This sequence must be repeated for the whole cycle duration of the
% sequence defined above
sequenceFrequency = sequenceFrequency * (totalCycleDuration / period);
% now union these two independent sequences
sequence = P.union(sequenceExperiment, sequenceFrequency);
% Here the sequences have the very same length. If this is not the case
% shorter sequences are padded with the very last pulse programmed

runs = -1; %0 or -1 means that the sequence is repeated until the power is turned off
outputZero = OutputState(0,0,0);
% The sequence should start immediately after the upload (no hardware or software trigger)
start = PSStart.Immediate;

fprintf('Sent the generated sequences to the Pulse Streamer and start the output.\n\n');
% sent the data to the Pulse Streamer and start the sequence
ps.stream(sequence, runs, outputZero, outputZero, outputZero, start);
fprintf('Output is active.\n');
