classdef EventExtraScanUpdated < handle
    %EVENTEXTRASCANUPDATED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        scan        % matrix of double. Scan results
        axes        % a vector or a cell of 2 vectors
        axesString  % vector of chars. Axes labels (for example 'zx' or 'y')
        stageName  % "string" (vector of chars). Name of scanning stage
        botLabel    % the label to show below
        leftLabel   % the label to show on the left
    end
        
    methods
        function obj = EventExtraScanUpdated(scan, axes, axesString, stageName, botLabel, leftLabel)
            obj@handle;
            obj.scan = scan;
            obj.axes = axes;
            obj.axesString = axesString;
            obj.stageName = stageName;
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
        
        function num = dimNumber(obj)
            % Dimensions of scan
            num = length(obj.axesString);
        end
    end
    
end

