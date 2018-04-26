classdef Setup < handle
    %SETUP responsible for initiation of "real world physics" objects
    %   this class generates everything the controller 
    %       needs, physically speaking.
    
    properties
    end
    
    properties (Hidden, Constant)
        NEEDED_FIELDS = {'lasers', 'niDaq', 'pulseGenerator', 'setupNumber', 'stages', 'spcm'};
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
    
    methods (Access = private) 
        function obj = Setup()
            obj@handle();          
            
            %%%% Get the json %%%%
            jsonStruct = JsonInfoReader.getJson();
            
            %%%% Check missing fields %%%%
            missingField = FactoryHelper.usualChecks(jsonStruct, Setup.NEEDED_FIELDS);
            if ~isnan(missingField)
                EventStation.anonymousError(...
                    'Can''t find the reserved word "%s" in the main section of the file "setupInfo.json"', ...
                    missingField);
            end
                        
            %%%% init important objects %%%%
            NiDaq.create(jsonStruct.niDaq);
            PulseGenerator.create(jsonStruct.pulseGenerator);
            Spcm.create(jsonStruct.spcm);
            ImageScanResult.init;
            StageScanner.init;
            Experiment.init;
            SaveLoad.init;
            LaserGate.getLasers;	% the first call to getLasers() also inits them
			ClassStage.getStages;	% the first call to getStages() also inits them
            Tracker.init;
            % Joystick.init should be also here. For the moment, it is found in the appropriate stage
        end
    end
    
end

