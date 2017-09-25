classdef FactoryHelper
    %FACTORYHELPER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods(Static)
        function missingField = usualChecks(struct, neededFields)
            % checks for fields in  a struct
            % neededFields - can look like that:
            %     {'nickname', 'classname', 'directControl', 'aomControl'}
            %
            % returns - the first missing field if exists or NaN
            
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

