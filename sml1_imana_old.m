function varargout=sml1_imana(what,varargin)

% ------------------------- Directories -----------------------------------
baseDir         ='/Users/nicola/Documents/Data/SuperMotorLearning';
behavDir        =[baseDir '/behavioral_data'];            
imagingDir      =[baseDir '/imaging_data'];              
imagingDirRaw   =[baseDir '/imaging_data_raw'];           
dicomDir        =[baseDir '/imaging_data_dicom'];         
anatomicalDir   =[baseDir '/anatomicals'];               
freesurferDir   =[baseDir '/surfaceFreesurfer'];          
%caretDir        =[baseDir '/surfaceCaret'];              
%regDir          =[baseDir '/RegionOfInterest/'];          


% ------------------------- Experiment Info -------------------------------
numDummys  = 4;      % per run
numTRs     = 480;    % per run (includes dummies)
numruns    = [7 6];  % per subject
run        = {'1','2','3','4','5','6','7'};

% ------------------------- Subject things --------------------------------
% The variables in this section must be updated for every new subject.
%       DiconName  :  first portion of the raw dicom filename
%       NiiRawName :  first protion of the nitfi filename (get after 'PREP_4d_nifti')
%       fscanNum   :  series # for corresponding functional runs. Enter in run order
%       anatNum    :  series # for anatomical scans (~208 or so imgs/series)
%       loc_AC     :  location of the anterior commissure. 
%
% The values of loc_AC should be acquired manually prior to the preprocessing
%   Step 1: get .nii file of anatomical data by running "spmj_tar2nii(TarFileName,NiiFileName)"
%   Step 2: open .nii file with MRIcron and manually find AC and read the xyz coordinate values
%           (note: there values are not [0 0 0] in the MNI coordinate)
%   Step 3: set those values into loc_AC (subtract from zero)

subj_name  = {'p01a','p01b'};  % same pilot subject
loc_AC     = {[-106 -163 -172],...
    [-106 -163 -172]};

DicomName  = {'2017_03_15_TQ-001.MR.DIEDRICHSEN_LONGSEQLEARN',...
    '2017_03_16_TQ-02.MR.DIEDRICHSEN_LONGSEQLEARN'};

NiiRawName = {'170315110129DST131221107523418932',...
    '170316091541DST131221107523418932'};

fscanNum   = {[16 18 20 22 24 28 30],...                                 
    [12 18 20 22 28 30]};

anatNum    = {[10:14],...
    [10:14]};   % same subject, 1 anatomical 

