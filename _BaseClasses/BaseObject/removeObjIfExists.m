function baseObjOrNan = removeObjIfExists(baseObjName)
%REMOVEOBJIFEXISTS Removes a base object if it exists
    try
        baseObj = getObjByName(baseObjName);
        BaseObject.removeObject(baseObj);
        baseObjOrNan = baseObj;
    catch
        % Don't remove anything as error indicates that it was not there in the first place
        baseObjOrNan = nan;
    end
end

