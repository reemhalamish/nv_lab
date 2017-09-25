classdef LaserAomPhysicalFactory
    %LASERLASERPHYSICSFACTORY creates the laser part for a laser
    %   has only one method: createFromStruct()
    
    properties(Constant)
        NEEDED_FIELDS = {'classname'};
    end
    
    methods(Static)
        function aomPhysicalPart = createFromStruct(name, struct)
            if isempty(struct)
                aomPhysicalPart = [];
                return
            end
            
            missingField = FactoryHelper.usualChecks(struct, LaserLaserPhysicalFactory.NEEDED_FIELDS);
            if ~isnan(missingField)
                error(...
                    'trying to create an AOM part into laser "%s", encountered missing field - "%s". aborting',...
                    name, missingField);
            end
            
            partName = sprintf('%s aom_part', name);
            
            switch(lower(struct.classname))
                case 'dummy'
                    aomPhysicalPart = AomDummy(partName);
                    return
                case 'nidaq'
                    aomPhysicalPart = AomNiDaq.create(partName, struct);
                    return
                otherwise
                    error('can''t create an AOM part into laser "%s" with classname = "%s" - unknow classname! aborting.');
            end
        end
                    
                    
    end
    
end