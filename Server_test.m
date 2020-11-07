
ModBusTCP = openConnection(ipaddress, port)
while 1
    while ~ModBusTCP.BytesAvailable
        % wait for the response to be in the buffer
    end
   requestInfo = handleRequest(ModBusTCP,DataBase)
end

function ModBusTCP = openConnection(ipaddress, port)
    ModBusTCP=tcpip(ipaddress, port); %Create the tcpip obeject
    set(ModBusTCP, 'InputBufferSize', 512); %assign the buffer
    ModBusTCP.ByteOrder='bigEndian'; %specify the order in which bytes are transmitted
    try 
        if ~strcmp(ModBusTCP.Status,'open') 
            fopen(ModBusTCP);
            disp(['TCP/IP connection opened with host:', ipaddress]);
        end
    catch fault % display error if the channel is not opened.
        if ~strcmp(ModBusTCP.Status,'open') % check if the channel is really closed
            disp(fault);
            disp(['Error: Can''t establish TCP/IP connection with: ',ipaddress,':',num2str(port)] ); 
            disp('You can check the following:');
            disp('- If the cable is plugged in correctly ');
            disp('- Whether the Codesys controller is turned on.');
            disp('- Your firewall settings');
        end
    end
end

function [FunCod,AddressOffset,RegNumber] = handleRequest(ModBusTCP,DataBase)
    % check if the message is received correctly
    TransID = fread(ModBusTCP,1, 'int16');
    ProtID =  fread(ModBusTCP,1, 'int16');
    Lenght =  fread(ModBusTCP,1, 'int16');
    
    UnitID = fread(ModBusTCP,1, 'int8');
    if UnitID != SlaveID
        FunCod = -1
        return
    end
    FunCod = fread(ModBusTCP,1, 'int8');
    AddressOffset = fread(ModBusTCP,1, 'int16');
    RegNumber = fread(ModBusTCP,1, 'int16');
   
    switch FunCod
        case 4
            disp('Read Input Registers'); 
            return
        case 3
            disp('Read Multiple Holding Registers'); 
            return
        case 6
            disp('Write Single Holding Register'); 
            return
        case 16
            disp('Write Multiple Holding Registers'); 
            return
        otherwise
            FunCod = -2
    end
end