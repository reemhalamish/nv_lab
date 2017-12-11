classdef LaserGate < Savable
    %GATELASER represents a laser object
    %   a laser object has 3 inner parts: aom, laser, switch. 
    %   the switch is mostly connected to the pulse blaster, controlling
    %   the aom.
    %   sometimes, the AOM can be enabled\disabled itself. and can be set
    %   with new voltage values
    %   sometimes, the "laser" inner part can be enabled\disabled itself,
    %   and some times it can be set with new voltage values
    
    properties
        laser
        aom
        aomSwitch
    end
    
    properties(Constant)
        NEEDED_FIELDS = {'nickname', 'directControl', 'aomControl', 'pb'};
        STRUCT_IO_IS_ENABLED = 'isEnabled';  % used to save and load the state
        STRUCT_IO_CUR_VALUE = 'currentValue';   % used to save and load the state
    end
    
    methods
        %% constructor
        function obj = LaserGate(name, laser, aom, aomSwitch)
            obj@Savable(name);
            BaseObject.addObject(obj);  % so it can be reached by BaseObject.getByName()
            
            obj.aom = aom;
            obj.laser = laser;
            obj.aomSwitch = aomSwitch;
        end
        
        function bool = isLaserAvail(obj)
            % check if this laser gate can manipulate a smart laser
            bool = isobject(obj.laser);
        end
        
        function bool = isAomAvail(obj)
            % check if this laser gate can manipulate the aom
            bool = isobject(obj.aom);
        end
    end
    
    %% overriding from Savable
    methods(Access = protected) 
        function outStruct = saveStateAsStruct(obj, category, type) %#ok<*MANU>
            % saves the state as struct. overriden from Savable
            
            % save only if you have the right category...
            if ~any(strcmp(category, {...
                    Savable.CATEGORY_IMAGE, ...
                    Savable.CATEGORY_EXPERIMENTS}))
                outStruct = NaN;
                return;
            end
            % and the right type of data (i.e. experiment parameter)
            if ~strcmp(type,Savable.TYPE_PARAMS)
                outStruct = NaN;
                return;
            end
            
            
            outStruct = struct;
            outStruct.switch = obj.aomSwitch.isEnabled;
            if obj.isAomAvail()
                outStruct.aom_isEnabled = obj.aom.isEnabled;
                outStruct.aom_curValue = obj.aom.currentValue;
            end
            if obj.isLaserAvail()
                outStruct.laser_isEnabled = obj.laser.isEnabled;
                outStruct.laser_curValue = obj.laser.currentValue;
            end
        end
        
        function loadStateFromStruct(obj, savedStruct, category, subCategory) %#ok<*INUSD>
            % loads the state from a struct.
            % to support older versoins, always check for a value in the
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
            
            if obj.isAomAvail()
                if isfield(savedStruct, 'aom_isEnabled') && obj.aom.canSetEnabled()
                    obj.aom.setEnabled(savedStruct.aom_isEnabled);
                end
                if isfield(savedStruct, 'aom_curValue') && obj.aom.canSetValue()
                    obj.aom.setNewValue(savedStruct.aom_curValue);
                end
            end
            if obj.isLaserAvail()
                if isfield(savedStruct, 'laser_isEnabled') && obj.laser.canSetEnabled()
                    obj.laser.setEnabled(savedStruct.laser_isEnabled);
                end
                if isfield(savedStruct, 'laser_curValue') && obj.laser.canSetValue()
                    obj.laser.setNewValue(savedStruct.laser_curValue);
                end
            end
        end
        
        function string = returnReadableString(obj, savedStruct)
            isOn = BooleanHelper.boolToOnOff(obj.aomSwitch.isEnabled);
            value = 100;
            if obj.isAomAvail()
                value = value * obj.aom.currentValue / 100;
            end
            if obj.isLaserAvail()
                value = value * obj.laser.currentValue / 100;
            end
            string = sprintf('%s - value %d%% (%s)', obj.name, int16(value), isOn);
        end
    end
    
    methods(Static)
		function cellOfLasers = getLasers()
		% creates all the lasers from the json.
		
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
                    warning('Missing field in struct! Aborting.');
                    error(laserStruct);
                end
                
                laserName = laserStruct.nickname;
                laserPhysical = LaserLaserPhysicalFactory.createFromStruct(laserName, laserStruct.directControl);
                aomPhysical = LaserAomPhysicalFactory.createFromStruct(laserName, laserStruct.aomControl);
                pbSwitch = PbControlledSwitch.createFromStruct(laserName, laserStruct.pb);
                laserGate = LaserGate(laserName, laserPhysical, aomPhysical, pbSwitch);
        end        
    end
end

