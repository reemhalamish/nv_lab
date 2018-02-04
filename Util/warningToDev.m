function warningToDev( ME )
%ERRORTODEV gets MException, and sends warning, if we are in Debug mode

if JsonInfoReader.getJson.debugMode
    warning(ME.message)
end

end

