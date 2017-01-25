% Script to run "asta tosta" game adapted for fMRI
% Martina Puppi & Nadege Bault, January 2017

function astatostaMain

global taskTimeStamp

%% Set things up
Cfg = Config;
tNoDecision = Cfg.tNoDecision; % feedback time
tFeedback =Cfg.tFeedback; % feedback time
tVal = Cfg.tVal;

% Screenshots
Screenshot=0;  %1 to take screenshots in each trial, 0 to not take any screenshot
if Screenshot==1 && ~isdir('Screenshots')
    mkdir('Screenshots')
end

% Set Logfiles
iSubject=input('Participant number: ');
DateTime = datestr(now,'yyyymmdd-HHMM');
if ~exist('Logfiles', 'dir')
    mkdir('Logfiles');
end
resultname = fullfile('Logfiles', strcat('Sub',num2str(iSubject),'_', DateTime, '.mat'));
backupfile = fullfile('Logfiles', strcat('Bckup_Sub',num2str(iSubject), '_', DateTime, '.mat')); %save under name composed by number of subject and session

KbName('UnifyKeyNames');
Screen('Preference', 'VBLTimestampingMode', 3); %Add this to avoid timestamping problems

% Color definition
white = [255 255 255];
black = [0 0 0];
red = [255 0 0]; %#ok<NASGU>
green = [0 255 0];
blue = [0 0 255]; %#ok<NASGU>
grey = [150 150 150];

objectSize = 50;
stroke = 10;

% Bar coordinates
width_coeff = 60;
start_coord = 400;
y_coord1 = 640;
y_coord2 = 690;

%Keyboard parameters
enter=KbName('return'); % Enter
%% Trials organization
conditions = Cfg.conditions;
nrRuns = length(conditions);

% Instruction messages
instr1 = 'Benvenuto! \n \n Premi INVIO per cominciare 3 turni di prova.';
message = {'Fine della prova. \n \n Premi INVIO per cominciare l''esperimento'
    'Pausa. \n \n Premi INVIO per continuare.'
    'Pausa. \n \n Premi INVIO per continuare.'
    'Fine del gioco!'};

condname = {'BASE'
    'SECONDA PUNTATA'
    'PUNTATA VINCENTE'};

condmsg = {'La tua scelta: _____'
    'La seconda puntata: _____'
    'La puntata vincente: _____'};
%% Variables
% The two sets of object values
valueObjA = [9 12 6 19 15];
valueObjB = [5 8 11 14 18];

% Matrix of possible bids
perA = [2 5 7 9 11];
perB = [1 4 6 8 10];
matrix90 = [repmat(perA, 45, 1); repmat(perB, 45, 1)];
bigMatrix = matrix90(randperm(90),:);

% Computer choices Nash equilibrium A
lookup{6} = 2; lookup{12} = 7; lookup{15} = 9; lookup{19} = 11; lookup{9} = 5;

% Computer choices Nash equilibrium B
lookup{5} = 1; lookup{8} = 4; lookup{11} = 6; lookup{14} = 8; lookup{18} = 10;

%% initialize event log
Events.types = {};
Events.values = {};
Events.times = [];
Events.exptimes = [];
Events.act_durations = [];
Events.int_durations = [];
Events.info = {};
nbevents = 0;

%% open serial port

if strcmp(Cfg.run_mode,'mriScanner')
    SerPort = OpenSerialPort();    % open Serial Port and called it "MySerPor"
else
    SerPort = [];
end

%% Start exp
% Open PTB
screens=Screen('Screens');
Screen('Preference', 'SkipSyncTests', 2);
screenNumber=max(screens); % Main screen
[win,winRect] = Screen('OpenWindow',screenNumber,black);
Screen('TextSize',win, 22);
% Center location
[xc, yc] = RectCenterd(winRect); % Get coordinates of screen center 
hCrossRect = [(xc - objectSize) (yc - stroke) (xc + objectSize) (yc + stroke)];
vCrossRect = [(xc - stroke) (yc - objectSize) (xc + stroke) (yc + objectSize)];
% Instructions (minimal)
taskTimeStamp = GetSecs;
time.start = taskTimeStamp;

if strcmp(Cfg.run_mode,'behav')
    RestrictKeysForKbCheck(enter); % to restrict key presses to enter
    DrawFormattedText(win,instr1,'center','center',white);
    Screen('Flip',win);

    [secs, keyCode, deltaSecs] = KbWait([],2);  %#ok<*ASGLU>
    keyName{1} = KbName(keyCode);
    
    time.end = GetSecs;
    [Events, nbevents] = LogEvents(Events, nbevents,  'Picture', 'Instructions', time);
    [Events, nbevents] = LogEvents(Events, nbevents,  'Button Press', keyName, secs);
