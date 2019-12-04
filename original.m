function varargout = original(varargin)

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @original_OpeningFcn, ...
                   'gui_OutputFcn',  @original_OutputFcn, ...
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


function original_OpeningFcn(hObject, eventdata, handles, varargin)
set(handles.text5,'string','0');   %frejoles
set(handles.text6,'string','0');   %lentejas
set(handles.text4,'string','0');   %arverjas
set(handles.text2,'string','0');   %pallares
set(handles.text3,'string','0');   %garbanzo

handles.output = hObject;

guidata(hObject, handles);



function varargout = original_OutputFcn(hObject, eventdata, handles) 

varargout{1} = handles.output;


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
global vid 
closepreview;
clc;
vid=videoinput('winvideo',1,'YUY2_640x480');
set(vid,'ReturnedColorSpace','rgb');
src = getselectedsource(vid);
        src.BacklightCompensation = 'off'
        src.Brightness = 15;
        src.Contrast = 13;
        src.Exposure = -5;
        src.ExposureMode = 'manual'
        src.FrameRate = '30.0000';
        src.Gamma = 100;
        src.Hue = 0;
        src.Pan = 0;
        src.Saturation = 38;
        src.Sharpness = 35;
        src.Tilt = 0;
        src.WhiteBalance = 6100;
        src.WhiteBalanceMode = 'manual';
        src.Zoom = 1.1;
axes(handles.axes1);
V1=get(vid,'VideoResolution');
V2=get(vid,'NumberofBands');
hImage=image(zeros(V1(1),V1(1),V2),'Parent',handles.axes1);
preview(vid,hImage);

%Cargar Base de Datos
load Cp;
load Menest;   
cp= Cp;
menest =  Menest;
Entren = fitcecoc(cp,menest);
save Entren.mat Entren


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
global vid BIN H S V
%%%%%%%%%%Reconocimiento de objeto
load Entren
% Entren2 = Entren(1:767)
cont_mens=[0 0 0 0 0 0 0];
[M N]=size(BIN);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[f k] = bwlabel(BIN,8);
ob_reco = [];  %%objetos grandes reconocidos
for i = 1:k  %%%%%%%%%reconocer en que etiquetas estan los objetos de importancia
    f3 = length(find(f == i));
    if f3 > 50
       ob_reco = [ob_reco i];        
    end
end
for l = 1:length(ob_reco)
    z1 = find(f == ob_reco(l));
    z2 = zeros(M,N);
    H2 = zeros(M,N);
    V2 = zeros(M,N);
    S2 = zeros(M,N);
    z2(z1) = 1;
    for i =1:M
        for j =1:N
          if z2(i,j) == 1
                H2(i,j) = H(i,j);
                V2(i,j) = V(i,j);
                S2(i,j) = S(i,j);
          end
        end
    end
    [h1,h]=imhist(uint8(H2));
    [h2,h]=imhist(uint8(V2));
    [h3,h]=imhist(uint8(S2));
    HH=[];
    h1=h1';
    hh1=(h1(2:end));
    h2=h2';
    hh2=(h2(2:end));
    h3=h3';
    hh3=(h3(2:end));
    [B,L] = bwboundaries(z2,'noholes'); % traza los limites exteriores de los objetos, donde especifica la conectividad que se utilizara al trazar los limites primarios y secundarios
    length(z2)
    pp = regionprops(L,'Area','Centroid'); %%%sacamos Area y centroide
    for k = 1:length(B)  %metrica es igual a 1 solo para un círculo y es menor que uno para cualquier otra forma
    boundary = B{k};   
    delta_sq = diff(boundary).^2;     
    perimeter = sum(sqrt(sum(delta_sq,2)));      % perimetro
    area = pp(k).Area;      % area  
    metric = (4*pi*area/perimeter^2)*200; %metrica
    end
    %metric 
    HH = [hh1 hh2 hh3 metric length(z1)];
    R_VOCAL = predict(Entren,HH);
    if R_VOCAL == 'pa'
        cont_mens(5)=cont_mens(5) + 1; 
    elseif R_VOCAL == 'le'
        cont_mens(3)=cont_mens(3) + 1; 
    elseif R_VOCAL == 'ga'
        cont_mens(6)=cont_mens(6) + 1;
    elseif R_VOCAL == 'fp'
        cont_mens(1)=cont_mens(1) + 1; 
    elseif R_VOCAL == 'av'
        cont_mens(4)=cont_mens(4) + 1;  
    end
end

set(handles.text5,'string',cont_mens(1));   %frejoles
set(handles.text6,'string',cont_mens(3));   %lentejas
set(handles.text4,'string',cont_mens(4));   %arverjas
set(handles.text2,'string',cont_mens(5));   %pallares
set(handles.text3,'string',cont_mens(6));   %garbanzo


function pushbutton3_Callback(hObject, eventdata, handles)

global vid BIN H S V
I= getsnapshot(vid);
I = imcrop(I,[50 50 580 390]); %%%%%%%%%%%%%%Area de trabajo
%%%%%%%%%%%%%%%%%%HSV%%%%%%%%%%%%%%%%%%%%%%%
Ih=rgb2hsv(I);
H=double(Ih(:,:,1))*255;
S=double(Ih(:,:,2))*255;
V=double(Ih(:,:,3))*255;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
GRy = rgb2gray(I);
title('Escala de grises');
BIN = im2bw(GRy,0.3); %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%umbrallllll 0.35
[M N]=size(BIN);
B2 = strel('disk',4);
BIN = imerode(BIN,B2);
B2 = strel('disk',8);
BIN = imdilate(BIN,B2);
axes(handles.axes2);
imshow(I);
