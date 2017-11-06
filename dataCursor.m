classdef dataCursor < handle
    %DATACURSOR class for wrapping data cursor with options specified for
    %it
    
    properties
        fig
        cursor
    end
    
    methods
        function obj = dataCursor(fig)
        obj@handle;
        obj.fig = fig;        % todo: check if really needed
        obj.cursor = datacursormode(figure, ...
            'UpdateFcn', @obj.update);
        end
        
        %%%% Callback %%%%
        function update(obj)
            % triggered when new data tip is created
            
        end
    end
end

