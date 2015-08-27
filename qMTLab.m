function varargout = qMTLab(varargin)
% QMTLAB MATLAB code for qMTLab.fig
% GUI to simulate/fit qMT data 

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name', mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @qMTLab_OpeningFcn, ...
    'gui_OutputFcn',  @qMTLab_OutputFcn, ...
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


% --- Executes just before qMTLab is made visible.
function qMTLab_OpeningFcn(hObject, eventdata, handles, varargin)
clc;
startup;
handles.root = cd;
handles.method = '';
handles.CurrentData = [];
handles.FitDataDim = [];
handles.FitDataSize = [];
handles.FitDataSlice = [];
handles.output = hObject;
guidata(hObject, handles);

% LOAD DEFAULTS
load(fullfile(handles.root,'Common','Parameters','DefaultMethod.mat'));
ii=1;
switch Method
    case 'bSSFP'
        ii = 1;
    case 'SIRFSE'
        ii = 2;
    case 'SPGR'
        ii = 3;
end
set(handles.MethodMenu, 'Value', ii);
Method = GetMethod(handles);
cd(fullfile(handles.root, Method));
LoadDefaultOptions(fullfile(cd,'Parameters'));
LoadSimVaryOpt(fullfile(handles.root,'Common','Parameters'), 'DefaultSimVaryOpt.mat', handles);
LoadSimRndOpt(fullfile(handles.root, 'Common','Parameters'), 'DefaultSimRndOpt.mat',  handles);

% SET WINDOW AND PANELS
% CurrentPos = get(gcf, 'Position');
% NewPos     = CurrentPos;
% NewPos(3)  = 162;
% set(gcf, 'Position', NewPos);
movegui(gcf,'center')
CurrentPos = get(gcf, 'Position');
NewPos     = CurrentPos;
NewPos(1)  = CurrentPos(1) - 40;
set(gcf, 'Position', NewPos);

% PanelPos = get(handles.SimCurvePanel, 'Position');
% set(handles.SimRndPanel,  'Position', PanelPos);
% set(handles.SimVaryPanel, 'Position', PanelPos);
% set(handles.FitDataPanel, 'Position', PanelPos);

SetActive('SimCurve', handles);
OpenOptionsPanel_Callback(hObject, eventdata, handles);

% Outputs from this function are returned to the command line.
function varargout = qMTLab_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;

% Executes when user attempts to close qMTLab.
function SimGUI_CloseRequestFcn(hObject, eventdata, handles)
h = findobj('Tag','OptionsGUI');
delete(h);
delete(hObject);
cd(handles.root);
AppData = getappdata(0);
Fields = fieldnames(AppData);
for k=1:length(Fields)
    rmappdata(0, Fields{k});
end






%###########################################################################################
%                                 COMMON FUNCTIONS
%###########################################################################################

% METHODMENU
function MethodMenu_Callback(hObject, eventdata, handles)
Method = GetMethod(handles);
cd(fullfile(handles.root, Method));
handles.method = fullfile(handles.root,Method);
PathName = fullfile(handles.method,'Parameters');
LoadDefaultOptions(PathName);
% Update Options Panel
h = findobj('Tag','OptionsGUI');
if ~isempty(h)
    delete(h);
    OpenOptionsPanel_Callback(hObject, eventdata, handles)
end

function MethodMenu_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% GET METHOD
function Method = GetMethod(handles)
contents =  cellstr(get(handles.MethodMenu, 'String'));
Method   =  contents{get(handles.MethodMenu, 'Value')};
setappdata(0, 'Method', Method);
handles.method = fullfile(handles.root, Method);
guidata(gcf,handles);
ClearAxes(handles);
switch Method
    case 'bSSFP'
        set(handles.SimCurveAxe1, 'Visible', 'on');
        set(handles.SimCurveAxe2, 'Visible', 'on');
        set(handles.SimCurveAxe,  'Visible', 'off');
    otherwise
        set(handles.SimCurveAxe1, 'Visible', 'off');
        set(handles.SimCurveAxe2, 'Visible', 'off');
        set(handles.SimCurveAxe,  'Visible', 'on');
end

% SET DEFAULT METHODMENU
function DefaultMethodBtn_Callback(hObject, eventdata, handles)
Method = GetMethod(handles);
save(fullfile(handles.root,'Common','Parameters','DefaultMethod.mat'),'Method');

% SIMCURVE
function SimCurveBtn_Callback(hObject, eventdata, handles)
SetActive('SimCurve', handles);

% SIMVARY
function SimVaryBtn_Callback(hObject, eventdata, handles)
SetActive('SimVary', handles);

% SIMRND
function SimRndBtn_Callback(hObject, eventdata, handles)
SetActive('SimRnd', handles);

% SET ACTIVE PANEL
function SetActive(panel, handles)
setappdata(0, 'CurrentPanel', panel);
Panels = {'SimCurve', 'SimVary', 'SimRnd', 'FitData'};
for ii = 1:length(Panels)
    if (strcmp(panel,Panels{ii}))
        eval(sprintf('set(handles.%sPanel, ''Visible'', ''on'')', Panels{ii}));
        eval(sprintf('set(handles.%sBtn,''BackgroundColor'', [0.73,0.83,0.96])', Panels{ii}));
    else
        eval(sprintf('set(handles.%sPanel, ''Visible'', ''off'')', Panels{ii}));
        eval(sprintf('set(handles.%sBtn,''BackgroundColor'', [0.94,0.94,0.94])', Panels{ii}));
    end
end

% OPEN OPTIONS
function OpenOptionsPanel_Callback(hObject, eventdata, handles)
Method = GetAppData('Method');
switch Method
    case 'bSSFP'
        bSSFP_OptionsGUI(gcf);
    case 'SPGR'
        SPGR_OptionsGUI(gcf);
    case 'SIRFSE'
        SIRFSE_OptionsGUI(gcf);
end

% UPDATE OPTIONS
function UpdateOptions(Sim,Prot,FitOpt)
h = findobj('Tag','OptionsGUI');
if ~isempty(h)
    OptionsGUIhandles = guidata(h);
    set(OptionsGUIhandles.SimFileName,   'String',  Sim.FileName);
    set(OptionsGUIhandles.ProtFileName,  'String',  Prot.FileName);
    set(OptionsGUIhandles.FitOptFileName,'String',  FitOpt.FileName);
end