else 
    Screen('DrawTexture', win, texCross);
    Screen('Flip',win);
    time.end = GetSecs;
    [Events, nbevents] = LogEvents(Events, nbevents,  'Picture', 'FixCross', time);
end
    


%% Trial loop
trialnb = 0;

for j=1:nrRuns
    
    if strcmp(Cfg.run_mode,'mriScanner') || strcmp(Cfg.run_mode,'mriSimulator')
        %SYNCHRONIZATION TO MR SCANNER
        pulsetime = Wait_N_SerialTrigger(SerPort, Cfg.synchToScanner, Cfg.scannerSynchTimeOutMs);
        [Events, nbevents] = LogEvents(Events, nbevents,  'Pulse', [], pulsetime);
    end
    Beeper
    
    nrTrials = length(conditions{j});
    for i=1:nrTrials
        save(backupfile)   % backs the entire workspace up just in case we have to do a nasty abort
        trialnb = trialnb + 1;
        runnb(trialnb,1) = j; %#ok<*AGROW>
        
        if any(bigMatrix(i,:) == 7)
            valueObj = valueObjA;
        elseif any(bigMatrix(i,:) == 10)
            valueObj = valueObjB;
        end
        
        permvalueObj = valueObj(randperm(5));
        greenValueSubj = datasample(valueObj,1);
        greenValue = datasample(valueObj,1);
        row = bigMatrix(i,:); %set of options
        survivingChoices = row(row <= greenValueSubj);
        
        compChoice = lookup{greenValue};
        disp_only_white_values; 
        
        time.start = GetSecs;
        Screen('Flip',win);
        WaitSecs(tVal);

        if Screenshot==1
            imageArray = Screen('GetImage', win); % GetImage call. Alter the rect argument to change the location of the screen shot
            imwrite(imageArray, ['Screenshots\Trial' num2str(trialnb) '_1DispValues.jpg']) % imwrite is a Matlab function
        end
        
        time.end = GetSecs;
        [Events, nbevents] = LogEvents(Events, nbevents,  'Picture', 'DispValues', time, tVal);
        
        disp_green_value;
        disp_bars;
        disp_ticks;
        time.start = GetSecs;
        Screen('Flip',win);
        WaitSecs(tNoDecision);
        time.end = GetSecs;
        [Events, nbevents] = LogEvents(Events, nbevents,  'Picture', 'DispBarNoCursor', time, tNoDecision);
        
        %% Cursor
        %random placement of cursor
        disp_green_value;
        disp_bars;
        disp_ticks;
        randomcursor = datasample(survivingChoices,1);
        disp_cursor(randomcursor)
        
        keyCode = []; %#ok<NASGU>
        keyName=''; % empty initial value
        time.start = GetSecs;
        Time_start = GetSecs;
        Screen('Flip',win);
        
        time.end = GetSecs;
        if Screenshot==1
            imageArray = Screen('GetImage', win); % GetImage call. Alter the rect argument to change the location of the screen shot
            imwrite(imageArray, ['Screenshots\Trial' num2str(trialnb) '_2DispBar.jpg']) % imwrite is a Matlab function
        end
        
        [Events, nbevents] = LogEvents(Events, nbevents,  'Picture', 'DispBarCursor', time);
        
        %% Selection
        pos = find(survivingChoices==randomcursor);
        RestrictKeysForKbCheck([]);
        while(~strcmp(keyName,'space')) % continues until current keyName is space
            [keyTime, keyCode]=KbWait([],2);
            keyName{1} = KbName(keyCode);
            [Events, nbevents] = LogEvents(Events, nbevents,  'Button Press', keyName, keyTime);
            switch keyName{1}
                case 'LeftArrow'
                    if pos > 1
                        pos = pos - 1;
                    end
                    
                    disp_green_value;
                    disp_bars;
                    disp_ticks;
                    disp_cursor(survivingChoices(pos));
                    time.start = GetSecs;
                    Screen('Flip',win);
                    time.end = GetSecs;
                    [Events, nbevents] = LogEvents(Events, nbevents,  'Picture', 'MoveCursorLeft', time);
            
                case 'RightArrow'
                    if pos < length(survivingChoices)
                        pos = pos + 1;
                    end
                    disp_green_value;
                    disp_bars;
                    disp_ticks;
                    disp_cursor(survivingChoices(pos));
                    time.start = GetSecs;
                    Screen('Flip',win);
                    time.end = GetSecs;
                    [Events, nbevents] = LogEvents(Events, nbevents,  'Picture', 'MoveCursorRight', time);
            end
        end
        
        Time_end = GetSecs;
        Choice_RT(trialnb,1) = Time_end - Time_start;
            
        disp_green_value;
        disp_bars;
        disp_ticks;
        disp_cursor_select(survivingChoices(pos));
        time.start = GetSecs;
        Screen('Flip',win);
        Jittime = Cfg.Val_min + rand*(Cfg.Val_max - Cfg.Val_min);
        WaitSecs(Jittime);
            
        if Screenshot==1
            imageArray = Screen('GetImage', win); % GetImage call. Alter the rect argument to change the location of the screen shot
            imwrite(imageArray, ['Screenshots\Trial' num2str(trialnb) '_3DispChoiceSelect.jpg']) % imwrite is a Matlab function
        end
        
        time.end = GetSecs;
        [Events, nbevents] = LogEvents(Events, nbevents,  'Picture', 'DispChoiceSelect', time, Jittime);
        
        imp{j}(i) = survivingChoices(pos); %subject choice
        Sub_ch = survivingChoices(pos);
        
        %% determine who won
        if compChoice > Sub_ch
            humanWin = 0;
            payoff(trialnb,1) = 0;
        elseif compChoice < Sub_ch
            humanWin = 1;
            payoff(trialnb,1) = greenValueSubj - Sub_ch;
        elseif compChoice == Sub_ch
            humanWin = randi([0 1], 1, 1); %assign 50% prob of winning in case of draw
            payoff(trialnb,1) = greenValueSubj - Sub_ch;
        end
        
        %% Show post-choice info screen
        disp_ticks;
        DrawFormattedText(win, num2str(greenValueSubj), start_coord + greenValueSubj*width_coeff-10, y_coord2 + 50, white);
        
        Screen('TextSize',win, 48);
        DrawFormattedText(win,condname{conditions{j}(i)},'center',200,white);
        Screen('TextSize',win, 22);
        DrawFormattedText(win,condmsg{conditions{j}(i)},'center',900,white);
        if (conditions{j}(i) == 1) && (humanWin == 1) %BASE
            DrawFormattedText(win,num2str(Sub_ch),1110,900,white);
            Screen('TextSize',win, 48);
            DrawFormattedText(win,'Hai vinto!','center',450,white);
            Screen('TextSize',win, 22);
            Screen('FillRect', win, white, [start_coord y_coord1 start_coord+Sub_ch*width_coeff y_coord2]);
            Screen('FillRect', win, white, [start_coord+Sub_ch*width_coeff y_coord1 start_coord+(greenValueSubj)*width_coeff y_coord2]);
            disp_cursor_select(Sub_ch)
        elseif (conditions{j}(i) == 1) && (humanWin == 0) %BASE
            DrawFormattedText(win,num2str(Sub_ch),1110,900,white);
            Screen('TextSize',win, 48);
            DrawFormattedText(win,'Hai perso!','center',450,white);
            Screen('TextSize',win, 22);
            Screen('FillRect', win, white, [start_coord y_coord1 start_coord+greenValueSubj*width_coeff y_coord2]);
            disp_cursor_select(Sub_ch)
        elseif (conditions{j}(i) == 2) && (humanWin == 1) %SECONDA PUNTATA
            DrawFormattedText(win,num2str(compChoice),1110,900,white);
            Screen('TextSize',win, 48);
            DrawFormattedText(win,'Hai vinto!','center',450,white);
            Screen('TextSize',win, 22);
            Screen('FillRect', win, white, [start_coord y_coord1 start_coord+compChoice*width_coeff y_coord2]);
            Screen('FillRect', win, white, [start_coord+compChoice*width_coeff y_coord1 start_coord+Sub_ch*width_coeff y_coord2]);
            Screen('FillRect', win, white, [start_coord+Sub_ch*width_coeff y_coord1 start_coord+greenValueSubj*width_coeff y_coord2]);
            disp_cursor_select(Sub_ch)
            Screen('FillRect', win, grey, [start_coord+compChoice*width_coeff-7 y_coord1-10 start_coord+compChoice*width_coeff+7 y_coord2+10]);
            Screen('FrameRect', win, black, [start_coord+compChoice*width_coeff-8 y_coord1-16 start_coord+compChoice*width_coeff+8 y_coord2+16]);
        elseif (conditions{j}(i) == 2 && humanWin == 0) %SECONDA PUNTATA
            DrawFormattedText(win,num2str(Sub_ch),1110,900,white);
            Screen('TextSize',win, 48);
            DrawFormattedText(win,'Hai perso!','center',450,white); 
            Screen('TextSize',win, 22);
            Screen('FillRect', win, white, [start_coord y_coord1 start_coord+greenValueSubj*width_coeff y_coord2]);
            disp_cursor_select(Sub_ch)
        elseif (conditions{j}(i) == 3 && humanWin == 1) %PUNTATA VINCENTE
            DrawFormattedText(win,num2str(Sub_ch),1110,900,white);
            Screen('TextSize',win, 48);
            DrawFormattedText(win,'Hai vinto!','center',450,white);
            Screen('TextSize',win, 22);
            Screen('FillRect', win, white, [start_coord y_coord1 start_coord+Sub_ch*width_coeff y_coord2]);
            Screen('FillRect', win, white, [start_coord+Sub_ch*width_coeff y_coord1 start_coord+(greenValueSubj)*width_coeff y_coord2]);
            disp_cursor_select(Sub_ch)
        elseif (conditions{j}(i) == 3 && humanWin == 0) %PUNTATA VINCENTE
            DrawFormattedText(win,num2str(compChoice),1110,900,white);
            Screen('TextSize',win, 48);
            DrawFormattedText(win,'Hai perso!','center',450,white);
            Screen('TextSize',win, 22);
            if greenValueSubj>compChoice
                Screen('FillRect', win, white, [start_coord y_coord1 start_coord+Sub_ch*width_coeff y_coord2]);
                Screen('FillRect', win, white, [start_coord+Sub_ch*width_coeff y_coord1 start_coord+compChoice*width_coeff y_coord2]);
                Screen('FillRect', win, white, [start_coord+compChoice*width_coeff y_coord1 start_coord+greenValueSubj*width_coeff y_coord2]);
                disp_cursor_select(Sub_ch)
                Screen('FillRect', win, grey, [start_coord+compChoice*width_coeff-7 y_coord1-10 start_coord+compChoice*width_coeff+7 y_coord2+10]);
            elseif greenValueSubj<=compChoice
                Screen('FillRect', win, white, [start_coord y_coord1 start_coord+compChoice(end)*width_coeff y_coord2]);
                disp_cursor(Sub_ch)
                Screen('FillRect', win, grey, [start_coord+compChoice*width_coeff-7 y_coord1-10 start_coord+compChoice*width_coeff+7 y_coord2+10]);
                Screen('FrameRect', win, black, [start_coord+compChoice*width_coeff-8 y_coord1-16 start_coord+compChoice*width_coeff+8 y_coord2+16]);
            end
        end
        time.start = GetSecs;
        Screen('Flip',win);
        
        if Screenshot==1
            imageArray = Screen('GetImage', win); % GetImage call. Alter the rect argument to change the location of the screen shot
            imwrite(imageArray, ['Screenshots\Trial' num2str(trialnb) '_Feedback.jpg']) % imwrite is a Matlab function
        end
        
        
        WaitSecs(tFeedback);
        
        time.end = GetSecs;
        [Events, nbevents] = LogEvents(Events, nbevents,  'Picture', 'Feedback', time, tFeedback);
        
        s_value(trialnb,1) = greenValueSubj;
        s_fulloptions{trialnb} = row;
        s_options{trialnb} = survivingChoices;
        c_choice(trialnb,1) = compChoice;
        s_win(trialnb,1) = humanWin;
        
        Jittime = Cfg.Fix_min + rand*(Cfg.Fix_max - Cfg.Fix_min); 
        time.start = GetSecs;
        Screen('FillRect', win, white, vCrossRect);
        Screen('FillRect', win, white, hCrossRect);
        Screen('Flip',win);
        WaitSecs(Jittime);
        time.end = GetSecs;
        [Events, nbevents] = LogEvents(Events, nbevents,  'Picture', 'FixCross', time, Jittime);
        
    end
    
    %% Insert breaks after block 1 and block 2
    DrawFormattedText(win,message{j},'center','center',white);
    time.start = GetSecs;
    Screen('Flip',win);
    RestrictKeysForKbCheck(enter); % to restrict key presses to enter
    [secs, keyCode, deltaSecs] = KbWait([],2);
    RestrictKeysForKbCheck([]); %to turn of key presses restriction
    keyName = {KbName(keyCode)};
    time.end = GetSecs;
    [Events, nbevents] = LogEvents(Events, nbevents,  'Picture', 'Break', time);
    [Events, nbevents] = LogEvents(Events, nbevents,  'Button Press', keyName, secs);
    
