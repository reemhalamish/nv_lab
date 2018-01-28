clear

ipAddress = '132.64.56.49';

% connect to the pulse streamer
ps = PulseStreamer(ipAddress);

% basic settings
outputZero = OutputState(0,0,0);
initialOutputState = outputZero;
finalOutputState = outputZero;
underflowOutputState = outputZero;
start = PSStart.Immediate;

% settings for sequence generation
numberOfSequences = 10;
pulsesPerSequence = 100;
nRuns = 100;

disp(['Test performance for ' num2str(numberOfSequences * pulsesPerSequence * nRuns) ' of pulses in total.']);

fprintf('\n')
%generate Sequences
disp(['Generating ' num2str(numberOfSequences) ' sequences with ' num2str(pulsesPerSequence) ' PHs each, that means in total ' num2str(numberOfSequences * pulsesPerSequence) ' PHs.']);
tic 
% we first create "numberOfSequences" different sequence groups (S1, S2, ...)"
sequences = cell(1,numberOfSequences);        
for iSeq=1:numberOfSequences
    sequences{iSeq} = [];        
    for iPulse = 1:pulsesPerSequence
        % the content of the PHs is more or less arbitary
        sequences{iSeq} = sequences{iSeq} + PH(1000, mod(iPulse * iSeq, 256), 0, 0);
    end
end
toc

fprintf('\n')
% case one - output one sequences after another and loop this "nRuns" times
% (S1, S2, ...) * nRuns
disp(['a) Output one sequences after another and loop this ' num2str(nRuns) ' times.']);
disp(['Total number of pulses: ' num2str(numberOfSequences * pulsesPerSequence * nRuns)]);
disp(['The number of times all sequences are repeated are passed to the "stream" method, which is the most efficient way for repeating the whole sequence.']);
tic
runs = nRuns;
pSeq = [];
for iSeq=1:numberOfSequences
    pSeq = pSeq + sequences{iSeq};
end
ps.stream(pSeq, runs, initialOutputState, finalOutputState, underflowOutputState, start);
toc

fprintf('\n')
% case two - output each sequence "nRuns" times. Then continue with the
% next sequence for "nRuns" times and so on...
% (S1*nRuns, S2*nRuns, ...)
disp(['b) Output each sequence ' num2str(nRuns) ' times and continue with the next sequence the same way.']);
disp(['Total number of pulses: ' num2str(numberOfSequences * pulsesPerSequence * nRuns)]);
disp(['The repetition is build up with "*" which is slower compared to the method of a).'])
disp(['The advantage is that not only the whole sequence in total can be repeated, but also sub-sequences as shown here.']);
tic
pSeq = [];
for iSeq=1:numberOfSequences
    pSeq = pSeq + sequences{iSeq} * nRuns;
end
runs = 1;
ps.stream(pSeq, runs, initialOutputState, finalOutputState, underflowOutputState, start);
toc

