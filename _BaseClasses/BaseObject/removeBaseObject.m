function removeBaseObject( baseObject)
%REMOVEBASEOBJECT calls BaseObject.removeObject, so there will be an auto-complete typing for removing objects
%   won't throw any exception onceoever. Silently ignores calls to remove
%   object that weren't there in the first place
BaseObject.removeObject(baseObject);
end
