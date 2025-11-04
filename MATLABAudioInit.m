function soundP = MATLABAudioInit(varargin)

    if ~nargin % then we'll use some default settings
        OVERRIDE_deviceId               = ''; % 7, 8, 9 for my laptop, BUT possible issues with sawtooth; works with 9 and headphones
        sf                              = 48000;  % sampling frequency     
        soundHz                         = 1000; % only indicate Hz if you want a single frequency sound; if soundHz=[], generates white noise
        soundDur                        = 0.5;
        nrchannels                      = 2;
        systemVol                       = 0.5; % percent of system max volume  
    elseif nargin==6
        OVERRIDE_deviceId               = varargin{1};
        sf                              = varargin{2};
        soundHz                         = varargin{3};
        soundDur                        = varargin{4};
        nrchannels                      = varargin{5};
        systemVol                       = varargin{6};
    else
        error('PTBAudioInit expects 0 or 6 arguments. Current nargin==%d.',nargin);
    end
    
    [~, hostname]                   = system('hostname');
    hostname                        = deblank(hostname);     
    
    deviceId                        = [];
    audioDevices = audiodevinfo;
    audioDevices = audioDevices.output;
    
    % THE FOLLOWING SELECTION HAS TO BE REVISED WHEN SWITCHING COMPUTERS!
    if strcmp(hostname,'stimpc1')        
        for d = 1:size(audioDevices,2)
            if strcmp(audioDevices(d).Name,'Digitalaudio (S/PDIF) (High Definition Audio-Gerät) (Windows DirectSound)')                
                deviceId = audioDevices(d).ID; 
            end
        end
    elseif strcmp(hostname,'isnaced5c6c9deb')
        deviceId = audiodevinfo(0,'Speakers (Conexant SmartAudio HD) (Windows DirectSound)');             
    elseif strcmp(hostname,'DESKTOP-8NI7JVS ')
        deviceId = audiodevinfo(0,'Köpfhörer (Conexant ISST Audio))');  
    elseif strcmp(hostname,'DESKTOP-MKH0P49')
        deviceId = audiodevinfo(0,'Lautsprecher (High Definition Audio Device) (Windows DirectSound)'); 
    elseif strcmp(hostname,'Janika-DESKTOP-E469S9A')
        deviceId = audiodevinfo(0,'Headphone (Realtek(R) Audio)');
    elseif strcmp(hostname,'DESKTOP-H8IHKLE')
        deviceId = audiodevinfo(0,'Speakers / Headphones (Realtek Audio)');
    elseif isempty(OVERRIDE_deviceId)
        error('Device ID not defined.');
    end
    if ~isempty(OVERRIDE_deviceId)
        deviceId = OVERRIDE_deviceId;
    end    
       
    % for export
    soundP              = [];
    soundP.deviceId     = deviceId;
    soundP.sf           = sf;
    soundP.soundHz      = soundHz;
    soundP.nrchannels   = nrchannels;            
    