DataBaseHolding = uint16([111,222,333,444])
DataBaseInput = uint16([11,22,33,44])
DataBaseCoils = logical(0)

while 1
    ModBusTCP = openConnectionServer('192.168.100.123', 502)
    while ~ModBusTCP.BytesAvailable
        %wait for the response to be in the buffer
    end
   [DataBaseInput,DataBaseHolding] = handleRequest(ModBusTCP,DataBaseInput,DataBaseHolding,DataBaseCoils);
   
   fclose(ModBusTCP);
   break
end

function ModBusTCP = openConnectionServer(ipaddress, port)
    ModBusTCP=tcpip(ipaddress, port,'NetworkRole', 'Server'); %Create the tcpip obeject
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

function [UpdatedDataInput,UpdatedDataBaseHolding,UpdatedCoils] = handleRequest(ModBusTCP,DataBaseInput,DataBaseHolding,DataBaseCoils)
    UpdatedDataBaseHolding = DataBaseHolding; % In case Holding is not written
    UpdatedDataInput = DataBaseInput; % Input cannot be written
    UpdatedCoils = DataBaseCoils;     % Coils cannot be written  
    
    % Read MBAP
    TransID     = fread16Bit(ModBusTCP);
    ProtID      = fread16Bit(ModBusTCP);
    Length      = fread16Bit(ModBusTCP);
    UnitID      = fread8Bit(ModBusTCP);
    
    %Handle PDU
    FunCod  = fread8Bit(ModBusTCP);
    switch FunCod
        
        case 4 % Read Multiple Input Registers
            StartingAdress          = fread16Bit(ModBusTCP);
            NumberOfRegisters       = fread16Bit(ModBusTCP);
            Message = HandleFunctionCode3(TransID,ProtID,Length,UnitID,FunCod,StartingAdress,NumberOfRegisters,DataBaseInput);
            
            fwrite(ModBusTCP, Message,'uint8');
            return
            
        case 3 % Read Multiple Holding Registers
            StartingAdress          = fread16Bit(ModBusTCP);
            NumberOfRegisters       = fread16Bit(ModBusTCP);
            Message = HandleFunctionCode3(TransID,ProtID,Length,UnitID,FunCod,StartingAdress,NumberOfRegisters,DataBaseHolding);
            
            fwrite(ModBusTCP, Message,'uint8');
            UpdatedDataBaseHolding = DataBaseHolding; 
            return
            
        case 6 % Write Single Register
            RegisterAdress          = fread16Bit(ModBusTCP);
            RecivedData             = fread16Bit(ModBusTCP);
            [Message,DataBaseHolding] = HandleFunctionCode6(TransID,ProtID,Length,UnitID,FunCod,RegisterAdress,RecivedData,DataBaseHolding);
            
            fwrite(ModBusTCP, Message,'uint8');
            UpdatedDataBaseHolding = DataBaseHolding; 
            return
            
        case 16 % Write Multiple Registers
            StartingAdress          = fread16Bit(ModBusTCP);
            NumberOfRegisters       = fread16Bit(ModBusTCP);
            ByteCount               = fread8Bit(ModBusTCP);
            RecivedData = uint16(zeros(NumberOfRegisters,1));
            for index = 1:1:NumberOfRegisters
                %Recives Little endian data
                RecivedData(index) = fread16Bit(ModBusTCP);
            end
            
            [Message,DataBaseHolding] = HandleFunctionCode16(TransID,ProtID,Length,UnitID,FunCod,StartingAdress,NumberOfRegisters,RecivedData,DataBaseHolding);
            fwrite(ModBusTCP, Message,'uint8');
            UpdatedDataBaseHolding = DataBaseHolding; 
            return
            
        otherwise % Not tested
            disp('Recived bad Request');
            return
    end
end
