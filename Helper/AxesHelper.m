classdef AxesHelper
    %AXESHELPER Handles all plotting technicalities, with some added
    %options
    
    properties (Constant)
        DEFAULT_X = 0;
        DEFAULT_Y = NaN;
    end
    
    methods (Static)
        function fill(gAxes, data, dimNumber, firstAxisVector, secondAxisOptionalVector, bottomLabel, leftLabel, stdev)
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
            
            if ~any(dimNumber == [1,2])
                EventStation.anonymousWarning('Can''t understand and display %d-dimensional scan!', dimNumber);
                return
            end
            
            % We want to clear the slate
            gAxes.NextPlot = 'replace';
            if ~exist('stdev', 'var'); stdev = []; end
            
            % Plot and add labels
            AxesHelper.update(gAxes, data, dimNumber, firstAxisVector, secondAxisOptionalVector, stdev);
            xlabel(gAxes, bottomLabel);
            ylabel(gAxes, leftLabel);
            
            % 2D needs some special attention 
            if dimNumber == 2
                axis(gAxes, 'xy', 'tight', 'normal')
                axis(gAxes, 'manual')
                c = colorbar(gAxes, 'location', 'EastOutside');
                xlabel(c, 'kcps')
            end
            
            % Next plots should only change the lines/image in the plot
            gAxes.NextPlot = 'replacechildren';
            
        end
        
        function update(gAxes, data, dimNumber, firstAxisVector, secondAxisOptionalVector, stdev)
            switch dimNumber
                case 1
                    if exist('stdev','var') && length(data)==length(stdev)
                        errorbar(gAxes, firstAxisVector, data, stdev)
                    else
                        plot(gAxes, firstAxisVector, data);
                    end
                case 2                    
                    % todo: add more data to image (e.g. std)                    
                    imagesc(...
                        data,...
                        'Parent', gAxes, ...
                        'XData', firstAxisVector, ...
                        'YData', secondAxisOptionalVector...
                        );
                    
                otherwise
                    EventStation.anonymousWarning('Can''t understand and display %d-dimensional scan!', dimNumber);
                    return
            end
        end
        
        function clear(gAxes)
            % Clears the (graphic) axes by "filling" with nothing
            AxesHelper.fill(gAxes, obj.DEFAULT_Y, 1, obj.DEFAULT_X, [], '', '')
        end
        
        function gNewAxes = addAxisAcross(gAxes, axisLetter, ticks, label)
            % Adds an axis over given axis, with different ticks (or tick
            % labels, to the very least) and maybe a label
            %
            % gAxes - axes handle. The new ticks will be at the top of these axes.
            % axisLetter - either 'x' (for horizontal axis) or 'y' (for
            %              vertical axis).
            % ticks - two options
            %         1. vector of doubles - requested ticks;
            %         2. function handle - transformation of the
            %            original axis.
            % label - label for the new axis.
            %
            % Returns:
            %   gNewAxes - handle to axes created by this function
            %
            %
            % Inspired by AddTopAxis() on MathWorks FileExchange
            %	Author : Emmanuel P. Dinnat
            %	Date : 09/2005
            %	Contact: emmanueldinnat@yahoo.fr
            
            % Create new axis from old one
            if ~ishandle(gAxes)
                error('Graphical axes handle is invalid!')
            end
            
            gNewAxes = axes('Position', gAxes.Position, ... position of first axes
                'XAxisLocation', 'top', ...
                'YAxisLocation','right');
            
            % Select NumericRuler (either X or Y)
            switch lower(axisLetter)
                case 'x'
                    oldRuler = gAxes.XAxis;
                    newRuler = gNewAxes.XAxis;
                    % + Remove Y ticks
                    set(gNewAxes, 'yTickLabel', []);
                case 'y'
                    oldRuler = gAxes.YAxis;
                    newRuler = gNewAxes.YAxis;
                    % + Remove X ticks
                    set(gNewAxes, 'xTickLabel', []);
            end
            
            % Create appropriate tick labels
            switch class(newTicks)
                case {'double', 'cell'}
                    tickLen = length(ticks);
                    lim = oldRuler.Limits;
                    newRuler.TickValues = linspace(lim(1), lim(2), tickLen);
                    newRuler.TickLabels = ticks;
                    
                case 'function_handle'
                    tick_fun = ticks;
                    newAxisTicks = tick_fun(oldRuler.TickValues);
                    newRuler.TickLabels = num2str(newAxisTicks);
            end
            
            % Add label (if needed)
            if exist('label', 'var')
                newRuler.Label = label;
            end
            
            % We return gNewAxes, which were changed when we changed their
            % child NumericRuler
        end
    end
end

