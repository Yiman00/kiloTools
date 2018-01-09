%% MasterMegaFile
% The kilosort repo comes with 3 files that need to be editted:
%       masterFile.m, configFile.m, & createChanMap.m
% I think that's unnecessarily messy so I've combined them all into this 
% masterMegaFile.m, where manual input is reduced. 
%
% Instructions:
%   - define dataset directory ('dirDataset') 
%   - define dataset name ('dsn')
%   - set paths to necessary toolboxes
%   - go over all parameteres below and make sure they are accurate.
%     Especially in the chanMap section (e.g. fs, Nchannels etc...)


%% Define paths to your dataset:

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dirDataset  = '~/Dropbox/_transfer_big_data/20170615/data/convertedToRaw/';
dsn         = 'xxxxx'; % dataset name
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% add paths:
[~, hostName] = system('hostname');
switch hostName
    case 'la-cps828317mn-huk-2.local'
        addpath(genpath('~/Dropbox/Code/spike_sorting/packages/KiloSort')) % path to kilosort folder
        addpath(genpath('~/Dropbox/Code/spike_sorting/toolboxes/npy-matlab')) % path to npy-matlab scripts
    case 'xxx'
        addpath(genpath('~/Dropbox/Code/spike_sorting/packages/KiloSort')) % path to kilosort folder
        addpath(genpath('~/Dropbox/Code/spike_sorting/toolboxes/npy-matlab')) % path to npy-matlab scripts
    otherwise
        error('Unrecognized hostname. Could not add necessary paths for sorting')
end
        
    

%% 'createChanMap.m' section:
% this section is take from the createChanMap.m file. 

fs          = 40000; % sampling frequency
Nchannels   = 24;
connected   = true(Nchannels, 1);
chanMap     = 1:Nchannels;
chanMap0ind = chanMap - 1;

electrodeGeometry = 'linear'; % linear/ stereo / whatever...

