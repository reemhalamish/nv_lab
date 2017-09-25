%% Instrument Connection

% Find a tcpip object.
obj1 = instrfind('Type', 'tcpip', 'RemoteHost', '132.64.56.146', 'RemotePort', 7802, 'Tag', '');

% Create the tcpip object if it does not exist
% otherwise use the object that was found.
if isempty(obj1)
    obj1 = tcpip('132.64.56.146', 7802);
else
    fclose(obj1);
    obj1 = obj1(1);
end

% Configure instrument object, obj1.
set(obj1, 'Name', 'TCPIP-132.64.56.146');
set(obj1, 'RemoteHost', '132.64.56.146');

%% Instrument Connection

% Connect to instrument object, obj1.
fopen(obj1);

%% Instrument Configuration and Control

% Communicating with instrument object, obj1.
fprintf(obj1, 'set,row,u16');
data1 = fscanf(obj1);