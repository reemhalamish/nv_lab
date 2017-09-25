%% Instrument Connection
format long

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
% Connect to instrument object, obj1.
fopen(obj1);

t1=ones(1,100);
t2= ones(1,100);
t3= ones(1,100);
t4= ones(1,100);
t5= ones(1,100);
data1= ones(1,100);
data2= ones(1,100);
data3= ones(1,100);
data4= ones(1,100);
data5= ones(1,100);

tic
a=0;


for n= 1:100
   
    
    % Communicating with instrument object, obj1.
    fprintf(obj1, 'press');
data1(n) = str2double(fscanf(obj1));
t1(n) = datenum(datetime('now'));
fprintf(obj1, 'wave,air');
data2(n) = str2double(fscanf(obj1));
t2(n) = (datenum(datetime('now')));
fprintf(obj1, 'wave,vac');
data3(n) = str2double(fscanf(obj1));
t3(n) = datenum(datetime('now'));
fprintf(obj1, 'wave,thz');
data4(n) = str2double(fscanf(obj1));
t4(n) = datenum(datetime('now'));
fprintf(obj1, 'wave,nun');
data5(n)= str2double(fscanf(obj1));
t5(n) = datenum(datetime('now'));
    a = a+1;
disp('this is check num:'), disp(a);
disp ('press,time calculated');
disp(data1(n));
disp(t1(n));
disp ('wave in air,time calculated');
disp(data2(n));
disp(t2(n));
disp('wave in vac,time calculated')
disp(data3(n));
disp(t3(n));
disp( 'wave in thz,time calculated')
disp(data4(n));
disp(t4(n));
disp('wave in nun,time calculated')
disp(data5(n));
disp(t5(n));
toc
end
t1min=min(t1);
t2min=min(t2);
t3min=min(t3);
t4min=min(t4);
t5min=min(t5);
t1fix = t1-t1min;
t2fix = t2-t2min;
t3fix = t3-t3min;
t4fix = t4-t4min;
t5fix = t5-t5min;
for i=1:10
plot((t1fix),(data1));
xlabel('time in sec');
ylabel('press');
pause(3)
plot((t2fix),(data2));
xlabel('time in sec');
ylabel('wave in air');
pause(3)
plot((t3fix),(data3));
xlabel('time in sec');
ylabel('wave in vac');
pause(3)
plot((t4fix),(data4));
xlabel('time in sec')
ylabel('wave in thz')
pause(3)
end