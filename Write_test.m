address = '192.168.87.134' 
port = 502 %port typically 502 for Modbus
ModBusTCP = openConnection(address, port); %open the connection
message = prepareWritingMessage(int32(33), 1);

writeModBus(ModBusTCP, message);
disp('message sent')
fclose(ModBusTCP);


%customized functions
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
            disp('- Whether the Yaskawa controller is turned on.');
            disp('- Your firewall settings');
        end
    end
end
    
function message = prepareWritingMessage(value, registry )
    %the message has to be in the following int8 form:
    %0000  0000    000c     00      10      0001 0002 04           d636 603d 
    %tr_id prot_id len(=17) unit_id fc(=16) addr reg# byteToFollow lsb   msb  
    
    transID=int8(0);%8 bits transaction identifier
    ProtID=int8(0);%8 bits protocol id
    Lenght =int8(11); % 8bits Remaining bytes 
    UnitID = int8(1); % Unit ID (1)
    FunCod = int8(16); % Function code to write register 
	%Function code 16= write multipple registry 
	%Function code 6 = write single registry
    Address_offset =int8(registry); % 16b Adress of the register
    reg_number = int8(2);%number of register to read
    byteToFollow = int8(4);%bytes that will follow 
    data = typecast(value, 'int8');% 4x8bit data: the order of each 2 bytes has to be reversed

    message = [int8(0); transID;int8(0);ProtID; int8(0);Lenght; UnitID; FunCod; int8(0); Address_offset;int8(0);reg_number;byteToFollow; data(2); data(1); data(4); data(3)];
end


function result = writeModBus(ModBusTCP, message)
    % Write the message
    fwrite(ModBusTCP, message,'int8');

    % check if the message is received correctly
    while ~ModBusTCP.BytesAvailable
        % wait for the response to be in the buffer
    end
    result = fread(ModBusTCP,ModBusTCP.BytesAvailable); %get received bytes
  
    %% check the function code and display error
    if result(8) >= 128 % function code error
        % There is an error on the communication the function code is byte 8
        % in the received message. PLC adds some numbers (e.g. 128) to the function code to say
        % an error occured. The next field (9) contains the error code.
        err = result(9);
        disp(['Communication error. The controller responds with error code: ', num2str(err)]);
    end
end
