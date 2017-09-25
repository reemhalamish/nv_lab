classdef AxesHelper
    %AXESHELPER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods(Static = true)
        function fillAxes(axesFig, data, dimNumber, firstAxisVector, secondAxisOptionalVector, bottomLabel, leftLabel)
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
                        plot(axesFig, firstAxisVector, data);
                        xlabel(bottomLabel);
                        ylabel(leftLabel);
                    case 2
                        % todo
                        imagesc(...
                            data, ...
                            'XData', firstAxisVector, ...
                            'YData', secondAxisOptionalVector, ...
                            'Parent', axesFig);
                        xlabel(bottomLabel);
                        ylabel(leftLabel);
                        axis xy tight normal
                        axis manual
                        c = colorbar('peer', axesFig, 'location', 'EastOutside');
                        xlabel(c, 'kcps')
                    otherwise
                        EventStation.anonymousWarning('can''t understand and display scan with %s dimension numbers!', dimNumber);
                        return
            end
        end
        
        function newInvisFigure = copyAxes(axesFig)
            % copy the axes() object into a new figure
            newInvisFigure = figure('Visible', 'off');
            copyobj([axesFig colorbar(axesFig)], newInvisFigure);
        end
    end
end

