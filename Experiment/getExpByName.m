function expObj = getExpByName(searchedName)
%GETEXPBYNAME Returns the experiment object, if its name is the same as
%EXP_NAME, otherwise... (for now, throws exception/error)

msgNoExp = 'No experiment is currently running!';
msgNotCurrent = '"%s" is not the current experiment! Running now %s';

currentExp = getObjByName(Experiment.NAME);
if isempty(currentExp.EXP_NAME)
    ME = MException(Experiment.EXCEPTION_ID_NO_EXPERIMENT, msgNoExp);
    throw(ME);
elseif strcmp(currentExp.EXP_NAME, searchedName)
    expObj = currentExp;
else
    ME = MException(Experiment.EXCEPTION_ID_NOT_CURRENT, msgNotCurrent, searchedName, currentExp.EXP_NAME);
    throw(ME);
end

end

