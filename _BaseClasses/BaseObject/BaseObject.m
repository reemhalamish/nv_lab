classdef BaseObject < HiddenMethodsHandle & PropertiesDisplaySorted
    %BASEOBJECT an object which has a name
    %   objects of type BaseObject can be identified by their name, so they
    %   would be able to perform well when book-keeping is needed. Because
    %   of that, all the "interesting" classes (like e.g. EventSender or
    %   Savable) derive from BaseObject.
    %   
    %   this class has a static map of BaseObjects that someone thought
    %   they would be nice to have around. Adding an object to this map
    %   would be via calling addBaseObject() --> an Exception will be
    %   thrown if an object is in with the same name.
    %   Removing a BaseObject from the map is done via removeBaseObject().
    %   Querying (getting) objects from the map is done via 
    %   getObjByName(string), which will return the BaseObject or throw an
    %   exception if no BaseObject was found
    %
    %   This class extends CustomDisplay so that properties could look
    %   better and readable
    
    properties
        name  % An object is recognized in the event system by its name only! vector of chars
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
                error('Can''t set BaseObject with different names! That will cause TROUBLE!\nPrevious name: "%s", current name: "%s"',...
                    obj.name, ...
                    newName);
            end
        end
                
        function delete(obj)
            BaseObject.removeObject(obj);
        end
        
    end
    
    methods(Static = true, Access = public, Hidden = true) % Change "public" in working copy!!!!!!
        function objectMap = allObjects
            persistent allObjectsMap
            if isempty(allObjectsMap)
                temp = containers.Map;
                allObjectsMap = HandleWrapper(temp); 
            end
            objectMap = allObjectsMap;
        end
        
        function baseObject = getByName(objName)
            % searches and returns an object based on his "name" property
            % can error() if not such object has been found
            % although this function is accessable from anywhere in the
            % code, i tis hidden so that it won't auto-complete in every
            % object inheriting from BaseObject. call "getObjByName(name)"
            % instead, as it's a wrapper function for "BaseObject.getByName(name)"
            allBaseObjects = BaseObject.allObjects.wrapped;

            if ~ischar(objName) && ~isstring(objName)
                error('Requested object name, %s, is invalid!', objName)
            elseif ~allBaseObjects.isKey(objName)
                error('No object named "%s" exists!', objName)
            end
            baseObject = allBaseObjects(objName);
            assert(length(baseObject) == 1); % found only one object
        end
        
        function addObject(baseObject)
            allBaseObjects = BaseObject.allObjects;
            objName = baseObject.name;
            if allBaseObjects.wrapped.isKey(objName)
                % so apparently an object with this name exist.
                % It's probably an error, but maybe it's the same object
                % being constructed twice (it can happen with diamond
                % inheritance. for example if something inherits both
                % "Savable" and "EventSender", both inherit from
                % "BaseObject". We need to check this
                if allBaseObjects.wrapped(objName) == baseObject
                    % Dismiss - same object constructed twice. Not an error
                    return
                end
                EventStation.anonymousError('Another object named "%s" already exists!', objName)
            end
            
            allBaseObjects.wrapped(objName) = baseObject;
        end
        
        function removeObject(baseObjectOrObjName)
            if ischar(baseObjectOrObjName)
                nameToRemove = baseObjectOrObjName;
            else
                nameToRemove = baseObjectOrObjName.name;
            end
            
            allBaseObjects = BaseObject.allObjects;
            if allBaseObjects.wrapped.isKey(nameToRemove)
                allBaseObjects.wrapped.remove(nameToRemove);
            end
        end
    end
    
%     methods(Static = true, Access = public)         % why public?
%         function objectMap = allObjects
%             persistent allObjectsMap
%             if isempty(allObjectsMap) || ~isvalid(allObjectsMap)
%                 allObjectsMap = containers.Map;
%             end
%             objectMap = HandleWrapper(allObjectsMap);
%         end
%     end
end
