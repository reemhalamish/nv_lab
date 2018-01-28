clear

% IP address of the pulse streamer
ipAddress = '132.64.56.49';

% connect to the pulse streamer
ps = PulseStreamer(ipAddress);


%duration of the pulses
frequency = 1e6; % Hz
disp(['Selected frequency: ' num2str(frequency)]);

duration = 1e9 / frequency;
durationHigh = round(duration / 2);
durationLow = round(duration - durationHigh);

if (durationHigh + durationLow ~= duration) 
    deviation = abs(durationHigh + durationLow - duration) / duration;
    warning(['The output frequency deviates by a factor of ' num2str(deviation) ' from the selected frequency.'])
    disp(['Output frequency: ' num2str(1e9 / (durationHigh + durationLow))]);
end

% We repeat the high/low sequence 8 times to be sure that the total duration 
% of the sequence is a multiple of 8 ns.
% Otherwise we would get a slight offset because the duration of a sequence
% is padded to a multiple of 8ns
sequence = [];
for i=1:8
    sequence = sequence + P(durationHigh, 0:7, 1, 1); % digital output channel 0:7 high
    sequence = sequence + P(durationLow, [], 0, 0);   % no digital output channels are high []
end

outputZero = OutputState(0,0,0);
runs = 0;
initialOutputState = outputZero;
finalOutputState = outputZero;
underflowOutputState = outputZero;
start = PSStart.Immediate;

% Sent the data to the Pulse Streamer.
ps.stream(sequence, runs, initialOutputState, finalOutputState, underflowOutputState, start);

% check for underflows
if ~ps.getUnderflows()
    disp('Test successful');
else
    error('A buffer underflow was detected during the test run!');
end