% SimSave
function SimSave_Callback(hObject, eventdata, handles)
[FileName,PathName] = uiputfile(fullfile('SimResults','SimResults.mat'));
if PathName == 0, return; end
CurrentPanel = GetAppData('CurrentPanel');
switch CurrentPanel
    case 'SimCurve'
        SimCurveSaveResults(PathName, FileName, handles);
    case 'SimVary'
        SimVarySaveResults(PathName,  FileName, handles);
    case 'SimRnd'
        SimRndSaveResults(PathName,   FileName, handles);
end

% SimLoad
function SimLoad_Callback(hObject, eventdata, handles)
[Filename,Pathname] = uigetfile(fullfile('SimResults','*.mat'));
if Pathname == 0, return; end
load(fullfile(Pathname,Filename));

switch FileType
    case 'SimCurveResults'
        SetActive('SimCurve', handles)
        SimCurveLoadResults(Pathname, Filename, handles);
    case 'SimVaryResults'
        SetActive('SimVary', handles)
        SimVaryLoadResults(Pathname, Filename, handles);
    case 'SimRndResults'
        SetActive('SimRnd', handles)
        SimRndLoadResults(Pathname, Filename, handles);
    otherwise
        errordlg('Invalid simulation results file');
end

% SimGO
function SimGO_Callback(hObject, eventdata, handles)
CurrentPanel = GetAppData('CurrentPanel');
switch CurrentPanel
    case 'SimCurve'
        SimCurveGO(handles);
    case 'SimVary'
        SimVaryGO(handles);
    case 'SimRnd'
        SimRndGO(handles);
end

% GETAPPDATA
function varargout = GetAppData(varargin)
for k=1:nargin; varargout{k} = getappdata(0, varargin{k}); end

% SETAPPDATA
function SetAppData(varargin)
for k=1:nargin; setappdata(0, inputname(k), varargin{k}); end

% RMAPPDATA
function RmAppData(varargin)
for k=1:nargin; rmappdata(0, varargin{k}); end

% CLEARAXES
function ClearAxes(handles)
cla(handles.SimCurveAxe1);
cla(handles.SimCurveAxe2);
cla(handles.SimCurveAxe);
cla(handles.SimVaryAxe);
cla(handles.SimRndAxe);
h = findobj(gcf,'Type','axes','Tag','legend');
delete(h);




% ##############################################################################################
%                                SINGLE VOXEL SIM
% ##############################################################################################

% SIMULATE DATA
function SimCurveGO(handles)
[Method,Prot,Sim] = GetAppData('Method','Prot','Sim');
switch Method
    case 'bSSFP';   MTdata = bSSFP_sim(Sim, Prot, 1);
    case 'SIRFSE';  MTdata = SIRFSE_sim(Sim, Prot, 1);
    case 'SPGR';    MTdata = SPGR_sim(Sim, Prot, 1);
end
SetAppData(MTdata);
SimCurveUpdate(handles);

% POP FIG
function SimCurvePopFig_Callback(hObject, eventdata, handles)
FileName =  get(handles.SimCurveFileName,'String');
Method   =  GetAppData('Method');
figure('Name',FileName);
switch Method
    case 'bSSFP'
        axe1 = handles.SimCurveAxe1;
        axe2 = handles.SimCurveAxe2;
        subplot(2,1,1);
        handles.SimCurveAxe1 = gca;
        subplot(2,1,2);
        handles.SimCurveAxe2 = gca;
        guidata(hObject, handles);
        SimCurvePlotResults(handles);
        handles.SimCurveAxe1 = axe1;
        handles.SimCurveAxe2 = axe2;
        guidata(hObject, handles);
    otherwise
       SimCurvePlotResults(handles); 
end

% UPDATE FIT
function SimCurveUpdate_Callback(hObject, eventdata, handles)
SimCurveUpdate(handles);

function SimCurveUpdate(handles)
MTdata = GetAppData('MTdata');
SimCurveResults = SimCurveFitData(MTdata);
SimCurveSetFitResults(SimCurveResults, handles);
axes(handles.SimCurveAxe);
SimCurvePlotResults(handles);
SimCurveSaveResults(fullfile(handles.method,'SimResults'), 'SimCurveTempResults.mat', handles)

% SET FIT RESULTS TABLE
function SimCurveSetFitResults(SimCurveResults, handles)
SetAppData(SimCurveResults);
[Method, Sim, Prot] = GetAppData('Method','Sim','Prot');
Param = Sim.Param;
switch Method   
    case 'bSSFP'
        names = {'F  '; 'kr '; 'R1f'; 'R1r'; 'T2f '; 'M0f'};
        input = [Param.F; Param.kr; Param.R1f; Param.R1r; Param.T2f; Param.M0f];       
    case 'SIRFSE'
        names = {'F  '; 'kr '; 'R1f'; 'R1r'; 'Sf '; 'Sr '; 'M0f'};
        [Sr,Sf] = computeSr(Param, Prot);
        input = [Param.F; Param.kr;  Param.R1f; Param.R1r; Sf; Sr; Param.M0f];       
    case 'SPGR'
        names = {'F  '; 'kr '; 'R1f'; 'R1r'; 'T2f '; 'T2r'};
        input = [Param.F; Param.kr;  Param.R1f; Param.R1r; Param.T2f; Param.T2r];  
end
error =  100*(SimCurveResults.table - input)./input;
data  =  [names, num2cell(input), num2cell(SimCurveResults.table), num2cell(error)];
set(handles.SimCurveResultsTable, 'Data', data);

% SAVE SIM RESULTS
function SimCurveSaveResults(PathName, FileName, handles)
FileType = 'SimCurveResults';
[Sim,Prot,FitOpt,MTdata,MTnoise,SimCurveResults] =  GetAppData(...
    'Sim','Prot','FitOpt','MTdata','MTnoise','SimCurveResults');
save(fullfile(PathName,FileName), '-regexp', '^(?!(handles)$).');
set(handles.SimCurveFileName,'String',FileName);

% LOAD SIM RESULTS
function SimCurveLoadResults(PathName, FileName, handles)
load(fullfile(PathName,FileName));
if (~exist('SimCurveResults', 'var'))
    errordlg('Invalid fit simulation results file');
    return;
end
SetAppData(Sim, Prot, FitOpt, MTdata, MTnoise, SimCurveResults);
UpdateOptions(Sim, Prot, FitOpt);
SimCurveSetFitResults(SimCurveResults, handles);
axes(handles.SimCurveAxe);
SimCurvePlotResults(handles);
set(handles.SimCurveFileName, 'String', FileName);

