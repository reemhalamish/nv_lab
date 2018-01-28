function callbackTestFunction(pulseStreamer)
    % this is the test callback function for testPulseStreamer - case 4
    disp('callback - Pulse Streamer finsished.');
    if pulseStreamer.getUnderflows()
        error('A buffer underflow was detected during the test run!');
    end
end

