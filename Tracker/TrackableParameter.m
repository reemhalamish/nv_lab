% Probably unneeded
classdef TrackableParameter < ExpParameter
    %TRACKABLEPARAMETER A parameter which can be tracked by some class Trackable
    % Note that it is not clear whether there is a need of such class
    methods
        function obj = TrackableParameter(name, type, valueOptional, trackedName)
            obj@ExpParameter(name, type, valueOptional);
            if exist('trackedName', 'var')
                obj.EXP_NAME = trackedName;
            end
        end
    end
end

