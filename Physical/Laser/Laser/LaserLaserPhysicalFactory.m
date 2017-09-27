classdef LaserLaserPhysicalFactory
    %LASERLASERPHYSICSFACTORY creates the laser part for a laser
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
            
            missingField = FactoryHelper.usualChecks(struct, LaserLaserPhysicalFactory.NEEDED_FIELDS);
            if ~isnan(missingField)
                error(...
                    'trying to create a laser part into laser "%s", encountered missing field - "%s". aborting',...
                    name, missingField);
            end
            
            partName = sprintf('%s laser_part', name);
            
            switch(lower(struct.classname))
                case 'dummy'
                    laserPhysicalPart = LaserDummy(partName);
                    return
                otherwise
                    error('can''t create a laser part into laser "%s" with classname = "%s" - unknown classname! aborting.');
            end
        end
                    
                    
    end
    
end

