classdef SpcmDummy < Spcm
    %SPCMDUMMY dummy spcm
    %   inherit from Spcm and have default implementations for all the
    %   methods
    
    properties
        timesToRead % int
        isEnabled   % boolean
        integrationTime  % units: seconds. when using the SPCM counter
        calledStart % boolean. is used to check that the user actually called startRead() before calling read()
    end
    
    properties (Constant)
        MAX_RANDOM_READ = 1000;
        
        NEEDED_FIELDS = Spcm.SPCM_NEEDED_FIELDS;
    end
    
    methods
        function obj = SpcmDummy
            obj@Spcm(Spcm.NAME);
            obj.timesToRead = 0;
            obj.isEnabled = false;
            obj.integrationTime = 0;
            obj.calledStart = false;
        end
        
        function prepareReadByTime(obj, integrationTimeInSec)
            obj.integrationTime = integrationTimeInSec;
        end
        
        function [kcps, std] = readFromTime(obj)
            if obj.integrationTime <= 0
                obj.sendError('Can''t call readFromTime() without calling obj.prepareReadByTime() first!');
            end
            pause(obj.integrationTime)
            kcps = randi([0 obj.MAX_RANDOM_READ],1,1);
            std = abs(0.2 * kcps * randn);	% Gaussian noise proportional to signal
        end
        
        function clearTimeRead(obj)
            obj.integrationTime = 0;
        end
        
        
        % prepare to read from the spcm, when using a stage as a signal
        function prepareReadByStage(obj, ~, nPixels, timeout, ~)
            if ~ValidationHelper.isValuePositiveInteger(nPixels)
                obj.sendError(sprintf('Can''t prepare for reading %s times, only positive integers allowed! igonring', nPixels));
            end
            obj.timesToRead = nPixels;
            obj.integrationTime = timeout / (2 * nPixels);
        end
        
        % actually start the process
        function startScanRead(obj)
            obj.calledStart = true;
        end
        
        % read vector of signals from the spcm
        function vectorOfKcps = readFromScan(obj)
            if ~obj.isEnabled
                obj.sendError('Can''t readFromScan() without calling ''setSPCMEnabled()''!');
            end
            
            if obj.timesToRead <= 0
                obj.sendError('Can''t readFromScan() without calling ''prepareReadByStage()''!  ');
            end
            
            if ~obj.calledStart
                obj.sendError('Can''t readFromScan() without calling startScanRead()!');
            end
            
            pause(obj.integrationTime * obj.timesToRead);
            vectorOfKcps = randi([0 obj.MAX_RANDOM_READ], 1, obj.timesToRead);
        end
        
        % complete the task of reading the spcm from a stage
        function clearScanRead(obj)
            obj.timesToRead = 0;
        end
        
        function setSPCMEnable(obj, newBooleanValue)
            obj.isEnabled = newBooleanValue;
        end
    end
    
end

