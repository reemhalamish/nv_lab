function expObj = getExpByName(searchedName)
%GETEXPBYNAME Returns the experiment object, if its name is the same as
%expName, otherwise... (for now, throws exception/error)

msgNoExp = 'No experiment is currently running!';
msgNotCurrent = '"%s" is not the experiment currently running!';

try
    obj = getObjByName(Experiment.NAME);
catch
    ME = MException(Experiment.EXCEPTION_ID_NO_EXPERIMENT, msgNoExp);
    throw(ME);
end

if strcmp(obj.expName,searchedName)
    expObj = obj;
else
    ME = MException(Experiment.EXCEPTION_ID_NOT_CURRENT, msgNotCurrent, obj);
    throw(ME);
end

end

