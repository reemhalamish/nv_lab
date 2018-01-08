classdef FactoryHelper
    %FACTORYHELPER Facilitates "factory" architecture
    %   When creating a new object, we might want to make sure we have all
    %   we need for that purpose. This check is conceptualized as a
    %   "factory" for the object, and should use this class
    
    properties
    end
    
    methods(Static)
        function missingField = usualChecks(struct, neededFields)
            % Checks for the needed fields in the struct
            % neededFields - cell array of character vectors. For example:
            %     {'nickname', 'classname', 'directControl', 'aomControl'}
            %
            % returns - the first missing field (if exists) or NaN
            
            for i=1 : length(neededFields)
                if ~isfield(struct, neededFields{i})
                    missingField = neededFields{i};
                    return;
                end
            end
            missingField = NaN;
        end
    end
    
end

