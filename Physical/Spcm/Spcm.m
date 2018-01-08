classdef(Abstract) Spcm < EventSender
    %SPCM single photon counter
    %   the spcm is controlled by the NiDaq
    
    properties
    end
    
    properties(Constant = true)
        NAME = 'spcm';
    end
    properties(Constant = true, Hidden = true)
        NEEDED_FIELDS = {'classname'};
    end
    
    methods(Abstract)
        % prepare to read spcm count from opening the spcm window to unit of time
        prepareReadByTime(obj, integrationTimeInSec)
        
        % actually do the read - it takes "integrationTimeInSec" to do so
        [kcps, std] = readFromTime(obj)
        
        % clear the reading task
        clearTimeRead(obj)
        
        
        
        
        % prepare to read from the spcm, when using a stage as a signal
        prepareReadByStage(obj, stageName, nPixels, timeout, fastScan)
        
        % actually start the process
        startScanRead(obj)
        
        % read vector of signals from the spcm
        vectorOfKcps = readFromScan(obj)
        
        % complete the task of reading the spcm from a stage
        clearScanRead(obj)
        
        % control the spcm - turn it on\off
        setSPCMEnable(obj, newBooleanState)
    end
    
    methods(Access = protected)
        function obj = Spcm(spcmName)
            obj@EventSender(spcmName);
        end
    end

    methods(Static = true)
        function spcmObject = create(spcmTypeStruct)
            removeObjIfExists(Spcm.NAME);
            
            missingField = FactoryHelper.usualChecks(spcmTypeStruct, Spcm.NEEDED_FIELDS);
            if ~isnan(missingField)
                error('Can''t initialize SPCM - needed field "%s" was not found in initialization struct!', missingField);
            end
            
            switch (lower(spcmTypeStruct.classname))
                case 'nidaq'
                    spcmObject = NiDaqControlledSpcm.create(Spcm.NAME, spcmTypeStruct);
                case 'dummy'
                    spcmObject = SpcmDummy();
                otherwise
                    error('%s\n%s', ...
                        sprintf('The requested SPCM classname ("%s") was not recognized.\n',spcmTypeStruct.classname), ...
                        'Please fix the .json file and try again.');
            end
            
            addBaseObject(spcmObject);
        end
    end
end