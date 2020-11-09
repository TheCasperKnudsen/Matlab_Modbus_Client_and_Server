
ModBusTCP = openConnection(ipaddress, port)
while 1
    while ~ModBusTCP.BytesAvailable
        % wait for the response to be in the buffer
    end
   DataBase = handleRequest(ModBusTCP,DataBase)
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

function UpdatedDataBase = handleRequest(ModBusTCP,DataBase)
    % check if the message is received correctly
    TransID = fread(ModBusTCP,1, 'int16');
    ProtID =  fread(ModBusTCP,1, 'int16');
    Lenght =  fread(ModBusTCP,1, 'int16');
    UnitID = fread(ModBusTCP,1, 'int8');
    FunCod = fread(ModBusTCP,1, 'int8');
   
    switch FunCod
        case 4
            disp('Read Input Registers'); 
            
            UpdatedDataBase = DataBase;
            return
        case 3
            disp('Read Multiple Holding Registers'); 
            
            UpdatedDataBase = DataBase;
            return
        case 6
            disp('Wrote Single Holding Register'); 
            return
        case 16
            disp('Wrote Multiple Holding Registers');
            
            return 
        otherwise 5 % Not tested
            FunCodResponce = int16(-2);
            Length = int16(ModbusHeaderLenght + ByteSizeInt(FunCodResponce));
            message = [transID; ProtID; Lenght; UnitID; FunCod];
            fwrite(ModBusTCP, message,'int8');
            
            disp('Recived bad Request');
            UpdatedDataBase = DataBase;
            return
    end
end


% ========== Supporting functions ========== 
function bytes = ByteSizeInt(variable)
    string = class(variable);
    bitsString = extractAfter(string,"int");
    if isempty(bitsString)
        error('Input must be int or uint')
        return
    end
    bits = str2num(bitsString);
    bytes = bits/8;
end

% ========== Constants ========== 
function ans = ModbusHeaderLenght
    % As the header is [transID; ProtID; Lenght; UnitID]
    % The defined length is 7*8bit
    ans = 7;
end