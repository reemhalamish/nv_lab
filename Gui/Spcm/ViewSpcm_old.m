classdef ViewSpcm_old < ViewVBox
    %VIEWSPCM view for the SPCM counter
    %   
    
    properties
        vPlottingArea
        vControls
    end
    
    methods
        function obj = ViewSpcm_old(parent, controller)
            padding = 5;
            obj@ViewVBox(parent, controller, padding);
            
            obj.vPlottingArea = ViewSpcmPlot(obj,controller);
            obj.vControls = ViewSpcmControls(obj,controller);
            
            obj.height = obj.vPlottingArea.height + obj.vControls.height + 10;
            obj.width = max([obj.vPlottingArea.width, obj.vControls.width]) + 10;
            
            obj.setHeights([-1, obj.vControls.height]);
        end
    end
    
end

