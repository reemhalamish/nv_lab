classdef BaseObject < HiddenMethodsHandle & PropertiesDisplaySorted
    %BASEOBJECT an object which has a name
    %   objects of type BaseObject can be identified by their name, so they
    %   would be able to perform well when book-keeping is needed. Because
    %   of that, all the "interesting" classes (like e.g. EventSender or
    %   Savable) derive from BaseObject.
    %   
    %   this class has a static vector of BaseObjects that someone thought
    %   they would be nice to have around. adding an object to this vector
    %   would be via calling addBaseObject() --> an Exception will be thrown if an object is in with the same name
    %   removing a BaseObject from the vector is done via removeBaseObject().
    %   querying (getting) objects from the vector is done via the function
    %   getObjByName(string), which will return the BaseObject or throw an
    %   exception if no BaseObject was found
    %
    %   this class extends CustomDisplay so that properties could look
    %   better and readable
    
    properties
        name  % this is the way you are recognized in the events system - by your name! vector of chars
    end
    
    methods
        function obj = BaseObject(name)
            % name - the object name
            obj@HiddenMethodsHandle;
            obj@PropertiesDisplaySorted;
            obj.name = name; 
        end
        
        function set.name(obj, newName)
            if isempty(obj.name)
                obj.name = newName;
                return
            end
            
            if ~strcmp(obj.name, newName)
                error('can''t set BaseObject with different names! that would bring you TROUBLES!\nprevious name: "%s", current name: "%s"',...
                    obj.name, ...
                    newName);
            end
        end
                
        function delete(obj)
            BaseObject.removeObject(obj);
        end
        
    end
    
    methods(Static = true, Hidden = true)
        function baseObject = getByName(objName)
            % searches and returns an object based on his "name" property
            % can error() if not such object has been found
            % although this function is accessable from anywhere in the
            % code, i tis hidden so that it won't auto-complete in every
            % object inheriting from BaseObject. call "getObjByName(name)"
            % instead, as it's a wrapper function for "BaseObject.getByName(name)"
            allBaseObjects = BaseObject.getAllObjects.cells;
            find = cellfun(@(x) strcmp(x.name, objName), allBaseObjects);
            if ~any(find)
                error('no such object (with name "%s") exists!', objName)
            end
            assert(sum(find) == 1); % found only one object
            baseObject = allBaseObjects{find};
        end
        
        function addObject(baseObject)
            allBaseObjects = BaseObject.getAllObjects;
            
            objectsSameName = cellfun(@(x) strcmp(x.name, baseObject.name), allBaseObjects.cells);
            if any(objectsSameName)
                % so apparently an object with this name exist.
                % probably it's an error, but maybe it's the same object
                % being constructed twice (it can happen with diamond
                % inheritance. for example if something inherit both
                % "Savable" and "EventSender", both inherit from
                % "BaseObject". we need to check this
                if allBaseObjects.cells{objectsSameName} == baseObject
                    % dismiss - same object constructed twice. not an error
                    return
                end
                EventStation.anonymousError('another object already exists with the same name! (name: "%s")', baseObject.name)
            end
            
            allBaseObjects.cells{end +1} = baseObject;
        end
        
        function removeObject(baseObjectOrObjName)
            if ischar(baseObjectOrObjName)
                nameToRemove = baseObjectOrObjName;
            else
                nameToRemove = baseObjectOrObjName.name;
            end
            
            allBaseObjects = BaseObject.getAllObjects;
            objectsToKeep = cellfun(@(x) ~strcmp(x.name, nameToRemove), allBaseObjects.cells);
            allBaseObjects.cells = allBaseObjects.cells(objectsToKeep);
        end
    end
    
    methods(Static = true, Access = public)
        function allBaseObjects = getAllObjects()
            persistent allObjects
            if isempty(allObjects) || ~isvalid(allObjects)
                allObjects = CellContainer;
            end
            allBaseObjects = allObjects;
        end
    end
end