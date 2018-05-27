classdef (Abstract) Spcm < EventSender
    %SPCM single photon counter
    %   the spcm is controlled by the NiDaq
    
    properties
        availableProperties = struct;
    end
    
    properties (Constant)
        NAME = 'spcm';
        
        HAS_LIFETIME = 'hasLifetime';
        HAS_G2 = 'hasG2';
        HAS_BINNING = 'hasBinning';
    end
    properties (Constant, Hidden)
        % This needs to be implemented, one way or another, in all SPCMs
        SPCM_NEEDED_FIELDS = {'classname'};
    end
    
    methods (Abstract)
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
    
    methods (Access = protected)
        function obj = Spcm(spcmName)
            obj@EventSender(spcmName);
        end
    end

    methods (Static)
        function create(spcmTypeStruct)
            % Get all we need from json
            missingField = FactoryHelper.usualChecks(spcmTypeStruct, Spcm.SPCM_NEEDED_FIELDS);
            if ~isnan(missingField)
                EventStation.anonymousError('Can''t initialize SPCM - needed field "%s" was not found in initialization struct!', missingField);
            end
            
            try % Maybe there is already one
                getObjByName(Spcm.NAME);
                warning('Another instance of the SPCM already exists')
                return
            catch
                % We actually hope to get here, since this means we are not
                % creating an object that already exists
            end
            
            % Create new object
            switch (lower(spcmTypeStruct.classname))
                case 'nidaq'
                    spcmObject = SpcmNiDaqControlled.create(Spcm.NAME, spcmTypeStruct);
                case 'dummy'
                    spcmObject = SpcmDummy();
                otherwise
                    EventStation.anonymousError(...
                        ['The requested SPCM classname ("%s") was not recognized.\n', ...
                        'Please fix the .json file and try again.'], ...
                        spcmTypeStruct.classname);
            end

            addBaseObject(spcmObject);
        end
    end
    
    methods % Available properties    
        function properties = getAvailableProperties(obj)
            properties = obj.avilableProperties;
        end

        function bool = hasLifetime(obj)
            bool = isfield(obj.availableProperties,obj.HAS_LIFETIME);
        end
        
        function bool = hasG2(obj)
            bool = isfield(obj.availableProperties,obj.HAS_G2);
        end
        
        function bool = hasBinning(obj)
            bool = isfield(obj.availableProperties,obj.HAS_BINNING);
        end
    end
end