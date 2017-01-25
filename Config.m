function Cfg = Config

Cfg.run_mode = 'behav'; % 'mriScanner' or 'mriSimulator' or 'behav'


A = [1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3 3 3 3 3 3 3 3 3];
Ashuffled=A(randperm(length(A)));
Bshuffled=A(randperm(length(A)));
Cshuffled=A(randperm(length(A)));

Practice = [1 2 3];
Cfg.conditions = {Practice, Ashuffled, Bshuffled, Cshuffled};


% RUNNING IN THE MR WITH LUMINA BOX EPSON IN MR
Cfg.Screen.xDimCm = 42;
Cfg.Screen.yDimCm = 34;
Cfg.Screen.distanceCm = 134;

Cfg.synchToScanner = 5;
Cfg.ScannerSynchShowDefaultMessage = 1;

if strcmp(Cfg.run_mode,'mriScanner')
    Cfg.synchToScannerPort = 'SERIAL';
    Cfg.scannerSynchTimeOutMs = Inf; %BY DEFAULT WAIT FOREVER
    Cfg.responseDevice = 'LUMINASERIAL';
    Cfg.serialPortName = 'COM1';
    Cfg.TR = 2.2;
elseif strcmp(Cfg.run_mode,'mriSimulator')
    Cfg.synchToScannerPort = 'SIMULATE';
    Cfg.scannerSynchTimeOutMs = 3000; %BY DEFAULT WAIT FOREVER
    Cfg.responseDevice = 'KEYBOARD';
else
    Cfg.responseDevice = 'KEYBOARD';
end

% % Start PsychToolBox
% screens=Screen('Screens'); 
% screenNumber=max(screens); % Main screen 
% if strcmp(Cfg.run_mode,'mriScanner') || strcmp(Cfg.run_mode,'mriSimulator')
%     Cfg.Screen.skipSyncTests = 0;
%     oldRes=SetResolution(screenNumber,1280,1024,60);
% else
%     Screen('Preference', 'SkipSyncTests', 2); % 2 to skip tests, as we don't need milisecond precision, 0 otherwise
% end

%% timing parameters
% for fMRI current order is fixation cross, validation,
% symbols_other, show owm choice
Cfg.Val_min = 2;
Cfg.Val_max = 4;
Cfg.Fix_min = 2;
Cfg.Fix_max = 4;

% behavior
Cfg.tFixation=1.5; %time of cross on screen
Cfg.tVal=1; %parameter that we now have only in cfPost because being the response in cfTest self paced, we do not need it anymore
Cfg.tNoDecision=1.0; % feedback time

%% keyboard parameters
KbName('UnifyKeyNames'); % Use same key codes across operating systems for better portability

switch Cfg.run_mode
    case {'mriScanner', 'mriSimulator_serial'}
        keyLeft     = 3;  % RED=52
        keyRight    = 4;  % BLUE=49
        unused = [1 2];
    case {'behav','behavior', 'mriSimulator'}
        keyLeft=KbName('leftArrow'); % Left arrow
        keyRight=KbName('rightArrow'); % Right arrow
end
escape=KbName('ESCAPE');