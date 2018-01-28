classdef LaserSourcePhysicalFactory
    %LASERSOURCEPHYSICSFACTORY creates the source part for a laser
    %   has only one method: createFromStruct()
    
    properties(Constant)
        NEEDED_FIELDS = {'classname'};
    end
    
    methods(Static)
        function laserPhysicalPart = createFromStruct(name, struct)
            if isempty(struct)
                laserPhysicalPart = [];
                return
            end
            
            missingField = FactoryHelper.usualChecks(struct, LaserSourcePhysicalFactory.NEEDED_FIELDS);
            if ~isnan(missingField)
                error(...
                    'Trying to create a laser part for laser "%s", encountered missing field - "%s". Aborting',...
                    name, missingField);
            end
            
            partName = sprintf('%s laser_part', name);
            
            switch(lower(struct.classname))
                case 'dummy'
                    laserPhysicalPart = LaserSourceDummy(partName);
                    return
                otherwise
                    error('Can''t create a %s-class laser part for laser "%s" - unknown classname! Aborting.', struct.classname, name);
            end
        end
                    
                    
    end
    
end