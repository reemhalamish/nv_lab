classdef JsonInfoReader
    %MAINJSONINFOREADER reads the main JsonInfo setup-file
    
    
    properties
    end
    
    methods(Static)
        function jsonStruct = getJson()
            %%%% get the json %%%%
            jsonTxt = fileread('setupInfo.json');
            jsonStruct = jsondecode(jsonTxt);
            
            %%%% add extra fields %%%%
            if ~isfield(jsonStruct, 'debugMode')
                jsonStruct.debugMode = false;
            end
        end
    end
    
end

