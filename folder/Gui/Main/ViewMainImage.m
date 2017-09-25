classdef ViewMainImage < ViewVBox
    %VIEWMAIN the main window
    %   is cunstructed from a vertical box with 2 elements: 
    %     *  top erea is for the 3 columns (via horizontal box), 
    %     *  bottom erea is for the error messages. 
    %
    %   notice that obj.component is a vertical box!
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        % constructor - parent of a main view is the figure itself!
        function obj = ViewMainImage(parent, controller)
            obj@ViewVBox(parent, controller);
            
            % create a new position for the lasers
            mainView = ViewHBox(obj, controller);
            column1 = ViewContainerStage(mainView, controller);
            column2 = ViewImageResult(mainView, controller);
            column3 = ViewVBox(mainView, controller);
            column3.component.Spacing = 5;
            column3.component.Padding = 5;
            
            viewLaserContainer = ViewLasersContainer(column3, controller);
            
            viewSaveLoad = ViewSaveLoad(column3, controller, Savable.CATEGORY_IMAGE);
            column3.setHeights([viewLaserContainer.height, viewSaveLoad.height]);
            column3width = max(viewLaserContainer.width, viewSaveLoad.width);

            columnsWidths = [column1.width, column2.width, column3width];
            mainView.component.Widths = [column1.width, -1, column3width];
            errorView = ViewError(obj, controller);
            column3height = viewSaveLoad.height + viewLaserContainer.height + 10;
            maximumColumnsHeight = max([column1.height, column2.height, column3height]);
            obj.component.Heights = [-1, errorView.height];
            
            minWidth = max([errorView.width, sum(columnsWidths)]) + 20;
            minHeight = errorView.height + maximumColumnsHeight;
            
            obj.width = minWidth;
            obj.height = minHeight;
        end      
    end
    
end

