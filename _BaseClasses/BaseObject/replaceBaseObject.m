function oldObjOrNan = replaceBaseObject(newObj)
%REPLACEOBJECT Finds and replaces old object of same type as new object
%   Recieves object to be "pushed" into the base object map
%   (BaseObject.allObjects). If such an object already exists, it "pops" it
%   out; otherwise, it returns NaN.
%
%   This function unifies the function of "removeObjIfExists" and
%   "addBaseObj", so that they are (as far as I know) redundant

% Find and remove previous object
name = newObj.NAME;
try
    baseObj = getObjByName(name);
    BaseObject.removeObject(baseObj);
    oldObjOrNan = baseObj;
catch
    % Don't remove anything as error indicates that it was not there in the first place
    oldObjOrNan = nan;
end
BaseObject.addObject(newObj);

end

