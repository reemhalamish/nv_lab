classdef LaserGate < Savable % Needs to be EventSender
    %GATELASER represents a laser object
    %   A laser object has 3 inner parts: source, AOM, and switch.
    %   The (fast) switch is usually a pulse blaster or a pulse streamer,
    %   controlling the AOM.
    %   Sometimes, the AOM can be enabled\disabled itself, and can be set
    %   with new voltage values.
    %   Sometimes, the source itself can be enabled\disabled,
    %   and sometimes it can be set to a new voltage value.
    
    properties (SetAccess = protected)
        source
        aom
        aomSwitch
    end
    
    properties (Dependent) % Only this is available for external functions
        value
        isOn
    end
    
    properties(Constant)
        NEEDED_FIELDS = {'nickname', 'directControl', 'aomControl', 'switch'};
        STRUCT_IO_IS_ENABLED = 'isEnabled';     % used to save and load the state
        STRUCT_IO_CUR_VALUE = 'value';          % used to save and load the state
        
        GREEN_LASER_NAME = 'Green Laser';
    end
    
    methods
        %% constructor
        function obj = LaserGate(name, source, aom, aomSwitch)
            obj@Savable(name);
            BaseObject.addObject(obj);  % so it can be reached by BaseObject.getByName()
            
            obj.source = source;
            obj.aom = aom;
            obj.aomSwitch = aomSwitch;
        end
        
        function tf = isSourceAvail(obj)
            % Check if this laser gate can manipulate a smart laser source
            tf = isobject(obj.source);
        end
        
        function tf = isAomAvail(obj)
            % Check if this laser gate can manipulate the AOM
            tf = isobject(obj.aom);
        end
        
    end
    
    methods % setters and getters
        % Default methods. Assume value in percents.
        % Child objects can override it, if needed
        
        function set.value(obj, newVal)
            % Value is given in percentage
            tfSource = obj.isSourceAvail && obj.source.canSetValue;
            tfAom = obj.isAomAvail && obj.aom.canSetValue;
            if ~tfAom && ~tfSource
                errMsg = sprintf('Cannot set %s as value for %s', newVal, obj.name);
                EventStation.anonymousError(errMsg);
            elseif tfAom
                part = obj.aom;
            elseif tfSource
                part = obj.source;
                % there is no other option
            end
            part.value = obj.percent2absolute(part, newVal);
        end
        
        function set.isOn(obj, newVal)
            tf = logical(newVal);
                        
            % Maybe it isn't possible
            tfAom = obj.isAomAvail;
            tfSource = isSourceAvail && obj.source.canSetEnabled;
            if ~tfAom && ~tfSource
                errMsg = sprintf('On/off state of %s can''t be set!', obj.name);
                EventStation.anonymousError(errMsg);
            end
            
            switch tf
                case true
                    % We want everything on
                    if tfAom; obj.aomSwitch.isEnabled = true; end
                    if tfSource; obj.source.isEnabled = true; end
                case false
                    % turn off only AOM, if possible
                    if tfAom
                        obj.aomSwitch.isEnabled = false;
                    else
                        obj.source.isEnabled = true;
                    end
                otherwise
                    % tf could not be converted to logical
                    errMsg = sprintf('Cannot set %s as On/off state of %s!', newVal, obj.name);
                    EventStation.anonymousError(errMsg);
            end
        end
        
        %%%%
        function value = get.value(obj)
            % Value is given in percentage
            if obj.isAomAvail()
                part = obj.aom;
            elseif obj.isSourceAvail()
                part = obj.source;
            else
                value = 100;
                return
            end
            value = obj.absolute2percent(part, part.value);
        end
        
        function isOn = get.isOn(obj)
            isOn = obj.aomSwitch.isEnabled && obj.source.isEnabled;
        end
        
    end
    
    %%
    methods (Static)
        function absValue = percent2absolute(part, percentValue)
            assert(isprop(part, 'maxValue'))
            absValue = percentValue * part.maxValue / 100;      % We assume, for simplicity, that minimum value is 0
        end
        
        function percentValue = absolute2percent(part, absValue)
            assert(isprop(part, 'maxValue'))
            percentValue = absValue * 100 / part.maxValue;      % We assume, for simplicity, that minimum value is 0
        end
    end
    
    %% overriding from Savable
    methods(Access = protected)
        function outStruct = saveStateAsStruct(obj, category, type) %#ok<*MANU>
            % Saves the state as struct. Overriden from Savable
            
            outStruct = NaN;
            % Save only if you have the right category...
            if ~any(strcmp(category, {...
                    Savable.CATEGORY_IMAGE, ...
                    Savable.CATEGORY_EXPERIMENTS}))
                return;
            end
            % and the right type of data (i.e. experiment parameter)
            if ~strcmp(type,Savable.TYPE_PARAMS)
                return;
            end
            
            outStruct = struct;
            outStruct.switch = obj.aomSwitch.isEnabled;
            if obj.isAomAvail()
                outStruct.aom_isEnabled = obj.aom.isEnabled;
                outStruct.aom_curValue = obj.aom.value;
            end
            if obj.isSourceAvail()
                outStruct.source_isEnabled = obj.source.isEnabled;
                outStruct.source_curValue = obj.source.value;
            end
        end
        
        function loadStateFromStruct(obj, savedStruct, category, subCategory)
            % Loads the state from a struct.
            % To support older versoins, always check for a value in the
            % struct before using it. view example in the first line.
            % category - a string, some savable objects will load stuff
            %            only for the 'image_lasers' category and not for
            %            'image_stages' category, for example
            % subCategory - string. could be empty string
            
            % load only if you're in need to load:
            %       @ if the category is Experiment
            %       @ or, category is image, and subCat is "default" or "laser"
            
            catIsExp = strcmp(category, Savable.CATEGORY_EXPERIMENTS);
            catIsImage = strcmp(category, Savable.CATEGORY_IMAGE);
            subcatImageIsOk = any(strcmp(subCategory, {Savable.CATEGORY_IMAGE_SUBCAT_LASER, Savable.SUB_CATEGORY_DEFAULT}));
            shouldLoad = catIsExp || (catIsImage && subcatImageIsOk);
            
            if ~shouldLoad; return; end
            
            if isfield(savedStruct, 'switch')
                obj.aomSwitch.isEnabled = savedStruct.switch;
            end
            
            if obj.isAomAvail
                if isfield(savedStruct, 'aom_isEnabled') && obj.aom.canSetEnabled
                    obj.aom.isEnabled = savedStruct.aom_isEnabled;
                end
                if isfield(savedStruct, 'aom_curValue') && obj.aom.canSetValue()
                    obj.aom.value = savedStruct.aom_curValue;
                end
            end
            if obj.isSourceAvail()
                if isfield(savedStruct, 'source_isEnabled') && obj.source.canSetEnabled
                    obj.source.isEnabled = savedStruct.source_isEnabled;
                end
                if isfield(savedStruct, 'source_curValue') && obj.source.canSetValue
                    obj.source.value = savedStruct.source_curValue;
                end
            end
        end
        
        function string = returnReadableString(obj, savedStruct) %#ok<INUSD>
            isOnString = BooleanHelper.boolToOnOff(obj.isOn);
            string = sprintf('%s - value %d%% (%s)', obj.name, int16(obj.value), isOnString);
        end
    end
    
    methods(Static)
        function cellOfLasers = getLasers()
            % Creates all the lasers from the json.
            
            persistent lasersCellContainer
            if isempty(lasersCellContainer) || ~isvalid(lasersCellContainer)
                lasersJson = JsonInfoReader.getJson.lasers;
                lasersCellContainer = CellContainer;
                
                for i = 1 : length(lasersJson)
                    curLaserJson = lasersJson(i);
                    newLaserGate = LaserGate.createFromStruct(curLaserJson);
                    lasersCellContainer.cells{end + 1} = newLaserGate;
                end
            end
            cellOfLasers = lasersCellContainer.cells;
        end
        
        function laserGate = createFromStruct(laserStruct)
            
            missingField = FactoryHelper.usualChecks(laserStruct, LaserGate.NEEDED_FIELDS);
            if ~isnan(missingField)
                warning('Can''t initialize Laser - needed field "%s" was not found in initialization struct!', missingField);
                error(laserStruct);
            end
            
            laserName = laserStruct.nickname;
            sourcePhysical = LaserSourcePhysicalFactory.createFromStruct(laserName, laserStruct.directControl);
            aomPhysical = LaserAomPhysicalFactory.createFromStruct(laserName, laserStruct.aomControl);
            switchPhysical = LaserSwitchPhysicalFactory.createFromStruct(laserName, laserStruct.switch);
            laserGate = LaserGate(laserName, sourcePhysical, aomPhysical, switchPhysical);
        end
    end
end

