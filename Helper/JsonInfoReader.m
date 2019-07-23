classdef JsonInfoReader
    %MAINJSONINFOREADER reads the main JsonInfo setup-file
    
    
    properties
    end
    
    methods (Static)
        function jsonStruct = getJson()
            %%%% get the json %%%%
            jsonTxt = fileread('C:\\lab\\setupInfo.json');
            jsonStruct = jsondecode(jsonTxt);
            
            %%%% add extra fields %%%%
            if ~isfield(jsonStruct, 'debugMode')
                jsonStruct.debugMode = false;
            end
        end
        
        function setupNum = setupNumber()
            jsonStruct = JsonInfoReader.getJson;
            setupNum = jsonStruct.setupNumber;
            if ~ischar(setupNum)
                setupNum = num2str(setupNum);
            end  
        end
        
        function object = getDefaultObject(listName, defaultNameOptional)
            % Gets from the json an object in a list which has a 'default'
            % property. That is, when we don't know which object from the
            % list we should take, we take the default.
            %
            % listName - char array. Name of the list (e.g. 'stages')
            % defaultNameOptional - char array. If the value is not
            % 'default' (for example, if it's 'greenLaser'), we want to be
            % able to choose it.
            
            if nargin == 1
                % No default name given
                defaultName = 'default';
            else
                defaultName = defaultNameOptional;
            end
            
            if strcmp(listName, 'lasers') && strcmp(defaultName, LaserGate.GREEN_LASER_NAME)
                % This one was designed differently than the
                % others. We can get
                object = getObjByName(LaserGate.GREEN_LASER_NAME);
                % and we're done.
                return
            end
            
            % Otherwise
            jsonStruct = JsonInfoReader.getJson;
            list = jsonStruct.(listName);
            isListACell = isCell(list);
            
            % Initialize search
            isDefault = false(size(list));    % initialize
            
            for i = 1:length(list)
                % Get struct of current object
                if isListACell
                    currentStruct = list{i};
                else
                    currentStruct = list(i);
                end
                
                % Check whether this is THE default object
                if isfield(currentStruct, defaultName)
                    isDefault(i) = true;
                end
            end
            
            % Find out if we have a winner
            nDefault = sum(isDefault);
            switch nDefault
                case 0
                    EventStation.anonymousError('None of the %s is set to be %s! Aborting.', ...
                        listName, defaultName);
                case 1
                    switch listName
                        % We get the object from an objectCell, that should
                        % have already been created
                        case 'stages'
                            objectCell = ClassStage.getStages();
                        case 'frequencyGenerator'
                            objectCell = FrequencyGenerator.getFG();
                    end
                    if length(list) ~= length(objectCell)
                        EventStation.anonymousError('.json file was changed since system setup. Please restart MATLAB.')
                    end
                    
                    % And there it is:
                    object = objectCell{isDefault};
                        
                otherwise
                    EventStation.anonymousError('Too many %s were set as %s! Aborting.', ...
                        listName, defaultName)
            end
            
        end
        
        function [f, minim, maxim, units] = getFunctionFromLookupTable(tabl)
            % Creates linear interpolation from lookup table.
            %
            % table - string. Path of lookup table file
            arr = importdata(tabl);
            data = arr.data;
            percentage = data(:,1);
            physicalValue = data(:,2);
            f = @(x) interp1(percentage, physicalValue, x);
            
            minim = min(percentage);
            maxim = max(percentage);
            headers = arr.colheaders;
            if size(headers)>=2
                units = headers{2};
            else
                units = '';
            end
        end
    end
    
end