% FIT DATA
function SimCurveResults = SimCurveFitData(MTdata)
[Sim,Prot,FitOpt,Method] = GetAppData('Sim', 'Prot', 'FitOpt', 'Method');

FitOpt.R1 = computeR1obs(Sim.Param);
MTnoise = [];
if (Sim.Opt.AddNoise)
    MTnoise = noise( MTdata, Sim.Opt.SNR );
    data = MTnoise;
else
    data = MTdata;
end

switch Method
    case 'bSSFP'
        Fit = bSSFP_fit(data, Prot, FitOpt );
        SimCurveResults = bSSFP_SimCurve(Fit, Prot, FitOpt );
    case 'SPGR'
        Fit = SPGR_fit(data, Prot, FitOpt );
        SimCurveResults = SPGR_SimCurve(Fit, Prot, FitOpt );
    case 'SIRFSE'
        Fit = SIRFSE_fit(data, Prot, FitOpt);
        SimCurveResults = SIRFSE_SimCurve(Fit, Prot, FitOpt );
end
SetAppData(MTnoise,SimCurveResults);

% PLOT DATA
function SimCurvePlotResults(handles)
[ Method,  Sim,  Prot,  MTdata,  MTnoise,  SimCurveResults] = GetAppData(...
 'Method','Sim','Prot','MTdata','MTnoise','SimCurveResults');
cla;
switch Method
    case 'bSSFP'
        axe(1) = handles.SimCurveAxe1;
        axe(2) = handles.SimCurveAxe2;
        cla(axe(1)); cla(axe(2));
        bSSFP_PlotSimCurve(MTdata,  MTnoise, Prot, Sim, SimCurveResults, axe);
    case 'SIRFSE'
        SIRFSE_PlotSimCurve(MTdata, MTnoise, Prot, Sim, SimCurveResults);
    case 'SPGR'
        SPGR_PlotSimCurve(MTdata,   MTnoise, Prot, Sim, SimCurveResults);
end




% ##############################################################################################
%                                 VARY PARAMETER SIM
% ##############################################################################################

% SIMULATE DATA
function SimVaryGO(handles)
[Sim,Prot,FitOpt,Method] = GetAppData('Sim','Prot','FitOpt','Method');
SimVaryOpt = GetSimVaryOpt(handles);

opt = SimVaryOpt.table;
fields = {'F';'kr';'R1f';'R1r';'T2f';'T2r';'M0f';'SNR'};

% Data simulation
for ii = 1:8
    if opt(ii,1)
        SimVaryOpt.min  = opt(ii, 2);
        SimVaryOpt.max  = opt(ii, 3);
        SimVaryOpt.step = opt(ii, 4);
        SimVaryResults.(fields{ii}) = VaryParam(fields{ii},Sim,Prot,FitOpt,SimVaryOpt,Method);
    end
    if (getappdata(0, 'Cancel'));  break;  end
end

SetAppData(SimVaryResults);
SimVarySaveResults('SimResults', 'SimVaryTempResults.mat', handles);
SimVaryUpdatePopUp(handles);
axes(handles.SimVaryAxe);
SimVaryPlotResults(handles);


% ######################### SIMVARY OPTIONS ################################
% SAVE SimVaryOpt
function SimVaryOptSave_Callback(hObject, eventdata, handles)
SimVaryOpt = GetSimVaryOpt(handles);
SimVaryOpt.FileType = 'SimVaryOpt';
[FileName,PathName] = uiputfile(fullfile(handles.root,'Common','Parameters','SimVaryOpt.mat'));
if PathName == 0, return; end
save(fullfile(PathName,FileName),'-struct','SimVaryOpt');
setappdata(gcf, 'oldSimVaryOpt', SimVaryOpt);

% LOAD SimVaryOpt
function SimVaryOptLoad_Callback(hObject, eventdata, handles)
[FileName,PathName] = uigetfile(fullfile(handles.root,'Common','Parameters','*.mat'));
if PathName == 0, return; end
LoadSimVaryOpt(PathName, FileName, handles);

% RESET SimVaryOpt
function SimVaryOptReset_Callback(hObject, eventdata, handles)
SimVaryOpt = getappdata(gcf, 'oldSimVaryOpt');
SetSimVaryOpt(SimVaryOpt, handles);


% ########################### PLOT ########################################
% PLOT XAXIS MENU
function SimVaryPlotX_Callback(hObject, eventdata, handles)
axes(handles.SimVaryAxe);
SimVaryPlotResults(handles);

% PLOT YAXIS MENU
function SimVaryPlotY_Callback(hObject, eventdata, handles)
axes(handles.SimVaryAxe);
SimVaryPlotResults(handles);

% POP FIG
function SimVaryPopFig_Callback(hObject, eventdata, handles)
FileName = get(handles.SimVaryFileName,'String');
figure('Name',FileName);
SimVaryPlotResults(handles);


%############################ FUNCTIONS ###################################
% SAVE SIM RESULTS
function SimVarySaveResults(PathName, FileName, handles)
FileType = 'SimVaryResults';
[ Sim,  Prot,  FitOpt,  SimVaryOpt,  SimVaryResults] = GetAppData(...
 'Sim','Prot','FitOpt','SimVaryOpt','SimVaryResults');

save(fullfile(PathName,FileName), '-regexp', '^(?!(handles)$).');
set(handles.SimVaryFileName, 'String', FileName);

% LOAD SIM RESULTS
function SimVaryLoadResults(PathName, FileName, handles)
load(fullfile(PathName, FileName));
if (~exist('SimVaryResults','var'))
    errordlg('Invalid simulation results file');
    return;
end
set(handles.SimVaryFileName,'String', FileName);
SetAppData(Sim, Prot, FitOpt, SimVaryOpt, SimVaryResults)
SetSimVaryOpt(SimVaryOpt, handles);
UpdateOptions(Sim, Prot, FitOpt);
SimVaryUpdatePopUp(handles);
axes(handles.SimVaryAxe);
SimVaryPlotResults(handles);

% GET GetSimVaryOpt Get SimVaryOpt from table
function SimVaryOpt = GetSimVaryOpt(handles)
data = get(handles.SimVaryOptTable,'Data');
table(:,2:4) =  cell2mat(data(:,2:4));
table(:,1)   =  cell2mat(data(:,1));
SimVaryOpt.table =  table;
SimVaryOpt.runs  =  str2double(get(handles.SimVaryOptRuns,'String'));
SetAppData(SimVaryOpt);

