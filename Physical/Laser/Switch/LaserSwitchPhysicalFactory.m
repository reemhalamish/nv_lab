classdef LaserSwitchPhysicalFactory
    %LASERSWITCHPHYSICSFACTORY creates the fast switch for a laser
    %   has only one method: createFromStruct()
    
    properties (Constant)
        NEEDED_FIELDS = {'switchChannelName'}
        OPTIONAL_FIELDS = {'isEnabled'}
    end
    
    methods (Static)
        function switchPhysicalPart = createFromStruct(name, struct)
            if isempty(struct)
                switchPhysicalPart = [];
                return
            end
            
            missingField = FactoryHelper.usualChecks(struct, LaserSwitchPhysicalFactory.NEEDED_FIELDS);
            if ~isnan(missingField)
                EventStation.anonymousError(...
                    'Trying to create a fast switch for laser "%s", encountered missing field - "%s". Aborting',...
                    name, missingField);
            end
            
            partName = sprintf('%s fast switch', name);
            
            switch lower(struct.classname)
                case {'pulsegenerator', 'pulsestreamer', 'pulseblaster'}
%                     switchPhysicalPart = SwitchPgControlled(partName, struct.switchChannelName);
%                     After PG is properly implemented, we want:
                    switchChannel = Channel.Digital(struct.switchChannelName, struct.switchChannel);
                    switchPhysicalPart = SwitchPgControlled(partName, switchChannel);
                otherwise
                    EventStation.anonymousError(...
                        'Can''t create a %s-class fast switch for laser "%s" - unknown classname! Aborting.', ...
                        struct.classname, name);
            end
            % check for optional field "isEnabled" and set it correctly
            if isnan(FactoryHelper.usualChecks(struct, SwitchPgControlled.OPTIONAL_FIELDS))
                % usualChecks() returning nan means everything ok
                switchPhysicalPart.isEnabled = struct.isEnabled;
            end
        end
                    
                    
    end
    
end