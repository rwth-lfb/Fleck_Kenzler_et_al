%code repository: https://github.com/rwth-lfb/Fleck_Kenzler_et_al
%see "manual.pdf" for instructions

%download and unzip the example movies: 
%https://www.lfb.rwth-aachen.de/download/Fleck_Kenzler_et_al_data/calcium_imaging.zip
%https://www.lfb.rwth-aachen.de/download/Fleck_Kenzler_et_al_data/reflected_light_microscopy.zip

%get started by adding all required files to the Matlab path:
set_path()

%GUI for batch registration of recordings:
movement_correction()

%GUI for data analysis: ROI extraction from the registered recordings
analysis()