function errorToDev( ME )
%ERRORTODEV gets MException, and sends warning, if we are in Debug mode

if JsonInfoReader.getJson.debugMode
    throwAsCaller(ME)
end

end

