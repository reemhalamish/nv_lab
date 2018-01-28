clear
% IP address of the pulse streamer (default hostname is PulseStreamer)
ipAddress = '132.64.56.49';

% connect to the pulse streamer
ps = PulseStreamer('132.64.56.49');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This matlab file shows various aspects of the API for the Pulse Streamer
% In comparison to the Quickstart example the class PH is used instead of P
% to define pulses. PH requires a bitmask for the output channels instead
% of an array of the channels used in P. 
%
% choose the active example here

exampleNo = 1;

% 1: all zero
% 2: all max
% 3: jumping between zero and max
% 4: callback function after 3 runs
% 5: sequence with alternating pulses (random length)
% 6: sequence duration of two seconds with callback when finished

switch exampleNo
    case 1
        % set all to zero
        
        % first create the OutputState object which stores the output
        % values for the
        % digital (first parameter) and the
        % analog channels second and third parameter
        % OutputState(digital, analog0, analog1)
        outputZero = OutputState(0,0,0);
        
        ps.constant(outputZero);
    case 2
        % set all to max value
        
        % digital channels
        % lowest bit: ch0
        % highest bit: ch7
        % 8 bits are required for 8 channels
        digi = hex2dec('ff');
        
        % analog channels
        % each analog channel has 16 bit giving out
        analog0 = 1;
        analog1 = -1;
        
        outputMax = OutputState(digi,analog0,analog1);
        ps.constant(outputMax);
    case 3
        % stream a pattern (switch between the two values from case 1 and 2
               
        %duration of the pulses
        duration = 1000; %ns
        
        sequence = PH(duration, 0, 0, 0);
        sequence = sequence + PH(duration, hex2dec('ff'), 1, -1);
        
        % The number of times the sequence should be repeated must be given
        % all values < 1 mean that sequence should be repeated
        % indefinitely. Otherwise the the sequence if repeated for the
        % given value.
        runs = 0;
        
        % For the streaming output we also have to define the output which
        % should be given out initally, finally and when an overflow
        % occurs.
        outputZero = OutputState(0,0,0);
        initialOutputState = outputZero;
        finalOutputState = outputZero;
        underflowOutputState = outputZero;
        
        % Finally the way to start the sequence must be given. Here we
        % start the sequence as soon as it sent to the Pulse Streamer
        start = PSStart.Immediate;
        
        % Sent the data to the Pulse Streamer.
        ps.stream(sequence, runs, initialOutputState, finalOutputState, underflowOutputState, start);
    case 4
        % Use a callback method as a way to find out whether the
        % pulsestreamer output has finished
        
        % We take the sequence from case 3 but with a duration of 1 for
        % each pulse so that the duration of a sequence is 1s each.
        % In total we run it for 3 times that means 3x2 seconds.
        
        runs = 3;
        outputZero = OutputState(0,0,0);
        initialOutputState = outputZero;
        finalOutputState = outputZero;
        underflowOutputState = outputZero;
        start = PSStart.Immediate;
        
        duration = 1e9; %ns
        
        sequence = PH(duration, 0, 0, 0);
        sequence = sequence + PH(duration, hex2dec('ff'), 1, -1);
        
        % now add the callback function
        ps.setCallbackFinished(@Example2_VariousCallbackMethod);
        ps.stream(sequence, runs, initialOutputState, finalOutputState, underflowOutputState, start);
        
        % the callback function should be called after 6s and shows in the
        % console a message
    case 5
        %
        %   Generate a sequence of alternating high low pulses with randum pulse lengths on the digital
        %   channels 1-7 and the two analog channels.
        %
        %   Digital channel 0 is used as a trigger.
        %
        %   The generated sequence runs in an infitie loop.
        pulses = 1000;
        minPulseLength = 6;
        maxPulseLength = 1000;
        runs = 0;
        pulseTimes = randi([minPulseLength, maxPulseLength],1,pulses);
        sequence = PH(8, 1, 0, 0);
        for i = 1:pulses
            state = mod(i,2);
            sequence = sequence + PH(pulseTimes(i), 254*state, state, -state);
        end
        
        outputZero = OutputState(0,0,0);
        ps.stream(sequence, runs, outputZero, outputZero, outputZero, PSStart.Immediate);
    case 6
        %
        %   Generate a sequence of 200 alternating high low pulses (low: 10us,
        %   high: 10us) which are repeated 1000 times (total duration: 2s).
        %   A callback function is registered so that at the end the 
        %   Example2_VariousCallbackMethod
        %   is executed showing 
        %   callback - Pulse Streamer finished in the console
        pulses = 200;
        runs = 1000;
        sequence = [];
        for i = 1:pulses
            state = mod(i,2);
            sequence = sequence + PH(10000, 255*state, state, -state);
        end       
        outputZero = OutputState(0,0,0);
        ps.setCallbackFinished(@Example2_VariousCallbackMethod)
        ps.stream(sequence, runs, outputZero, outputZero, outputZero, PSStart.Immediate);
end

% check for underflows
if ~ps.getUnderflows()
    disp('Test successful');
else
    error('A buffer underflow was detected during the test run!');
end