% ------------------------- Analysis Cases --------------------------------
switch(what)
    
    case '0_PREP' % ------------ PREP: preprocessing. Expand for more info. ----
        % The PREP cases are preprocessing cases. 
        % You should run these in the following order:
        %       'PREP_dicom_import'* :  call with 'series_type','functional', 
        %                               and again with
        %                               'series_type','anatomical'.
        %       'PREP_process1'      :  Runs steps 1.3 - 1.7 (see below).
        %       'PREP_coreg'*        :  Registers meanepi to anatomical img. (step 1.8)
        %       'PREP_process2'*     :  Runs steps 1.9 - 1.11 (see below).
        %
        %   * requires user input/checks after running BEFORE next steps.
        %       See corresponding cases for more info about required
        %       user input.
        %
        % When calling any case, you can submit an array of Subj#s as so:
        %       ('some_case','sn',[Subj#s])
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    case 'PREP_dicom_import'                                                % STEP 1.1/2   :  Import functional/anatomical dicom series: enter sn
        % converts dicom to nifti files w/ spm_dicom_convert
        
        series_type = 'functional';
        vararginoptions(varargin,{'sn','series_type'});
        cwd = pwd;
        
        switch series_type
            case 'functional'
                seriesNum = fscanNum;
            case 'anatomical'
                seriesNum = anatNum;  
        end
        
        % Loop through subjects
        for s = sn;
            cd(fullfile(dicomDir,subj_name{s}));
            
            % For each series number of this subject (in 'Subject Things')
            for i=1:length(seriesNum{s})
                r     = seriesNum{s}(i);
                % Get DICOM FILE NAMES
                DIR   = dir(sprintf('%s.%4.4d.*.IMA',DicomName{s},r));          
                Names = vertcat(DIR.name);
                % Convert the dicom files with these names.
                if (~isempty(Names))
                    % Load dicom headers
                    HDR=spm_dicom_headers(Names,1);  
                    % Make a directory for series{r} for this subject.
                    % The nifti files will be saved here.
                    dirname = fullfile(dicomDir,subj_name{s},sprintf('series%2.2d',r));
                    dircheck(dirname);
                    % Go to the dicom directory of this subject
                    cd(dirname);
                    % Convert the data to nifti
                    spm_dicom_convert(HDR,'all','flat','nii');                  
                    cd ..
                end
                display(sprintf('Series %d done \n',seriesNum{s}(i)))
            end
            % Display verbose messages to user. 
            switch series_type
                case 'functional'
                    fprintf('Subject %02d functional runs imported. Copy the unique .nii name for subj files and place into ''Subject Things''.\n',s)
                case 'anatomical'
                    fprintf('Anatomical runs have been imported for subject %d.\n',s); 
                    fprintf('Please locate the T1 weighted anatomical img. Copy it to the anatomical folder.\n')
                    fprintf('Rename this file to ''s%02d_anatomical_raw.nii'' in the anatomical folder.\n',s); 
            end
        end
        cd(cwd);

    case 'PREP_func_preprocess'                                             % STEP 1.3-1.6 : Run all functional preprocessing steps
        % need to have dicom_import done prior to this step.
        vararginoptions(varargin,{'sn'});
        
        for s = sn
            sml1_imana('PREP_make_4dNifti','sn',s);
            sml1_imana('PREP_realign','sn',s);
            sml1_imana('PREP_move_data','sn',s);
            sml1_imana('PREP_meanimage_bias_correction','sn',s);
        end
    case 'PREP_make_4dNifti'                                                % STEP 1.3     :  Converts dicoms to 4D niftis out of your raw data files
        vararginoptions(varargin,{'sn'});
        for s = sn
            % For each functional run
            for i = 1:length(fscanNum{s})                                      
                outfilename = fullfile(imagingDirRaw,subj_name{s},sprintf('%s_run_%2.2d.nii',subj_name{s},i));
                % Create a 4d nifti of all functional imgs in this run.
                % Don't include the first few dummy scans in this 4d nifti.
                for j = 1:(numTRs-numDummys)                                        
                    P{j}=fullfile(dicomDir,subj_name{s},sprintf('series%2.2d',fscanNum{s}(i)),...
                        sprintf('f%s-%4.4d-%5.5d-%6.6d-01.nii',NiiRawName{s},fscanNum{s}(i),j+numDummys,j+numDummys));
                end;
                dircheck(fullfile(imagingDirRaw,subj_name{s}))
                spm_file_merge(char(P),outfilename);
                fprintf('Run %d done\n',i);
            end
        end
    case 'PREP_realign'                                                     % STEP 1.4     :  Realign functional runs
        % SPM realigns first volume in each run to first volume of first
        % run, and then registers each image in that run to the first
        % volume of that run. Hence also why it's often better to run
        % anatomical before functional scans.

        % SPM does this with 4x4 affine transformation matrix in nifti
        % header (see function 'coords'). These matrices convert from voxel
        % space to world space(mm). If the first image has an affine
        % transformation matrix M1, and image two has one (M2), the mapping
        % from 1 to 2 is: M2/M1 (map image 1 to world space-mm - and then
        % mm to voxel space of image 2).

        % Registration determines the 6 parameters that determine the rigid
        % body transformation for each image (described above). Reslice
        % conducts these transformations; resampling each image according
        % to the transformation parameters. This is for functional only!
        vararginoptions(varargin,{'sn'});

        cd(fullfile(imagingDirRaw,subj_name{sn}));
        for s=sn;
            data={};
            for i=1:length(fscanNum{sn});
                for j=1:numTRs-numDummys;
                    data{i}{j,1}=sprintf('%s_run_%2.2d.nii,%d',subj_name{sn},i,j);
                end;
            end;
            spmj_realign(data);
            fprintf('Subj %d realigned\n',s);
        end;


    %__________________________________________________________________
    case 'PREP_move_data'                                                   % STEP 1.5     :  Moves subject data from raw directories to working directories
        % Moves image data from imaging_dicom_raw into a "working dir":
        % imaging_dicom.
        vararginoptions(varargin,{'sn'});

        prefix='';
        dircheck(fullfile(baseDir, 'imaging_data',subj_name{sn}))
        for r=1:numruns(sn);

            source = fullfile(baseDir, 'imaging_data_raw',subj_name{sn}, ['r' prefix subj_name{sn},'_run_0',run{r},'.nii']);
            dest = fullfile(baseDir, 'imaging_data',subj_name{sn}, ['r' prefix subj_name{sn},'_run_0',run{r},'.nii']);

            copyfile(source,dest);
            source = fullfile(baseDir, 'imaging_data_raw',subj_name{sn}, ['rp_' subj_name{sn},'_run_0',run{r},'.txt']);
            dest = fullfile(baseDir, 'imaging_data',subj_name{sn}, ['rp_' subj_name{sn},'_run_0',run{r},'.txt']);

            copyfile(source,dest);
        end;
        source = fullfile(baseDir, 'imaging_data_raw',subj_name{sn}, ['mean' prefix subj_name{sn},'_run_0',run{1},'.nii']);
        dest = fullfile(baseDir, 'imaging_data',subj_name{sn}, ['meanepi_' subj_name{sn} '.nii']);

        copyfile(source,dest);


    %__________________________________________________________________
    case 'PREP_meanimage_bias_correction'                                   % STEP 1.6     :  Bias correct mean image prior to coregistration
        vararginoptions(varargin,{'sn'});
        
        % make copy of original mean epi, and work on that
        source  = fullfile(baseDir, 'imaging_data',subj_name{sn},['meanepi_' subj_name{sn} '.nii']);
        dest    = fullfile(baseDir, 'imaging_data',subj_name{sn},['bmeanepi_' subj_name{sn} '.nii']);
        copyfile(source,dest);
        
        % bias correct mean image for grey/white signal intensities 
        P{1}    = dest;
        spmj_bias_correct(P);
  
    case 'PREP_anat_preprocess'                                             % STEP 1.7-1.8 : Run all anatomical preprocessing steps
        % need to have dicom_import done prior to this step.
        vararginoptions(varargin,{'sn'});
        
        for s = sn
            sml1_imana('PREP_reslice_LPI','sn',s);
            sml1_imana('PREP_centre_AC','sn',s);
        end         
    case 'PREP_reslice_LPI'                                                 % STEP 1.7     :  Reslice anatomical image within LPI coordinate systems
        vararginoptions(varargin,{'sn'});
        
        % (1) Reslice anatomical image to set it within LPI co-ordinate frames
        source  = fullfile(anatomicalDir,subj_name{sn},[subj_name{sn}, '_anatomical_raw','.nii']);
        dest    = fullfile(anatomicalDir,subj_name{sn},[subj_name{sn}, '_anatomical','.nii']);
        spmj_reslice_LPI(source,'name', dest);
        
        % (2) In the resliced image, set translation to zero
        V               = spm_vol(dest);
        dat             = spm_read_vols(V);
        V.mat(1:3,4)    = [0 0 0];
        spm_write_vol(V,dat);
        display 'Manually retrieve the location of the anterior commissure (x,y,z) before continuing'
        
        
        %___________
    case 'PREP_centre_AC'                                                   % STEP 1.8     :  Re-centre AC in anatomical image
        % Set origin of anatomical to anterior commissure (must provide
        % coordinates in section (4)).
        vararginoptions(varargin,{'sn'});
        
        img    = fullfile(anatomicalDir,subj_name{sn},[subj_name{sn}, '_anatomical','.nii']);
        V               = spm_vol(img);
        dat             = spm_read_vols(V);
        V.mat(1:3,4)    = loc_AC{sn};
        spm_write_vol(V,dat);
        display 'Done'
        
        
        %_____



end    % switch(what)
end


% % Local functions

function dircheck(dir)
% Checks existance of specified directory. Makes it if it does not exist.
% SArbuckle 01/2016
if ~exist(dir,'dir');
    %warning('%s didn''t exist, so this directory was created.\n',dir);
    mkdir(dir);
end
end