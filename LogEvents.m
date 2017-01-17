function [Ev, nbev] = LogEvents(Ev, nbev,  type, value, ttime, varargin)
 
global taskTimeStamp

switch type
    case 'Picture'
        nbev = nbev + 1;
        Ev.types(nbev,1) = {'Picture'};
        Ev.values(nbev,1) = {value};
        Ev.times(nbev,1) = ttime.start;
        Ev.exptimes(nbev,1) = ttime.start-taskTimeStamp;
        Ev.act_durations(nbev,1) = ttime.end-ttime.start;                
        if nargin > 5
            Ev.int_durations(nbev,1) = varargin{1};
            if nargin == 7
                Ev.info(nbev,1) = varargin(2);
            else
                Ev.info(nbev,1) = {[]};
            end
        else
            %Ev.int_durations(nbev,1) = [];
        end
    case 'Button Press'
        if ~isempty(value)
            Ev.types(nbev+1:nbev+length(value),1) = {'Button Press'};
%             for i=1:length(value)
%                 if (isnumeric(value{i}) && value{i}==5 )
%                     Ev.types(nbev+i) = {'Pulse'}; 
%                 end
%             end
            Ev.values(nbev+1:nbev+length(value),1) = value;
            Ev.times(nbev+1:nbev+length(value),1) = ttime;
            Ev.exptimes(nbev+1:nbev+length(value),1) = ttime-taskTimeStamp;
            Ev.act_durations(nbev+1:nbev+length(value),1) = 0;
            Ev.int_durations(nbev+1:nbev+length(value),1) = NaN;
            Ev.info(nbev+1:nbev+length(value),1) = {[]};
            nbev = nbev + length(value);
        end
    case 'Pulse'
        Ev.types(nbev+1:nbev+length(ttime),1) = {'Pulse'};
        Ev.values{nbev+1:nbev+length(ttime),1} = 5;
        Ev.times(nbev+1:nbev+length(ttime),1) = ttime;
        Ev.exptimes(nbev+1:nbev+length(ttime),1) = ttime-taskTimeStamp;
        Ev.act_durations(nbev+1:nbev+length(ttime),1) = 0;
        Ev.int_durations(nbev+1:nbev+length(ttime),1) = NaN;
        Ev.info(nbev+1:nbev+length(ttime),1) = {[]};
        nbev = nbev + length(ttime);
end
