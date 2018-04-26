function expObj = getExpByName(searchedName)
%GETEXPBYNAME Returns the experiment object, if its name is the same as
%expName, otherwise... (for now, throws exception/error)

msgNoExp = 'No experiment is currently running!';
msgNotCurrent = '"%s" is not the current experiment! Running now %s';

currentExp = getObjByName(Experiment.NAME);
if isempty(currentExp.expName)
    ME = MException(Experiment.EXCEPTION_ID_NO_EXPERIMENT, msgNoExp);
    throw(ME);
elseif strcmp(currentExp.expName, searchedName)
    expObj = currentExp;
else
    ME = MException(Experiment.EXCEPTION_ID_NOT_CURRENT, msgNotCurrent, searchedName, currentExp.expName);
    throw(ME);
end

end