% SET SetSimVaryOpt Set SimVaryOpt table data
function SetSimVaryOpt(SimVaryOpt, handles)
data = [num2cell(logical(SimVaryOpt.table(:,1))), num2cell(SimVaryOpt.table(:,2:4))];
set(handles.SimVaryOptTable, 'Data',   data);
set(handles.SimVaryOptRuns,  'String', SimVaryOpt.runs);
SetAppData(SimVaryOpt);

function SimVaryOptRuns_Callback(hObject, eventdata, handles)
GetSimVaryOpt(handles);

% LOAD LoadSimVaryOpt SimVaryOpt
function LoadSimVaryOpt(PathName, FileName, handles)
SimVaryOpt = load(fullfile(PathName, FileName));
if (~any(strcmp('FileType',fieldnames(SimVaryOpt))) || ~strcmp(SimVaryOpt.FileType,'SimVaryOpt') )
    errordlg('Invalid options file');
    return;
end
SetSimVaryOpt(SimVaryOpt, handles);
setappdata(gcf, 'oldSimVaryOpt', SimVaryOpt);

% UPDATE POPUP Update the PopUp menus
function SimVaryUpdatePopUp(handles)
[FitOpt, SimVaryResults] = GetAppData('FitOpt','SimVaryResults');
fieldsX = fieldnames(SimVaryResults);
fieldsY = FitOpt.names;
set(handles.SimVaryPlotX, 'Value',  1);
set(handles.SimVaryPlotY, 'Value',  1);
set(handles.SimVaryPlotX, 'String', fieldsX);
set(handles.SimVaryPlotY, 'String', fieldsY);

% PLOT RESULTS
function SimVaryPlotResults(handles)
[Sim, SimVaryResults] = GetAppData('Sim','SimVaryResults');
Param     =  Sim.Param;
Xcontents =  cellstr(get(handles.SimVaryPlotX,   'String'));
Xaxis     =  Xcontents{get(handles.SimVaryPlotX, 'Value')};
Ycontents =  cellstr(get(handles.SimVaryPlotY,   'String'));
Yaxis     =  Ycontents{get(handles.SimVaryPlotY, 'Value')};

Xmin =  SimVaryResults.(Xaxis).x(1)   - SimVaryResults.(Xaxis).step;
Xmax =  SimVaryResults.(Xaxis).x(end) + SimVaryResults.(Xaxis).step;
X    =  SimVaryResults.(Xaxis).x;
Y    =  SimVaryResults.(Xaxis).(Yaxis).mean;
E    =  SimVaryResults.(Xaxis).(Yaxis).std;

errorbar(X, Y, E, 'bo'); hold on;
if (strcmp(Xaxis,Yaxis))
    plot([Xmin Xmax], [Xmin Xmax], 'k-');
elseif (any(strcmp(Yaxis,fieldnames(Param))))
    plot([Xmin Xmax],[Param.(Yaxis) Param.(Yaxis)], 'k-');    
end

xlabel(sprintf('Input %s',  Xaxis), 'FontWeight', 'Bold');
ylabel(sprintf('Fitted %s', Yaxis), 'FontWeight', 'Bold');
xlim([Xmin Xmax]);
hold off;




% ##############################################################################################
%                              RANDOM PARAMETERS SIM
% ##############################################################################################

%############################# SIMULATION #################################
% SIMULATE DATA
function SimRndGO(handles)
SimRndOpt = GetSimRndOpt(handles);
[ Sim,  Prot,  FitOpt,  RndParam,  Method] = GetAppData(...
 'Sim','Prot','FitOpt','RndParam','Method');
if (isempty(RndParam)); RndParam = GetRndParam(handles); end

SimRndResults  =  VaryRndParam(Sim,Prot,FitOpt,SimRndOpt,RndParam,Method);
SetAppData(SimRndResults);
AnalyzeResults(RndParam, SimRndResults, handles);
SimRndSaveResults('SimResults', 'SimRndTempResults.mat', handles)


%########################### RANDOM OPTIONS ###############################
% SAVE SimRndOpt
function SimRndOptSave_Callback(hObject, eventdata, handles)
SimRndOpt = GetSimRndOpt(handles);
SimRndOpt.FileType  =  'SimRndOpt';
[FileName,PathName] =  uiputfile(fullfile(handles.root,'Common','Parameters','SimRndOpt.mat'));
if PathName == 0, return; end
save(fullfile(PathName,FileName), '-struct', 'SimRndOpt');
setappdata(gcf, 'oldSimRndOpt', SimRndOpt);

% LOAD SimRndOpt
function SimRndOptLoad_Callback(hObject, eventdata, handles)
[FileName,PathName] = uigetfile(fullfile(handles.root,'Common','Parameters','*.mat'));
if PathName == 0, return; end
LoadSimRndOpt(PathName, FileName, handles);

% RESET SimRndOpt
function SimRndOptReset_Callback(hObject, eventdata, handles)
SimRndOpt = getappdata(0, 'oldSimRndOpt');
SetSimRndOpt(SimRndOpt, handles);

% SimRndOpt TABLE EDIT
function SimRndOptTable_CellEditCallback(hObject, eventdata, handles)
SimRndOptEdit(handles);

% NUMVOXELS
function SimRndOptVoxels_Callback(hObject, eventdata, handles)
SimRndOptEdit(handles);

% GET RND OPT
function SimRndOpt = GetSimRndOpt(handles)
data = get(handles.SimRndOptTable, 'Data');
table(:,2:3) =  cell2mat(data(:,2:3));
table(:,1)   =  cell2mat(data(:,1));
SimRndOpt.table     =  table;
SimRndOpt.NumVoxels =  str2double(get(handles.SimRndOptVoxels, 'String'));
SetAppData(SimRndOpt);

% SET RND OPT
function SetSimRndOpt(SimRndOpt,handles)
data = [num2cell(logical(SimRndOpt.table(:,1))), num2cell(SimRndOpt.table(:,2:3))];
set(handles.SimRndOptTable,  'Data',   data);
set(handles.SimRndOptVoxels, 'String', SimRndOpt.NumVoxels);
SetAppData(SimRndOpt);

