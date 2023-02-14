function varargout = NaneyeinterfaceUSB2(varargin)
% NANEYEINTERFACEUSB2 MATLAB code for NaneyeinterfaceUSB2.fig
%      
%   NANEYEINTERFACEUSB2, creates an interface based on MATLAB's GUIDE,
%   to be used with AWAIBA's Image Sensor NanEye2D when used on a USB2 evaluation board.
%   
%   This interface goal is to give an example of what can be done on MATLAB with NanEye Sensor.
%   Here we show how to write registers, turn on the LED (if that is an
%   option), check the histogram of all the pixels - values density or
%   pixel count - a 3D profile of the gray values or from the RGB values,
%   etc.
%   
%   It is important to maintain all the .dll downloaded with this file on
%   the MATLAB's current folder. 
%
%   More details can be found on the AWAIBA documentation that was provided
%   with this file.
%
%   If you need help please contact: support@awaiba.com

% Edit the above text to modify the response to help NaneyeinterfaceUSB2

% Last Modified by GUIDE v2.5 22-Apr-2021 15:39:40

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @NaneyeinterfaceUSB2_OpeningFcn, ...
                   'gui_OutputFcn',  @NaneyeinterfaceUSB2_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before NaneyeinterfaceUSB2 is made visible.
function NaneyeinterfaceUSB2_OpeningFcn(hObject, eventdata, handles, varargin)
% Choose default command line output for NaneyeinterfaceUSB2
global lock naneye1 w h colorlist BW FPGA

hdlsetuptoolpath('ToolName','Altera Quartus II','ToolPath','C:\intelFPGA_lite\18.1\quartus\bin64\quartus.exe'); % Adds the required tools to the path for communication between MATLAB and the Cyclone 10 LP
FPGA = aximaster('Intel'); % Creating the object for the Cyclone 10 LP
writememory(FPGA,16384,0); % Writes a 0 to the memory address 16384, ensures all LEDs are off to start

% The 'lock' variable is used to control if a histogram is to be displayed.
% 'lock = -1' ensures that no histogram was requested and 'lock = 3' enables the displaying of the histogram. 
% These are random values. It is possible to use any other value according to the user. 

lock=-1;
handles.output = hObject;
movegui(hObject,'center')

% Calling the .NET assemblies it's an important part of the process. 
% MSCORLIB is an internal dll from Windows and has to be loaded for the 
% below dlls to work. 
if exist('asm')~= 1
    asm = NET.addAssembly('mscorlib');
end

NET.addAssembly([pwd '\awcorecs.dll']);
NET.addAssembly([pwd '\CesysProvider.dll']);
NET.addAssembly([pwd '\AwFrameProcessing.dll']);

% Update handles structure
guidata(hObject, handles);
disp('....Application Starting')

% Setting the sensor according to the NanEye Provider Demo, and setting the
% .mat file that corresponds to the register setting to present on the
% table. The second .mat file loaded is regarding the default register
% values. Optionally not all the default registers can be edited on this
% interface.

Awaiba.Drivers.Grabbers.Location.Paths.SetFpgaFilesDirectory('') % Sets the path where the .dll files are located
Awaiba.Drivers.Grabbers.Location.Paths.SetBinFile('nanousb2_fpga_v07.bin') % Each USB interface has a different .bin file which is chosen here

naneye1 = Awaiba.Drivers.Grabbers.NanEye2DNanoUSB2Provider; w=250; h=250;

SensorReg=load('NaneyeRegDataUSB2.mat');
set(handles.registertable,'data',SensorReg.RegData);

SensorDefault=load('NaneyeRegDataUSB2_default.mat');

for i = 1:8
    regobj=Awaiba.Drivers.Grabbers.NanEyeRegisterPayload(false,i, true, 0, cell2mat(SensorDefault.RegData(i,4)));
    naneye1.WriteRegister(regobj)
end

