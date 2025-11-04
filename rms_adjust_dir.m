function rms_adjust_dir(inpath, outpath, rms, db)
%
% reads in wavfiles, adjusts loudness of all wav files and writes them to
% new directory
%
% INPUT
% inpath = 'path to stimulus directory' (Dont forget the \ at the end!)
% outpath = 'path where new stimuli are saved' (Dont forget the \ at the
% end!)
% rmslevel: scalar specifying new rms value (loudness), decimal between 0-1
% db : scalar specifying increase/decrease in decibel (+10 for 10 more db,
% -10 for minus 10 db). if db is specified set rms to 1.
%
% Example: rms_adjust('~/stimuli/raw/', '~/stimuli/adjusted/', 0.05)
% actual rms value: mean(rms) = 0.0210 (!)

% sampling rate and bits
sr = 44100; %48000;
nbits = '16';

% if increase/decrease was not specified in db set db to 1
if nargin < 4
    db = 1;
else
    db = 10^(db/20);
end

% list all wav files in stimulus directory
list = dir([inpath '*.wav']);


for i = 1:length(list)
    %read wav file
    W    = audioread([inpath list(i).name]);
    %[Y,FS,NBITS] = wavread([inpath list(i).name]);
    
    % W is normalized by its standard deviation (rms) and then rescaled with new
    % rms value / decibel level; since W has zero mean, standard deviation
    % and root mean square are the same!   
    Wnew = rms * db * W/std(W);
    
    %write new wav file to specified path
    audiowrite([outpath 'rmsCorrected_' list(i).name], Wnew, sr)
end