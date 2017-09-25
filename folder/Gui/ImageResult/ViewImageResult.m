classdef ViewImageResult < ViewVBox
    %VIEWSTAGESCAN Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        vHeader % the options view
        vImage  % the image view
    end
    
    methods
        function obj = ViewImageResult(parent, controller)
            obj@ViewVBox(parent, controller);
            obj.vHeader = ViewImageResultHeader(obj, controller);
            obj.vImage = ViewImageResultImage(obj, controller);
            
            obj.height = obj.vHeader.height + obj.vImage.height + 10;
            obj.width = max([obj.vHeader.width, obj.vImage.width]) + 10;
            
            obj.setHeights([obj.vHeader.height, -1]);
        end
    end
    
    methods(Static = true)
        % get the axes() in the GUI figure
        function axesFig = getAxes
            view = getObjByName(ViewImageResultImage.NAME);
            axesFig = view.vAxes;
        end
    end
end