end
    disp_earning
%% save data
subject(1:trialnb,1) = iSubject;
data = [subject, runnb, [1:trialnb]', cell2mat(conditions)', cell2mat(imp)', s_value,  Choice_RT, c_choice, s_win, payoff, s_fulloptions, s_options]; %#ok<NBRAK,NASGU>
save(resultname, 'data', 'Events');

%final_payoff = [];
%A = cell2mat(conditions);
%for i=1:3
 %   idx = find(A==i+1);
  %  picktrial = randsample(length(idx),1);
   % final_payoff = [final_payoff; payoff(idx(picktrial))] ;
%end

%sprintf('final payoff: %d\n', sum(final_payoff))

%% display functions
    function disp_only_white_values
        pos_horz = [1000 1100 1200 1300 1400];
        Screen('TextSize',win, 48);
        DrawFormattedText(win,condname{conditions{j}(i)},'center',200,white);
        Screen('TextSize',win, 22);
        DrawFormattedText(win,condmsg{conditions{j}(i)},'center',900,white);
        DrawFormattedText(win,'Possibili valori oggetto:',450,450,white)
        for tt=1:5
            DrawFormattedText(win, num2str(permvalueObj(1,tt)),pos_horz(tt),450,white)
        end
    end

    function disp_green_value
        pos_horz = [1000 1100 1200 1300 1400];
        Screen('TextSize',win, 48);
        DrawFormattedText(win,condname{conditions{j}(i)},'center',200,white);
        Screen('TextSize',win, 22);
        DrawFormattedText(win,condmsg{conditions{j}(i)},'center',900,white);
        DrawFormattedText(win,'Possibili valori oggetto:',450,450,white)
        for tt=1:5
            DrawFormattedText(win, num2str(permvalueObj(1,tt)),pos_horz(tt),450,white)
        end
        DrawFormattedText(win, num2str(greenValueSubj),pos_horz(greenValueSubj == permvalueObj),450,green);
    end

    function disp_bars
        Screen('FillRect', win, white, [start_coord y_coord1 start_coord+greenValueSubj*width_coeff y_coord2]);
    end

    function disp_ticks
        for rr = 1:greenValueSubj
            Screen('DrawLine', win, white, start_coord + rr*width_coeff, y_coord2, start_coord + rr*width_coeff,  y_coord2+20, 1); %tick marks
            if find(rr == survivingChoices)
                Screen('TextStyle',win, 1);
                DrawFormattedText(win, num2str(rr), start_coord + rr*width_coeff-10, y_coord2 + 50, white); %white numbers if selectable
            end
            Screen('TextStyle',win, 0);
        end
        
        %Gray out unbiddable values
        if max(row)>greenValueSubj
            Screen('FillRect', win, white, [start_coord+greenValueSubj*width_coeff y_coord2-5 start_coord+max(bigMatrix(i,:))*width_coeff y_coord2]); %bar
            for rrr = find(row > greenValueSubj)
                Screen('DrawLine', win, white, start_coord + row(rrr)*width_coeff, y_coord2, start_coord + row(rrr)*width_coeff,  y_coord2+20, 1) %tick marks; %grey ticks
                DrawFormattedText(win, num2str(row(rrr)), start_coord + row(rrr)*width_coeff-10, y_coord2 + 50, white); %gnumbers
            end
        end
    end

    function disp_cursor(horiz_pos)
        Screen('FillRect', win, white, [start_coord+horiz_pos*width_coeff-6 y_coord1-16 start_coord+horiz_pos*width_coeff+6 y_coord2+16]);
        Screen('FrameRect', win, black, [start_coord+horiz_pos*width_coeff-7 y_coord1-16 start_coord+horiz_pos*width_coeff+7 y_coord2+16]);
    end

    function disp_cursor_select(horiz_pos)
        Screen('FillRect', win, white, [start_coord+horiz_pos*width_coeff-7 y_coord1-16 start_coord+horiz_pos*width_coeff+7 y_coord2+16]);
        Screen('FrameRect', win, black, [start_coord+horiz_pos*width_coeff-8 y_coord1-16 start_coord+horiz_pos*width_coeff+8 y_coord2+16]);
    end
    
    function disp_earning
        final_payoff = [];
        A = cell2mat(conditions);
        for k=1:nrTrials
            idx = find(A==k+1);
            picktrial = randsample(length(idx),1);
            final_payoff = [final_payoff; payoff(idx(picktrial))];
        end
        DrawFormattedText(win,num2str(final_payoff),'center','center',white);
        Screen('flip',win);

    end
Screen('CloseAll');
end
