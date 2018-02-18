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
                    'Trying to create a source for laser "%s", encountered missing field - "%s". Aborting',...
                    name, missingField);
            end
            
            partName = sprintf('%s source', name);
            
            switch(lower(struct.classname))
                case 'dummy'
                    laserPhysicalPart = LaserSourceDummy(partName);
                    return
                case 'onefive katana 05'
                    laserPhysicalPart = LaserSourceOnefiveKatana05.create(partName, struct);
                otherwise
                    error('Can''t create a %s-class laser part for laser "%s" - unknown classname! Aborting.', struct.classname, name);
            end
        end
                    
                    
    end
    
end