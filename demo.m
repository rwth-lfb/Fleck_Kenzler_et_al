%set paths:
addpath(genpath('.\IAT_v0.9.3'));
addpath('.\movement_correction');
addpath('.\imaging_analysis');

%GUI for batch registration of recordings:
movement_correction()

%GUI for data analysis: ROI extraction from the registered recordings
analysis()