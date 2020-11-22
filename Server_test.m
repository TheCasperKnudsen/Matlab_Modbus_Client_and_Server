h DataBase = uint16([111,222,333,444])
while 1
    ModBusTCP = openConnection('192.168.87.119', 502)
    while ~ModBusTCP.BytesAvailable
        %wait for the response to be in the buffer
    end
   DataBase = handleRequest(ModBusTCP,DataBase)
   fclose(ModBusTCP);
end

function ModBusTCP = openConnection(ipaddress, port)
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

function UpdatedDataBase = handleRequest(ModBusTCP,DataBaseHolding)
    % Read MBAP
    TransID = uint16(fread(ModBusTCP, 1, 'uint16'));
    ProtID  = uint16(fread(ModBusTCP, 1, 'uint16'));
    Lenght  = uint16(fread(ModBusTCP, 1, 'uint16'));
    UnitID  = uint8(fread(ModBusTCP, 1, 'uint8'));
    
    %Handle PDU
    FunCod  = uint8(fread(ModBusTCP, 1, 'uint8'));
    switch FunCod
        case 4
            disp('Read Input Registers'); 
            
            UpdatedDataBase = DataBase;
            return
        case 3
            %Read command
            StartingAdress      = uint16(fread(ModBusTCP, 1, 'uint16'));
            NumberOfRegisters   = uint16(fread(ModBusTCP, 1, 'uint16'));
            
            %Check if registers are available
            if IsExceeded(StartingAdress,NumberOfRegisters,DataBaseHolding)
                %Build PDU
                PDU = uint8(131); %Error cod: 0x83
                PDU = [PDU; uint8(2)]; % Exception code: ILLEGAL DATA ADDRESS
                
                %Build MBAP
                Lenght = int16(ModbusHeaderLenght + 16);
                MBAP = [TransID; ProtID; Lenght; UnitID];
                disp('Read Multiple Holding Registers - ERROR');                
            
            else
                %Build PDU
                NumberOfDataBytes = uint8(NumberOfRegisters*2);
                PDU = [FunCod; NumberOfDataBytes];
                for Index = 0:1:NumberOfRegisters-1
                    Data = typecast(swapbytes(DataBaseHolding(StartingAdress+Index)),'uint8')';                    
                    PDU = [PDU; Data];
                end
                
                %Build MBAP
                PDULenght = ByteSizeInt(FunCod)...
                    + ByteSizeInt(NumberOfDataBytes)...
                    + NumberOfDataBytes;
                Lenght = int16(ByteSizeInt(UnitID) + PDULenght);
                MBAP = [TransID; ProtID; Lenght; UnitID];
                
                disp('Read Multiple Holding Registers');    
            end
            
            %Send Message
            MBAP = PrepMBAP(MBAP);  %Arrange to little Endian
            Message = [MBAP; PDU];
            fwrite(ModBusTCP, Message,'uint8');
            UpdatedDataBase = DataBaseHolding; 
            return
        case 6
            
            
            disp('Wrote Single Holding Register');
            
            return
        case 16
            
            disp('Wrote Multiple Holding Registers');            
            return 
        otherwise % Not tested
            FunCodResponce = int16(-2);
            Lenght = int16(ModbusHeaderLenght + ByteSizeInt(FunCodResponce));
            
            MBAP = [transID; ProtID; Lenght; UnitID];
            PDU = [FunCod];
            Message = [MBAP,PDU];
            
            fwrite(ModBusTCP, Message,'int8');
            UpdatedDataBase = DataBaseHolding;
            
            disp('Recived bad Request');
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

function bool =IsExceeded(StartingIndex,Number,Array)
    Size = length(Array);
    bool = StartingIndex + Number -1 > Size;
    return
end

function PrepedMBAP = PrepMBAP(Message)
    TransID = typecast(swapbytes(Message(1)),'uint8')';
    ProtID  = typecast(swapbytes(Message(2)),'uint8')';
    Lenght  = typecast(swapbytes(Message(3)),'uint8')';
    UnitID = Message(4);
    PrepedMBAP = [TransID; ProtID; Lenght; UnitID];
end
% ========== Constants ========== 
function ans = ModbusHeaderLenght
    % As the header is [transID; ProtID; Lenght; UnitID]
    % The defined length is 7*8bit
    ans = 2;
end