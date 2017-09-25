classdef EventExtraScanUpdated
    %EVENTEXTRASCANUPDATED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        scan        % the scan results
        axes        % the axes vector(s) - could be 1 or cell of 2.
        dimNumber   % the scan dimensions
        botLabel    % the label to show below
        leftLabel   % the label to show on the left
    end
        
    methods
        function obj = EventExtraScanUpdated(scan, dimNumber, axes, botLabel, leftLabel)
            obj.scan = scan;
            obj.axes = axes;
            obj.dimNumber = dimNumber;
            obj.botLabel = botLabel;
            obj.leftLabel = leftLabel;
        end
        
        function axis = getFirstAxis(obj)
            if iscell(obj.axes)
                axis = obj.axes{1};
            else
                axis = obj.axes;
            end
        end
        
        function axis = getSecondAxis(obj)
            if ~iscell(obj.axes) || obj.dimNumber ~= 2
%                 EventStation.anonymousWarning('asking for second axis when no such exist! answer will be a 0x0 vector')
                axis = [];
            else
                axis = obj.axes{2};
            end
            
        end
    end
    
end

