classdef LaserSwitchPhysicalFactory
    %LASERSWITCHPHYSICSFACTORY creates the fast switch for a laser
    %   has only one method: createFromStruct()
    
    properties(Constant)
        NEEDED_FIELDS = {'switchChannel'}
        OPTOINAL_FIELDS = {'isEnabled'}
    end
    
    methods(Static)
        function switchPhysicalPart = createFromStruct(name, struct)
            if isempty(struct)
                switchPhysicalPart = [];
                return
            end
            
            missingField = FactoryHelper.usualChecks(struct, LaserSwitchPhysicalFactory.NEEDED_FIELDS);
            if ~isnan(missingField)
                error(...
                    'Trying to create a fast switch for laser "%s", encountered missing field - "%s". Aborting',...
                    name, missingField);
            end
            
            partName = sprintf('%s fast switch', name);
            
            switch lower(struct.classname)
                case 'pulseblaster'
                    switchPhysicalPart = SwitchPbControlled(name, struct.switchChannel);
                case 'pulsestreamer'
                    switchPhysicalPart = SwitchPsControlled(partName, struct.switchChannel);
                otherwise
                    error('Can''t create a %s-class fast switch for laser "%s" - unknown classname! Aborting.', struct.classname, name);
            end
            % check for optional field "isEnabled" and set it correctly
            if isnan(FactoryHelper.usualChecks(struct, SwitchPbControlled.STRUCT_OPTOINAL_FIELDS))
                % usualChecks() returning nan means everything ok
                switchPhysicalPart.isEnabled = struct.isEnabled;
            end
        end
                    
                    
    end
    
end