classdef SpcmDummy < Spcm
    %SPCMDUMMY dummy spcm
    %   inherit from Spcm and have default implementations for all the
    %   methods
    
    properties
        timesToRead         % int
        isEnabled           % logical
        integrationTime     % double (in seconds). Time over which photons are counted
        calledScanStart     % logical. Used for checking that the user actually called startScanRead() before calling readFromScan()
        calledGatedStart	% logical. Used for checking that the user actually called startGatedRead() before calling readGated()
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
            obj.calledScanStart = false;
            obj.calledGatedStart = false;
        end
        
    %%% From time %%%
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
    %%% End (from time) %%%
        
        
    %%% From stage %%%
        function prepareReadByStage(obj, ~, nPixels, timeout, ~)
            % Prepare to read from the spcm, when using a stage as a signal
            if ~ValidationHelper.isValuePositiveInteger(nPixels)
                obj.sendError(sprintf('Can''t prepare for reading %d times, only positive integers allowed! Igonring.', nPixels));
            end
            obj.timesToRead = nPixels;
            obj.integrationTime = timeout / (2 * nPixels);
        end
        
        function startScanRead(obj)
            % Actually start the process
            obj.calledScanStart = true;
        end
        
        function vectorOfKcps = readFromScan(obj)
            % Read vector of signals from the spcm
            if ~obj.isEnabled
                obj.sendError('Can''t readFromScan() without calling ''setSPCMEnabled()''!');
            end
            
            if obj.timesToRead <= 0
                obj.sendError('Can''t readFromScan() without calling ''prepareReadByStage()''!  ');
            end
            
            if ~obj.calledScanStart
                obj.sendError('Can''t readFromScan() without calling startScanRead()!');
            end
            
            pause(obj.integrationTime * obj.timesToRead);
            vectorOfKcps = randi([0 obj.MAX_RANDOM_READ], 1, obj.timesToRead);
        end
        
        function clearScanRead(obj)
            % Complete the task of reading the spcm from a stage
            obj.timesToRead = 0;
        end
    %%% End (from stage) %%%
        
        
    %%% From gated %%%
        function prepareGatedRead(obj, nReads, timeout)
            % Prepare to read spcm count from opening the spcm window
            if ~ValidationHelper.isValuePositiveInteger(nReads)
                obj.sendError(sprintf('Can''t prepare for reading %d times, only positive integers allowed! Igonring.', nReads));
            end
            obj.timesToRead = nReads;
            obj.integrationTime = timeout / (2 * nReads);
        end
        
        function startGatedRead(obj)
            % Actually start the process
            obj.calledGatedStart = true;
        end
        
        function vectorOfKcps = readGated(obj)
            % Read vector of signals from the spcm
            if ~obj.isEnabled
                obj.sendError('Can''t readFromScan() without calling ''setSPCMEnabled()''!');
            end
            
            if obj.timesToRead <= 0
                obj.sendError('Can''t readFromScan() without calling ''prepareReadByStage()''!  ');
            end
            
            if ~obj.calledScanStart
                obj.sendError('Can''t readFromScan() without calling startScanRead()!');
            end
            
            pause(obj.integrationTime * obj.timesToRead);
            vectorOfKcps = randi([0 obj.MAX_RANDOM_READ], 1, obj.timesToRead);
        end
        
        function clearGatedRead(obj)
            % Complete the task of reading the spcm
            obj.integrationTime = 0;
        end
        
    %%% End (from gated) %%%
        
        function setSPCMEnable(obj, newBooleanValue)
            obj.isEnabled = newBooleanValue;
        end
    end
    
end

