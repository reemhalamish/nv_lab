function [status, readArray]= DAQmxReadAnalogF64 (taskHandle, numSampsPerChan, ...
   timeout, fillMode, readArray, arraySizeInSamps, sampsPerChanRead)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% Written by Jeronimo Maze, July 2007 %%%%%%%%%%%%%%%%%%
%%%%%%%%%% Harvard University, Cambridge, USA  %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% for new matlab
% [status,taskhandle,readArray]=calllib('mynidaqmx','DAQmxReadAnalogF64',taskHandle, numSampsPerChan, ...
%    timeout, fillMode, readArray, arraySizeInSamps, sampsPerChanRead, []);

% for old matlab
[status,readArray, sampsPerChanRead, reserved] = daq.ni.NIDAQmx.DAQmxReadAnalogF64(taskHandle, int32(numSampsPerChan), ...
   timeout, uint32(fillMode), readArray, uint32(arraySizeInSamps), int32(sampsPerChanRead), uint32(0));

