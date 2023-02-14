function displayobjCalibration(inbytes,handles)
% Function that captures images while the LEDs are illuminating with the
% calibration sequence on white paper. Reads from the FPGA to determine
% which frames are which.
global fullimage w h lock FPGA previousin previousimg ZeroCal RedOn RedOff RedZero GreenOn GreenOff GreenZero BlueOn BlueOff BlueZero RedOnimg RedOffimg RedZeroimg GreenOnimg GreenOffimg GreenZeroimg BlueOnimg BlueOffimg BlueZeroimg

hbytes = double(inbytes.GetImageData.GetRawPixels1Byte); % Saves the frame that was already read in as hbytes. This can be read in as processed data as well (search through the .dll files with dotPeek)
img = reshape(hbytes(), [w,h]).'; % Images being read in are 1x62500 so they must be reshaped into squares before being displayed
different = find(img ~= previousimg); % This finds how many pixels have changed in value from the last image read in

if (size(different,1) > 59000) % If the difference between the frames is greater than 58500 we are confident that it is indeed a different frame

    previousimg = img; % Then we save this new as the previousimg for next time
   
    while true % This acts as a "do while" statement which then makes sure that the FPGA signal also changes
        input = readmemory(FPGA,16400,1);
        pause(0.0001); % This pause is necessary to keep the code from stalling
        if (input ~= previousin) % If they are different save the current input as the previousin for next time and move on
            previousin = input;
            break;
        end       
    end
    
    % Determines where to save each image depending on what the FPGA is
    % saying
    switch input
        case 0 % All leds off
        ZeroCal = hbytes; % This is not used anywhere but could be if a background measurement was taken to subract off from each image
        case 2 % Red on
            if ((size(find(hbytes ~= RedOff),2) < 59000) || (size(find(hbytes ~= BlueZero),2) < 59000)) % Each transition will have a different number of differing pixels so each surrounding step is checked against individually for higher stability
                pause(0.001);
            else
            RedOn = hbytes; % If this is for sure what we captured, save the respective matrices
            RedOnimg = img;
            end
        case 3 % Red off
            if ((size(find(hbytes ~= RedOn),2) < 59000) || (size(find(hbytes ~= RedZero),2) < 59000))
                pause(0.001);
            else
            RedOff = hbytes;
            RedOffimg = img;
            end
        case 4 % Red staying off
            if ((size(find(hbytes ~= RedOff),2) < 59000) || (size(find(hbytes ~= GreenOn),2) < 59000))
                pause(0.001);
            else
            RedZero = hbytes;
            RedZeroimg = img;
            end
        case 5 % Green on
            if ((size(find(hbytes ~= RedZero),2) < 59000) || (size(find(hbytes ~= GreenOff),2) < 59000))
                pause(0.001);
            else
            GreenOn = hbytes;
            GreenOnimg = img;
            end
        case 6 % Green off
            if ((size(find(hbytes ~= GreenOn),2) < 59000) || (size(find(hbytes ~= GreenZero),2) < 59000))
                pause(0.001);
            else
            GreenOff = hbytes;
            GreenOffimg = img;
            end
        case 7 % Green staying off
            if ((size(find(hbytes ~= GreenOff),2) < 59000) || (size(find(hbytes ~= BlueOn),2) < 59000))
                pause(0.001);
            else
            GreenZero = hbytes;
            GreenZeroimg = img;
            end
        case 8 % Blue on
            if ((size(find(hbytes ~= GreenZero),2) < 59000) || (size(find(hbytes ~= BlueOff),2) < 59000))
                pause(0.001);
            else
            BlueOn = hbytes;
            BlueOnimg = img;
            end
        case 9 % Blue off
            if ((size(find(hbytes ~= BlueOn),2) < 59000) || (size(find(hbytes ~= BlueZero),2) < 59000))
                pause(0.001);
            else
            BlueOff = hbytes;
            BlueOffimg = img;
            end
        case 1 % Blue staying off
            if ((size(find(hbytes ~= BlueOff),2) < 59000) || (size(find(hbytes ~= RedOn),2) < 59000))
                pause(0.001);
            else
            BlueZero = hbytes;
            BlueZeroimg = img;
            end
        case 13 % Error in FPGA code
        disp("Error in FPGA code");
        otherwise
        disp("Not in calibration mode");
    end    
    

    set(handles.image,'CData',img); % These change the displayed image on the GUI
    fullimage = img;

    % This is for the histogram
    if lock == 3
        setgraph(handles,handles.axes2);
    else
    end
    
else
    pause(0.0001); % If the frames are the same wait a tiny bit and check again
end
end