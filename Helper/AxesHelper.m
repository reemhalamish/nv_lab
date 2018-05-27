classdef AxesHelper
    %AXESHELPER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Static)
        function fillAxes(gAxes, data, dimNumber, firstAxisVector, secondAxisOptionalVector, bottomLabel, leftLabel, stdev)
            % fills axes with data - usefull for displaying the scan results on GUI views
            %
            %
            % axesFig - a handle to a GUI axes() object
            % data - a 1D or 2D array of results
            % dimNumber - can be 1 or 2. easier to get it as an argument
            %               than calculate it every time with every func
            % firstAxisVector - vector to be shown as X axis in the figure
            % secondAxisOptionalVector - optional vector to be shown as Y
            % bottomLabel - string
            % leftLabel - string
            switch dimNumber
                case 1
                    if exist('stdev','var') && length(data)==length(stdev)
                        errorbar(gAxes, firstAxisVector, data, stdev)
                    else
                        plot(gAxes, firstAxisVector, data);
                    end
                    
                    xlabel(gAxes,bottomLabel);
                    ylabel(gAxes,leftLabel);
                case 2
                    % todo
                    imagesc(...
                        data, ...
                        'XData', firstAxisVector, ...
                        'YData', secondAxisOptionalVector, ...
                        'Parent', gAxes);
                    xlabel(gAxes,bottomLabel);
                    ylabel(gAxes,leftLabel);
                    axis(gAxes, 'xy', 'tight', 'normal')
                    axis(gAxes, 'manual')
                    c = colorbar('peer', gAxes, 'location', 'EastOutside');   % todo: peer is outdated
                    xlabel(c, 'kcps')
                otherwise
                    EventStation.anonymousWarning('Can''t understand and display %d-dimensional scan!', dimNumber);
                    return
            end
        end
    end
end

