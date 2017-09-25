classdef Setup < handle
    %SETUP responsible for initiation of "real world physics" objects
    %   this class generates everything the controller 
    %       needs, physically speaking.
    
    properties(GetAccess = public, SetAccess = private)
       laserGates;  % 1D cell array of laserGates (each containing Aaser&Aom components)
       stages;      % 1D cell array of stages
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
            
            %%%% init lasers %%%%
            laserGates = {};
            for i = 1 : length(jsonStruct.lasers)
                laserGates{i} = LaserGate.createFromStruct(jsonStruct.lasers(i)); %#ok<AGROW>
            end
            obj.laserGates = laserGates;
            
            %%%% init stages %%%%
            obj.stages = ClassStage.getStages;
            
        end
    end
    
end

