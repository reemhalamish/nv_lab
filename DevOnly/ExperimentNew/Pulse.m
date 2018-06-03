classdef Pulse < matlab.mixin.Copyable 
    %PULSE Single pulse of all devices
    %   A pulse is defined by duration, and channels which are on in this
    %   pulse (could be empty)
    
    properties
        duration        % double. Duration of pulse in microseconds
        nickname = [];	% char array. Optional name for the pulse.
    end
    
    properties (Access = private)
        onChannels = struct;    % struct of char arrays. We assume, for now, 
                                % only digital cahnnels, so we only need to
                                % know which ones are on.
        % phase?
    end
    
    methods
        function obj = Pulse(duration, channelNames, nickame) % Constructor
            narginchk(1,3)
            obj@matlab.mixin.Copyable;  % Superclass providing copy functionality for handle objects
            
            try     % Property uses setters, and might result in error.
            obj.duration = duration;
            catch err
                delete(obj)
                rethrow(err)
            end
            
            switch nargin
                case 2
                    obj.changeChannels(channelNames);
                    obj.nickname = '';
                case 3
                    obj.changeChannels(channelNames);
                    obj.nickname = nickame;
            end
            
        end
    end
        
    methods

        function [pulse1, pulse2] = split(obj, time)
            % Split current Pulse into two parts.
            % Method: create two copies of the current Pulse, and change
            % their duration accordingly
            remainder = obj.duration - time;
            if time <= 0 || remainder <= 0
                error('Pulse could not be split in requested time')
            end
            
            pulse1 = obj.copy;
            pulse1.duration = time;
            
            pulse2 = obj.copy;
            pulse2.duration = remainder;
        end
        
    end
    
    %% Setters and getters
    methods
        function set.duration(obj, newDuration)
            if ~isscalar(newDuration) || ~isnumeric(newDuration)
                error('Duration must be a scalar numeric value!')
            end
            if newDuration <= 0
                error('Duration must be positive! Requested: %d', newDuration)
            end
            obj.duration = newDuration;
        end
        
        function changeChannels(obj, channels, levels)
            % Sets the levels for each channel.
            % This only changes from current levels. Otherwise, create new
            % pulse.
            %
            % channels - char array or cell of char arrays. Names of the
            % channels refered to in this pulse
            % levels - array of logicals. Whether the channel is on or off.
            % channel and level must be of the same length!
            
            if ~exist('levels', 'var')
                % Allows for syntax obj.changeChannels(channels), which
                % only adds channels.
                levels = true(size(channels));
            elseif length(channels) ~= length(levels)
                error('Channel names and channel levels must be of the same length!')
            elseif length(unique(channels)) ~= length(channels)
                error('Channel names include repetitions. Each channel must have a unique name!')
            end
            
            oc = obj.onChannels; % for brevity
            for i = 1:length(channels)
                if levels(i)
                    % Add channels which are (true)
                    channel = channels{i};
                    oc.(channel) = true;
                elseif isfield(oc, channel)
                    % Remove channels which are (false), if they exist
                    oc = rmfield(oc, channel);
                end
            end
            obj.onChannels = oc;     % after changes are done, we assign them back to object property
        end
        
        function clear(obj)
            % Removes all active channels in Pulse
            obj.onChannels = struct;
        end
        
        function chans = getOnChannels(obj)
            chans = fields(obj.onChannels);
        end
    end 
end

