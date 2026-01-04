function varargout = gui_kod(varargin)
% GUI_KOD MATLAB code for gui_kod.fig
%      GUI_KOD, by itself, creates a new GUI_KOD or raises the existing singleton*.
%
%      H = GUI_KOD returns the handle to a new GUI_KOD or the handle to
%      the existing singleton*.
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Last Modified by GUIDE v2.5 01-Dec-2025 14:22:18

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @gui_kod_OpeningFcn, ...
                   'gui_OutputFcn',  @gui_kod_OutputFcn, ...
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


% --- Executes just before gui_kod is made visible.
function gui_kod_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for gui_kod
handles.output = hObject;

% ========== UCITAVANJE ANFIS MODELA ==========
try
    handles.fis = readfis('AnfisModel_Pozari.fis');
catch ME
    errordlg(['Ne mogu da učitam AnfisModel_Pozari.fis: ' ME.message], ...
             'Greška pri učitavanju');
end

% ========== DEFINISANI OPSEZI  ==========
handles.min_vals = [0  0   0   0];   % [Temp, Vlažnost, Vetar, Nagib]
handles.max_vals = [50 100 20  60];

% edit5 (rezultat) je read-only
if isfield(handles,'edit5')
    set(handles.edit5,'Enable','inactive');
end

%=========== SEMAFOR=================
if isfield(handles,'axes1')
    axes(handles.axes1);
    cla;
    axis equal off;

    r = 0.13;
    t = linspace(0, 2*pi, 50);

   centers = [0.25 0.5;   % zelen
           0.50 0.5;   % žut
           0.75 0.5];  % crven

    for i = 1:3
        cx = centers(i,1);
        cy = centers(i,2);
        x = cx + r*cos(t);
        y = cy + r*sin(t);
        patch(x, y, [0.3 0.3 0.3], 'EdgeColor','k', 'LineWidth',1.2); % ugašeno
    end

    xlim([0 1]);
    ylim([0 1]);
end

% Update handles structure
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = gui_kod_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;



function edit1_Callback(hObject, eventdata, handles)
% Temperatura (°C)


function edit1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit2_Callback(hObject, eventdata, handles)
% Vlažnost (%)


function edit2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit3_Callback(hObject, eventdata, handles)
% Brzina vetra (m/s)


function edit3_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit4_Callback(hObject, eventdata, handles)
% Nagib terena (stepeni)


function edit4_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% Dugme "Izračunaj rizik"

% 1) Čitanje vrednosti iz GUI polja
T = str2double(get(handles.edit1,'String'));  % Temperatura
H = str2double(get(handles.edit2,'String'));  % Vlažnost
W = str2double(get(handles.edit3,'String'));  % Vetar
G = str2double(get(handles.edit4,'String'));  % Nagib

% Provera da li su unosi brojevi
if any(isnan([T H W G]))
    errordlg('Unesite ispravne numeričke vrednosti u sva četiri polja.', ...
             'Greška u unosu');
    return;
end

% 2) Provera opsega (moraju biti u granicama korišćenim u treningu)
poruka = '';
if T < 0 || T > 50
    poruka = [poruka 'Temperatura mora biti između 0 i 50 °C.' newline];
end
if H < 0 || H > 100
    poruka = [poruka 'Vlažnost mora biti između 0 i 100%.' newline];
end
if W < 0 || W > 20
    poruka = [poruka 'Brzina vetra mora biti između 0 i 20 m/s.' newline];
end
if G < 0 || G > 60
    poruka = [poruka 'Nagib mora biti između 0 i 60 stepeni.' newline];
end

if ~isempty(poruka)
    errordlg(poruka, 'Vrednosti van opsega');
    return;
end

% 3) Originalni vektor ulaza
x_orig = [T H W G];

% 4) Skaliranje na [0,1] istim opsezima kao u treningu
min_vals = handles.min_vals;
max_vals = handles.max_vals;

x_norm = (x_orig - min_vals) ./ (max_vals - min_vals);

% 5) Izračunavanje rizika pomoću ANFIS-a
fis = handles.fis;
risk = evalfis(fis, x_norm);

% 6) Ograničavanje na [0,1]
risk = max(0, min(1, risk));

% 7) Prikazivanje rezultata-rizika
set(handles.edit5,'String',sprintf('%.3f', risk));

% 8) Tekstualna poruka o nivou rizika
if risk < 0.33
    nivo = sprintf('NIZAK rizik od požara (%.3f)', risk);
    boja = [0 0.6 0];      % zeleno
elseif risk < 0.66
    nivo = sprintf('SREDNJI rizik od požara (%.3f)', risk);
    boja = [1 0.5 0];      % narandžasto
else
    nivo = sprintf('VISOK rizik od požara (%.3f)', risk);
    boja = [0.8 0 0];      % crveno
end

if isfield(handles,'text10')
    set(handles.text10, 'String', nivo, ...
                            'ForegroundColor', boja);
end

% 9) Grafički prikaz rizika na semaforu
if isfield(handles,'axes1')
    axes(handles.axes1);
    cla;
    axis equal off;

    r = 0.13;
    t = linspace(0, 2*pi, 50);

    
    centers = [0.25 0.5;   % zelen
           0.50 0.5;   % žut
           0.75 0.5];  % crven


    % boje aktivnog
    bojeAktivne = [0   0.8 0   ;   % zelen
                   1   0.8 0   ;   % žut
                   0.8 0   0   ];  % crven

    % ugašeno = sivo
    bojaUgaseno = [0.3 0.3 0.3];

    % koji krug svetli
    if risk < 0.33
        idxSemafor = 1;
    elseif risk < 0.66
        idxSemafor = 2;
    else
        idxSemafor = 3;
    end

    % iscrtaj 3 kruga
    for i = 1:3
        cx = centers(i,1);
        cy = centers(i,2);
        x = cx + r*cos(t);
        y = cy + r*sin(t);

        if i == idxSemafor
            col = bojeAktivne(i,:);
        else
            col = bojaUgaseno;
        end

        patch(x, y, col, 'EdgeColor','k', 'LineWidth',1.2);
    end

    xlim([0 1]);
    ylim([0 1]);
end




function edit5_Callback(hObject, eventdata, handles)
% Rezultat (rizik)


function edit5_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% Dugme "Odustani"
close;
