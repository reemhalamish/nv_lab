classdef Setup < handle
    %SETUP responsible for initiation of "real world physics" objects
    %   this class generates everything the controller 
    %       needs, physically speaking.
    
    properties
    end
    
    properties(Hidden = true, Constant = true)
        NEEDED_FIELDS = {'lasers', 'niDaq', 'pulseBlaster', 'setupNumber', 'stages', 'spcm'};
    end
    
    methods (Static)
        function obj = getInstance()
            persistent localObj
            if isempty(localObj) || ~isvalid(localObj)
                localObj = Setup;
            end
            obj = localObj;
        end
        
        function init()
            Setup.getInstance;
        end
    end
    
    methods(Access = private) 
        function obj = Setup()
            obj@handle();          
            
            %%%% get the json %%%%
            jsonStruct = JsonInfoReader.getJson();          
            
            %%%% check missing fields %%%%
            missingField = FactoryHelper.usualChecks(jsonStruct, Setup.NEEDED_FIELDS);
            if ~isnan(missingField)
                error('Can''t find the preserved word "%s" in the main section at the file "setupInfo.json"', missingField);
            end
                        
            %%%% init important objects %%%%
            NiDaq.create(jsonStruct.niDaq);
            PulseBlaster.create(jsonStruct.pulseBlaster);
            Spcm.create(jsonStruct.spcm);
            ImageScanResult.init;
            StageScanner.init;
            SpcmCounter.init;
            LaserGate.getLasers;  % the first call on getLasers() also inits them
			ClassStage.getStages;  % the first call on getStages() also inits them
			
        end
    end
    
end