switch electrodeGeometry
    case 'linear'
        % linear geometry:
        xcoords = ones(Nchannels,1);
        ycoords = (1:Nchannels)';
        kcoords = ones(Nchannels,1);
    case 'stereo'
        % sterotrode geometry
        xSpacing = 200; % phy visualization is weird with x axis so I'm giving it 200 (despite real value being 50).
        ySpacing = 50;
        xcoords = xSpacing * repmat([0 1]', Nchannels/2,1);
        ycoords = ySpacing * kron(((Nchannels/2):-1:1)-1, [1 1])'; % using kron for stereo geometry
end

% save:
save(fullfile(dirDataset, 'chanMap.mat'), ...
    'chanMap','connected', 'xcoords', 'ycoords', 'kcoords', 'chanMap0ind', 'fs')

%% 'standardConfig.m' section:
% this section is taken from the standardConfig.m file.

ops.dirDatasets         = dirDataset;   % save into ops struct so it feeds the master.m file
ops.performAutoMerge    = false;        % if true, will create a subdirectory and save the automerged data there

ops.GPU                 = 1; % whether to run this code on an Nvidia GPU (much faster, mexGPUall first)		
ops.parfor              = 0; % whether to use parfor to accelerate some parts of the algorithm		
ops.verbose             = 1; % whether to print command line progress		
ops.showfigures         = 1; % whether to plot figures during optimization		
		
ops.datatype            = 'dat';  % binary ('dat', 'bin') or 'openEphys'		
ops.fbinary             = fullfile(dirDataset, [dsn '.' ops.datatype]); % will be created for 'openEphys'		
ops.fproc               = fullfile(dirDataset, 'temp_wh.dat'); % residual from RAM of preprocessed data		
ops.root                = dirDataset; % 'openEphys' only: where raw files are		
		
% ops.fs                  = 22000;        % sampling rate		(omit if already in chanMap file)
% ops.NchanTOT            = 24;           % total number of channels (omit if already in chanMap file)
% ops.Nchan               = 24;           % number of active channels (omit if already in chanMap file)
ops.Nfilt               = 64;           % number of clusters to use (2-4 times more than Nchan, should be a multiple of 32)     		
ops.nNeighPC            = 12; % visualization only (Phy): number of channnels to mask the PCs, leave empty to skip (12)		
ops.nNeigh              = 16; % visualization only (Phy): number of neighboring templates to retain projections of (16)		
		
% options for channel whitening		
ops.whitening           = 'full'; % type of whitening (default 'full', for 'noSpikes' set options for spike detection below)		
ops.nSkipCov            = 1; % compute whitening matrix from every N-th batch (1)		
ops.whiteningRange      = inf; % how many channels to whiten together (Inf for whole probe whitening, should be fine if Nchan<=32)		
		
% define the channel map as a filename (string) or simply an array		
ops.chanMap             = fullfile(dirDataset, 'chanMap.mat'); % make this file using createChannelMapFile.m		
ops.criterionNoiseChannels = 0.2; % fraction of "noise" templates allowed to span all channel groups (see createChannelMapFile for more info). 		
% ops.chanMap = 1:ops.Nchan; % treated as linear probe if a chanMap file		
		
% other options for controlling the model and optimization		
ops.Nrank               = 3;    % matrix rank of spike template model (3)		
ops.nfullpasses         = 6;    % number of complete passes through data during optimization (6)		
ops.maxFR               = 20000;  % maximum number of spikes to extract per batch (20000)		
ops.fshigh              = 300;   % frequency for high pass filtering		
% ops.fslow             = 2000;   % frequency for low pass filtering (optional)
ops.ntbuff              = 64;    % samples of symmetrical buffer for whitening and spike detection		
ops.scaleproc           = 200;   % int16 scaling of whitened data		
ops.NT                  = 128*1024+ ops.ntbuff;% this is the batch size (try decreasing if out of memory) 		
% for GPU should be multiple of 32 + ntbuff		
		
% the following options can improve/deteriorate results. 		
% when multiple values are provided for an option, the first two are beginning and ending anneal values, 		
% the third is the value used in the final pass. 		
ops.Th               = [6 12 12];    % threshold for detecting spikes on template-filtered data ([6 12 12])		
ops.lam              = [5 20 20];   % large means amplitudes are forced around the mean ([10 30 30])		
ops.nannealpasses    = 4;            % should be less than nfullpasses (4)		
ops.momentum         = 1./[20 400];  % start with high momentum and anneal (1./[20 1000])		
ops.shuffle_clusters = 1;            % allow merges and splits during optimization (1)		
ops.mergeT           = .1;           % upper threshold for merging (.1)		
ops.splitT           = .1;           % lower threshold for splitting (.1)		
		
% options for initializing spikes from data		
ops.initialize      = 'no'; %'fromData' or 'no'		
ops.spkTh           = -6;      % spike threshold in standard deviations (4)		
ops.loc_range       = [3  1];  % ranges to detect peaks; plus/minus in time and channel ([3 1])		
ops.long_range      = [30  6]; % ranges to detect isolated peaks ([30 6])		
ops.maskMaxChannels = 2;       % how many channels to mask up/down ([5])		
ops.crit            = .65;     % upper criterion for discarding spike repeates (0.65)		
ops.nFiltMax        = 10000;   % maximum "unique" spikes to consider (10000)		
		
% lnk commenting these lines out:
% load predefined principal components (visualization only (Phy): used for features)		
% dd                  = load('PCspikes2.mat'); % you might want to recompute this from your own data		
% ops.wPCA            = dd.Wi(:,1:7);   % PCs 		
		
% options for posthoc merges (under construction)		
ops.fracse  = 0.1; % binning step along discriminant axis for posthoc merges (in units of sd)		
ops.epu     = Inf;		
		
ops.ForceMaxRAMforDat   = 32e9; % maximum RAM the algorithm will try to use; on Windows it will autodetect.

save('ops.mat', 'ops')


%% sort that sweet sweet data:
% taken from the masterFile.m

if ops.GPU     
    gpuDevice(1); % initialize GPU (will erase any existing GPU arrays)
end

tic;
[rez, DATA, uproj] = preprocessData(ops); % preprocess data and extract spikes for initialization
rez                = fitTemplates(rez, DATA, uproj);  % fit templates iteratively
rez                = fullMPMU(rez, DATA);% extract final spike times (overlapping extraction)

% save sort results
save(fullfile(ops.root,  'rez.mat'), 'rez', '-v7.3');
rezToPhy(rez, autoMergeFolder);

% AutoMerge:
% rez2Phy will use clusters from the new 5th column of st3 if you run this
if isfield(ops, 'performAutoMerge') && ops.performAutoMerge
    rez = merge_posthoc2(rez);
    % save post autoMerge results in root folder:
    autoMergeFolder = fullfile(dirDataset, 'autoMerged');
    mkdir(autoMergeFolder)
    save(fullfile(autoMergeFolder,  'rez.mat'), 'rez', '-v7.3');
    rezToPhy(rez, autoMergeFolder);
end

% remove temporary file
delete(ops.fproc);

% ding!
try
    evalc('soundsc(double(aiffread(''/System/Library/Sounds/Glass.aiff''))'',50000)');
catch
end