% LOAD RND OPT
function LoadSimRndOpt(PathName, FileName, handles)
FullFile = fullfile(PathName,FileName);
if PathName == 0, return; end
SimRndOpt = load(FullFile);
if (~any(strcmp('FileType',fieldnames(SimRndOpt))) || ~strcmp(SimRndOpt.FileType,'SimRndOpt') )
    errordlg('Invalid random parameters options file');
    return;
end
SetSimRndOpt(SimRndOpt,handles);
setappdata(0, 'oldSimRndOpt', SimRndOpt);

% RND OPT EDIT
function SimRndOptEdit(handles)
RndParam = GetRndParam(handles);
SetAppData(RndParam);

% GETRNDPARAM
function SimRndGetParam_Callback(hObject, eventdata, handles)
SimRndOptEdit(handles)
SimRndUpdatePopUp(handles);
SimRndPlotResults(handles);

% GET RANDOM PARAMETERS
function RndParam = GetRndParam(handles)
Sim   = GetAppData('Sim');
Param = Sim.Param;
SimRndOpt = GetSimRndOpt(handles);
n    = SimRndOpt.NumVoxels;
Vary = SimRndOpt.table(:,1);
Mean = SimRndOpt.table(:,2);
Std  = SimRndOpt.table(:,3);
fields = {'F','kr','R1f','R1r','T2f','T2r','M0f'};
for ii = 1:length(fields)
    if(Vary(ii)); RndParam.(fields{ii}) = abs(Mean(ii) + Std(ii)*(randn(n,1)));
    else          RndParam.(fields{ii}) = Param.(fields{ii})*(ones(n,1));
    end
end
SetAppData(RndParam);


% ########################### SIM RESULTS #################################
% SAVE SIM RESULTS
function SimRndSaveResults(PathName, FileName, handles)
FileType = 'SimRndResults';
[ Sim,  Prot,  FitOpt,  SimRndOpt,  RndParam,  SimRndResults] = GetAppData(...
 'Sim','Prot','FitOpt','SimRndOpt','RndParam','SimRndResults'); 
save(fullfile(PathName,FileName),'Sim','Prot','FitOpt','SimRndOpt','RndParam','SimRndResults','FileType');
set(handles.SimRndFileName, 'String', FileName);

% LOAD SIM RESULTS
function SimRndLoadResults(PathName, FileName, handles)
load(fullfile(PathName,FileName));
if (~exist('SimRndResults','var'))
    errordlg('Invalid random simulation results file');
    return;
end
set(handles.SimRndFileName,'String', FileName);
SetAppData(Sim,Prot,FitOpt,SimRndOpt,RndParam,SimRndResults);
SetSimRndOpt(SimRndOpt,handles)
UpdateOptions(Sim,Prot,FitOpt);
AnalyzeResults(RndParam, SimRndResults, handles);

% ANALYZE SIM RESULTS
function SimRndStats = AnalyzeResults(Input, Results, handles)
Fields = intersect(fieldnames(Input), fieldnames(Results));
for ii = 1:length(Fields)
    n = length(Input.(Fields{ii}));
    SimRndStats.Error.(Fields{ii})    = Results.(Fields{ii}) - Input.(Fields{ii}) ;
    SimRndStats.PctError.(Fields{ii}) = 100*(Results.(Fields{ii}) - Input.(Fields{ii})) ./ Input.(Fields{ii});
    SimRndStats.MPE.(Fields{ii})      = 100/n*sum((Results.(Fields{ii}) - Input.(Fields{ii})) ./ Input.(Fields{ii}));
    SimRndStats.RMSE.(Fields{ii})     = sqrt(sum((Results.(Fields{ii}) - Input.(Fields{ii})).^2 )/n);
    SimRndStats.NRMSE.(Fields{ii})    = SimRndStats.RMSE.(Fields{ii}) / (max(Input.(Fields{ii})) - min(Input.(Fields{ii})));
end
SetAppData(SimRndStats);
SimRndUpdatePopUp(handles);
SimRndPlotResults(handles);


% ############################## FIGURE ###################################
% UPDATE POPUP MENU
function SimRndUpdatePopUp(handles)
[RndParam, SimRndResults, SimRndStats] = GetAppData('RndParam','SimRndResults','SimRndStats');
axes(handles.SimRndAxe);
colormap('default');
set(handles.SimRndPlotX, 'Value', 1);
set(handles.SimRndPlotY, 'Value', 1);
PlotTypeFields = cellstr(get(handles.SimRndPlotType, 'String'));
PlotType = PlotTypeFields{get(handles.SimRndPlotType, 'Value')};
switch PlotType
    case 'Input parameters'
        XdataFields = fieldnames(RndParam);
        set(handles.SimRndPlotX, 'String', XdataFields);
        set(handles.SimRndPlotY, 'String', 'Voxels count');
    case 'Fit results'
        XdataFields = SimRndResults.fields;
        set(handles.SimRndPlotX, 'String', XdataFields);
        set(handles.SimRndPlotY, 'String', 'Voxels count');
    case 'Input vs. Fit'
        XdataFields = fieldnames(RndParam);
        set(handles.SimRndPlotX, 'String', XdataFields);
        YdataFields = SimRndResults.fields;
        set(handles.SimRndPlotY, 'String', YdataFields);
    case 'Error'
        XdataFields = fieldnames(SimRndStats.Error);
        set(handles.SimRndPlotX, 'String', XdataFields);
        set(handles.SimRndPlotY, 'String', 'Voxels count');
    case 'Pct error'
        XdataFields = fieldnames(SimRndStats.PctError);
        set(handles.SimRndPlotX, 'String', XdataFields);
        set(handles.SimRndPlotY, 'String', 'Voxels count');
    case 'RMSE'
        set(handles.SimRndPlotX, 'String', 'Parameters');
        set(handles.SimRndPlotY, 'String', 'RMSE');
    case 'NRMSE'
        set(handles.SimRndPlotX, 'String', 'Parameters');
        set(handles.SimRndPlotY, 'String', 'NRMSE');
    case 'MPE'
        set(handles.SimRndPlotX, 'String', 'Parameters');
        set(handles.SimRndPlotY, 'String', 'MPE');
end
guidata(gcbf,handles);

% PLOT DATA
function SimRndPlotResults(handles)
[RndParam, SimRndResults, SimRndStats] = GetAppData('RndParam','SimRndResults','SimRndStats');
PlotTypeFields  = cellstr(get(handles.SimRndPlotType, 'String'));
PlotType = PlotTypeFields{get(handles.SimRndPlotType, 'Value')};
XdataFields    =     cellstr(get(handles.SimRndPlotX, 'String'));
Xdata          = XdataFields{get(handles.SimRndPlotX, 'Value')};
YdataFields    =     cellstr(get(handles.SimRndPlotY, 'String'));
Ydata          = YdataFields{get(handles.SimRndPlotY, 'Value')};

