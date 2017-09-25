function baseObjOrNan = removeObjIfExists(baseObjName)
%REMOVEOBJIFEXISTS removes a base object if it exists
    try
        baseObj = getObjByName(baseObjName);
        removeBaseObject(baseObj);
        baseObjOrNan = baseObj;
    catch
        % don't remove anything as error indicates that it was not here in the first place
        baseObjOrNan = nan;
    end
end