%Here some of the image processing algorithms are activated. They can all
%be manually activated/deactivated on the interface.
naneye1.AutomaticExpControl().ShowROI = 0;
naneye1.AutomaticExpControl().Enabled = 0;
colorlist = Awaiba.FrameProcessing.ProcessingWrapper.Instance(0);
colorlist.colorReconstruction.Apply=1; % NOTE that this color reconstruction is from the manufacturer and is for the histogram with a Bayer mask camera, not our image merging method

BW=0;

isAECon = naneye1.AutomaticExpControl().IsEnabled;
isROIon = naneye1.AutomaticExpControl().ShowROI;
isCOLORon = colorlist.colorReconstruction.Apply;
set(handles.checkbox1,'Value',isAECon);
set(handles.checkbox2,'Value',isROIon);
set(handles.checkbox3,'Value',isCOLORon);

guidata(hObject,handles);

% UIWAIT makes NaneyeinterfaceUSB2 wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = NaneyeinterfaceUSB2_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

varargout{1} = handles.output;

% --------------------------------------------------------------------
function FileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to FileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function OpenMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to OpenMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
file = uigetfile('*.fig');
if ~isequal(file, 0)
    open(file);
end

% --------------------------------------------------------------------
function PrintMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to PrintMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
printdlg(handles.figure1)

% --------------------------------------------------------------------
function CloseMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to CloseMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

delete(handles.figure1)

% --- Executes on selection change in scriptlist.
function scriptlist_Callback(hObject, eventdata, handles)
% On the 3D graphs there is no need to have a button to freeze the axes or 
% to change the axis scales, from density mode to pixel count. Here those features are deactivated. 

 chosen_graph = get(handles.scriptlist,'Value');
 
 if chosen_graph > 1
     set(handles.axisauto,'Enable','Off');
     set(handles.togglebutton3,'Enable','Off');
     set(handles.axisauto,'Value',0);
     set(handles.axisauto,'String','Freeze Axes');
 else
     set(handles.axisauto,'Enable','On');
     set(handles.togglebutton3,'Enable','On');
 end

% --- Executes on button press in StartSynchronous_button.
function StartSynchronous_button_Callback(hObject, eventdata, handles)
% The start button starts the displaying of what the sensor is capturing,
% keeping that capture until the Stop is pressed.

global naneye1 keep_running A B C FPGA frameOrder record v r g b lh1 Aimg Bimg Cimg oldput previmg scalered scalegreen scaleblue

keep_running=true;
choice=get(handles.StartSynchronous_button,'string');

