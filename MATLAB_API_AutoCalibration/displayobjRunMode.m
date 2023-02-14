function displayobjRunMode(inbytes,handles)
% Function that reads in the camera's image lit with the normal run mode
% sequence and calculates the resulting color image, displaying it to the
% user.
global fullimage lock w h FPGA caliRed caliGreen caliBlue A B C frameOrder record v r g b Aimg Bimg Cimg input oldput previmg scalered scalegreen scaleblue

hbytes = double(inbytes.GetImageData.GetRawPixels1Byte); % Reads in the captured image where each pixel is one byte representing the raw value read in by the camera
img = reshape(hbytes(), [w,h]).';
different = find(img ~= previmg);

if (size(different,1) > 58500) % Same process as the calibration function, ensuring the image is different from the previous to reduce repeats

    previmg = img;
    
    % This is the same loop as in calibration to ensure the signal from the
    % FPGA also changes
    while true
        input = readmemory(FPGA,16400,1);
        pause(0.0001);
        if (input ~= oldput)
            oldput = input;
            break;
        end       
    end  

% Some other options we tried instead of the if statement at the top of this function

%if (isequal(img,previmg)) % The images are never exactly equal since the
%add listener function waits for a new image to be processed by the camera,
%however, even when the images have many different pixels they have barely
%changed and still represent the same stage in the LED illumination
%process. We are not sure what causes this to happen.

%if (abs(img-previmg) <= ( 0.08*max(abs(img),abs(previmg)) + eps))

%if (mean(img~=previmg) < 0.25)
%     pause(0.001);
% elseif (size(different,1) >= 10000)
%    previmg = img;


    switch input
        case 10 %Blue off, red on
            if ((size(find(hbytes ~= B),2) < 57500) || (size(find(hbytes ~= C),2) < 57500)) % Same idea as in the calibration mode, checking both frames surrounding the current frame
                pause(0.001);
            else
            A = hbytes;
            Aimg = img;
            end
        case 11 %red off, green on
            if ((size(find(hbytes ~= A),2) < 57500) || (size(find(hbytes ~= C),2) < 57500))
                pause(0.001);
            else
            B = hbytes;
            Bimg = img;
            end
        case 12 %green off, blue on
            if ((size(find(hbytes ~= A),2) < 57500) || (size(find(hbytes ~= B),2) < 57500))
                pause(0.001);
            else
            C = hbytes;
            Cimg = img;
            end
        case 13
            disp("Error in FPGA code");
        otherwise
            disp("Not in normal run mode");
    end
   
    % These are the actual image merging calculations
    ABC = cat(2,A.',B.',C.'); % Puts all three frames into one matrix
    Red = sum(ABC.*caliRed,2); % Elementwise multiplication between the three frames and red calibration matrix, summing across the rows
        r = scalegreen*reshape(Red(), [w,h]); % Actually green due to frame buffer/delay, reshapes and applies scalar set by user on GUI
    Green = sum(ABC.*caliGreen,2);
        g = scaleblue*reshape(Green(), [w,h]); % Actually blue due to frame buffer/delay, reshapes and applies scalar set by user on GUI
    Blue = sum(ABC.*caliBlue,2);
        b = scalered*reshape(Blue(), [w,h]); % Actually red due to frame buffer/delay, reshapes and applies scalar set by user on GUI

    % Determines color order, allows for switching by the user
    if frameOrder == 3
        imgh = cat(3, r,g,b);
    elseif frameOrder == 2
        imgh = cat(3, g,b,r);
    elseif frameOrder == 1 % As a result of the frame buffer/delay we chose to leave the variable names and inputs that we expect from the FPGA and simply change the order here, normally we would expect r,g,b
        imgh = cat(3, b,r,g);
    end

    % Checks for any pixel values that are below 0 or above 1 and set them
    % to their respective limits (this is essential to save video). Notice
    % that the pixels start off as bytes ranging from 0-255 in decimal but
    % the calculations result in a value from 0-1 and this is what is
    % required to display the images because they are converted to doubles
    % on the way in (we could multiply by 255 to get the original value
    % form if required, the display axis works with both forms).
    imgh(imgh > 1) = 1;
    imgh(imgh < 0) = 0;

    % Checks record variable set by user and saves the current image to the
    % video file if the record button has been pressed
    if record == 1
        writeVideo(v,imgh);
        pause(0.0001);
    else
    end

    % Sets the displayed image
    set(handles.image,'CData',imgh);
    fullimage=imgh;

    % For the histogram
    if lock == 3
        setgraph(handles,handles.axes2);
    else  
    end
else
    pause(0.001); % If the image is the same as the previous, wait a little bit and check again
end
end
