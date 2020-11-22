
address = '192.168.87.119' 
port = 502 %port typically 502 for Modbus
ModBusTCP = openConnection(address, port); %open the connection

message = prepareReadingMessage(1);
response = readFloating(ModBusTCP, message);  
fclose(ModBusTCP);

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


function message = prepareReadingMessage(registry)
    stationId = 1; %the station id on the slave we are referring to
    transID=uint16(0);
    FunCod =  int16(3); % Function code to read register (3)
    ProtID = int16(0); % 16b Protocol ID (0 for ModBus) 
    Lenght = int16(6); % 16b Remaining bytes (24) 
    UnitID = int16(256*stationId); % Unit ID (1)
    %UnitID = bitshift(UnitID,8); 
    UnitIDFunCod = bitor(FunCod,UnitID); 
    % Concatenation of UnitID & FunctionCode 
    % in one uint16 word
    % According to modbus protocol, UnitID and Function code are 8bit data. 
    % In order to maintain the same data tipe in vector "message", I converted 
    % each of them to uint16, and used "bitor" to create a uint16 word when 
    % the MSB is the UnitID and the LSB is the function code
    Address_offset = int16(registry); % 16b Adress of the register
    reg_number = int16(1);%number of register to read
    message = [transID; ProtID; Lenght; UnitIDFunCod; Address_offset;reg_number];
end

function response = readFloating(ModBusTCP, message)
    % Write the message
    fwrite(ModBusTCP, message,'int16');

    % check if the message is received correctly
    while ~ModBusTCP.BytesAvailable
        % wait for the response to be in the buffer
    end
      %response = fread(ModBusTCP,ModBusTCP.BytesAvailable); %get received bytes
    transId = fread(ModBusTCP,1, 'int16');
    protId =  fread(ModBusTCP,1, 'int16');
    len =  fread(ModBusTCP,1, 'int16');
    uidFC = fread(ModBusTCP,1, 'int16');
    bytesToFollow = fread(ModBusTCP,1, 'int8');
    reg_num = message(6); % Number of registers to read
    response = zeros(1,reg_num);
    for i=1:reg_num
        debug = fread(ModBusTCP,1, 'int16');
        response(i) = debug
    end
    
    disp(['Reading Value:',num2str(response)]); 
end