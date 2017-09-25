function LoadNIDAQmx

if ~libisloaded('mynidaqmx')
    disp('Matlab: Load nicaiu.dll')
    % Added by Jero
    % nidaxmx.h C:\Program Files\National Instruments\NI-DAQ\DAQmx ANSI C
    % Dev\include
    % nicaiu.dll C:\WINDOWS\system32
    funclist = loadlibrary('nicaiu.dll','nidaqmx.h','alias','mynidaqmx');
    %funclist = libfunctions('myni','-full')
    %libfunctionsview('myni')
end
disp('Matlab: dll loaded')