switch PlotType
    case 'Input parameters'
        hist(RndParam.(Xdata), 30);
        xlabel(['Input ', Xdata], 'FontWeight', 'Bold');
        ylabel(Ydata, 'FontWeight',' Bold');  
    case 'Fit results'
        hist(SimRndResults.(Xdata), 30);
        xlabel(['Fitted ', Xdata], 'FontWeight','Bold');
        ylabel(Ydata, 'FontWeight','Bold');
    case 'Input vs. Fit'
        plot(RndParam.(Xdata), SimRndResults.(Ydata),'.');
        xlabel(['Input ' , Xdata], 'FontWeight','Bold');
        ylabel(['Fitted ', Ydata], 'FontWeight','Bold');
    case 'Error'
        hist(SimRndStats.Error.(Xdata), 30);
        xlabel(['Error ', Xdata], 'FontWeight','Bold');
        ylabel(Ydata, 'FontWeight','Bold');
    case 'Pct error'
        hist(SimRndStats.PctError.(Xdata), 30);
        xlabel(['Pct Error ', Xdata], 'FontWeight','Bold');
        ylabel(Ydata, 'FontWeight','Bold');
    case 'RMSE'
        Fields = fieldnames(SimRndStats.RMSE);
        for ii = 1:length(Fields)
            dat(ii) = SimRndStats.RMSE.(Fields{ii});
        end
        bar(diag(dat),'stacked');
        set(gca,'Xtick',1:5,'XTickLabel', Fields);
        legend(Fields);
        xlabel('Fitted parameters', 'FontWeight','Bold');
        ylabel('Root Mean Squared Error', 'FontWeight','Bold');
    case 'NRMSE'
        Fields = fieldnames(SimRndStats.NRMSE);
        for ii = 1:length(Fields)
            dat(ii) = SimRndStats.NRMSE.(Fields{ii});
        end
        bar(diag(dat),'stacked');
        set(gca,'Xtick',1:5,'XTickLabel', Fields);
        legend(Fields);
        xlabel('Fitted parameters', 'FontWeight','Bold');
        ylabel('Normalized Root Mean Squared Error', 'FontWeight','Bold'); 
    case 'MPE'
        Fields = fieldnames(SimRndStats.MPE);
        for ii = 1:length(Fields)
            dat(ii) = SimRndStats.MPE.(Fields{ii});
        end
        bar(diag(dat),'stacked');
        set(gca,'Xtick',1:5,'XTickLabel', Fields);
        legend(Fields);
        xlabel('Fitted parameters', 'FontWeight','Bold');
        ylabel('Mean Percentage Error', 'FontWeight','Bold');
end


% ########################### PLOT RESULTS ################################
function SimRndPopFig_Callback(hObject, eventdata, handles)
FileName = get(handles.SimRndFileName,'String');
figure('Name', FileName);
SimRndPlotResults(handles);

function SimRndPlotType_Callback(hObject, eventdata, handles)
SimRndUpdatePopUp(handles);
SimRndPlotResults(handles);

function SimRndPlotX_Callback(hObject, eventdata, handles)
SimRndPlotResults(handles);

function SimRndPlotY_Callback(hObject, eventdata, handles)
SimRndPlotResults(handles);




% ##############################################################################################
%                                    FIT DATA
% ##############################################################################################

% FITDATA
function FitDataBtn_Callback(hObject, eventdata, handles)
SetActive('FitData', handles);

% FITRESULTSSAVE
function FitResultsSave_Callback(hObject, eventdata, handles)
FitResults = GetAppData('FitResults');
[FileName,PathName] = uiputfile(fullfile('FitResults','NewFitResults.mat'));
if PathName == 0, return; end
save(fullfile(PathName,FileName),'-struct','FitResults');
set(handles.CurrentFitId,'String',FileName);

% FITRESULTSLOAD
function FitResultsLoad_Callback(hObject, eventdata, handles)
[FileName,PathName] = uigetfile(fullfile('FitResults','*.mat'));
if PathName == 0, return; end
set(handles.CurrentFitId,'String',FileName);
FitResults = load(fullfile(PathName,FileName));
Prot   =  FitResults.Prot;
FitOpt =  FitResults.FitOpt;
SetAppData(FitResults, Prot, FitOpt);
% Update Options Panel
h = findobj('Tag','OptionsGUI');
if ~isempty(h)
    OpenOptionsPanel_Callback(hObject, eventdata, handles)
end
SetActive('FitData', handles);
handles.CurrentData = FitResults;
guidata(hObject,handles);
UpdatePopUp(handles);
GetPlotRange(handles);
RefreshPlot(handles);

% MTDATA
function MTdataLoad_Callback(hObject, eventdata, handles)
[FileName,PathName] = uigetfile(fullfile('Data','*.mat'));
if PathName == 0, return; end
set(handles.MTdataFileBox,'String',fullfile(PathName,FileName));
load(fullfile(PathName,FileName));
% Set sequence
if (exist('Prot','var'))
    SetAppData(Prot);
end
OpenOptionsPanel_Callback(hObject, eventdata, handles);

function MTdataFileBox_Callback(hObject, eventdata, handles)

% MASKDATA
function MaskLoad_Callback(hObject, eventdata, handles)
[FileName,PathName] = uigetfile(fullfile('Data','*.mat'));
if PathName == 0, return; end
set(handles.MaskFileBox,'String',fullfile(PathName,FileName));

function MaskFileBox_Callback(hObject, eventdata, handles)

% R1MAP DATA
function R1mapLoad_Callback(hObject, eventdata, handles)
[FileName,PathName] = uigetfile(fullfile('Data','*.mat'));
if PathName == 0, return; end
set(handles.R1mapFileBox,'String',fullfile(PathName,FileName));

function R1mapFileBox_Callback(hObject, eventdata, handles)

% B1 MAP
function B1mapLoad_Callback(hObject, eventdata, handles)
[FileName,PathName] = uigetfile(fullfile('Data','*.mat'));
if PathName == 0, return; end
set(handles.B1mapFileBox,'String',fullfile(PathName,FileName));

function B1mapFileBox_Callback(hObject, eventdata, handles)

