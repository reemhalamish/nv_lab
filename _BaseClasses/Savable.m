classdef (Abstract) Savable < BaseObject
    %SAVABLE object that can be saved to (and loaded from) a file
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %      copy & paste the code below for child classes!       %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %     %% overriding from Savable
    %     methods(Access = protected)
    %         function outStruct = saveStateAsStruct(obj, category) %#ok<*MANU>
    %             % saves the state as struct. if you want to save stuff, make
    %             % (outStruct = struct;) and put stuff inside. if you dont
    %             % want to save, make (outStruct = NaN;)
    %             %
    %             % category - string. some objects saves themself only with
    %             % specific category (image/experimetns/etc)
    %
    %             outStruct = NaN;
    %         end
    %
    %         function loadStateFromStruct(obj, savedStruct, category, subCategory) %#ok<*INUSD>
    %             % loads the state from a struct.
    %             % to support older versoins, always check for a value in the
    %             % struct before using it. view example in the first line.
    %             % category - a string, some savable objects will load stuff
    %             %            only for the 'image_lasers' category and not for
    %             %            'image_stages' category, for example
    %             % subCategory - string. could be empty string
    %
    %
    %
    %             if isfield(savedStruct, 'some_value')
    %                 obj.my_value = savedStruct.some_value;
    %             end
    %         end
    %
    %         function string = returnReadableString(obj, savedStruct)
    %             % return a readable string to be shown. if this object
    %             % doesn't need a readable string, make (string = NaN;) or
    %             % (string = '');
    %
    %             string = NaN;
    %         end
    %     end
    
    
    
    properties(Constant = true)
        CATEGORY_IMAGE = 'image';
        CATEGORY_IMAGE_SUBCAT_STAGE = 'image_stage';
        CATEGORY_IMAGE_SUBCAT_LASER = 'image_laser';
        CATEGORY_EXPERIMENRS = 'experiments';
        
        SUB_CATEGORY_DEFAULT = '';  % default sub-category is empty string
        
        TIMESTAMP_FORMAT = 'yyyymmdd_HHMMSS';
        PROPERTY_CATEGORY = 'savable___category';
        PROPERTY_TIMESTAMP = 'savable___timestamp';
        CHILD_PROPERTY_READABLE_STRING = 'readable_string';
    end
    
    methods(Access = protected, Abstract = true)
        saveStateAsStruct(obj, category) %#ok<*MANU>
        % saves the state as struct.
        % override this function to save.
        % to save, you should return a new struct with your properties.
        % if you don't want to save anything, return NaN.
        %
        % category - a string, some savable objects will save stuff
        %            only for the 'image' category and not for
        %            'Experiments' category, for example
        %
        loadStateFromStruct(obj, savedStruct, category, subCategory) %#ok<*INUSD>
        % loads the state from a struct previousely saved.
        % override this function to load
        % category - a string, some savable objects will load stuff
        %            only for the 'image_lasers' category and not for
        %            'image_stages' category, for example
        %
        
        returnReadableString(obj, savedStruct)
        % returns a string representation of the struct. can return empty
        % string or NaN if no readable string is needed
    end
    
    methods(Access = protected)
        function obj = Savable(name)
            % name - the object name
            obj@BaseObject(name);
            Savable.addSavable(obj);
        end
    end
    
    methods
        % destructor
        function delete(obj)
            if JsonInfoReader.getJson.debugMode
                fprintf('deleting savable object "%s" of type %s\n', obj.name, class(obj));
            end
            Savable.removeSavable(obj);
        end
    end
    
    
    methods(Static = true, Access = private)
        function savableObjects = getAllSavableObjects()
            persistent allObjects
            if isempty(allObjects)
                allObjects = CellContainer;
            end
            savableObjects = allObjects;
        end
        
        function addSavable(savableObject)
            allObjects = Savable.getAllSavableObjects();
            allObjects.cells{end + 1} = savableObject;
        end
        
        function removeSavable(savableObject)
            allObjects = Savable.getAllSavableObjects();
            objectsToKeep = cellfun(@(x) ~strcmp(x.name, savableObject.name), allObjects.cells);
            allObjects.cells = allObjects.cells(objectsToKeep);
        end
    end
    
    methods(Static = true, Hidden = true)
        function outStruct = saveAllObjects(category)
            % saves all the savable objects to a struct.
            % this struct will look like that:
            % (savable object name) ---> (inner struct. info this savable wants to save)
            % whitespaces are not premitted in struct properties, so they
            % are replaced with underscores
            % for example, a simple struct could look like that:
            %
            %   struct with fields:
            %       red_laser: [1ª1 struct]
            %       NI_DAQ: [1ª1 struct]
            %
            % category - a string
            %
            outStruct = struct();
            allObjects = Savable.getAllSavableObjects();
            for i = 1 : length(allObjects.cells)
                savableObject = allObjects.cells{i};
                objectStruct = savableObject.saveStateAsStruct(category);
                if isstruct(objectStruct)
                    % readable string - get the string
                    readableString = savableObject.returnReadableString(objectStruct);
                    if ischar(readableString) && ~isempty(readableString)
                        objectStruct.(Savable.CHILD_PROPERTY_READABLE_STRING) = readableString;
                    end
                    
                    % property name - replace all spaces with underscores
                    nameToSave = regexprep(savableObject.name, ' ', '_');
                    outStruct.(nameToSave) = objectStruct;
                end
            end
            outStruct.(Savable.PROPERTY_CATEGORY) = category;
            outStruct.(Savable.PROPERTY_TIMESTAMP) = datestr(now, Savable.TIMESTAMP_FORMAT);
        end
        
        function loadAllObjects(structToLoadFrom, category, subCategory)
            % loads all the savable objects from a struct.
            %
            % category - string
            % subCategory - string. could be empty string
            % 
            % structToLoadFrom - this struct should look like that:
            % (savable object name) ---> (inner struct. info this object saved before)
            % whitespaces are not premitted in struct properties, so they
            % are replaced with underscores
            % for example, a simple struct could look like that:
            %
            %   struct with fields:
            %       red_laser: [1ª1 struct]
            %       NI_DAQ: [1ª1 struct]
            %
            allObjects = Savable.getAllSavableObjects();
            for i = 1 : length(allObjects.cells)
                savableObject = allObjects.cells{i};
                % replace all spaces with underscores
                nameToLoad = regexprep(savableObject.name, ' ', '_');
                if isfield(structToLoadFrom, nameToLoad)
                    savableObject.loadStateFromStruct(structToLoadFrom.(nameToLoad), category, subCategory);
                end
            end
        end
        
        function longString = onlyReadableStrings(loadedStruct)
            % extract all the readable strings
            fields = fieldnames(loadedStruct);
            longString = '';
            for i = 1 : length(fields)
                fieldCell = fields(i);
                field = fieldCell{:};
                value = loadedStruct.(field);
                if isstruct(value) && isfield(value, Savable.CHILD_PROPERTY_READABLE_STRING)
                    % found a value with a readable string! extract the readable string...
                    readableString = value.(Savable.CHILD_PROPERTY_READABLE_STRING);
                    longString = sprintf('%s%s\n', longString, readableString);
                end
            end
            longString = longString(1 : end - 1);  % remove the last "\n"
            
        end
        
        function smallStruct = extractSpecificSavableStruct(savableObject, bigStructToLoadFrom)
            % extracts the part of the big struct that the savable object
            % has written
            % returns - the small part of the struct, or nan if this
            % savable hasn't written anything
            nameToLoad = regexprep(savableObject.name, ' ', '_');
            if isfield(bigStructToLoadFrom, nameToLoad)
                smallStruct = bigStructToLoadFrom.(nameToLoad);
            else
                smallStruct = nan;
            end
        end
    end
    
end