while keep_running
    
    switch choice
        
       case 'Prepare for Synchronous'
            disp("Setting up variables, hit Confirm Start when ready");
            A = ones(1,62500); % Initializing the frames to different values so no errors are thrown
            B = 2*A;
            C = 3*B;
            r = reshape(A(), [250,250]);
            g = reshape(B(), [250,250]);
            b = reshape(C(), [250,250]);
            previmg = double(zeros(250,250));
            scalered = 1;
            scalegreen = 1;
            scaleblue = 1;
            frameOrder = 1;
            record = 2;
            v = VideoWriter('NewColorVideoTest.avi','Uncompressed AVI'); % sets up the object to save video, this is where to change the file format
            writememory(FPGA,16384,2); % Begins the normal run mode LED illumination
            disp("Ready");
            choice=set(handles.StartSynchronous_button,'string','Confirm Start');
            keep_running = false;
            
        case 'Confirm Start'
            oldput = readmemory(FPGA,16400,1); % Used to ensure that the program waits for a new value from the FPGA
            axes(handles.axes1); % these initialize the display axis
            colormap gray
            handles.image=image;
            axis off;
            lh1 = addlistener(naneye1,'ImageProcessed', @(o,e)displayobjRunModetesting(e,handles)); % Adds the displayobjRunMode as a function that will run every time a new frame is processed by the Awaiba box
            naneye1.StartCapture();            
            choice=set(handles.StartSynchronous_button,'string','Stop');
            keep_running = false;
        
        case 'Stop'
            naneye1.StopCapture();
            delete(lh1); % Deletes the listener function because the calibration process uses a different one
            writememory(FPGA,16384,0); % Turns all LEDs off
            
            figure; % This figure shows the last three frames read in, useful for testing
            tiledlayout(1,3);
            nexttile
            image(flipud(Aimg.')); title("A");
            nexttile
            image(flipud(Bimg.')); title("B");
            nexttile
            image(flipud(Cimg.')); title("C");
            
%             save('A_NormalRun.mat','Aimg'); % This can be used to save
%             the images for further use and/or calculation
%             save('B_NormalRun.mat','Bimg');
%             save('C_NormalRun.mat','Cimg');

            choice=set(handles.StartSynchronous_button,'string','Prepare to Start');
            keep_running = false;
    end
    
end

guidata(hObject,handles);


% --- Executes on button press in StartBayer_button.
function StartBayer_button_Callback(hObject, eventdata, handles)
% hObject    handle to StartBayer_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global naneye1 keep_running FPGA lh3

keep_running=true;
choice=get(handles.StartBayer_button,'string');

while keep_running
    
    switch choice
        
       case 'Start Bayer'
            writememory(FPGA,16384,3); % Tells the FPGA to turn all LEDs on
            axes(handles.axes1); % these initialize the display axis
            handles.image=image;
            axis off;
            lh3 = addlistener(naneye1,'ImageProcessed', @(o,e)displayobjBayer(e,handles)); % Adds the displayobjBayer as a function that will run every time a new frame is processed by the Awaiba box
            naneye1.StartCapture();            
            choice=set(handles.StartBayer_button,'string','Stop');
            keep_running = false;
        
        case 'Stop'
            naneye1.StopCapture();
            delete(lh3); % Deletes the listener function to prepare for a different mode to be used
            writememory(FPGA,16384,0); % Turns all LEDs off
            choice=set(handles.StartBayer_button,'string','Start Bayer');
            keep_running = false;
    end
    
end

guidata(hObject,handles);


% --- Executes on button press in StartMonochrome_button.
function StartMonochrome_button_Callback(hObject, eventdata, handles)
% hObject    handle to StartMonochrome_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global naneye1 keep_running FPGA lh4

keep_running=true;
choice=get(handles.StartMonochrome_button,'string');

while keep_running
    
    switch choice
        
       case 'Start Monochrome'
            writememory(FPGA,16384,3); % Tells the FPGA to turn all LEDs on
            axes(handles.axes1); % these initialize the display axis
            colormap gray
            handles.image=image;
            axis off;
            lh4 = addlistener(naneye1,'ImageProcessed', @(o,e)displayobjMonochrome(e,handles)); % Adds the displayobjBayer as a function that will run every time a new frame is processed by the Awaiba box
            naneye1.StartCapture();            
            choice=set(handles.StartMonochrome_button,'string','Stop');
            keep_running = false;
        
        case 'Stop'
            naneye1.StopCapture();
            delete(lh4); % Deletes the listener function to prepare for a different mode to be used
            writememory(FPGA,16384,0); % Turns all LEDs off
            choice=set(handles.StartMonochrome_button,'string','Start Monochrome');
            keep_running = false;
    end
    
end

guidata(hObject,handles);

% --- Executes on button press in saveimage, to save the image captured by
% the sensor.
function saveimage_Callback(hObject, eventdata, handles)

global fullimage

save('NewScreenshot.mat','fullimage');

% MODIFIED
% figure('units','pixels','position',[1 1 250 250]);
% exported_fig=gca;
% copyobj(allchild(handles.axes1), exported_fig);
% set(gca,'Units','pixels');
% set(gca, 'Position',[1 1 250 250]);
% axis(exported_fig,'tight','square');
% axis off;

% ORIGINAL
% figure;
% exported_fig=gca;
% copyobj(allchild(handles.axes1), exported_fig);
% axis(exported_fig,'tight','square');
% axis off;

% TESTING - Works the best so far, keeps orginal file size
displayimage = load('NewScreenshot.mat','fullimage');
imtool(flipud(displayimage.fullimage))

guidata(hObject,handles);


function scriptlist_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
     set(hObject,'BackgroundColor','white');
end

set(hObject, 'String', {'Histogram', '3D Red Values', '3D Green Values', '3D Blue Values'});


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
global naneye1

naneye1.Dispose();

disp('....Application Ended')
delete(hObject);
clear variables
close all

% --- Executes on button press in saveplot, to save any histogram or 3D
% graphic.
function saveplot_Callback(hObject, eventdata, handles)
% hObject    handle to saveplot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% global StatData
% assignin('base', 'DataORION', handles.axes2);

figure;
exported_fig=gca;
copyobj(allchild(handles.axes2), exported_fig);
% copyobj(allchild(handles.axes2), exported_fig);

guidata(hObject,handles);


% --- Executes on button press in RunnigScript.
function RunnigScript_Callback(hObject, eventdata, handles)
% This will use the 'lock' variable to transmit the information that there
% is something to present on the second axes ('lock = 3').

global lock data

 if get(hObject,'Value') == 1
     lock=3;
     data=[];
     set(handles.RunnigScript,'String','Stop Script');
     set(handles.saveplot,'Enable','On');
     set(handles.axisauto,'Enable','On');
     set(handles.togglebutton3,'Enable','On');
 else
     assignin('base', 'Data',data);
     lock=-1;
     set(handles.RunnigScript,'String','Run Script');
     set(handles.saveplot,'Enable','Off');
     set(handles.axisauto,'Enable','Off');
     set(handles.togglebutton3,'Enable','Off');
 end
 
 % If one of the 3D graphs options is chosen, then the options 'Freeze
 % Axes' and 'Density/Pixel Count' will be deactivated.
 chosen_graph = get(handles.scriptlist,'Value');
 
 if chosen_graph > 1
     set(handles.axisauto,'Enable','Off');
     set(handles.togglebutton3,'Enable','Off');
     set(handles.axisauto,'Value',0);
     set(handles.axisauto,'String','Freeze Axes');
 else
 end     

 
function xmin_Callback(hObject, eventdata, handles)
% hObject    handle to xmin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of xmin as text
%        str2double(get(hObject,'String')) returns contents of xmin as a double
global limits
value=str2double(get(hObject,'String'));
limits(1)=value;
limits(3)=(str2double(get(handles.xmax,'String'))-value)+1;
set(handles.rect,'Position',limits);


% --- Executes on button press in axisauto.
function axisauto_Callback(hObject, eventdata, handles)
% This freezes the axis scale, limiting it to the max value found when the
% button is pressed. That maximum value is kept on variable 'limitation' to
% be transported into the "setgraph.m" file.
global limitation

if get(hObject,'Value') == 1
    limitation=get(handles.axes2,'YLim');
    set(handles.axes2,'YLimMode','manual');
    set(handles.axisauto,'String','Unfreeze Axes')
else
    axis(handles.axes2,'auto')
    set(handles.axisauto,'String','Freeze Axes')
end

 guidata(hObject,handles);


% --- Executes when entered data in editable cell(s) in registertable.
function registertable_CellEditCallback(hObject, eventdata, handles)
% Each of the values added to the table (on the fourth row - decimal
% values) will be writen on sensor's registers.
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
global naneye1
disp('....Writting Registers');

x=eventdata.Indices(2);
y=eventdata.Indices(1);
registertable=get(handles.registertable,'data');
value=cell2mat(registertable(y,x));

    
    if x == 3 ;
        value=hex2dec(value); 
    end
    
    featureoutput = setSensorFeature(value,y);
    
    value=featureoutput;
    
    registertable(y,3)={dec2hex(value)};
    registertable(y,4)={value};
    
    RegAddress=hex2dec(cell2mat(registertable(y,2)));

    regobj=Awaiba.Drivers.Grabbers.NanEyeRegisterPayload(false,RegAddress, true, 0,value);
    naneye1.WriteRegister(regobj)

set( handles.registertable,'data',registertable)
guidata(hObject,handles);


% --- Executes on button press in checkbox1.
function checkbox1_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global naneye1

if get(handles.checkbox1,'Value') == 0
   disp('AEC disabled...')
   naneye1.AutomaticExpControl().Enabled = 1;
else
    disp('AEC enabled...')
    naneye1.AutomaticExpControl().Enabled = 0;
end


% --- Executes on button press in checkbox2.
function checkbox2_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global naneye1

if get(handles.checkbox2,'Value') == 0
   disp('ROI disabled...')
   naneye1.AutomaticExpControl().ShowROI = 0;
else
    disp('ROI enabled...')
    naneye1.AutomaticExpControl().ShowROI = 1;
end


% --- Executes on button press in checkbox3.
function checkbox3_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global colorlist BW lock

if get(handles.checkbox3,'Value') == 0
    disp('Color Reconstruction disabled...')
    colorlist.colorReconstruction.Apply=false;
    set(handles.scriptlist, 'String', {'Histogram', '3D Histogram'});
    set(handles.scriptlist, 'Value',1);
    BW = 1;
else
    disp('Color Reconstruction enabled...')
    colorlist.colorReconstruction.Apply=true;
    set(handles.scriptlist, 'String', {'Histogram', '3D Red Values', '3D Green Values', '3D Blue Values'});
    BW = 0;
end

if lock == 3
    set(handles.scriptlist, 'Value',2);
else
end

% --------------------------------------------------------------------
function Untitled_1_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes on button press in pushbutton8.
function pushbutton8_Callback(hObject, eventdata, handles)
% Reprogramming the board, in case the user has forgot to plug it before
% initializing the interface.
global naneye1 w h
naneye1 = Awaiba.Drivers.Grabbers.NanEye2DNanoUSB2Provider; w=250; h=250;
set(handles.StartSynchronous_button,'string','Start');
SensorReg=load('NaneyeRegDataUSB2.mat');
set(handles.registertable,'data',SensorReg.RegData);

SensorDefault=load('NaneyeRegDataUSB2_default.mat');

for i = 1:8
    regobj=Awaiba.Drivers.Grabbers.NanEyeRegisterPayload(false,i, true, 0, cell2mat(SensorDefault.RegData(i,4)));
    naneye1.WriteRegister(regobj)
end

%Here some of the image processing algorithms are activated. They can all
%be manually activated/deactivated on the interface.
naneye1.AutomaticExpControl().ShowROI = 0;
naneye1.AutomaticExpControl().Enabled = 0;
colorlist = Awaiba.FrameProcessing.ProcessingWrapper.Instance(0);
colorlist.colorReconstruction.Apply=1;

BW=0;

isAECon = naneye1.AutomaticExpControl().IsEnabled;
isROIon = naneye1.AutomaticExpControl().ShowROI;
isCOLORon = colorlist.colorReconstruction.Apply;
set(handles.checkbox1,'Value',isAECon);
set(handles.checkbox2,'Value',isROIon);
set(handles.checkbox3,'Value',isCOLORon);


% --- Executes on button press in togglebutton3.
function togglebutton3_Callback(hObject, eventdata, handles)
% hObject    handle to togglebutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global presenting_mode

disposal = get(handles.togglebutton3,'String');

switch disposal
    
    case 'Density'
        set(handles.togglebutton3,'String','Pixel Count')
        presenting_mode = 1;
    
    case 'Pixel Count'
        set(handles.togglebutton3,'String','Density')
        presenting_mode = 2;

end
    

% --- Executes on button press in checkbox5.
function checkbox5_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global naneye1
led_on = get(handles.checkbox5, 'Value');
if led_on == 1
    regobj=Awaiba.Drivers.Grabbers.NanEyeRegisterPayload(false,5, true, 0, 1);
    naneye1.WriteRegister(regobj)
else
    regobj=Awaiba.Drivers.Grabbers.NanEyeRegisterPayload(false,5, true, 0, 0);
    naneye1.WriteRegister(regobj)
end


% --- Executes on button press of Calibrate button.
function calibratebutton_Callback(hObject, eventdata, handles)
% hObject    handle to calibratebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global naneye1 keeprunning previousin previousimg input_test FPGA caliRed caliGreen caliBlue RedOn RedOff RedZero GreenOn GreenOff GreenZero BlueOn BlueOff BlueZero lh2 RedOnimg RedOffimg RedZeroimg GreenOnimg GreenOffimg GreenZeroimg BlueOnimg BlueOffimg BlueZeroimg buffer

keeprunning=true;
choice=get(handles.calibratebutton,'string');

while keeprunning
   
    switch choice
        
       case 'Calibrate'
            writememory(FPGA,16384,1); % Starts the calibration LED sequence
            previousin = readmemory(FPGA,16400,1); % Like the normal run mode, ensures the FPGA signal is changing before reading
            input_test = [0 0 0];
            previousimg = zeros(250,250); % Initializing matrices
            RedOn = zeros(1,62500);
            RedOff = zeros(1,62500);
            RedZero = zeros(1,62500);
            GreenOn = zeros(1,62500);
            GreenOff = zeros(1,62500);
            GreenZero = zeros(1,62500);
            BlueOn = zeros(1,62500);
            BlueOff = zeros(1,62500);
            BlueZero = zeros(1,62500);
            
            axes(handles.axes1);
            colormap gray;
            handles.image=image;
            axis off;
            lh2 = addlistener(naneye1,'ImageProcessed', @(o,e)displayobjCalibrationtesting(e,handles)); % This is the specific function used for calibration
            naneye1.StartCapture();
            disp("Calibrating...place a white sheet of paper under camera");
            disp("Hit End Calibration after a couple seconds");
            choice=set(handles.calibratebutton,'string','End Calibration');
            keeprunning = false;
         
        case 'End Calibration'
            naneye1.StopCapture();
            delete(lh2);
            writememory(FPGA,16384,0); % Turns all LEDs off
            CAL = zeros(187500,3); % Initializes matrices
            CALinv = zeros(187500,3);
            
            % This loop goes through each pixel and picks out the
            % respective values from each calibration matrix. It also
            % filters out the matrices which cannot be inverted and sets
            % them to zero (these are all the set pixels on the edge
            % anyways)
            for n=1:62500
                CAL(3*n-2:3*n,:)=[RedOn(n) GreenZero(n) BlueOff(n); RedOff(n) GreenOn(n) BlueZero(n); RedZero(n) GreenOff(n) BlueOn(n)];
                detCAL(3*n-2:3*n,:) = det(CAL(3*n-2:3*n,:));
                if detCAL(3*n-2:3*n,:) == 0
                    CALinv(3*n-2:3*n,:) = zeros(3,3);
                else
                    CALinv(3*n-2:3*n,:)=inv([RedOn(n) GreenZero(n) BlueOff(n); RedOff(n) GreenOn(n) BlueZero(n); RedZero(n) GreenOff(n) BlueOn(n)]);
                end
            end
            
            % Reshaping the calibration matrices again to make the normal
            % run mode math quicker
            %caliRed   = 0.9*CALinv(1:3:end,:);
            %caliGreen = 1.11*CALinv(2:3:end,:);
            %caliBlue  = 1.118*CALinv(3:3:end,:);
            caliRed   = CALinv(1:3:end,:);
            caliGreen = CALinv(2:3:end,:);
            caliBlue  = CALinv(3:3:end,:);
            
            figure; % This figure shows all the captured calibration matrices so the user can make sure everything worked as expected
            tiledlayout(3,3);
            nexttile
            image(RedOnimg); title("Red On");
            nexttile
            image(RedOffimg); title("Red Off");
            nexttile
            image(RedZeroimg); title("After Red Off");
            nexttile
            image(GreenOnimg); title("Green On");
            nexttile
            image(GreenOffimg); title("Green Off");
            nexttile
            image(GreenZeroimg); title("After Green Off");
            nexttile
            image(BlueOnimg); title("Blue On");
            nexttile
            image(BlueOffimg); title("Blue Off");
            nexttile
            image(BlueZeroimg); title("After Blue Off");
            
            save('RedOn.mat','RedOnimg');
            save('RedOff.mat','RedOffimg');
            save('RedZero.mat','RedZeroimg');
            save('GreenOn.mat','GreenOnimg');
            save('GreenOff.mat','GreenOffimg');
            save('GreenZero.mat','GreenZeroimg');
            save('BlueOn.mat','BlueOnimg');
            save('BlueOff.mat','BlueOffimg');
            save('BlueZero.mat','BlueZeroimg');
            save('input_test.mat','input_test');
            
            disp("Calibration finished");
            disp("If calibration images do not match expected, repeat calibration");
            choice=set(handles.calibratebutton,'string','Calibrate');
            keeprunning = false;
            
    end
end

guidata(hObject,handles);


% --- Executes on button press in switchorderbutton.
function switchorderbutton_Callback(hObject, eventdata, handles)
% hObject    handle to switchorderbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global frameOrder

choice=get(handles.switchorderbutton,'string');

% Works while the video is running, simply changes the frameOrder variable
% which is used in the normal run mode function
switch choice
    case 'Switch Order (1st Time)'
        frameOrder = 2;
        choice=set(handles.switchorderbutton,'string','Switch Order (2nd Time)');
    case 'Switch Order (2nd Time)'
        frameOrder = 3;
        choice=set(handles.switchorderbutton,'string','Revert to Original');
    case 'Revert to Original'
        frameOrder = 1;
        choice=set(handles.switchorderbutton,'string','Switch Order (1st Time)');
end


% --- Executes on button press in savevideobutton.
function savevideobutton_Callback(hObject, eventdata, handles)
% hObject    handle to savevideobutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global record v

choice=get(handles.savevideobutton,'string');

switch choice
    case 'Start Record'
        open(v); % Opens the file we set earlier
        record = 1;
        choice=set(handles.savevideobutton,'string','Stop Record');
    case 'Stop Record'
        record = 2;
        close(v); % Closes same file
        choice=set(handles.savevideobutton,'string','Start Record');
end


% --- Executes on slider movement.
function redslider_Callback(hObject, eventdata, handles)
% hObject    handle to redslider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

global scalered
scalered = get(hObject,'Value');

% --- Executes during object creation, after setting all properties.
function redslider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to redslider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
set(hObject,'Value',1);


% --- Executes on slider movement.
function greenslider_Callback(hObject, eventdata, handles)
% hObject    handle to greenslider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global scalegreen
scalegreen = get(hObject,'Value');

% --- Executes during object creation, after setting all properties.
function greenslider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to greenslider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
set(hObject,'Value',1);

% --- Executes on slider movement.
function blueslider_Callback(hObject, eventdata, handles)
% hObject    handle to blueslider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global scaleblue
scaleblue = get(hObject,'Value');

% --- Executes during object creation, after setting all properties.
function blueslider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to blueslider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
set(hObject,'Value',1);

% --- Executes on button press in colorscaleresetbutton.
function colorscaleresetbutton_Callback(hObject, eventdata, handles)
% hObject    handle to colorscaleresetbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global scalered scalegreen scaleblue

% This resets each color scalar to one
scalered = 1;
set(handles.redslider, 'Value', 1);
scalegreen = 1;
set(handles.greenslider, 'Value', 1);
scaleblue = 1;
set(handles.blueslider, 'Value', 1);

guidata(hObject,handles);


% --- Executes on button press in pushbutton16.
function pushbutton16_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global caliRed caliGreen caliBlue RedOn RedOff RedZero GreenOn GreenOff GreenZero BlueOn BlueOff BlueZero RedOnimg RedOffimg RedZeroimg GreenOnimg GreenOffimg GreenZeroimg BlueOnimg BlueOffimg BlueZeroimg

% RedOnimg = load('RedOn.mat');
% RedOffimg = load('RedOff.mat');
% RedZeroimg = load('RedZero.mat');
% GreenOnimg = load('GreenOn.mat');
% GreenOffimg = load('GreenOff.mat');
% GreenZeroimg = load('GreenZero.mat');
% BlueOnimg = load('BlueOn.mat');
% BlueOffimg = load('BlueOff.mat');
% BlueZeroimg = load('BlueZero.mat');

RedOn = reshape(RedOnimg.',1,62500);
RedOff = reshape(RedOffimg.',1,62500);
RedZero = reshape(RedZeroimg.',1,62500);
BlueOn = reshape(BlueOnimg.',1,62500);
BlueOff = reshape(BlueOffimg.',1,62500);
BlueZero = reshape(BlueZeroimg.',1,62500);
GreenOn = reshape(GreenOnimg.',1,62500);
GreenOff = reshape(GreenOffimg.',1,62500);
GreenZero = reshape(GreenZeroimg.',1,62500);

CAL = zeros(187500,3); % Initializes matrices
CALinv = zeros(187500,3);

% This loop goes through each pixel and picks out the
% respective values from each calibration matrix. It also
% filters out the matrices which cannot be inverted and sets
% them to zero (these are all the set pixels on the edge
% anyways)
for n=1:62500
    CAL(3*n-2:3*n,:)=[RedOn(n) GreenZero(n) BlueOff(n); RedOff(n) GreenOn(n) BlueZero(n); RedZero(n) GreenOff(n) BlueOn(n)];
    detCAL(3*n-2:3*n,:) = det(CAL(3*n-2:3*n,:));
    if detCAL(3*n-2:3*n,:) == 0
        CALinv(3*n-2:3*n,:) = zeros(3,3);
    else
        CALinv(3*n-2:3*n,:)=inv([RedOn(n) GreenZero(n) BlueOff(n); RedOff(n) GreenOn(n) BlueZero(n); RedZero(n) GreenOff(n) BlueOn(n)]);
    end
end

% Reshaping the calibration matrices again to make the normal
% run mode math quicker
%caliRed   = 0.9*CALinv(1:3:end,:);
%caliGreen = 1.11*CALinv(2:3:end,:);
%caliBlue  = 1.118*CALinv(3:3:end,:);
caliRed   = CALinv(1:3:end,:);
caliGreen = CALinv(2:3:end,:);
caliBlue  = CALinv(3:3:end,:);

figure; % This figure shows all the captured calibration matrices so the user can make sure everything worked as expected
tiledlayout(3,3);
nexttile
image(RedOnimg); title("Red On");
nexttile
image(RedOffimg); title("Red Off");
nexttile
image(RedZeroimg); title("After Red Off");
nexttile
image(GreenOnimg); title("Green On");
nexttile
image(GreenOffimg); title("Green Off");
nexttile
image(GreenZeroimg); title("After Green Off");
nexttile
image(BlueOnimg); title("Blue On");
nexttile
image(BlueOffimg); title("Blue Off");
nexttile
image(BlueZeroimg); title("After Blue Off");

            
guidata(hObject,handles);

% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over pushbutton16.
function pushbutton16_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