% B0 MAP
function B0mapLoad_Callback(hObject, eventdata, handles)
[FileName,PathName] = uigetfile(fullfile('Data','*.mat'));
if PathName == 0, return; end
set(handles.B0mapFileBox,'String',fullfile(PathName,FileName));

function B0mapFileBox_Callback(hObject, eventdata, handles)

% VIEW MAPS
function MaskView_Callback(hObject, eventdata, handles)
FullFile = get(handles.MaskFileBox,'String');
if(isempty(FullFile)); return; end;
data = importdata(FullFile);
Data.Mask = double(data);
Data.fields = {'Mask'};
handles.CurrentData = Data;
guidata(hObject,handles);
UpdatePopUp(handles);
GetPlotRange(handles);
RefreshPlot(handles);

function R1mapView_Callback(hObject, eventdata, handles)
FullFile = get(handles.R1mapFileBox,'String');
data = importdata(FullFile);
Data.R1map = double(data);
Data.fields = {'R1map'};
handles.CurrentData = Data;
guidata(hObject,handles);
UpdatePopUp(handles);
GetPlotRange(handles);
RefreshPlot(handles);

function B1mapView_Callback(hObject, eventdata, handles)
FullFile = get(handles.B1mapFileBox,'String');
data = importdata(FullFile);
Data.B1map = double(data);
Data.fields = {'B1map'};
handles.CurrentData = Data;
guidata(hObject,handles);
UpdatePopUp(handles);
GetPlotRange(handles);
RefreshPlot(handles);

function B0mapView_Callback(hObject, eventdata, handles)
FullFile = get(handles.B0mapFileBox,'String');
data = importdata(FullFile);
Data.B0map = double(data);
Data.fields = {'B0map'};
handles.CurrentData = Data;
guidata(hObject,handles);
UpdatePopUp(handles);
GetPlotRange(handles);
RefreshPlot(handles);

function StudyIDBox_Callback(hObject, eventdata, handles)



% ############################# FIT DATA ##################################
% FITDATA GO
function FitGO_Callback(hObject, eventdata, handles)
SetActive('FitData', handles);
Method =  GetAppData('Method');
data   =  struct;

% Load MTdata
MTdataFullFile = get(handles.MTdataFileBox,'String');
if (~isempty(MTdataFullFile))
    load(MTdataFullFile);
    data.MTdata = MTdata;
else
    errordlg('No MT data supplied');
    return;
end

% Mask data
data.Mask = [];
MaskFullFile = get(handles.MaskFileBox,'String');
if (~isempty(MaskFullFile));  data.Mask = importdata(MaskFullFile); end

% R1map data
data.R1map = [];
R1mapFullFile = get(handles.R1mapFileBox,'String');
if (~isempty(R1mapFullFile)); data.R1map = importdata(R1mapFullFile); end

% B1map data
data.B1map = [];
B1mapFullFile = get(handles.B1mapFileBox,'String');
if (~isempty(B1mapFullFile)); data.B1map = importdata(B1mapFullFile); end

% B0map data
data.B0map = [];
B0mapFullFile = get(handles.B1mapFileBox,'String');
if (~isempty(B0mapFullFile)); data.B0map = importdata(B0mapFullFile); end

% Get Options
[Prot, FitOpt] = GetAppData('Prot','FitOpt');

% Do the fitting
FitResults = FitData(data,Prot,FitOpt,Method,1);
FitResults.StudyID = get(handles.StudyIDBox,'String');
SetAppData(FitResults);

% Save fit results in temp file
save(fullfile('.','FitResults','FitTempResults.mat'),'-struct','FitResults');
set(handles.CurrentFitId,'String','FitTempResults.mat');

% Show results
handles.CurrentData = FitResults;
guidata(hObject,handles);
UpdatePopUp(handles);
GetPlotRange(handles);
RefreshPlot(handles);



% #########################################################################
%                            PLOT DATA
% #########################################################################

function ColorMapStyle_Callback(hObject, eventdata, handles)
val  =  get(handles.ColorMapStyle, 'Value');
maps =  get(handles.ColorMapStyle, 'String'); 
colormap(maps{val});

function Auto_Callback(hObject, eventdata, handles)
GetPlotRange(handles);
RefreshPlot(handles);

% SOURCE
function SourcePop_Callback(hObject, eventdata, handles)
GetPlotRange(handles);
RefreshPlot(handles);

% MIN
function MinValue_Callback(hObject, eventdata, handles)
min   =  str2double(get(hObject,'String'));
max = str2double(get(handles.MaxValue, 'String'));
lower =  0.5 * min;
set(handles.MinSlider, 'Value', min);
set(handles.MinSlider, 'min',   lower);
caxis([min max]);
% RefreshColorMap(handles);

function MinSlider_Callback(hObject, eventdata, handles)
min = get(hObject, 'Value');
max = str2double(get(handles.MaxValue, 'String'));
set(handles.MinValue,'String',min);
caxis([min max]);
% RefreshColorMap(handles);

% MAX
function MaxValue_Callback(hObject, eventdata, handles)
min = str2double(get(handles.MinValue, 'String'));
max = str2double(get(handles.MaxValue, 'String'));
upper =  1.5 * max;
set(handles.MaxSlider, 'Value', max)
set(handles.MaxSlider, 'max',   upper);
caxis([min max]);
% RefreshColorMap(handles);

function MaxSlider_Callback(hObject, eventdata, handles)
min = str2double(get(handles.MinValue, 'String'));
max = get(hObject, 'Value');
set(handles.MaxValue,'String',max);
caxis([min max]);
% RefreshColorMap(handles);

% VIEW
function ViewPop_Callback(hObject, eventdata, handles)
UpdatePopUp(handles);
RefreshPlot(handles);

% SLICE
function SliceValue_Callback(hObject, eventdata, handles)
Slice = str2double(get(hObject,'String'));
set(handles.SliceSlider,'Value',Slice);
View =  get(handles.ViewPop,'Value');
handles.FitDataSlice(View) = Slice;
guidata(gcbf,handles);
RefreshPlot(handles);

function SliceSlider_Callback(hObject, eventdata, handles)
Slice = get(hObject,'Value');
Slice = round(Slice);
set(handles.SliceSlider, 'Value', Slice);
set(handles.SliceValue, 'String', Slice);
View =  get(handles.ViewPop,'Value');
handles.FitDataSlice(View) = Slice;
guidata(gcbf,handles);
RefreshPlot(handles);

