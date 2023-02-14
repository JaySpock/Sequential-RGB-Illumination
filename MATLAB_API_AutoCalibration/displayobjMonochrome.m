function displayobjMonochrome(inbytes,handles)
% Function that displays the sensor's image. First grabs the values from
% the sensor and reshapes them in a 3 dimensions vector. 
global fullimage lock w h

hbytes=uint8(inbytes.GetImageData.GetRawPixels1Byte);
%hbytes=uint16(inbytes.GetImageData.GetProcessedDataUshort);
imgh = reshape(hbytes(), [w,h]);

%imgh = cat(3 ,s,s,s);

set(handles.image,'CData',imgh);
 
fullimage=imgh;

if lock == 3
    setgraph(handles,handles.axes2);
else
end
    
end