% OPEN FIG
function PopFig_Callback(hObject, eventdata, handles)
figure();
RefreshPlot(handles);

% SAVE FIG
function SaveFig_Callback(hObject, eventdata, handles)
[FileName,PathName] = uiputfile(fullfile('FitResults','NewFig.fig'));
if PathName == 0, return; end
h = figure();
RefreshPlot(handles);
savefig(fullfile(PathName,FileName));
delete(h);

% HISTOGRAM FIG
function Histogram_Callback(hObject, eventdata, handles)
Current = GetCurrent(handles);
ii = find(Current);
nVox = length(ii);
data = reshape(Current(ii),1,nVox);
assignin('base','data',data);
figure();
hist(data,20);

% PAN
function PanBtn_Callback(hObject, eventdata, handles)
pan on;

% ZOOM
function ZoomBtn_Callback(hObject, eventdata, handles)
zoom on;

% CURSOR
function CursorBtn_Callback(hObject, eventdata, handles)
datacursormode on;

% ############################ FUNCTIONS ##################################
function UpdateSlice(handles)
View =  get(handles.ViewPop,'Value');
dim = handles.FitDataDim;
if (dim==3)
    slice = handles.FitDataSlice(View);
    size = handles.FitDataSize(View);
    set(handles.SliceValue,  'String', slice);
    set(handles.SliceSlider, 'Min',    0);
    set(handles.SliceSlider, 'Max',    size);
    set(handles.SliceSlider, 'Value',  slice);
    Step = [1, 1] / size;
    set(handles.SliceSlider, 'SliderStep', Step);
else
    slice = 1;
    set(handles.SliceValue,  'String',1);
    set(handles.SliceSlider, 'Min',   0);
    set(handles.SliceSlider, 'Max',   1);
    set(handles.SliceSlider, 'Value', 1);
    set(handles.SliceSlider, 'SliderStep', [0 0]);
end

function UpdatePopUp(handles)
axes(handles.FitDataAxe);
Data   =  handles.CurrentData;
fields =  Data.fields;
% set(handles.SourcePop, 'Value',  1);
set(handles.SourcePop, 'String', fields);
% set(handles.ViewPop,   'Value',  1);
handles.FitDataSize = size(Data.(fields{1}));
handles.FitDataDim = ndims(Data.(fields{1}));
dim = handles.FitDataDim;
if (dim==3)
        set(handles.ViewPop,'String',{'Sagittal','Coronal','Axial'});
        if (isempty(handles.FitDataSlice))
            handles.FitDataSlice = handles.FitDataSize/2;
        end
else
        set(handles.ViewPop,'String','Axial');
        handles.FitDataSlice = 1;
end
guidata(gcbf, handles);
UpdateSlice(handles);

function GetPlotRange(handles)
Current = GetCurrent(handles);
Min = min(min(min(Current)));
Max = max(max(max(Current)));
set(handles.MinValue,  'String', Min);
set(handles.MaxValue,  'String', Max);
set(handles.MinSlider, 'Value',  Min);
set(handles.MaxSlider, 'Value',  Max);
set(handles.MinSlider, 'Min',    0.5*Min);
set(handles.MinSlider, 'Max',    Max);
set(handles.MaxSlider, 'Max',    Min);
set(handles.MaxSlider, 'Max',    1.5*Max);
guidata(gcbf, handles);

function RefreshPlot(handles)
Current = GetCurrent(handles);
xl = xlim;
yl = ylim;
imagesc(flipdim(Current',1));
axis equal off;
RefreshColorMap(handles)
xlim(xl);
ylim(yl);

function RefreshColorMap(handles)
val  = get(handles.ColorMapStyle, 'Value');
maps = get(handles.ColorMapStyle, 'String'); 
colormap(maps{val});
colorbar('location', 'South');
colorbar('XColor',[0 0 0], 'YColor',[0 0 0]);
min = str2double(get(handles.MinValue, 'String'));
max = str2double(get(handles.MaxValue, 'String'));
caxis([min max]);

function Current = GetCurrent(handles)
SourceFields = cellstr(get(handles.SourcePop,'String'));
Source = SourceFields{get(handles.SourcePop,'Value')};
View = get(handles.ViewPop,'Value');
Slice = str2double(get(handles.SliceValue,'String'));
Data = handles.CurrentData;
data = Data.(Source);
switch View
    case 1;  Current = squeeze(data(Slice,:,:));
    case 2;  Current = squeeze(data(:,Slice,:));
    case 3;  Current = squeeze(data(:,:,Slice));
end
    

% ######################## CREATE FUNCTIONS ##############################
function SimVaryOptRuns_CreateFcn(hObject, eventdata, handles)
function SimVaryPlotX_CreateFcn(hObject, eventdata, handles)
function SimVaryPlotY_CreateFcn(hObject, eventdata, handles)
function SimVaryOptTable_CellEditCallback(hObject, eventdata, handles)
function SimRndOptVoxels_CreateFcn(hObject, eventdata, handles)
function SimRndPlotX_CreateFcn(hObject, eventdata, handles)
function SimRndPlotY_CreateFcn(hObject, eventdata, handles)
function SimRndPlotType_CreateFcn(hObject, eventdata, handles)
function CurrentFitId_CreateFcn(hObject, eventdata, handles)
function ColorMapStyle_CreateFcn(hObject, eventdata, handles)
function SourcePop_CreateFcn(hObject, eventdata, handles)
function View_CreateFcn(hObject, eventdata, handles)
function MinValue_CreateFcn(hObject, eventdata, handles)
function MaxValue_CreateFcn(hObject, eventdata, handles)
function MinSlider_CreateFcn(hObject, eventdata, handles)
function MaxSlider_CreateFcn(hObject, eventdata, handles)
function SliceSlider_CreateFcn(hObject, eventdata, handles)
function SliceValue_CreateFcn(hObject, eventdata, handles)
function ViewPop_CreateFcn(hObject, eventdata, handles)
function FitDataAxe_CreateFcn(hObject, eventdata, handles)
function StudyIDBox_CreateFcn(hObject, eventdata, handles)
function MTdataFileBox_CreateFcn(hObject, eventdata, handles)
function MaskFileBox_CreateFcn(hObject, eventdata, handles)
function R1mapFileBox_CreateFcn(hObject, eventdata, handles)
function B1mapFileBox_CreateFcn(hObject, eventdata, handles)
function B0mapFileBox_CreateFcn(hObject, eventdata, handles)
