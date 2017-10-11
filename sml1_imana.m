function varargout=sml1_imana(what,varargin)

% ------------------------- Directories -----------------------------------
baseDir         ='/Users/eberlot/Documents/Data/SuperMotorLearning';
%baseDir         ='/Users/nicola/Documents/Data/SuperMotorLearning';
behavDir        =[baseDir '/behavioral_data/data'];            
imagingDir      =[baseDir '/imaging_data'];              
imagingDirRaw   =[baseDir '/imaging_data_raw'];           
dicomDir        =[baseDir '/imaging_data_dicom'];         
anatomicalDir   =[baseDir '/anatomicals'];       
fieldmapDir     =[baseDir '/fieldmaps/'];
freesurferDir   =[baseDir '/surfaceFreesurfer'];          
caretDir        =[baseDir '/surfaceCaret'];              
regDir          =[baseDir '/RegionOfInterest/']; 
BGDir           =[baseDir '/basal_ganglia'];
suitDir         =[baseDir '/suit'];
physioDir       =[baseDir '/physio'];

% update glmDir when adding new glms
glmDir          ={[baseDir '/glmAll/glm1'],[baseDir '/glmAll/glm2'],[baseDir '/glmAll/glm3']};      % for all sessions together
glmLocDir       ={[baseDir '/glmLoc/glmL1'],[baseDir '/glmLoc/glmL2'],[baseDir '/glmLoc/glmL3']};   % localiser glm
glmLocSessDir   ={[baseDir '/glmLocSess/glmLocSess1'],[baseDir '/glmLocSess/glmLocSess2'],[baseDir '/glmLocSess/glmLocSess3'],[baseDir '/glmLocSess/glmLocSess4']}; % one glm for loc run per session
glmSessDir      ={[baseDir '/glmSess/glmSess1'],[baseDir '/glmSess/glmSess2'],[baseDir '/glmSess/glmSess3'],[baseDir '/glmSess/glmSess4']}; % one glm per session
glmFoSExDir     ={[baseDir '/glmFoSEx/glmFoSEx1'],[baseDir '/glmFoSEx/glmFoSEx2'],[baseDir '/glmFoSEx/glmFoSEx3'],[baseDir '/glmFoSEx/glmFoSEx4']};    

% ------------------------- Experiment Info -------------------------------
numDummys  = 4;        % per run
numTRs     = [440 440 440 160 440 440 440 160 440 440,...
              440 440 440 160 440 440 440 160 440 440,...
              440 440 440 160 440 440 440 160 440 440,...
              440 440 440 160 440 440 440 160 440 440];             
% per functional run (includes dummies)  
% 440 - task; 160 - localiser

% Stimuli - numbers given in SeqNumb
num_train = 1:6;
num_untrain = 7:12;   
num_seq = 1:12;
num_fing = 13:17;

% per session
numruns_sess      = 10;  
numruns_task_sess = 8;
numruns_loc_sess  = 2;

% total - per subject (the total in the end will always be 40)
numruns           = [40 40 40 40 40 40 20 20];
numruns_task      = 32;
numruns_loc       = 8;

sess = [repmat(1,1,10),repmat(2,1,10),repmat(3,1,10),repmat(4,1,10)];   % all sessions

sess_sn = [4,4,4,4,4,4,2,2];    % per subject

run_task   = [1:3 5:7 9:10;
              11:13 15:17 19:20;
              21:23 25:27 29:30;
              31:33 35:37 39:40];    % task
run_loc    = [4 8;
              14 18;
              24 28;
              34 38];             % localizer

run_num{1} = [1:10];
run_num{2} = [11:20];
run_num{3} = [21:30];
run_num{4} = [31:40];

runs{1}    = {'_01','_02','_03','_04','_05','_06','_07','_08','_09','_10'};
runs{2}    = {'_11','_12','_13','_14','_15','_16','_17','_18','_19','_20'};
runs{3}    = {'_21','_22','_23','_24','_25','_26','_27','_28','_29','_30'};
runs{4}    = {'_31','_32','_33','_34','_35','_36','_37','_38','_39','_40'};  
          
TRlength   = 1000;      % in ms
% seqNumb - all sequences: 1-19
% seqType - types of sequences 
    % 1 - training 
    % 2 - untrained (other group)
    % 3 - finger mapping

% ------------------------- ROI things ------------------------------------
hem        = {'lh','rh'};                                                   % left & right hemi folder names/prefixes
hemName    = {'LeftHem','RightHem'};
regname         = {'S1','M1','PMd','PMv','SMA','V12','SPLa','SPLp','CaudateN' 'Pallidum', 'Putamen' 'Thalamus','CIV','CV','CVI'};
regname_cortex  = {'S1','M1','PMd','PMv','SMA','V12','SPLa','SPLp'};
regname_BG      = {'CaudateN' 'Pallidum', 'Putamen', 'Thalamus'};
regname_cerebellum = {'LobIV','LobV','LobVI'};
numregions_surf = 8;
numregions_BG   = 4;
numregions_cerebellum = 3;
numregions = numregions_surf+numregions_BG+numregions_cerebellum;        
regSide=[ones(1,8) ones(1,8)*2]; % 1-left, 2-right
regType=[1:8  1:8]; % cortical areas: 1-8, BG: 8-12, cereb: 13-15


% ------------------------- Subject things --------------------------------
% The variables in this section must be updated for every new subject.
%       DicomName  :  first portion of the raw dicom filename
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

subj_name  = {'s01','s02','s03','s04','s05','s06','s07','s08'};  


% different sessions denoted with {}
DicomName{1}  = {'2017_07_18_S01.MR.DIEDRICHSEN_LONGSEQLEARN',...
                 '2017_07_25_S02.MR.DIEDRICHSEN_LONGSEQLEARN',...
                 '2017_07_25_S03.MR.DIEDRICHSEN_LONGSEQLEARN',...
                 '2017_08_08_S04.MR.DIEDRICHSEN_LONGSEQLEARN',...
                 '2017_09_05_S05.MR.DIEDRICHSEN_LONGSEQLEARN',...
                 '2017_09_19_S06.MR.Diedrichsen_LongSeqLearn',...
                 '2017_09_12_S07.MR.DIEDRICHSEN_LONGSEQLEARN'};             
DicomName{2}  = {'2017_07_25_S01.MR.DIEDRICHSEN_LONGSEQLEARN',...
                 '2017_08_01_S02.MR.DIEDRICHSEN_LONGSEQLEARN',...
                 '2017_08_01_S03.MR.DIEDRICHSEN_LONGSEQLEARN',...
                 '2017_08_15_S04.MR.DIEDRICHSEN_LONGSEQLEARN',...
                 '2017_09_12_S05.MR.DIEDRICHSEN_LONGSEQLEARN',...
                 '',...
                 '2017_09_19_S07.MR.Diedrichsen_LongSeqLearn',...
                 '2017_10_10_S08.MR.Diedrichsen_LongSeqLearn'};
DicomName{3}  = {'2017_08_15_S01.MR.DIEDRICHSEN_LONGSEQLEARN',...
                 '2017_08_22_S02.MR.DIEDRICHSEN_LONGSEQLEARN',...
                 '2017_08_23_S03.MR.DIEDRICHSEN_LONGSEQLEARN',...
                 '2017_09_06_S04.MR.DIEDRICHSEN_LONGSEQLEARN',...
                 '2017_10_03_S05.MR.Diedrichsen_LongSeqLearn',...
                 '',...
                 '2017_10_10_S07.MR.Diedrichsen_LongSeqLearn'};             
DicomName{4}  = {'2017_08_16_S01.MR.DIEDRICHSEN_LONGSEQLEARN',...
                 '2017_08_23_S02.MR.DIEDRICHSEN_LONGSEQLEARN',...
                 '2017_08_25_S03.MR.DIEDRICHSEN_LONGSEQLEARN',...
                 '2017_09_12_S04.MR.DIEDRICHSEN_LONGSEQLEARN',...
                 '2017_10_04_S05.MR.Diedrichsen_LongSeqLearn',...
                 '',...
                 '2017_10_11_S07.MR.Diedrichsen_LongSeqLearn'};


NiiRawName{1} = {'170718114530DST131221107523418932',...
                 '170725105405DST131221107523418932',...
                 '170725090958DST131221107523418932',...
                 '170808113354DST131221107523418932',...
                 '170905134655DST131221107523418932',...
                 '170919130243DST131221107523418932',...
                 '170912103955DST131221107523418932'};
NiiRawName{2} = {'170725124629DST131221107523418932',...
                 '170801131823DST131221107523418932',...
                 '170801113315DST131221107523418932',...
                 '170815122423DST131221107523418932',...
                 '170912143950DST131221107523418932',...
                 '',...
                 '170919112438DST131221107523418932'};
NiiRawName{3}  = {'170815144204DST131221107523418932',...
                  '170822110530DST131221107523418932',...
                  '170823110924DST131221107523418932',...
                  '170906090741DST131221107523418932',...
                  '171003133651DST131221107523418932',...
                  '',...
                  '171010145029DST131221107523418932'};  
NiiRawName{4}  = {'170816090254DST131221107523418932',...
                  '170823091559DST131221107523418932',...
                  '170825085040DST131221107523418932',...
                  's04',...
                  '171004134839DST131221107523418932',...
                  '',...
                  '171011103434DST131221107523418932'};

fscanNum{1}   = {[16 18 20 22 24 26 28 30 32 34],...
                 [16 18 20 22 24 26 28 30 32 34],...
                 [17 19 21 23 25 27 29 31 33 35],...
                 [16 18 20 22 24 26 28 30 32 34],...
                 [19 21 23 25 27 29 31 33 35 37],...
                 [10 12 14 16 18 20 22 24 26 28],...
                 [19 21 23 25 27 29 31 33 35 37],...
                 []};             
fscanNum{2}   = {[11 13 15 17 19 21 23 25 27 29],...
                 [11 13 15 17 19 21 23 25 27 29],...
                 [11 13 15 17 19 21 23 25 27 29],...
                 [11 13 15 17 23 27 31 25 33 35],...
                 [14 16 18 28 22 24 26 34 30 32],...
                 [],...
                 [12 14 16 18 20 22 24 26 28 30],...
                 []};    
fscanNum{3}   = {[11 13 15 17 19 21 23 25 27 29],...
                 [11 13 19 17 21 23 27 25 29 31],... 
                 [11 13 15 17 19 21 23 25 27 29],...
                 [12 14 16 18 20 22 24 26 28 30],...
                 [15 17 19 21 23 25 27 29 31 33],...
                 [],...
                 [13 15 17 19 21 23 27 29 31 35]};  
fscanNum{4}   = {[11 13 15 17 19 21 23 25 27 29],...
                 [11 13 15 17 21 23 27 25 29 31],...  
                 [11 13 15 17 19 21 23 25 27 29],...
                 [11 13 15 17 19 21 23 25 29 31],...
                 [14 16 18 20 22 24 26 28 30 32],...
                 [],...
                 [13 15 17 19 21 23 25 27 29 31]};    

fieldNum{1}   = {[35,36],...
                 [35,36],...
                 [36,37],...
                 [35,36],...
                 [38,39],...
                 [29,30],...
                 [38,39],...
                 []};
fieldNum{2}   = {[30,31],...
                 [30,31],...
                 [30,31],...
                 [36,37],...
                 [35,36],...
                 [],...
                 [31 32],...
                 []};
fieldNum{3}   = {[30,31],...
                 [32,33],...
                 [30,31],...
                 [31,32],...
                 [34 35],...
                 [],...
                 [36,37]};
fieldNum{4}   = {[30,31],...
                 [32,33],...
                 [30,31],...
                 [32,33],...
                 [33,34],...
                 [],...
                 [32 33]};

anatNum    = {[10:14],...
              [10:14],...
              [11:15],...
              [10:14],...
              [11:15],...
              [4:8],...
              [10:14]};  
          
loc_AC     = {[-112 -165 -176],...
              [-106 -173 -163],...
              [-107 -178 -163],...
              [-103 -162 -167],...
              [-105 -163 -163],...
              [-107 -169 -156],...
              [-105 -163 -162]};

% Other random notes %

% Dicom system changed with s05 (sessN 3,4), s06 (sessN 1-4) and s07 (sessN 2-4)


% ------------------------------ Analysis Cases --------------------------------
switch(what)
    
    case '0_MISC' % ------------ MISC: some aux. things ------------------------
    case 'MISC_check_time'                                                  % Check alignment of scanner and recorded time (sanity check): enter sn
        vararginoptions(varargin,{'sn'});
        %sn = Opt.sn;
        cd(behavDir);
        
        D=dload(sprintf('sml1_%s.dat',subj_name{sn}));
        figure('Name',sprintf('Timing of Task Onsets vs. TR onsets for Subj %d',sn),'NumberTitle','off')
        
        % plot alignment of TR time and trial onset time
        subplot(2,1,1); plot(D.startTimeReal/1000,(D.startTR-1)*TRlength/1000+D.startTRTime/1000)
        title('Alignment of TR time and Trial onset time')
        
        % plot difference of TR time and trial onset time
        subplot(2,1,2); plot((D.startTimeReal-(D.startTR-1)*TRlength+D.startTRTime)/1000)
        title('Difference of Trial onset time and TR time')
        xlabel('trial')
        ylabel('ms')
    case 'MISC_check_movement'                                              % Check movement of subject. Requires GLM 3 for specified subject.
        vararginoptions(varargin,{'sn','sessN'});
        
        glmSubjDir = [glmSessDir{sessN} filesep subj_name{sn}];
        cd(glmSubjDir);
        load SPM;
        spm_rwls_resstats(SPM)    
    
    case 'PHYSIO_read'                                              % Process pulse and respiration!! DEPRECIATED   
        % Read raw physio and make regressors for both sessions
        vararginoptions(varargin,{'sn'});

        % indicator for number of loc/func runs (across sessions)
        indx_lc = 1;
        indx_fn = 1;
        
        for sessN = 1:sess_sn(sn)   % do for all sessions for that subject
            physioRawDir=[dicomDir,'/',sprintf('%s_%d',subj_name{sn},sessN),'/Physio'];
            
            snDir = fullfile(dicomDir,sprintf('%s_%d',subj_name{sn},sessN));
            ndicom = DicomName{sessN}{sn};
            nscans = fscanNum{sessN}{sn};
            
            D = physio_processSiemens(snDir,ndicom,nscans,'dummyTR',numDummys,'physioDir',physioRawDir);
            
            [~,W] = physio_getCardiacPhase(D,'fig',1);
            
            % split into localizer and functional runs - separate glms used!
            W_LOC = {W{4} W{8}};  % localizer
            W_FUNC = {W{1} W{2} W{3} W{5} W{6} W{7} W{9} W{10}};   % functional
            
            % ensure all the runs have equal length - cut the longer runs
            for i = 1: numruns_task_sess
                if length(W_FUNC{i}) ~= numTRs(1)-numDummys
                    temp=W_FUNC{i}(1:(numTRs(1)-numDummys)); % store the initial values into a temp var
                    W_FUNC{i}=zeros(1,(numTRs(1)-numDummys)); % clear the long run
                    W_FUNC{i}=temp;
                end
            end
            
            [CregsLOC,CnamesLOC] = physio_makeCardiacRegressors(W_LOC);     % localizer
            [CregsFUNC,CnamesFUNC] = physio_makeCardiacRegressors(W_FUNC);   % functional runs
            
            % re-arrange in a structure with cos/sin regressors per run
            
            % localizer
            
            for r = 1:numruns_loc_sess
                L=[];
                L.regSin=CregsLOC((r*2)-1,:); % use sth else, not r - increments after every loop
                L.regCos=CregsLOC((r*2),:);
                P_loc{indx_lc}=L;
                indx_lc=indx_lc+1;
            end
            
            for r = 1:numruns_task_sess
                T=[];
                T.regSin=CregsFUNC((r*2)-1,:);
                T.regCos=CregsFUNC((r*2),:);
                P_func{indx_fn}=T;
                indx_fn=indx_fn+1;
            end
        end
        
        % save regressors for localizer and functional runs
        dircheck(fullfile(physioDir,subj_name{sn}));
        save(fullfile(physioDir,subj_name{sn},'physioLoc.mat'),'P_loc');
        save(fullfile(physioDir,subj_name{sn},'physioFunc.mat'),'P_func');

    case 'BEH_scanner_er_mt'                                                % Analyse and plot ER and MT per subject
        vararginoptions(varargin,{'sn'});
        
        sessN = sess_sn(sn);
        B_loc = [];
        B_fun = [];
        
        for ss = 1:sessN

            for s = sn

                D = dload(fullfile(behavDir,['sml1_',subj_name{s},'.dat']));
                
                R = getrow(D,D.ScanSess==ss);
                F = getrow(R,R.blockType==3 | R.blockType==9);  % functional runs  
                L = getrow(R,R.blockType==4);   % localiser
                % calculate / save variables
                % Loc - MT, ER
                BL.MT = L.MT;
                BL.ER = L.isError;
                BL.ScanSess = L.ScanSess;
                BL.sn = s*ones(size(L.ScanSess));
                % Func - MT, ER (for trained and untrained separately)
                BF.MT = F.MT;
                BF.ER = F.isError;
                BF.ScanSess = F.ScanSess;
                BF.seqType = F.seqType;
                BF.sn = s*ones(size(F.ScanSess));
                % Add all var into structures B_loc and B_fun
                
                B_loc = addstruct(B_loc,BL);
                B_fun = addstruct(B_fun,BF);
            end
        end
        
        lab = {'Sess1','Sess2'};
        
        figure(1)
        subplot(2,2,1)
        barplot(B_loc.ScanSess,B_loc.MT); ylabel('Mov Time'); title('Localiser'); xlabel('Session');
        subplot(2,2,2)
        barplot(B_fun.ScanSess,B_fun.MT,'split',B_fun.seqType,'leg',{'train','untrain'},'leglocation','northeast'); ylabel('Mov Time'); xlabel('Session'); title('Functional runs');
        subplot(2,2,3)
        barplot(B_loc.ScanSess,B_loc.ER); ylabel('Error rate'); xlabel('Session');
        subplot(2,2,4)
        barplot(B_fun.ScanSess,B_fun.ER,'split',B_fun.seqType,'leg',{'train','untrain'},'leglocation','northeast'); ylabel('Error rate'); xlabel('Session');
        
        figure;
        for i=1:5
            subplot(1,5,i)
            barplot(B_fun.ScanSess,B_fun.MT,'split',B_fun.seqType,'subset',B_fun.sn==i,'leg',{'train','untrain'})
        end
        
        keyboard;
    case 'BEH_training'
        vararginoptions(varargin,{'sn'});
        
        AllSubj = [];
        figure
        
        for s = sn
            
            D = dload(fullfile(behavDir,['sml1_',subj_name{s},'.dat']));
            
            R = getrow(D,D.blockType==6);
            
            runs = 1:length(unique(R.BN));
            blockNum = kron(runs',ones(24,1)); % 24 trials
            subplot(1,numel(sn),s)
            lineplot(blockNum,R.MT,'style_thickline');
            
            R.sn = s*ones(size(R.timeTrial));
            AllSubj = addstruct(AllSubj,R);
            
        end
        
        keyboard;

    case '1_PREP' % ------------ PREP: preprocessing. Expand for more info. ----
        % The PREP cases are preprocessing cases.
        % You should run these in the following order:
        %       'PREP_dicom_import'*    :  call with 'series_type','functional',
        %                                  'series_type','anatomical'
        %                                   and 'series_type','fieldmap'.
        %       'PREP_process1_func'    :   Runs steps 1.3 - 1.8 (see below).
        %       'PREP_precess1_anat'    :   Runs steps 1.9 - 1.11 (see below).
        %       'PREP_coreg'*           :   Registers meanepi to anatomical img. (step 1.12)
        %       'PREP_process2'*        :   Runs steps 1.9 - 1.11 (see below).
        %
        %   * requires user input/checks after running BEFORE next steps.
        %       See corresponding cases for more info about required
        %       user input.
        %
        % When calling any case, you can submit an array of Subj#s as so:
        %       ('some_case','sn',[Subj#s])
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    case 'PREP_dicom_import'                                                % STEP 1.1/2/3   :  Import functional/anatomical/field map dicom series: enter sn, series type
        % converts dicom to nifti files w/ spm_dicom_convert
        
        series_type = 'functional';
        sessN = 1;
        vararginoptions(varargin,{'sn','sessN','series_type'});
        cwd = pwd;
        
        switch series_type
            case 'functional'
                seriesNum = fscanNum{sessN};
            case 'anatomical'
                seriesNum = anatNum;
            case 'fieldmap'
                seriesNum = fieldNum{sessN};
        end
        
        % Loop through subjects
        for s = sn;
            dircheck(fullfile(dicomDir,[subj_name{s},sprintf('_%d',sessN)]));
            cd(fullfile(dicomDir,[subj_name{s},sprintf('_%d',sessN)]));
            
            % For each series number of this subject (in 'Subject Things')
            for i=1:length(seriesNum{s})
                r     = seriesNum{s}(i);
                % Get DICOM FILE NAMES
                if (sn<5 || sn==5 && sessN<3 || sn==7 && sessN<2)
                    DIR   = dir(sprintf('%s.%4.4d.*.IMA',DicomName{sessN}{s},r));   % Get DICOM FILE NAMES
                else
                    folder = fullfile(dicomDir,[subj_name{s},sprintf('_%d',sessN)],[sprintf('%4.4d',r)]);
                    cd(folder)
                    DIR   = dir(sprintf('%s.%4.4d.*.dcm',DicomName{sessN}{s},r));   % Get DICOM FILE NAMES
                end
                Names = vertcat(DIR.name);
                % Convert the dicom files with these names.
                if (~isempty(Names))
                    % Load dicom headers
                    HDR=spm_dicom_headers(Names,1);
                    
                    % Make a directory for series{r} for this subject.
                    % The nifti files will be saved here.

                    dirname = fullfile(dicomDir,[subj_name{s},sprintf('_%d',sessN)],sprintf('series%2.2d',r));
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
                    fprintf('Rename this file to ''%s_anatomical_raw.nii'' in the anatomical folder.\n',subj_name{s});
                case 'fieldmap'
                    fprintf('Subject %s fieldmaps imported.\n',subj_name{s});
                    fieldmapfold = fullfile(fieldmapDir,subj_name{s},sprintf('sess%d',sessN));
                    dircheck(fieldmapfold);
                    fprintf('The subfolder ''sess%d'' in the subject fieldmap folder ''%s'' was created for you.\n',sessN,subj_name{s});
                    fprintf('Please locate the magnitude and phase files (different series).\n');
                    fprintf('Rename the files into ''%s_magnitude.nii'' and ''%s_phase.nii''.\n',subj_name{s},subj_name{s});
            end
        end
        cd(cwd);

    case 'PREP_process1_func'                                               
        % need to have dicom_import done prior to this step.
        vararginoptions(varargin,{'sn','sessN'});
        
        for s = sn
            sml1_imana('PREP_make_4dNifti','sn',s,'sessN',sessN);
            sml1_imana('PREP_makefieldmap','sn',s,'sessN',sessN);
            sml1_imana('PREP_make_realign_unwarp','sn',s,'sessN',sessN);
            sml1_imana('PREP_move_data','sn',s,'sessN',sessN);
            sml1_imana('PREP_meanimage_bias_correction','sn',s);
        end
    case 'PREP_make_4dNifti'                                                % STEP 1.4       :  Converts dicoms to 4D niftis out of your raw data files
        vararginoptions(varargin,{'sn','sessN'});
        for s = sn
            for ss = 1:sessN
                % For each functional run
                for i = 1:length(fscanNum{sessN}{s})
                    outfilename = fullfile(imagingDirRaw,subj_name{s},sprintf('sess%d',ss),sprintf('%s_run_%2.2d.nii',subj_name{s},run_num{ss}(i)));
                    % Create a 4d nifti of all functional imgs in this run.
                    % Don't include the first few dummy scans in this 4d nifti.
                    P={};
                    for j = 1:(numTRs(i)-numDummys)
                        P{j}=fullfile(dicomDir,[subj_name{s},sprintf('_%d',ss)],sprintf('series%2.2d',fscanNum{ss}{s}(i)),...
                            sprintf('f%s-%4.4d-%5.5d-%6.6d-01.nii',NiiRawName{ss}{s},fscanNum{ss}{s}(i),j+numDummys,j+numDummys));
                    end;
                    dircheck(fullfile(imagingDirRaw,subj_name{s},sprintf('sess%d',ss)))
                    spm_file_merge(char(P),outfilename);
                    fprintf('Run %d in session %d done -> overall run %d\n',i,ss,run_num{ss}(i));
                end; % run
            end; % session - ss
        end; % sn
    case 'PREP_makefieldmap'                                                % STEP 1.5       :  Create field map
        prefix = '';
        vararginoptions(varargin,{'sn','sessN'});
        for ss=1:sessN
            subfolderRawdata    = sprintf('sess%d',ss);
            subfolderFieldmap   = sprintf('sess%d',ss);
            
            spmj_makefieldmap(baseDir, subj_name{sn}, runs{ss},'prefix',prefix,'subfolderRawdata',subfolderRawdata,'subfolderFieldmap',subfolderFieldmap);
        end
    case 'PREP_make_realign_unwarp'                                         % STEP 1.6       :  Realign + unwarp functional runs
        prefix  ='';
        vararginoptions(varargin,{'sn','sessN'});
                
        subfolderRawdata    = {'sess1','sess2','sess3','sess4'};
        subfolderFieldmap   = {'sess1','sess2','sess3','sess4'};
        subj_runs           = runs;
        
        subfolderRawdata    = subfolderRawdata(1:sessN);
        subfolderFieldmap   = subfolderFieldmap(1:sessN);
        subj_runs           = subj_runs(1:sessN);

        spmj_realign_unwarp_sess(baseDir, subj_name{sn}, subj_runs, numTRs, 'prefix',prefix, 'subfolderRawdata',subfolderRawdata,'subfolderFieldmap',subfolderFieldmap);      
    case 'PREP_plot_movementparameters'                                     % OPTIONAL       :  Investigate movement parameters
        vararginoptions(varargin,{'sn','sessN'});
        X=[];
        %r=[1:numruns(sn)];
        for r=1:10 % 10 functional runs
            x = dlmread (fullfile(baseDir, 'imaging_data',subj_name{sn}, ['rp_' subj_name{sn},'_run' runs{sessN}{r},'.txt']));
            X = [X; x];
        end
       
        clr = hsv(3);
        subplot(2,1,1); 
        for i = 1:3
            plot(X(:,i),'Color',clr(i,:))
            hold on;
        end
        legend('x', 'y', 'z', 'location' , 'EastOutside')

        subplot(2,1,2); 
        for j = 1:3
            plot(X(:,j+3)*180/pi,'Color',clr(j,:));
            hold on;
        end
        legend('pitch', 'roll', 'yaw', 'location' , 'EastOutside') 
    case 'PREP_move_data'                                                   % STEP 1.7       :  Moves subject data from raw directories to working directories
        % Moves image data from imaging_dicom_raw into a "working dir":
        % imaging_dicom.
        vararginoptions(varargin,{'sn','sessN'});

        prefix='';
        dircheck(fullfile(baseDir, 'imaging_data',subj_name{sn}));
        for ss=1:sessN;
            disp(['Sess' num2str(ss)]);
            for r=1:numruns_sess;
                
                source = fullfile(baseDir, 'imaging_data_raw',subj_name{sn},sprintf('sess%d',ss), ['u' prefix subj_name{sn},'_run',runs{ss}{r},'.nii']);
                dest = fullfile(baseDir, 'imaging_data',subj_name{sn}, ['u' prefix subj_name{sn},'_run',runs{ss}{r},'.nii']);
                
                copyfile(source,dest);
                source = fullfile(baseDir, 'imaging_data_raw',subj_name{sn},sprintf('sess%d',ss), ['rp_' subj_name{sn},'_run',runs{ss}{r},'.txt']);
                dest = fullfile(baseDir, 'imaging_data',subj_name{sn}, ['rp_' subj_name{sn},'_run',runs{ss}{r},'.txt']);
                
                copyfile(source,dest);
            end;
            
            if ss == 1
                source = fullfile(baseDir, 'imaging_data_raw',subj_name{sn},sprintf('sess%d',ss), ['meanu' prefix subj_name{sn},'_run',runs{1}{1},'.nii']); %first run of first session used for mean
                dest = fullfile(baseDir, 'imaging_data',subj_name{sn}, ['meanepi_' subj_name{sn} '.nii']);
                
                copyfile(source,dest);
            end
        end   

    %__________________________________________________________________
    case 'PREP_meanimage_bias_correction'                                   % STEP 1.8       :  Bias correct mean image prior to coregistration
        vararginoptions(varargin,{'sn'});
        
        % make copy of original mean epi, and work on that
        source  = fullfile(baseDir, 'imaging_data',subj_name{sn},['meanepi_' subj_name{sn} '.nii']);
        dest    = fullfile(baseDir, 'imaging_data',subj_name{sn},['bmeanepi_' subj_name{sn} '.nii']);
        copyfile(source,dest);
        
        % bias correct mean image for grey/white signal intensities 
        P{1}    = dest;
        spmj_bias_correct(P);
  
    case 'PREP_process1_anat'                                               
        % need to have dicom_import done prior to this step.
        % only run once per subject (after first session)
        vararginoptions(varargin,{'sn'});
        
        for s = sn
            sml1_imana('PREP_reslice_LPI','sn',s);
            sml1_imana('PREP_centre_AC','sn',s);
            sml1_imana('PREP_segmentation','sn',s);
        end         
    case 'PREP_reslice_LPI'                                                 % STEP 1.9       :  Reslice anatomical image within LPI coordinate systems
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
    case 'PREP_centre_AC'                                                   % STEP 1.10      :  Re-centre AC in anatomical image
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
    case 'PREP_segmentation'                                                % STEP 1.11      :  Segmentation & normalization
        vararginoptions(varargin,{'sn'});

        SPMhome=fileparts(which('spm.m'));
        J=[];
        for s=sn
            J.channel.vols = {fullfile(anatomicalDir,subj_name{sn},[subj_name{sn},'_anatomical.nii,1'])};
            J.channel.biasreg = 0.001;
            J.channel.biasfwhm = 60;
            J.channel.write = [0 0];
            J.tissue(1).tpm = {fullfile(SPMhome,'tpm/TPM.nii,1')};
            J.tissue(1).ngaus = 1;
            J.tissue(1).native = [1 0];
            J.tissue(1).warped = [0 0];
            J.tissue(2).tpm = {fullfile(SPMhome,'tpm/TPM.nii,2')};
            J.tissue(2).ngaus = 1;
            J.tissue(2).native = [1 0];
            J.tissue(2).warped = [0 0];
            J.tissue(3).tpm = {fullfile(SPMhome,'tpm/TPM.nii,3')};
            J.tissue(3).ngaus = 2;
            J.tissue(3).native = [1 0];
            J.tissue(3).warped = [0 0];
            J.tissue(4).tpm = {fullfile(SPMhome,'tpm/TPM.nii,4')};
            J.tissue(4).ngaus = 3;
            J.tissue(4).native = [1 0];
            J.tissue(4).warped = [0 0];
            J.tissue(5).tpm = {fullfile(SPMhome,'tpm/TPM.nii,5')};
            J.tissue(5).ngaus = 4;
            J.tissue(5).native = [1 0];
            J.tissue(5).warped = [0 0];
            J.tissue(6).tpm = {fullfile(SPMhome,'tpm/TPM.nii,6')};
            J.tissue(6).ngaus = 2;
            J.tissue(6).native = [0 0];
            J.tissue(6).warped = [0 0];
            J.warp.mrf = 1;
            J.warp.cleanup = 1;
            J.warp.reg = [0 0.001 0.5 0.05 0.2];
            J.warp.affreg = 'mni';
            J.warp.fwhm = 0;
            J.warp.samp = 3;
            J.warp.write = [1 1];   
            matlabbatch{1}.spm.spatial.preproc=J;
            spm_jobman('run',matlabbatch);
            fprintf('Check segmentation results for %s\n', subj_name{s})
        end;


    %__________________________________________________________________
        
    case 'PREP_coreg'                                                       % STEP 1.12      :  Coregister meanepi to anatomical image - only needs to be done for 1st session
        % (1) Manually seed the functional/anatomical registration
        % - Do "coregtool" on the matlab command window
        % - Select anatomical image and meanepi image to overlay
        % - Manually adjust meanepi image and save result as rmeanepi image
        % Note: this only needs to be done for the 1st session, because..
        % .. mean epi is taken from the 1st run of the 1st session
        vararginoptions(varargin,{'sn'});
        
        cd(fullfile(anatomicalDir,subj_name{sn}));
        coregtool;
        keyboard();
        
        % (2) Automatically co-register functional and anatomical images
        %sn=varargin{1};
        
        J.ref = {fullfile(anatomicalDir,subj_name{sn},[subj_name{sn}, '_anatomical','.nii'])};
        J.source = {fullfile(imagingDir,subj_name{sn},['rbbmeanepi_' subj_name{sn} '.nii'])}; 
        J.other = {''};
        J.eoptions.cost_fun = 'nmi';
        J.eoptions.sep = [4 2];
        J.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
        J.eoptions.fwhm = [7 7];
        matlabbatch{1}.spm.spatial.coreg.estimate=J;
        spm_jobman('run',matlabbatch);
        
        % (3) Manually check again
        coregtool;
        keyboard();
        
        % NOTE:
        % Overwrites meanepi, unless you update in stsml1ep one, which saves it
        % as rmeanepi.
        % Each time you click "update" in coregtool, it saves current
        % alignment by appending the prefix 'r' to the current file
        % So if you continually update rmeanepi, you'll end up with a file
        % called r...rrrmeanepi.
      
        %__________________________________________________________________

    case 'PREP_process2'                                                                                                     
        vararginoptions(varargin,{'sn'});
        
        for s=sn
            sml1_imana('PREP_make_samealign','sn',s);
            sml1_imana('PREP_check_samealign','sn',s);
            sml1_imana('PREP_make_maskImage','sn',s);
        end
    case 'PREP_make_samealign'                                              % STEP 1.13     :  Align to first image (rbmeanepi_* of first session)
        prefix  = 'u';
        vararginoptions(varargin,{'sn'});

        cd(fullfile(imagingDir,subj_name{sn}));

        % Select image for reference
        P{1} = fullfile(imagingDir,subj_name{sn},sprintf('rbbmeanepi_%s.nii',subj_name{sn}));

        % Select images to be realigned
        Q={};
        for r=1:numruns(sn)
            for i=1:numTRs(r)-numDummys;
                Q{end+1}    = fullfile(imagingDir,subj_name{sn},...
                    sprintf('%s%s_run_%2.2d.nii,%d',prefix, subj_name{sn},r,i));
            end;
        end;
        spmj_makesamealign_nifti(char(P),char(Q));
        % Run spmj_makesamealign_nifti to bring all functional runs into
        % same space as realigned mean epis  
    case 'PREP_check_samealign'                                             % OPTIONAL      :  Check if all functional scans are align to the anatomical
        prefix='u';
        vararginoptions(varargin,{'sn'});
        Q={};
        cd(fullfile(imagingDir,subj_name{sn}));
        for i=1:numruns(sn)
            r{i}=int2str(i);
        end;
        for r= 1:numel(r)
            for i=1:numTRs(r)-numDummys;
                %Q{end+1} = [fullfile(baseDir, 'imaging_data',subj_name{sn}, [prefix, subj_name{sn},'_run',r(r),'.nii,',num2str(i)])];
                Q{end+1}    = fullfile(imagingDir,subj_name{sn},...
                    sprintf('%s%s_run_%2.2d.nii,%d',prefix, subj_name{sn},r,i));
            end
        end
        P{1}= fullfile(baseDir, 'imaging_data',subj_name{sn}, ['rbbmeanepi_' subj_name{sn} '.nii']);
        spmj_checksamealign(char(P),char(Q))       
    case 'PREP_make_maskImage'                                              % STEP 1.14     :  Make mask images (noskull and gray_only) - only for the 1st session (using mean epi)
    vararginoptions(varargin,{'sn'});

    for sn=sn
        cd(fullfile(imagingDir,subj_name{sn}));

        nam{1}  = fullfile(imagingDir,subj_name{sn}, ['rbbmeanepi_' subj_name{sn} '.nii']);
        nam{2}  = fullfile(anatomicalDir, subj_name{sn}, ['c1' subj_name{sn}, '_anatomical.nii']);
        nam{3}  = fullfile(anatomicalDir, subj_name{sn}, ['c2' subj_name{sn}, '_anatomical.nii']);
        nam{4}  = fullfile(anatomicalDir, subj_name{sn}, ['c3' subj_name{sn}, '_anatomical.nii']);
        spm_imcalc_ui(nam, 'rmask_noskull.nii', 'i1>1 & (i2+i3+i4)>0.2')

        nam={};
        nam{1}  = fullfile(imagingDir,subj_name{sn}, ['rbbmeanepi_' subj_name{sn} '.nii']);
        nam{2}  = fullfile(anatomicalDir, subj_name{sn}, ['c1' subj_name{sn}, '_anatomical.nii']);
        spm_imcalc_ui(nam, 'rmask_gray.nii', 'i1>1 & i2>0.4')

    end
    
    case '2_SURF' % ------------ SURF: Freesurfer funcs. Expand for more info. -
        % The SURF cases are the surface reconstruction functions. Surface
        % reconstruction is achieved via freesurfer.
        % All functions can be called with ('SURF_processAll','sn',[Subj#s]).
        % You can view reconstructed surfaces with Caret software.
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    case 'SURF_processAll'                                                 
        vararginoptions(varargin,{'sn'});
        % You can call this case to do all the freesurfer processing.
        % 'sn' can be an array of subjects because each processing case
        % contained within loops through the subject array submitted to the
        % case.
        sml1_imana('SURF_freesurfer','sn',sn);
        sml1_imana('SURF_xhemireg','sn',sn);
        sml1_imana('SURF_map_ico','sn',sn);
        sml1_imana('SURF_make_caret','sn',sn);
    case 'SURF_freesurfer'                                                  % STEP 2.1   :  Call recon-all in                                                                                                                  Freesurfer                                                   
        vararginoptions(varargin,{'sn'});
        for i=sn
            freesurfer_reconall(freesurferDir,subj_name{i},fullfile(anatomicalDir,subj_name{i},[subj_name{i} '_anatomical.nii']));
        end
    case 'SURF_xhemireg'                                                    % STEP 2.2   :  Cross-Register surfaces left / right hem
        vararginoptions(varargin,{'sn'});
        for i=sn
            freesurfer_registerXhem({subj_name{i}},freesurferDir,'hemisphere',[1 2]); % For debug... [1 2] orig
        end;
    case 'SURF_map_ico'                                                     % STEP 2.3   :  Align to the new atlas surface (map icosahedron)
        vararginoptions(varargin,{'sn'});
        for i=sn
            freesurfer_mapicosahedron_xhem(subj_name{i},freesurferDir,'smoothing',1,'hemisphere',[1:2]);
        end;
    case 'SURF_make_caret'                                                  % STEP 2.4   :  Translate into caret format
        vararginoptions(varargin,{'sn'});
        for i=sn
            caret_importfreesurfer(['x' subj_name{i}],freesurferDir,caretDir);
        end;
    
    case '3a_GLM_ALL' % ------------- GLM: SPM GLM fitting across all sessions. Expand for more info. ---
        % The GLM cases fit general linear models to subject data with 
        % SPM functionality.
        %
        % All functions can be called with ('GLM_processAll','sn',[Subj#s]).      
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -    
    case 'GLM_make'                                                         % STEP 3.1a  :  Make the SPM.mat and SPM_info.mat files (prep the GLM for all sessions)
        % functional runs
        % makes the GLM file for each subject, and a corresponding 
        % SPM_info.mat file. The latter file contains nice summary
        % information of the model regressors, condition names, etc.
        
        glm = 2;    %1/2/3
        vararginoptions(varargin,{'sn','glm'});
        % Set some constants.
        prefix		 = 'u';
        T			 = [];
        dur			 = 2.5;                                                 % secs (length of task dur, not trial dur)
        delay        = [0 0 0];                                           % adjusting hrf per subject based on extracted timeseries!
        announceTime = 1.0;                                                 % length of task announce time - currently not used
        % Gather appropriate GLM presets.
        switch glm
            case 1  % wls
                hrf_params = [5.5 12.5]; 
                hrf_cutoff = 128;
                cvi_type   = 'wls';
            case 2  % fast + hpf
                hrf_params = [5.5 12.5];
                hrf_cutoff = 128;
                cvi_type   = 'fast';
            case 3  % fast, no hpf
                hrf_params = [5.5 12.5]; % change to 5.5 12.5
                hrf_cutoff = inf;
                cvi_type   = 'fast';
        end

        % Loop through subjects and make SPM files.
        for s = sn
            D = dload(fullfile(behavDir,['sml1_',subj_name{s},'.dat']));     
             
            % Do some subject structure fields.
            dircheck(fullfile(glmDir{glm}, subj_name{s}));
            J.dir 			 = {fullfile(glmDir{glm}, subj_name{s})};
            J.timing.units   = 'secs';                                      % timing unit that all timing in model will be
            J.timing.RT 	 = 1.0;                                         % TR (in seconds, as per 'J.timing.units')
            J.timing.fmri_t  = 16;
            J.timing.fmri_t0 = 1;
            
            % Loop through sessions
            for sessN = 1:4     % all 4 scanning sessions
                % Loop through runs.
                for r = 1:numruns_task_sess       % 8 functional runs
                    R = getrow(D,D.isScan==1 & D.ScanSess==sessN);    % all blocks in scan
                    for i = 1:(numTRs(run_task(r))-numDummys)                   % get nifti filenames, correcting for dummy scancs
                        
                        N{i} = [fullfile(baseDir, 'imaging_data',subj_name{s}, ...
                            [prefix subj_name{s},'_run',runs{sessN}{run_task(1,r)},'.nii,',num2str(i)])];
                        
                    end;
                    J.sess(r).scans = N;                                        % number of scans in run
                    % Loop through conditions.
                    
                    for c = 1:numel(num_seq)
                        idx						   = find(R.seqNumb==c);             % find indx of all trials in run - 1:6 trained; 7-12 untrained
                        condName = sprintf('SeqNumb-%d',R.seqNumb(idx(1)));
                        J.sess(r).cond(c).name 	   = condName;
                        % Correct start time for numDummys removed & convert to seconds
                        J.sess(r).cond(c).onset    = [R.startTimeReal(idx)/1000 - J.timing.RT*numDummys + announceTime + delay(sn)];
                        J.sess(r).cond(c).duration = dur;                       % durations of task we are modeling (not length of entire trial)
                        
                        J.sess(r).cond(c).tmod     = 0;
                        J.sess(r).cond(c).orth     = 0;
                        J.sess(r).cond(c).pmod     = struct('name', {}, 'param', {}, 'poly', {});
                        
                        % Do some subject info for fields in SPM_info.mat.
                        S.SN    		= s;
                        S.run   		= r;    % 1-8: functional runs
                        S.runAll        = (sessN-1)*8 + r;  % 1-32
                        S.seqNumb 		= R.seqNumb(idx(1));
                        S.seqType    	= R.seqType(idx(1));
                        S.isMetronome   = R.isMetronome(idx(1));
                        S.ScanSess      = R.ScanSess(idx(1));
                        T				= addstruct(T,S);
                    end;
                    
                    % Add any additional regressors here.
                    J.sess(r).multi 	= {''};
                    J.sess(r).regress 	= struct('name', {}, 'val', {});
                    J.sess(r).multi_reg = {''};
                    % Define high pass filter cutoff (in seconds): see glm cases.
                    J.sess(r).hpf 		= hrf_cutoff;
                end;    % runs
            end;        % scanning session
            
            J.fact 			   = struct('name', {}, 'levels', {});
            J.bases.hrf.derivs = [0 0];
            J.bases.hrf.params = hrf_params;    % make it subject specific
            J.volt 			   = 1;
            J.global 		   = 'None';
            J.mask 	           = {fullfile(baseDir, 'imaging_data',subj_name{s}, 'rmask_noskull.nii,1')};
            J.mthresh 		   = 0.05;
            J.cvi_mask 		   = {fullfile(baseDir, 'imaging_data',subj_name{s},'rmask_gray.nii')};
            J.cvi 			   = cvi_type;
            % Save the GLM file for this subject.
            spm_rwls_run_fmri_spec(J);        
            % Save the aux. information file (SPM_info.mat).
            % This file contains user-friendly information about the glm
            % model, regressor types, condition names, etc.
            save(fullfile(J.dir{1},'SPM_info.mat'),'-struct','T');
            
        end;
    case 'GLM_estimate'                                                     % STEP 3.2a  :  Run the GLM according to model defined by SPM.mat
        % Estimate the GLM from the appropriate SPM.mat file. 
        % Make GLM files with case 'GLM_make'.
        vararginoptions(varargin,{'sn','glm'});
        glm=2;
        for s = sn
            % Load files
            load(fullfile(glmDir{glm},subj_name{s},'SPM.mat'));
            SPM.swd = fullfile(glmDir{glm},subj_name{s});
            % Run the GLM.
            spm_rwls_spm(SPM);
        end;
        % for checking -returns img of head movements and corrected sd vals
        % spm_rwls_resstats(SPM)
    case 'GLM_contrast'                                                     % STEP 3.3a  :  Make t-contrasts for specified GLM estimates (trained seq vs. rest, untrain seq vs. rest).
        % enter sn, glm #
        % 1:   Trained seq vs. rest
        % 2:   Novel seq vs. rest
 
        vararginoptions(varargin,{'sn','glm'});
        cwd = pwd;
        % Loop through subjects.
        for s = sn
            glmSubjDir = [glmDir{glm} filesep subj_name{s}];
            cd(glmSubjDir);

            load SPM;
            SPM = rmfield(SPM,'xCon');
            T   = load('SPM_info.mat');

            %_____t contrast for trained seq vs. rest
            con                = zeros(1,size(SPM.xX.X,2));
            con(:,T.seqNumb<7) = 1;
            con                = con/sum(con);
            SPM.xCon(1)        = spm_FcUtil('Set',sprintf('TrainSeq_Rest'), 'T', 'c',con',SPM.xX.xKXs);
            
            %_____t contrast for novel seq vs. rest
            con                = zeros(1,size(SPM.xX.X,2));
            con(:,T.seqNumb>6 & T.seqNumb<13)  = 1;
            con                = con/sum(con);
            SPM.xCon(2)        = spm_FcUtil('Set',sprintf('UntrainSeq_Rest'), 'T', 'c',con',SPM.xX.xKXs);
   
            %____do the constrasts
            SPM = spm_contrasts(SPM,[1:length(SPM.xCon)]);
            save('SPM.mat','SPM');
            
                % rename contrast images and spmT images
                conName = {'con','spmT'};
                for i=1:length(SPM.xCon),
                    for n=1:numel(conName),
                        oldName{i} = fullfile(glmSubjDir,sprintf('%s_%2.4d.nii',conName{n},i));
                        newName{i} = fullfile(glmSubjDir,sprintf('%s_%s.nii',conName{n},SPM.xCon(i).name));
                        movefile(oldName{i},newName{i});
                    end
                end
        end;
        cd(cwd);
    
    case '3b_GLM_SESS' % ------------- GLM per session! ------------------
        % makes the glm per subject and per session
    case 'GLM_sess_all'
        glm=2;
        vararginoptions(varargin,{'sn','glm','sessN'});
        sml1_imana('GLM_make_sess','sn',sn,'glm',glm,'sessN',sessN);
        sml1_imana('GLM_estimate_sess','sn',sn,'sessN',sessN);
        sml1_imana('GLM_contrast_sess','sn',sn,'sessN',sessN);
    case 'GLM_make_sess'
        % makes the GLM file for each subject, and a corresponding 
        % SPM_info.mat file. The latter file contains nice summary
        % information of the model regressors, condition names, etc.
        
        glm = 2;    %1/2/3
        vararginoptions(varargin,{'sn','glm','sessN'});
        % Set some constants.
        prefix		 = 'u';
        T			 = [];
        dur			 = 2.5;                                                 % secs (length of task dur, not trial dur)
        % adjusting hrf per subject & session based on extracted timeseries!  
        delay     = [0.5 1 1 0.5 1 0 0];  

        announceTime = 0;                                                 % length of task announce time - currently not used
        % Gather appropriate GLM presets.
        switch glm
            case 1  % wls
                hrf_params = [5.5 12.5]; 
                hrf_cutoff = 128;
                cvi_type   = 'wls';
            case 2  % fast + hpf
                hrf_params = [5.5 12.5];
                hrf_cutoff = 128;
                cvi_type   = 'fast';
            case 3  % fast, no hpf
                hrf_params = [5.5 12.5];
                hrf_cutoff = inf;
                cvi_type   = 'fast';
        end

        % Loop through subjects / all sessions and make SPM files.
            for s = sn
                D = dload(fullfile(behavDir,['sml1_',subj_name{s},'.dat']));
                
                % Do some subject structure fields.
                dircheck(fullfile(glmSessDir{sessN}, subj_name{s}));
                J.dir 			 = {fullfile(glmSessDir{sessN}, subj_name{s})};
                J.timing.units   = 'secs';                                      % timing unit that all timing in model will be
                J.timing.RT 	 = 1.0;                                         % TR (in seconds, as per 'J.timing.units')
                J.timing.fmri_t  = 16;
                J.timing.fmri_t0 = 1;
                
                L = getrow(D,D.ScanSess==sessN);    % only blocks of that scan session
                %if (sn==2 & sessN==3)
                 %   uniqrun = [181,182,191,184,185,186,187,188,189,190];
                %elseif (sn==2 & sessN==4)
                 %   uniqrun = [192,193,194,195,202,197,198,199,200,201];
                %else
                 %   uniqrun = unique(L.BN);
                %end
                % Loop through runs.
                for r = 1:numruns_task_sess
                    if sessN == 4
                        Rr = getrow(L,L.blockType==9); %blockType==9 - func imaging run without metronome
                    else
                        Rr = getrow(L,L.blockType==3); %blockType==3 - funct imaging run with metornome
                    end
                    
                    uniqrun=unique(Rr.BN);
                    R = getrow(Rr,Rr.BN==uniqrun(r)); % 1-8 func runs of the session

                    for i = 1:(numTRs(run_task(r))-numDummys)                   % get nifti filenames, correcting for dummy scancs
                        
                        N{i} = [fullfile(baseDir, 'imaging_data',subj_name{s}, ...
                            [prefix subj_name{s},'_run',runs{sessN}{run_task(1,r)},'.nii,',num2str(i)])];
                        
                    end;
                    J.sess(r).scans = N;                                        % number of scans in run
                    % Loop through conditions.
                    
                    for c = 1:numel(num_seq)
                        idx						   = find(R.seqNumb==c);             % find indx of all trials in run - 1:6 trained; 7-12 untrained
                        condName = sprintf('SeqNumb-%d',R.seqNumb(idx(1)));
                        J.sess(r).cond(c).name 	   = condName;
                        % Correct start time for numDummys removed & convert to seconds
                        J.sess(r).cond(c).onset    = [R.startTimeReal(idx)/1000 - J.timing.RT*numDummys + announceTime + delay(sn)];
                        J.sess(r).cond(c).duration = dur;                       % durations of task we are modeling (not length of entire trial)
                        
                        J.sess(r).cond(c).tmod     = 0;
                        J.sess(r).cond(c).orth     = 0;
                        J.sess(r).cond(c).pmod     = struct('name', {}, 'param', {}, 'poly', {});
                        
                        % Do some subject info for fields in SPM_info.mat.
                        S.SN    		= s;
                        S.run   		= r;    % 1-8: functional runs
                        S.runAll        = (sessN-1)*8 + r;  % 1-32
                        S.seqNumb 		= R.seqNumb(idx(1));
                        S.seqType    	= R.seqType(idx(1));
                        S.isMetronome   = R.isMetronome(idx(1));
                        S.ScanSess      = R.ScanSess(idx(1));
                        T				= addstruct(T,S);
                    end;
                    
                    % Add any additional regressors here.
                    J.sess(r).multi 	= {''};
                    J.sess(r).regress 	= struct('name', {}, 'val', {});
                    J.sess(r).multi_reg = {''};
                    % Define high pass filter cutoff (in seconds): see glm cases.
                    J.sess(r).hpf 		= hrf_cutoff;
                end;
                J.fact 			   = struct('name', {}, 'levels', {});
                J.bases.hrf.derivs = [0 0];
                J.bases.hrf.params = hrf_params;    % make it subject specific
                J.volt 			   = 1;
                J.global 		   = 'None';
                J.mask 	           = {fullfile(baseDir, 'imaging_data',subj_name{s}, 'rmask_noskull.nii,1')};
                J.mthresh 		   = 0.05;
                J.cvi_mask 		   = {fullfile(baseDir, 'imaging_data',subj_name{s},'rmask_gray.nii')};
                J.cvi 			   = cvi_type;
                % Save the GLM file for this subject.
                spm_rwls_run_fmri_spec(J);
                % Save the aux. information file (SPM_info.mat).
                % This file contains user-friendly information about the glm
                % model, regressor types, condition names, etc.
                save(fullfile(J.dir{1},'SPM_info.mat'),'-struct','T');
                
            end;    % sn
    case 'GLM_estimate_sess'
        % Estimate the GLM from the appropriate SPM.mat file. 
        % Make GLM files with case 'GLM_make'.
        vararginoptions(varargin,{'sn','sessN'});
        
            for s = sn
                % Load files
                load(fullfile(glmSessDir{sessN},subj_name{s},'SPM.mat'));
                SPM.swd = fullfile(glmSessDir{sessN},subj_name{s});
                % Run the GLM.
                spm_rwls_spm(SPM);
            end; % sn
        % for checking -returns img of head movements and corrected sd vals
        % spm_rwls_resstats(SPM)
    case 'GLM_contrast_sess'
        % enter sn, sessN #
        % 1:   Trained seq vs. rest
        % 2:   Novel seq vs. rest
        
        vararginoptions(varargin,{'sn','sessN'});
        cwd = pwd;

            % Loop through subjects.
            for s = sn
                glmSubjDir = [glmSessDir{sessN} filesep subj_name{s}];
                cd(glmSubjDir);
                
                load SPM;
                SPM = rmfield(SPM,'xCon');
                T   = load('SPM_info.mat');
                
                nrun    = numel(SPM.nscan);
                tt      = repmat([1:numel(num_seq)],1,nrun);
                
                % (1) t contrasts each sequence against rest
                % (1:12)
                for c = 1:numel(num_seq)
                    con = zeros(1,size(SPM.xX.X,2));
                    con(tt==c) = 1;
                    con = con/sum(con);
                    SPM.xCon(c) = spm_FcUtil('Set',sprintf('Seq%d',c), 'T', 'c',con',SPM.xX.xKXs);
                end
                
                % (2) t contrast for trained seq vs. rest
                con                = zeros(1,size(SPM.xX.X,2));
                con(:,T.seqNumb<7) = 1;
                con                = con/sum(con);
                SPM.xCon(end+1)    = spm_FcUtil('Set',sprintf('TrainSeq'), 'T', 'c',con',SPM.xX.xKXs);
                
                % (3) t contrast for novel seq vs. rest
                con                = zeros(1,size(SPM.xX.X,2));
                con(:,T.seqNumb>6 & T.seqNumb<13)  = 1;
                con                = con/sum(con);
                SPM.xCon(end+1)    = spm_FcUtil('Set',sprintf('UntrainSeq'), 'T', 'c',con',SPM.xX.xKXs);
                
                %____do the constrasts
                SPM = spm_contrasts(SPM,[1:length(SPM.xCon)]);
                save('SPM.mat','SPM');
                
                % rename contrast images and spmT images
                conName = {'con','spmT'};
                for i=1:length(SPM.xCon),
                    for n=1:numel(conName),
                        oldName{i} = fullfile(glmSubjDir,sprintf('%s_%2.4d.nii',conName{n},i));
                        newName{i} = fullfile(glmSubjDir,sprintf('%s_%s.nii',conName{n},SPM.xCon(i).name));
                        movefile(oldName{i},newName{i});
                    end
                end
            end; % sn

        cd(cwd);
        
    case '3c_GLM_FoSEx' % ------- GLM with separate regressors for first / second execution --
        % fits regressors separately for FoSEx
    case 'GLM_FoSEx_all'
        glm=2;
        vararginoptions(varargin,{'sn','glm','sessN'});
        sml1_imana('GLM_make_FoSEx','sn',sn,'glm',glm,'sessN',sessN);
        sml1_imana('GLM_estimate_FoSEx','sn',sn,'sessN',sessN);
        sml1_imana('GLM_contrast_FoSEx','sn',sn,'sessN',sessN);
    case 'GLM_make_FoSEx'
        % functional runs - separate regressors for first / second execution
        % makes the GLM file for each subject, and a corresponding
        % SPM_info.mat file. The latter file contains nice summary
        % information of the model regressors, condition names, etc.
        
        glm = 2;
        vararginoptions(varargin,{'sn','glm','sessN'});
        % Set some constants.
        prefix		 = 'u';
        T			 = [];
        dur			 = 2.5;                                                 % secs (length of task dur, not trial dur)
        delay     = [0.5 1 1 0.5 1 0 0];                                            % adjusting hrf per subject based on extracted timeseries!
        announceTime = 0;                                                   % length of task announce time - currently not used
        % Gather appropriate GLM presets.
        switch glm
            case 1  % wls
                hrf_params = [5.5 12.5];
                hrf_cutoff = 128;
                cvi_type   = 'wls';
            case 2  % fast + hpf
                hrf_params = [5.5 12.5];
                hrf_cutoff = 128;
                cvi_type   = 'fast';
            case 3  % fast, no hpf
                hrf_params = [5.5 12.5];
                hrf_cutoff = inf;
                cvi_type   = 'fast';
        end
        
        for ss = sessN
            T=[];
            % Loop through subjects and make SPM files.
            for s = sn
                D = dload(fullfile(behavDir,['sml1_',subj_name{s},'.dat']));
                
                % Do some subject structure fields.
                dircheck(fullfile(glmFoSExDir{ss}, subj_name{s}));
                J.dir 			 = {fullfile(glmFoSExDir{ss}, subj_name{s})};
                J.timing.units   = 'secs';                                      % timing unit that all timing in model will be
                J.timing.RT 	 = 1.0;                                         % TR (in seconds, as per 'J.timing.units')
                J.timing.fmri_t  = 16;
                J.timing.fmri_t0 = 1;
                
                L = getrow(D,D.ScanSess==ss);    % only blocks of that scan session
                
               % if (sn==2 & ss==3)
                %    uniqrun = [181,182,191,184,185,186,187,188,189,190];
                %elseif (sn==2 & ss==4)
                %    uniqrun = [192,193,194,195,202,197,198,199,200,201];
                %else
                %    uniqrun = unique(L.BN);
                %end
                
                % Loop through sessions
                % Loop through runs.
                for r = 1:numruns_task_sess       % 8 functional runs
                    if sessN == 4
                        Rr = getrow(L,L.blockType==9); %blockType==9 - func imaging run without metronome
                    else
                        Rr = getrow(L,L.blockType==3); %blockType==3 - funct imaging run with metornome
                    end
                    
                    uniqrun=unique(Rr.BN);
                    R = getrow(Rr,Rr.BN==uniqrun(r)); % 1-8 func runs of the session

                    for i = 1:(numTRs(run_task(r))-numDummys)                   % get nifti filenames, correcting for dummy scancs
                        
                        N{i} = [fullfile(baseDir, 'imaging_data',subj_name{s}, ...
                            [prefix subj_name{s},'_run',runs{ss}{run_task(1,r)},'.nii,',num2str(i)])];
                        
                    end;
                    J.sess(r).scans = N;                                        % number of scans in run
                    % Loop through conditions.
                    for FoSEx = 1:2     % first / second execution
                        for c = 1:numel(num_seq) % each sequence
                            idx = find(R.seqNumb==c & R.FoSEx==FoSEx);   % find indx of all trials in run - 1:6 trained; 7-12 untrained
                            condName = sprintf('SeqNumb-%d-Ex%d',R.seqNumb(idx(1)),R.FoSEx(idx(1)));
                            J.sess(r).cond((FoSEx-1)*numel(num_seq)+c).name 	   = condName;
                            % Correct start time for numDummys removed & convert to seconds
                            J.sess(r).cond((FoSEx-1)*numel(num_seq)+c).onset    = [R.startTimeReal(idx)/1000 - J.timing.RT*numDummys + announceTime + delay(sn)];
                            J.sess(r).cond((FoSEx-1)*numel(num_seq)+c).duration = dur;                       % durations of task we are modeling (not length of entire trial)
                            
                            J.sess(r).cond((FoSEx-1)*numel(num_seq)+c).tmod     = 0;
                            J.sess(r).cond((FoSEx-1)*numel(num_seq)+c).orth     = 0;
                            J.sess(r).cond((FoSEx-1)*numel(num_seq)+c).pmod     = struct('name', {}, 'param', {}, 'poly', {});
                            
                            % Do some subject info for fields in SPM_info.mat.
                            S.SN    		= s;
                            S.run   		= r;    % 1-8: functional runs
                            S.runAll        = (ss-1)*8 + r;  % 1-32
                            S.seqNumb 		= R.seqNumb(idx(1));
                            S.seqType    	= R.seqType(idx(1));
                            S.FoSEx         = R.FoSEx(idx(1));
                            S.isMetronome   = R.isMetronome(idx(1));
                            S.ScanSess      = R.ScanSess(idx(1));
                            T				= addstruct(T,S);
                        end;
                    end
                    % Add any additional regressors here.
                    J.sess(r).multi 	= {''};
                    J.sess(r).regress 	= struct('name', {}, 'val', {});
                    J.sess(r).multi_reg = {''};
                    % Define high pass filter cutoff (in seconds): see glm cases.
                    J.sess(r).hpf 		= hrf_cutoff;
                end;    % runs
                
                J.fact 			   = struct('name', {}, 'levels', {});
                J.bases.hrf.derivs = [0 0];
                J.bases.hrf.params = hrf_params;    % make it subject specific
                J.volt 			   = 1;
                J.global 		   = 'None';
                J.mask 	           = {fullfile(baseDir, 'imaging_data',subj_name{s}, 'rmask_noskull.nii,1')};
                J.mthresh 		   = 0.05;
                J.cvi_mask 		   = {fullfile(baseDir, 'imaging_data',subj_name{s},'rmask_gray.nii')};
                J.cvi 			   = cvi_type;
                % Save the GLM file for this subject.
                spm_rwls_run_fmri_spec(J);
                % Save the aux. information file (SPM_info.mat).
                % This file contains user-friendly information about the glm
                % model, regressor types, condition names, etc.
                save(fullfile(J.dir{1},'SPM_info.mat'),'-struct','T');
                
            end; % sn
        end; % sessN
    case 'GLM_estimate_FoSEx'
        % Estimate the GLM from the appropriate SPM.mat file. 
        % Make GLM files with case 'GLM_make'.
        vararginoptions(varargin,{'sn','sessN'});
        for ss = sessN
        for s = sn
            % Load files
            load(fullfile(glmFoSExDir{ss},subj_name{s},'SPM.mat'));
            SPM.swd = fullfile(glmFoSExDir{ss},subj_name{s});
            % Run the GLM.
            spm_rwls_spm(SPM);
        end; % sn
        end; % sessN
        % for checking -returns img of head movements and corrected sd vals
        % spm_rwls_resstats(SPM)
    case 'GLM_contrast_FoSEx'  
     
        % enter sn
        % 1:   Trained seq (1st) vs. rest
        % 2:   Trained seq (2nd) vs. rest
        % 3:   Untrained seq (1st) vs. rest
        % 4:   Untrained seq (2nd) vs. rest
 
        vararginoptions(varargin,{'sn','sessN'});
        cwd = pwd;
        % Loop through subjects.
        for ss = sessN
        for s = sn
            glmSubjDir = [glmFoSExDir{ss} filesep subj_name{s}];
            cd(glmSubjDir);

            load SPM;
            SPM = rmfield(SPM,'xCon');
            T   = load('SPM_info.mat');

            %_____t contrast for trained seq 1st vs. rest
            con                                = zeros(1,size(SPM.xX.X,2));
            con(:,T.seqNumb<7 & T.FoSEx == 1) = 1;
            con                                = con/sum(con);
            SPM.xCon(1)                        = spm_FcUtil('Set',sprintf('TrainSeq_1st'), 'T', 'c',con',SPM.xX.xKXs);
            
            %_____t contrast for trained seq 2nd vs. rest
            con                                 = zeros(1,size(SPM.xX.X,2));
            con(:,T.seqNumb<7 & T.FoSEx == 2)   = 1;
            con                                 = con/sum(con);
            SPM.xCon(2)                         = spm_FcUtil('Set',sprintf('TrainSeq_2nd'), 'T', 'c',con',SPM.xX.xKXs);

            %_____t contrast for untrained seq 1st vs. rest
            con                                = zeros(1,size(SPM.xX.X,2));
            con(:,T.seqNumb>6 & T.FoSEx == 1) = 1;
            con                                = con/sum(con);
            SPM.xCon(3)                        = spm_FcUtil('Set',sprintf('UntrainSeq_1st'), 'T', 'c',con',SPM.xX.xKXs);
            
            %_____t contrast for untrained seq 2nd vs. rest
            con                                 = zeros(1,size(SPM.xX.X,2));
            con(:,T.seqNumb>6 & T.FoSEx == 2)   = 1;
            con                                 = con/sum(con);
            SPM.xCon(4)                         = spm_FcUtil('Set',sprintf('UntrainSeq_2nd'), 'T', 'c',con',SPM.xX.xKXs);
            %____do the constrasts
            SPM = spm_contrasts(SPM,[1:length(SPM.xCon)]);
            save('SPM.mat','SPM');
            
                % rename contrast images and spmT images
                conName = {'con','spmT'};
                for i=1:length(SPM.xCon),
                    for n=1:numel(conName),
                        oldName{i} = fullfile(glmSubjDir,sprintf('%s_%2.4d.nii',conName{n},i));
                        newName{i} = fullfile(glmSubjDir,sprintf('%s_%s.nii',conName{n},SPM.xCon(i).name));
                        movefile(oldName{i},newName{i});
                    end
                end
        end; % sn
        end; % sessN
        cd(cwd);
        
    case '3d_GLM_LOC'  %  ------- localizer GLM across the 4 sessions ------- % 
        % finger mapping 1-5
    case 'GLM_make_LOC'                                               % STEP 3.4a  :  Make the SPM.mat and SPM_info.mat files (prep the GLM - localizer)
        % localizer runs
        % makes the GLM file for each subject, and a corresponding 
        % SPM_info.mat file. The latter file contains nice summary
        % information of the model regressors, condition names, etc.
        
        glm = 2;    %1/2/3
        vararginoptions(varargin,{'sn','glm'});
        % Set some constants.
        prefix		 = 'u';
        T			 = [];
        dur			 = 2.5;                                                 % secs (length of task dur, not trial dur)
        delay        = [0.5 1 0 0];     
        announceTime = 1.0;                                                 % length of task announce time - currently not used
        % Gather appropriate GLM presets.
        switch glm
            case 1  % wls
                hrf_params = [5.5 12.5]; % change to 5.5 12.5
                hrf_cutoff = 128;
                cvi_type   = 'wls';
            case 2  % fast + hpf
                hrf_params = [5.5 12.5];
                hrf_cutoff = 128;
                cvi_type   = 'fast';
            case 3  % fast, no hpf
                hrf_params = [4.5 11]; % change to 5.5 12.5
                hrf_cutoff = inf;
                cvi_type   = 'fast';
        end

        % Loop through subjects and make SPM files.
        for s = sn
            D = dload(fullfile(behavDir,['sml1_',subj_name{s},'.dat']));     
             
            % Do some subject structure fields.
            dircheck(fullfile(glmLocDir{glm}, subj_name{s}));
            J.dir 			 = {fullfile(glmLocDir{glm}, subj_name{s})};
            J.timing.units   = 'secs';                                      % timing unit that all timing in model will be
            J.timing.RT 	 = 1.0;                                         % TR (in seconds, as per 'J.timing.units')
            J.timing.fmri_t  = 16;
            J.timing.fmri_t0 = 1;
            
            % Loop through sessions
            for sessN = 1:4     % all 4 scanning sessions
                L = getrow(D,D.ScanSess==sessN);    % only blocks of that scan session
                uniqrun = unique(L.BN);
                % Loop through runs.
                for r = 1:numruns_loc_sess       % 2 localizer runs per session
                    
                    for i = 1:(numTRs(run_loc(r))-numDummys)                   % get nifti filenames, correcting for dummy scancs
                        
                        N{i} = [fullfile(baseDir, 'imaging_data',subj_name{s}, ...
                            [prefix subj_name{s},'_run',runs{sessN}{run_loc(1,r)},'.nii,',num2str(i)])];
                        
                    end;
                    J.sess((sessN-1)*2+r).scans = N;                                        % number of scans in run
                    % Loop through conditions.
                    
                    for c = 1:numel(num_fing)   % 5
                        R = getrow(L,L.BN==uniqrun(run_loc(1,r)));
                        idx						   = find(R.seqNumb==num_fing(c));    % find indx for fingers 1-5 (overall 13-17)
                        condName = sprintf('SeqNumb-%d',R.seqNumb(idx(1)));
                        J.sess((sessN-1)*2+r).cond(c).name 	   = condName;
                        % Correct start time for numDummys removed & convert to seconds
                        J.sess((sessN-1)*2+r).cond(c).onset    = [R.startTimeReal(idx)/1000 - J.timing.RT*numDummys + announceTime + delay(sn)];
                        J.sess((sessN-1)*2+r).cond(c).duration = dur;                       % durations of task we are modeling (not length of entire trial)
                        
                        J.sess((sessN-1)*2+r).cond(c).tmod     = 0;
                        J.sess((sessN-1)*2+r).cond(c).orth     = 0;
                        J.sess((sessN-1)*2+r).cond(c).pmod     = struct('name', {}, 'param', {}, 'poly', {});
                        
                        % Do some subject info for fields in SPM_info.mat.
                        S.SN    		= s;
                        S.run           = (sessN-1)*2 + r;  % 1-8 overall func runs
                        S.seqNumb 		= R.seqNumb(idx(1));
                        S.seqType    	= R.seqType(idx(1));
                        S.isMetronome   = R.isMetronome(idx(1));
                        S.ScanSess      = R.ScanSess(idx(1));
                        T				= addstruct(T,S);
                    end;
                    
                    % Add any additional regressors here.
                    J.sess((sessN-1)*2+r).multi 	= {''};
                    J.sess((sessN-1)*2+r).regress 	= struct('name', {}, 'val', {});
                    J.sess((sessN-1)*2+r).multi_reg = {''};
                    % Define high pass filter cutoff (in seconds): see glm cases.
                    J.sess((sessN-1)*2+r).hpf 		= hrf_cutoff;
                end;    % runs
            end;        % scanning session
            
            J.fact 			   = struct('name', {}, 'levels', {});
            J.bases.hrf.derivs = [0 0];
            J.bases.hrf.params = hrf_params;    % make it subject specific
            J.volt 			   = 1;
            J.global 		   = 'None';
            J.mask 	           = {fullfile(baseDir, 'imaging_data',subj_name{s}, 'rmask_noskull.nii,1')};
            J.mthresh 		   = 0.05;
            J.cvi_mask 		   = {fullfile(baseDir, 'imaging_data',subj_name{s},'rmask_gray.nii')};
            J.cvi 			   = cvi_type;
            % Save the GLM file for this subject.
            spm_rwls_run_fmri_spec(J);        
            % Save the aux. information file (SPM_info.mat).
            % This file contains user-friendly information about the glm
            % model, regressor types, condition names, etc.
            save(fullfile(J.dir{1},'SPM_info.mat'),'-struct','T');
            
        end;
    case 'GLM_estimate_LOC'                                           % STEP 3.5a  :  Run the GLM according to model defined by SPM.mat
        % Estimate the GLM from the appropriate SPM.mat file. 
        % Make GLM files with case 'GLM_make'.
        vararginoptions(varargin,{'sn','glm'});
        glm=2;
        for s = sn
            % Load files
            load(fullfile(glmLocDir{glm},subj_name{s},'SPM.mat'));
            SPM.swd = fullfile(glmLocDir{glm},subj_name{s});
            % Run the GLM.
            spm_rwls_spm(SPM);
        end; % sn
        
        % for checking -returns img of head movements and corrected sd vals
        % spm_rwls_resstats(SPM)    
    case 'GLM_contrast_LOC'                                           % STEP 3.6a  :  Make t-contsmlrasts - any / every finger vs. rest.
        % enter sn, glm #
        % 1:   Finger average vs. rest
        % 2-6: Single finger mapping (1-5)
 
        glm=2;
        vararginoptions(varargin,{'sn','glm'});
        cwd = pwd;
        % Loop through subjects.
        for s = sn
            glmSubjDir = [glmLocDir{glm} filesep subj_name{s}];
            cd(glmSubjDir);

            load SPM;
            SPM = rmfield(SPM,'xCon');
            T   = load('SPM_info.mat');

            %_____t contrast for single finger mapping (average) vs. rest
            con                = zeros(1,size(SPM.xX.X,2));
            con(:,T.seqNumb>12)= 1;
            con                = con/sum(con);
            SPM.xCon(1)        = spm_FcUtil('Set',sprintf('DigitAny'), 'T', 'c',con',SPM.xX.xKXs);
         
            %_____t contrast for single finger mapping vs. rest
            for d = 1:5
                con                = zeros(1,size(SPM.xX.X,2));
                con(:,T.seqNumb==d+12)  = 1;
                con                = con/sum(con);
                SPM.xCon(d+1)      = spm_FcUtil('Set',sprintf('Digit%d',d), 'T', 'c',con',SPM.xX.xKXs);
            end;
            
            %____do the constrasts
            SPM = spm_contrasts(SPM,[1:length(SPM.xCon)]);
            save('SPM.mat','SPM');
            
                % rename contrast images and spmT images
                conName = {'con','spmT'};
                for i=1:length(SPM.xCon),
                    for n=1:numel(conName),
                        oldName{i} = fullfile(glmSubjDir,sprintf('%s_%2.4d.nii',conName{n},i));
                        newName{i} = fullfile(glmSubjDir,sprintf('%s_%s.nii',conName{n},SPM.xCon(i).name));
                        movefile(oldName{i},newName{i});
                    end
                end
        end;
        cd(cwd);
    
    case '3e_GLM_LOC_sess'  % ------- construct GLM for localizer runs per session! ------- %
        % important for assessing consistencies of patterns etc.
    case 'GLM_LOC_sess_all'
        glm=2;
        vararginoptions(varargin,{'sn','glm','sessN'});
        sml1_imana('GLM_make_LOC_sess','sn',sn,'glm',glm,'sessN',sessN);
        sml1_imana('GLM_estimate_LOC_sess','sn',sn,'sessN',sessN);
        sml1_imana('GLM_contrast_LOC_sess','sn',sn,'sessN',sessN);
    case 'GLM_make_LOC_sess'
        % localizer runs - per session
        % makes the GLM file for each subject, and a corresponding 
        % SPM_info.mat file. The latter file contains nice summary
        % information of the model regressors, condition names, etc.
        
        glm = 2;    %1/2/3
        sessN = 1;
        vararginoptions(varargin,{'sn','glm','sessN'});
        % Set some constants.
        prefix		 = 'u';
        T			 = [];
        dur			 = 2.5;                                                 % secs (length of task dur, not trial dur)
        delay        = [0.5 1 1 0.5 1];     
        announceTime = 0;                                                   % length of task announce time - currently not used
        % Gather appropriate GLM presets.
        switch glm
            case 1  % wls
                hrf_params = [5.5 12.5]; % change to 5.5 12.5
                hrf_cutoff = 128;
                cvi_type   = 'wls';
            case 2  % fast + hpf
                hrf_params = [5.5 12.5];
                hrf_cutoff = 128;
                cvi_type   = 'fast';
            case 3  % fast, no hpf
                hrf_params = [4.5 11]; % change to 5.5 12.5
                hrf_cutoff = inf;
                cvi_type   = 'fast';
        end

        % Loop through subjects and make SPM files.
        for s = sn
            D = dload(fullfile(behavDir,['sml1_',subj_name{s},'.dat']));
          for ss = 1:sessN   
            T = [];
            % Do some subject structure fields.
            dircheck(fullfile(glmLocSessDir{ss}, subj_name{s}));
            J.dir 			 = {fullfile(glmLocSessDir{ss}, subj_name{s})};
            J.timing.units   = 'secs';                                      % timing unit that all timing in model will be
            J.timing.RT 	 = 1.0;                                         % TR (in seconds, as per 'J.timing.units')
            J.timing.fmri_t  = 16;
            J.timing.fmri_t0 = 1;
            
            L = getrow(D,D.ScanSess==ss);    % only blocks of that scan session
            %if (sn==2 & ss==3)
             %   uniqrun = [181,182,191,184,185,186,187,188,189,190];
            %elseif (sn==2 & ss==4)
             %   uniqrun = [192,193,194,195,202,197,198,199,200,201];
            %else
             %   uniqrun = unique(L.BN);
            %end
            % Loop through runs.
            for r = 1:numruns_loc_sess       % 2 localizer runs per session
                Rr = getrow(L,L.blockType==4); %blockType==4 - funct imaging localizer
                
                uniqrun=unique(Rr.BN);
                R = getrow(Rr,Rr.BN==uniqrun(r)); % 1-2 localizer runs
                
                for i = 1:(numTRs(run_loc(r))-numDummys)                   % get nifti filenames, correcting for dummy scancs
                    
                    N{i} = [fullfile(baseDir, 'imaging_data',subj_name{s}, ...
                        [prefix subj_name{s},'_run',runs{ss}{run_loc(1,r)},'.nii,',num2str(i)])];
                    
                end;
                J.sess(r).scans = N;                                        % number of scans in run
                % Loop through conditions.
                
                for c = 1:numel(num_fing)   % 5
                    idx						   = find(R.seqNumb==num_fing(c));    % find indx for fingers 1-5 (overall 13-17)
                    condName = sprintf('SeqNumb-%d',R.seqNumb(idx(1)));
                    J.sess(r).cond(c).name 	   = condName;
                    % Correct start time for numDummys removed & convert to seconds
                    J.sess(r).cond(c).onset    = [R.startTimeReal(idx)/1000 - J.timing.RT*numDummys + announceTime + delay(sn)];
                    J.sess(r).cond(c).duration = dur;                       % durations of task we are modeling (not length of entire trial)
                    
                    J.sess(r).cond(c).tmod     = 0;
                    J.sess(r).cond(c).orth     = 0;
                    J.sess(r).cond(c).pmod     = struct('name', {}, 'param', {}, 'poly', {});
                    
                    % Do some subject info for fields in SPM_info.mat.
                    S.SN    		= s;
                    S.run           = r;
                    S.runAll        = (ss-1)*2 + r;  % 1-8 overall loc runs
                    S.seqNumb 		= R.seqNumb(idx(1))-12;     % 1-5
                    S.seqType    	= R.seqType(idx(1));
                    S.isMetronome   = R.isMetronome(idx(1));
                    S.ScanSess      = R.ScanSess(idx(1));
                    T				= addstruct(T,S);
                end;
                
                % Add any additional regressors here.
                J.sess(r).multi 	= {''};
                J.sess(r).regress 	= struct('name', {}, 'val', {});
                J.sess(r).multi_reg = {''};
                % Define high pass filter cutoff (in seconds): see glm cases.
                J.sess(r).hpf 		= hrf_cutoff;
            end;    % runs
            
            J.fact 			   = struct('name', {}, 'levels', {});
            J.bases.hrf.derivs = [0 0];
            J.bases.hrf.params = hrf_params;    % make it subject specific
            J.volt 			   = 1;
            J.global 		   = 'None';
            J.mask 	           = {fullfile(baseDir, 'imaging_data',subj_name{s}, 'rmask_noskull.nii,1')};
            J.mthresh 		   = 0.05;
            J.cvi_mask 		   = {fullfile(baseDir, 'imaging_data',subj_name{s},'rmask_gray.nii')};
            J.cvi 			   = cvi_type;
            % Save the GLM file for this subject.
            spm_rwls_run_fmri_spec(J);        
            % Save the aux. information file (SPM_info.mat).
            % This file contains user-friendly information about the glm
            % model, regressor types, condition names, etc.
            save(fullfile(J.dir{1},'SPM_info.mat'),'-struct','T');
        end; % sessN
        end; % subject    
    case 'GLM_estimate_LOC_sess'
        % Estimate the GLM from the appropriate SPM.mat file. 
        % Make GLM files with case 'GLM_make'.
        vararginoptions(varargin,{'sn','sessN'});
        for s = sn
            % Load files
            for ss = 1:sessN
                load(fullfile(glmLocSessDir{ss},subj_name{s},'SPM.mat'));
                SPM.swd = fullfile(glmLocSessDir{ss},subj_name{s});
                % Run the GLM.
                spm_rwls_spm(SPM);
            end; % session
        end; % subject
        % for checking -returns img of head movements and corrected sd vals
        % spm_rwls_resstats(SPM)   
    case 'GLM_contrast_LOC_sess'
         % enter sn, glm #
        % 1:   Finger average vs. rest
        % 2-6: Single finger mapping (1-5)
 
        vararginoptions(varargin,{'sn','sessN'});
        cwd = pwd;
        % Loop through subjects.
        for s = sn
            for ss = 1:sessN
                glmSubjDir = [glmLocSessDir{ss} filesep subj_name{s}];
                cd(glmSubjDir);
                
                load SPM;
                SPM = rmfield(SPM,'xCon');
                T   = load('SPM_info.mat');
                
                %_____t contrast for single finger mapping (average) vs. rest
                con                = zeros(1,size(SPM.xX.X,2));
                con(:,T.seqNumb>0)= 1;
                con                = con/sum(con);
                SPM.xCon(1)        = spm_FcUtil('Set',sprintf('DigitAny'), 'T', 'c',con',SPM.xX.xKXs);
                
                %_____t contrast for single finger mapping vs. rest
                for d = 1:5
                    con                = zeros(1,size(SPM.xX.X,2));
                    con(:,T.seqNumb==d)  = 1;
                    con                = con/sum(con);
                    SPM.xCon(d+1)      = spm_FcUtil('Set',sprintf('Digit%d',d), 'T', 'c',con',SPM.xX.xKXs);
                end;
                
                %____do the constrasts
                SPM = spm_contrasts(SPM,[1:length(SPM.xCon)]);
                save('SPM.mat','SPM');
                
                % rename contrast images and spmT images
                conName = {'con','spmT'};
                for i=1:length(SPM.xCon),
                    for n=1:numel(conName),
                        oldName{i} = fullfile(glmSubjDir,sprintf('%s_%2.4d.nii',conName{n},i));
                        newName{i} = fullfile(glmSubjDir,sprintf('%s_%s.nii',conName{n},SPM.xCon(i).name));
                        movefile(oldName{i},newName{i});
                    end
                end
                clear SPM;
            end; 
        end; % subject
        cd(cwd);
        
    case 'PSC_create'
    % calculate psc for trained and untrained sequences - based on betas    
        vararginoptions(varargin,{'sn','sessN'});
        name={'Seq1','Seq2','Seq3','Seq4','Seq5','Seq6','Seq7','Seq8','Seq9','Seq10','Seq11','Seq12','TrainSeq','UntrainSeq'};
        for s=sn
            cd(fullfile(glmSessDir{sessN}, subj_name{s}));
            load SPM;
            T=load('SPM_info.mat');
            X=(SPM.xX.X(:,SPM.xX.iC));      % Design matrix - raw
            h=median(max(X));               % Height of response;
            P={};
            numB=length(SPM.xX.iB);         % Partitions - runs
            for p=SPM.xX.iB
                P{end+1}=sprintf('beta_%4.4d.nii',p);       % get the intercepts and use them to calculate the baseline (mean images)
            end;
            for con=1:length(name)    % 14 contrasts
                P{numB+1}=sprintf('con_%s.nii',name{con});
                outname=sprintf('psc_sess%d_%s.nii',sessN,name{con}); % ,subj_name{s}
                
                formula=sprintf('100.*%f.*i9./((i1+i2+i3+i4+i5+i6+i7+i8)/8)',h);
                
                spm_imcalc_ui(P,outname,formula,...
                    {0,[],spm_type(16),[]});        % Calculate percent signal change
            end;
            fprintf('Subject %d sess %d: %3.3f\n',s,sessN,h);
        end;
    case 'PSC_surface'
     % create surface maps of percent signal change 
     % trained and untrained sequences
     
        smooth = 0;   
        vararginoptions(varargin,{'sn','sessN','smooth'});

        hemisphere=1:length(hem);
        fileList = [];
        column_name = [];
        name={'Seq1','Seq2','Seq3','Seq4','Seq5','Seq6','Seq7','Seq8','Seq9','Seq10','Seq11','Seq12','TrainSeq','UntrainSeq'};
        for n = 1:length(name)
            fileList{n}=fullfile(['psc_sess' num2str(sessN) '_' name{n} '.nii']);
            column_name{n} = fullfile(sprintf('Sess%d_%s.nii',sessN,name{n}));
        end
        for s=sn
            for h=hemisphere
                caretSDir = fullfile(caretDir,['x',subj_name{s}],hemName{h});
                specname=fullfile(caretSDir,['x',subj_name{s} '.' hem{h}   '.spec']);
                white=fullfile(caretSDir,[hem{h} '.WHITE.coord']);
                pial=fullfile(caretSDir,[hem{h} '.PIAL.coord']);
                
                C1=caret_load(white);
                C2=caret_load(pial);
                
                for f=1:length(fileList)
                    images{f}=fullfile(glmSessDir{sessN},subj_name{s},fileList{f});
                end;
                metric_out = fullfile(caretSDir,sprintf('%s_Contrasts_sess%d.metric',subj_name{s},sessN));
                M=caret_vol2surf_own(C1.data,C2.data,images,'ignore_zeros',1);
                M.column_name = column_name;
                caret_save(metric_out,M);
                fprintf('Subj %d, Hem %d\n',s,h);
                
                if smooth == 1;
                    % Smooth output .metric file (optional)
                    % Load .topo file
                    closed = fullfile(caretSDir,[hem{h} '.CLOSED.topo']);
                    Out = caret_smooth(metric_out, 'coord', white, 'topo', closed);%,...
                    %'algorithm','FWHM','fwhm',12);
                    char(Out);  % if smoothed adds an 's'
                else
                end;
                
            end;
        end;
    case 'PSC_create_loc'
        % calculate psc for all digits / ind digit vs. rest - based on betas    
        glm=2;
        vararginoptions(varargin,{'sn','glm'});
        name={'DigitAny','Digit1','Digit2','Digit3','Digit4','Digit5'};
        for s=sn
            cd(fullfile(glmLocDir{glm}, subj_name{s}));
            load SPM;
            T=load('SPM_info.mat');
            X=(SPM.xX.X(:,SPM.xX.iC));      % Design matrix - raw
            h=median(max(X));               % Height of response;
            P={};
            numB=length(SPM.xX.iB);         % Partitions - runs
            for p=SPM.xX.iB
                P{end+1}=sprintf('beta_%4.4d.nii',p);       % get the intercepts and use them to calculate the baseline (mean images)
            end;
            for con=1:length(name)    % 6 contrasts
                P{numB+1}=sprintf('con_%s.nii',name{con});
                outname=sprintf('psc_digit_%s.nii',name{con}); % ,subj_name{s}
                
                formula=sprintf('100.*%f.*i9./((i1+i2+i3+i4+i5+i6+i7+i8)/8)',h);    % 8 runs overall
                
                spm_imcalc_ui(P,outname,formula,...
                    {0,[],spm_type(16),[]});        % Calculate percent signal change
            end;
            fprintf('Subject %d: %3.3f\n',s,h);
        end;
    case 'PSC_surface_loc'
        % create surface maps of percent signal change 
     % trained and untrained sequences
     
        smooth=0;  
        glm=2;
        vararginoptions(varargin,{'sn','glm','smooth'});

        hemisphere=1:length(hem);
        fileList = [];
        column_name = [];
        name={'DigitAny','Digit1','Digit2','Digit3','Digit4','Digit5'};
        for n = 1:length(name)
            fileList{n}=fullfile(['psc_digit_' name{n} '.nii']);
            column_name{n} = fullfile(sprintf('%s.nii',name{n}));
        end
        for s=sn
            for h=hemisphere
                caretSDir = fullfile(caretDir,['x',subj_name{s}],hemName{h});
                specname=fullfile(caretSDir,['x',subj_name{s} '.' hem{h}   '.spec']);
                white=fullfile(caretSDir,[hem{h} '.WHITE.coord']);
                pial=fullfile(caretSDir,[hem{h} '.PIAL.coord']);
                
                C1=caret_load(white);
                C2=caret_load(pial);
                
                for f=1:length(fileList)
                    images{f}=fullfile(glmLocDir{glm},subj_name{s},fileList{f});
                end;
                metric_out = fullfile(caretSDir,sprintf('%s_Digit_PSC.metric',subj_name{s}));
                M=caret_vol2surf_own(C1.data,C2.data,images,'ignore_zeros',1);
                M.column_name = column_name;
                caret_save(metric_out,M);
                fprintf('Subj %d, Hem %d\n',s,h);
                
                if smooth == 1;
                    % Smooth output .metric file (optional)
                    % Load .topo file
                    closed = fullfile(caretSDir,[hem{h} '.CLOSED.topo']);
                    Out = caret_smooth(metric_out, 'coord', white, 'topo', closed);%,...
                    %'algorithm','FWHM','fwhm',12);
                    char(Out);  % if smoothed adds an 's'
                else
                end;
                
            end;
        end;
    case 'PSC_create_FoSEx'
        % calculate psc for trained and untrained sequences (1st/2nd) - based on betas    
        vararginoptions(varargin,{'sn','sessN'});
        name={'TrainSeq_1st','TrainSeq_2nd','UntrainSeq_1st','UntrainSeq_2nd'};
        for s=sn
            cd(fullfile(glmFoSExDir{sessN}, subj_name{s}));
            load SPM;
            T=load('SPM_info.mat');
            X=(SPM.xX.X(:,SPM.xX.iC));      % Design matrix - raw
            h=median(max(X));               % Height of response;
            P={};
            numB=length(SPM.xX.iB);         % Partitions - runs
            for p=SPM.xX.iB
                P{end+1}=sprintf('beta_%4.4d.nii',p);       % get the intercepts and use them to calculate the baseline (mean images)
            end;
            for con=1:length(name)    % 4 contrasts
                P{numB+1}=sprintf('con_%s.nii',name{con});
                outname=sprintf('psc_sess%d_%s.nii',sessN,name{con}); % ,subj_name{s}
                
                formula=sprintf('100.*%f.*i9./((i1+i2+i3+i4+i5+i6+i7+i8)/8)',h);
                
                spm_imcalc_ui(P,outname,formula,...
                    {0,[],spm_type(16),[]});        % Calculate percent signal change
            end;
            fprintf('Subject %d sess %d: %3.3f\n',s,sessN,h);
        end;
    case 'PSC_surface_FoSEx'
     % create surface maps of percent signal change 
     % trained and untrained sequences - 1st / 2nd execution
     
        smooth = 0;   
        vararginoptions(varargin,{'sn','sessN','smooth'});

        hemisphere=1:length(hem);
        fileList = [];
        column_name = [];
        name={'TrainSeq_1st','TrainSeq_2nd','UntrainSeq_1st','UntrainSeq_2nd'};
        for n = 1:length(name)
            fileList{n}=fullfile(['psc_sess' num2str(sessN) '_' name{n} '.nii']);
            column_name{n} = fullfile(sprintf('Sess%d_RS_%s.nii',sessN,name{n}));
        end
        for s=sn
            for h=hemisphere
                caretSDir = fullfile(caretDir,['x',subj_name{s}],hemName{h});
                specname=fullfile(caretSDir,['x',subj_name{s} '.' hem{h}   '.spec']);
                white=fullfile(caretSDir,[hem{h} '.WHITE.coord']);
                pial=fullfile(caretSDir,[hem{h} '.PIAL.coord']);
                
                C1=caret_load(white);
                C2=caret_load(pial);
                
                for f=1:length(fileList)
                    images{f}=fullfile(glmFoSExDir{sessN},subj_name{s},fileList{f});
                end;
                metric_out = fullfile(caretSDir,sprintf('%s_Contrasts_RS_sess%d.metric',subj_name{s},sessN));
                M=caret_vol2surf_own(C1.data,C2.data,images,'ignore_zeros',1);
                M.column_name = column_name;
                caret_save(metric_out,M);
                fprintf('Subj %d, Hem %d\n',s,h);
                
                if smooth == 1;
                    % Smooth output .metric file (optional)
                    % Load .topo file
                    closed = fullfile(caretSDir,[hem{h} '.CLOSED.topo']);
                    Out = caret_smooth(metric_out, 'coord', white, 'topo', closed);%,...
                    %'algorithm','FWHM','fwhm',12);
                    char(Out);  % if smoothed adds an 's'
                else
                end;
                
            end;
        end;
    case 'CONT_surface'
     % create surface maps of contrast maps
     % trained and untrained sequences
     
        smooth = 0;   
        vararginoptions(varargin,{'sn','sessN','smooth'});

        hemisphere=1:length(hem);
        fileList = [];
        column_name = [];
        name={'Seq1','Seq2','Seq3','Seq4','Seq5','Seq6','Seq7','Seq8','Seq9','Seq10','Seq11','Seq12','TrainSeq','UntrainSeq'};
        for n = 1:length(name)
            fileList{n}=fullfile(['psc_sess' num2str(sessN) '_' name{n} '.nii']);
            column_name{n} = fullfile(sprintf('Sess%d_%s.nii',sessN,name{n}));
        end
        for s=sn
            for h=hemisphere
                caretSDir = fullfile(caretDir,['x',subj_name{s}],hemName{h});
                specname=fullfile(caretSDir,['x',subj_name{s} '.' hem{h}   '.spec']);
                white=fullfile(caretSDir,[hem{h} '.WHITE.coord']);
                pial=fullfile(caretSDir,[hem{h} '.PIAL.coord']);
                
                C1=caret_load(white);
                C2=caret_load(pial);
                
                for f=1:length(fileList)
                    images{f}=fullfile(glmSessDir{sessN},subj_name{s},fileList{f});
                end;
                metric_out = fullfile(caretSDir,sprintf('%s_Contrasts_sess%d.metric',subj_name{s},sessN));
                M=caret_vol2surf_own(C1.data,C2.data,images,'ignore_zeros',1);
                M.column_name = column_name;
                caret_save(metric_out,M);
                fprintf('Subj %d, Hem %d\n',s,h);
                
                if smooth == 1;
                    % Smooth output .metric file (optional)
                    % Load .topo file
                    closed = fullfile(caretSDir,[hem{h} '.CLOSED.topo']);
                    Out = caret_smooth(metric_out, 'coord', white, 'topo', closed);%,...
                    %'algorithm','FWHM','fwhm',12);
                    char(Out);  % if smoothed adds an 's'
                else
                end;
                
            end;
        end;  
    
    case 'SEARCH_all'
        vararginoptions(varargin,{'sn','sessN'});
        if sessN == 1
        sml1_imana('SEARCH_define','sn',sn,'sessN',sessN);
        end
        sml1_imana('SEARCH_dist_runLDC','sn',sn,'sessN',sessN);
        sml1_imana('SEARCH_dist_map','sn',sn,'sessN',sessN);
        sml1_imana('SEARCH_dist_surf','sn',sn,'sessN',sessN);
    case 'SEARCH_define'                                                    % STEP 4.1a   :  Defines searchlights for 120 voxels in grey matter surface
        vararginoptions(varargin,{'sn','sessN'});
        
        for s=sn
            mask       = fullfile(regDir,sprintf('mask_%s.nii',subj_name{s}));
            Vmask      = spm_vol(mask);
            Vmask.data = spm_read_vols(Vmask);
            
            LcaretDir = fullfile(caretDir,['x',subj_name{s}],'LeftHem');
            RcaretDir = fullfile(caretDir,['x',subj_name{s}],'RightHem');
            white     = {fullfile(LcaretDir,'lh.WHITE.coord'),fullfile(RcaretDir,'rh.WHITE.coord')};
            pial      = {fullfile(LcaretDir,'lh.PIAL.coord'),fullfile(RcaretDir,'rh.PIAL.coord')};
            topo      = {fullfile(LcaretDir,'lh.CLOSED.topo'),fullfile(RcaretDir,'rh.CLOSED.topo')};
            S         = rsa_readSurf(white,pial,topo);
            
            L = rsa.defineSearchlight_surface(S,Vmask,'sphere',[15 120]);
            save(fullfile(anatomicalDir,subj_name{s},sprintf('%s_searchlight_120.mat',subj_name{s})),'-struct','L');
        end
    case 'SEARCH_dist_runLDC'                                               % STEP 4.2a   :  Runs LDC searchlight using defined searchlights (above)

        vararginoptions(varargin,{'sn','sessN'});
        
        block = 5e7;
        cwd   = pwd;                                                        % copy current directory (to return to later)
        for s=sn
            runs = 1:numruns_task_sess; 
            % make index vectors           
            conditionVec  = kron(ones(numel(runs),1),[1:12]');      % 12 sequences
            partition     = kron(runs',ones(12,1));
            % go to subject's glm directory 
            cd(fullfile(glmSessDir{sessN},subj_name{s}));
            % load their searchlight definitions and SPM file
            L = load(fullfile(anatomicalDir,subj_name{s},sprintf('%s_searchlight_120.mat',subj_name{s})));
            load SPM;
            SPM  = spmj_move_rawdata(SPM,fullfile(imagingDir,subj_name{s}));

            name = sprintf('%s_sess%d',subj_name{s},sessN);
            % run the searchlight
            rsa.runSearchlightLDC(L,'conditionVec',conditionVec,'partition',partition,'analysisName',name,'idealBlock',block);

        end
        cd(cwd);
    case 'SEARCH_dist_map'                                                  % STEP 4.3a   :  Averaged LDC values for specified contrasts

        sn  = 1;
        sessN = 1;
        vararginoptions(varargin,{'sn','sessN'});

        cWD = cd;
        for s = sn
            % Load subject surface searchlight results (1 vol per paired conds)
            LDC_file            = fullfile(glmSessDir{sessN},subj_name{s},sprintf('%s_sess%d_LDC.nii',subj_name{s},sessN)); % searchlight nifti
            [subjDir,fname,ext] = fileparts(LDC_file);
            cd(subjDir);

            vol     = spm_vol([fname ext]);
            vdat    = spm_read_vols(vol); % is searchlight data
            
            % average across all paired dists
            Y.LDC   = nanmean(vdat,4);
            % prep output file
            Y.dim   = vol(1).dim;
            Y.dt    = vol(1).dt;
            Y.mat   = vol(1).mat;
            Y.fname   = sprintf('%s_sess%d_dist.nii',subj_name{s},sessN);
            
            % separate trained / untrained dists
            indMat = indicatorMatrix('allpairs',[1:12]);
            trainInd = [];
            untrainInd = [];
            for i=1:length(indMat)
                if sum(any(indMat(i,num_train),1))==2
                    trainInd=[trainInd;i]; 
                elseif sum(any(indMat(i,num_untrain),1))==2
                    untrainInd=[untrainInd;i];
                else
                end
            end
            
            trainDist = vdat(:,:,:,trainInd);
            untrainDist = vdat(:,:,:,untrainInd);
            
            T = Y;
            U = Y;
            T.LDC = nanmean(trainDist,4);
            U.LDC = nanmean(untrainDist,4);
            T.fname = sprintf('%s_sess%d_dist_trained.nii',subj_name{s},sessN);
            U.fname = sprintf('%s_sess%d_dist_untrained.nii',subj_name{s},sessN);
            
            % save outputs
            spm_write_vol(Y,Y.LDC);
            spm_write_vol(T,T.LDC);
            spm_write_vol(U,U.LDC);
            fprintf('Done %s_sess%d \n',subj_name{s},sessN)
            
            clear vol vdat LDC Y T U
            
        end
        cd(cWD);  % return to working directory
    case 'SEARCH_dist_surf'                                                 % STEP 4.4a   :  Map searchlight results (.nii) onto surface (.metric)
        % map volume images to metric file and save them in individual surface folder
        sn  = 1;
        sessN = 1;
        
        vararginoptions(varargin,{'sn','sessN'});
        fileList = {'dist','dist_trained','dist_untrained'};
        hemisphere = 1:2;
        
        for s = sn
            for h=hemisphere
                caretSDir = fullfile(caretDir,['x',subj_name{s}],hemName{h});
                white     = caret_load(fullfile(caretSDir,[hem{h} '.WHITE.coord']));
                pial      = caret_load(fullfile(caretSDir,[hem{h} '.PIAL.coord']));
                
                for f = 1:length(fileList)
                    images{f}    = fullfile(glmSessDir{sessN},subj_name{s},sprintf('%s_sess%d_%s.nii',subj_name{s},sessN,fileList{f}));
                    column_name{f} = fullfile(sprintf('Sess%d_%s.nii',sessN,fileList{f}));
                end;    % filename
                outfile   = sprintf('%s_sess%d_dist.metric',subj_name{s},sessN);
                M         = caret_vol2surf_own(white.data,pial.data,images,'ignore_zeros',1);
                M.column_name = column_name;
                caret_save(fullfile(caretSDir,outfile),M);
                fprintf('Done subj %d sess %d hemi %d \n',s,sessN,h);
            end;    % hemi
        end;    % subj
    
    case 'SEARCH_fingmap_runLDC'                                            % STEP 4.1b   :  Runs LDC searchlight using defined searchlights (above)

        glm=2;
        vararginoptions(varargin,{'sn','glm'});
        
        block = 5e7;
        cwd   = pwd;                                                        % copy current directory (to return to later)
        for s=sn
            runs = 1:numruns_loc;   % all 8 runs across 4 sessions
            % make index vectors           
            conditionVec  = kron(ones(numel(runs),1),[1:5]');      % 12 sequences
            partition     = kron(runs',ones(5,1));
            % go to subject's glm directory 
            cd(fullfile(glmLocDir{glm},subj_name{s}));
            % load their searchlight definitions and SPM file
            L = load(fullfile(anatomicalDir,subj_name{s},sprintf('%s_searchlight_120.mat',subj_name{s})));
            load SPM;
            SPM  = spmj_move_rawdata(SPM,fullfile(imagingDir,subj_name{s}));

            name = sprintf('%s_fingmap',subj_name{s});
            % run the searchlight
            rsa.runSearchlightLDC(L,'conditionVec',conditionVec,'partition',partition,'analysisName',name,'idealBlock',block);

        end
        cd(cwd);
    case 'SEARCH_fingmap_map'
        sn=1;
        glm=2;
        vararginoptions(varargin,{'sn','glm'});

        cWD = cd;
        for s = sn
            % Load subject surface searchlight results (1 vol per paired conds)
            LDC_file            = fullfile(glmLocDir{glm},subj_name{s},sprintf('%s_fingmap_LDC.nii',subj_name{s})); % searchlight nifti
            [subjDir,fname,ext] = fileparts(LDC_file);
            cd(subjDir);

            vol     = spm_vol([fname ext]);
            vdat    = spm_read_vols(vol); % is searchlight data
            
            % average across all paired dists
            Y.LDC   = nanmean(vdat,4);
            % prep output file
            Y.dim   = vol(1).dim;
            Y.dt    = vol(1).dt;
            Y.mat   = vol(1).mat;
            Y.fname   = sprintf('%s_fingdist_mean.nii',subj_name{s});
            
            % per each finger
            C = rsa.util.pairMatrix(5); % ?!?!??!

            % save outputs
            spm_write_vol(Y,Y.LDC);
            fprintf('Done %s_fingmap \n',subj_name{s})
            
            clear vol vdat LDC Y
            
        end
        cd(cWD);  % return to working directory
    case 'SEARCH_fingmap_surf'
         % map volume images to metric file and save them in individual surface folder
        sn  = 1;
        glm = 2;
        
        vararginoptions(varargin,{'sn','glm'});
        fileList = {'fingdist_mean'};
        hemisphere = 1:2;
        
        for s = sn
            for h=hemisphere
                caretSDir = fullfile(caretDir,['x',subj_name{s}],hemName{h});
                white     = caret_load(fullfile(caretSDir,[hem{h} '.WHITE.coord']));
                pial      = caret_load(fullfile(caretSDir,[hem{h} '.PIAL.coord']));
                
                for f = 1:length(fileList)
                    images{f}    = fullfile(glmLocDir{glm},subj_name{s},sprintf('%s_%s.nii',subj_name{s},fileList{f}));
                    column_name{f} = fullfile(sprintf('%s.nii',fileList{f}));
                end;    % filename
                outfile   = sprintf('%s_fingdist.metric',subj_name{s});
                M         = caret_vol2surf_own(white.data,pial.data,images,'ignore_zeros',1);
                M.column_name = column_name;
                caret_save(fullfile(caretSDir,outfile),M);
                fprintf('Done subj %d hemi %d \n',s,h);
            end;    % hemi
        end;    % subj
        
    case '4_BG_SUIT' % ------------- BG and SUIT preparation. Expand for more info. ------
        % The ROI cases are used to:
        %       - map ROIs to each subject
        %       - harvest timeseries from each roi for each condition
        %
        % There is no 'processAll' case here. However, the following cases
        % must be called to utilize other roi cases:
        %       'ROI_makePaint'   :  Creates roi paint files (see case)
        %       'ROI_define'      :  Maps rois to surface of each subject-
        %                             requires paint files from above case.
        %       'ROI_timeseries'  :  Only if you wish to plot timeseries
        %       'ROI_getBetas'    :  Harvest patterns from roi
        %       'ROI_stats'       :  Estimate distances, etc. 
        %                               This is the big kahuna as it is
        %                               often loaded by future cases.
        %
        % You can view roi maps by loading paint files and subject surfaces
        % in Caret (software).
        % 
        % Most functionality is achieved with rsa toolbox by JDiedrichsen
        % and NEjaz (among others).
        %
        % See blurbs in each SEARCH case to understand what they do.
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -     
    case 'BG_FSLmask'                                                       % STEP 4.1-2  :  Do segmentation for BG using FSL (step 1&2)
        % uses FSL to do segmentation for BG and map the regions to
        % individual subject anatomy
        % need to run MATLAB through terminal 
        % command: /Applications/MATLAB_R2015b.app/bin/matlab
        
        % 1) Run step 1: sml1h_imana('BG_FSLmask',1,1)
        % 2) Open the zip folder p01b_BG_all_fast_firstseg.nii.gz
        % 3) Run step 2
        
        sn = varargin{1};
        step = varargin{2};
        
        switch (step)
            case 1 % run FSL routine                
                for s= sn%1:numel(subj_name)
                    IN= fullfile(anatomicalDir, subj_name{s}, [subj_name{s}, '_anatomical.nii']);
                    outDir = fullfile(baseDir, 'basal_ganglia', 'FSL');
                    dircheck(outDir);
                    OUT= fullfile(outDir, subj_name{s}, [subj_name{s}, '_BG.nii']);
                    %calc with FSL
                    comm=sprintf('run_first_all -i %s -o %s', IN, OUT);
                    fprintf('%s\n',comm);
                    system(comm);
                end
            case 2 % make the ROI images in subject space
                %         10 Left-Thalamus-Proper 40
                %         11 Left-Caudate 30
                %         12 Left-Putamen 40
                %         13 Left-Pallidum 40
                %         49 Right-Thalamus-Proper 40
                %         50 Right-Caudate 30
                %         51 Right-Putamen 40
                %         52 Right-Pallidum 40
                BGnumber= [11 13 12 10; 50 52 51 49];
                %'CaudateN' 'Pallidum', 'Putamen' 'Thalamus'
               
                for s= sn%1:numel(subj_name)
                    %----deform info for basal ganglia ROI to individual space
                    nam_def = fullfile(anatomicalDir,subj_name{s}, [subj_name{s},'_anatomical_to_std_sub.mat']);
                    mniDir = fullfile(baseDir, 'basal_ganglia', 'FSL', 'MNI', subj_name{s});
                    if ~exist(mniDir,'dir')
                        mkdir(mniDir);
                    end
                    
                    for h=1:2
                        for i=1:numregions_BG
                            fprintf('Working on subj: %i region: %s \n', s, [regname{i+numregions_surf},'_',hem{h}])
                            
                            %----get names!
                            IN= fullfile(baseDir, 'basal_ganglia', 'FSL', subj_name{s},...
                                [subj_name{s},'_BG_all_fast_firstseg.nii']);
                            
                            OUT{i}= fullfile(baseDir, 'basal_ganglia', 'FSL', subj_name{s},...
                                [subj_name{s},'_',regname{i+numregions_surf},'_',hem{h},'.nii']);
                            
                            OUT_MNI{i}= fullfile(baseDir, 'basal_ganglia', 'FSL', 'MNI', subj_name{s},...
                                [subj_name{s},'_',regname{i+numregions_surf},'_',hem{h}, '.nii']);
                            
                            %----make subj specific ROI image
                            spm_imcalc_ui(IN,OUT{i},sprintf('i1==%d',BGnumber(h,i)));
                        end
                        %----do deformation
                        % spmj_normalization_write(nam_def, OUT,'outimages',OUT_MNI);
                    end
                end
            case 3 %make the avrg mask image
                for h=1:2
                    for i=1:numregions_BG
                        for s = 1:numel(sn)%1:numel(subj_name)
                            IN{s} = fullfile(baseDir, 'basal_ganglia', 'FSL',subj_name{sn(s)},...
                                [subj_name{sn(s)},'_',regname{i+numregions_surf},'_',hem{h}, '.nii']);
                        end
                        outDir = fullfile(baseDir, 'basal_ganglia', 'FSL', 'MNI', 'avrg');
                        if ~exist(outDir, 'dir');
                            mkdir(outDir);
                        end
                        OUT = fullfile(outDir,...
                            ['avrg_',regname{i+numregions_surf},'_',hem{h}, '.nii']);
                        spmj_imcalc_mtx(IN,OUT,'mean(X)');
                    end
                end

        end
    case 'SUIT_process_all'  
        % example: sml1_imana('SUIT_process_all',1,2)'
        sn = varargin{1}; % subjNum
        glm = varargin{2}; % glmNum
        %         spm fmri - call first
        for s=sn,
            sml1h_imana('SUIT_isolate_segment','sn',s);
            sml1h_imana('SUIT_normalize','sn',s);
            sml1h_imana('SUIT_reslice',s,glm,'betas');
            sml1h_imana('SUIT_reslice',s,glm,'contrast');
            %sml1h_imana('SUIT_reslice_localizer',s,glm,'betas');
            %sml1h_imana('SUIT_reslice_localizer',s,glm,'contrast');
            sml1h_imana('SUIT_make_mask','sn',s,'glm',glm);
            sml1h_imana('SUIT_roi','sn',s);
            fprintf('Suit data processed for %s',subj_name{s});
        end
    case 'SUIT_isolate_segment'                                             % STEP 4.3   :  Isolate cerebellum using SUIT
        vararginoptions(varargin,{'sn'});     
        for s=sn,
            suitSubjDir = fullfile(suitDir,'anatomicals',subj_name{sn});
            dircheck(suitSubjDir);

            source = fullfile(anatomicalDir,subj_name{s},[subj_name{sn}, '_anatomical','.nii']);
            dest = fullfile(suitSubjDir,'anatomical.nii');
            copyfile(source,dest);
            cd(fullfile(suitSubjDir));
            suit_isolate_seg({fullfile(suitSubjDir,'anatomical.nii')},'keeptempfiles',1);
        end     
    case 'SUIT_normalize'                                                   % STEP 4.4   :  Put cerebellum into SUIT space
        vararginoptions(varargin,{'sn'});     
        for s=sn
            cd(fullfile(suitDir,'anatomicals',subj_name{sn}));
            %----run suit normalize
            suit_normalize(['c_anatomical.nii'], 'mask',['c_anatomical_pcereb.nii'])
        end;
    case 'SUIT_reslice'                                                     % STEP 4.5   :  Reslice functional images (glm as input)                      
        sn=varargin{1}; % subjNum
        glm=varargin{2}; % glmNum
        type=varargin{3}; % 'betas','contrast','mask'     
        
        for s=sn
            suitSubjDir = fullfile(suitDir,'anatomicals',subj_name{s});
            glmSubjDir = [glmDir{glm} filesep subj_name{s}];
            suitGLMDir = fullfile(suitDir,sprintf('glm%d',glm),subj_name{s});
            dircheck(suitGLMDir);
            mask   = fullfile(suitSubjDir,['c_anatomical_pcereb.nii']);
            params = fullfile(suitSubjDir,['mc_anatomical_snc.mat']);
            
            switch type
               case 'mask'
                    source=dir(fullfile(glmSubjDir,'mask.nii')); % images to be resliced
                case 'betas'
                    images='beta_0';
                    source=dir(fullfile(glmSubjDir,sprintf('*%s*',images))); % images to be resliced
                case 'contrast'
                    images='con';
                    source=dir(fullfile(glmSubjDir,sprintf('*%s*',images))); % images to be resliced
            end
            for i=1:size(source,1)
                P=fullfile(glmSubjDir,source(i).name);
                O=fullfile(suitGLMDir,[source(i).name]);
                cd(fullfile(suitGLMDir));
                suit_reslice(P,params,'outfilename',O,'mask',mask,'interp',1,'vox',[1 1 1]);
            end;
        end;
    case 'SUIT_reslice_localizer'
        sn=varargin{1}; % subjNum
        glm=varargin{2}; % glmNum
        type=varargin{3}; % 'betas','contrast','mask'     
        
        for s=sn
            suitSubjDir = fullfile(suitDir,'anatomicals',subj_name{s});
            glmSubjDir = [glmLocDir{glm} filesep subj_name{s}];
            suitGLMDir = fullfile(suitDir,sprintf('glm%d_loc',glm),subj_name{s});
            dircheck(suitGLMDir);
            mask   = fullfile(suitSubjDir,['c_anatomical_pcereb.nii']);
            params = fullfile(suitSubjDir,['mc_anatomical_snc.mat']);
            
            switch type
                case 'betas'
                    images='beta_0';
                    source=dir(fullfile(glmSubjDir,sprintf('*%s*',images))); % images to be resliced
                case 'contrast'
                    images='con';
                    source=dir(fullfile(glmSubjDir,sprintf('*%s*',images))); % images to be resliced
            end
            for i=1:size(source,1)
                P=fullfile(glmSubjDir,source(i).name);
                O=fullfile(suitGLMDir,[source(i).name]);
                cd(fullfile(suitGLMDir));
                suit_reslice(P,params,'outfilename',O,'mask',mask,'interp',1,'vox',[1 1 1]);
            end;
        end;
    case 'SUIT_make_mask'                                                   % STEP 4.6   :  Make cerebellar mask (glm as input)
        vararginoptions(varargin,{'sn','glm'});
        for s=sn
            suitSubjDir = fullfile(suitDir,'anatomicals',subj_name{s});
            mask_all = fullfile(baseDir,sprintf('glm%d',glm),subj_name{s}, 'mask.nii');
            mask_cerebellum = fullfile(suitSubjDir,['c_anatomical_pcereb.nii']);
            mask_suit = fullfile(suitSubjDir, 'mask_suit.nii'); % create
            spm_imcalc_ui({mask_all,mask_cerebellum}, mask_suit, 'i1>0 & i2>0');
        end;        
    case 'SUIT_roi'                                                         % STEP 4.7   :  Generate ROI from cerebellar atlas
        vararginoptions(varargin,{'sn'});
        for s=sn
            suitSubjDir = fullfile(suitDir,'anatomicals',subj_name{s});
            cd(suitSubjDir);
            
            SUIT_num = [1 3 5 2 4 7]; % Lobules IV, V, VI - left/right
            V = spm_vol(fullfile(fileparts(which('suit_reslice')), 'atlas', 'Cerebellum-SUIT.nii'));
            R_atlas= spm_read_vols(V);
            R=zeros(size(R_atlas));
                     
            for i= 1:6
                R(R_atlas==SUIT_num(i))=i;
            end
            % lh: 1,2,3; rh: 4,5,6 (LIV-VI)
            V.fname= fullfile(['ROI_cerebellum_orig.nii']);
            spm_write_vol(V,R);
                       
            %----create the ROI image in subj space saved in the anatomical folder
            refImage= fullfile(baseDir, 'imaging_data',subj_name{s}, ['rmask_noskull.nii']);
            defMat = fullfile(suitSubjDir,'mc_anatomical_snc.mat');
            source = fullfile(suitSubjDir, 'ROI_cerebellum_orig.nii');
            suit_reslice_inv(source, defMat,'reference',refImage,'prefix', 'subjspace_'); %ROI_cerebellum_orig is now in subject space!!!
        end;    
    
    case '5_ROI'% ------------------- ROI analysis. Expand for more info. ------
                % The ROI cases are used to:
        %       - map ROIs to each subject
        %       - harvest timeseries from each roi for each condition
        %
        % There is no 'processAll' case here. However, the following cases
        % must be called to utilize other roi cases:
        %       'ROI_define'      :  Maps rois to surface of each subject-
        %                             requires paint files from above case.
        %       'ROI_timeseries'  :  Only if you wish to plot timeseries
        %       'ROI_getBetas'    :  Harvest patterns from roi
        %       'ROI_stats'       :  Estimate distances, etc. 
        %
        % You can view roi maps by loading paint files and subject surfaces
        % in Caret (software).
        % 
        % Most functionality is achieved with rsa toolbox by JDiedrichsen
        % and NEjaz (among others).
        %
        % See blurbs in each SEARCH case to understand what they do.
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  
    case 'MASK_combine'
        % combine glm masks of all runs, create one mask overall
        
        vararginoptions(varargin,{'sn'});
        for s = sn
            for sess = 1:sess_sn(sn)
                file = fullfile(glmSessDir{sess},subj_name{s},'mask.nii');
                V = spm_vol(file);
                mask(:,:,:,sess)=spm_read_vols(V);
            end
            maskNew=mask(:,:,:,1).*mask(:,:,:,2).*mask(:,:,:,3).*mask(:,:,:,4);
            dest = fullfile(regDir, ['mask_' subj_name{sn} '.nii']);
            V.fname=dest;
            V.dim=size(maskNew);
            V=rmfield(V,'descrip');
            V.descrip = 'combined_mask';
            spm_write_vol(V,maskNew);
        end
    case 'ROI_define_sess'  % only used if not complete dataset - mask per glm rather than overall mask
        
        vararginoptions(varargin,{'sn','sessN'});
        for s=sn
            R=[];
            for h=1:2
                C = caret_load(fullfile(caretDir,'fsaverage_sym',hemName{h},['ROI.paint']));
                caretSubjDir = fullfile(caretDir,['x' subj_name{s}]);  
               % suitSubjDir = fullfile(suitDir,'anatomicals',subj_name{s});

               %file = fullfile(regDir,['mask_' subj_name{s} '.nii']); % mask constructed in mask_combine
               file = fullfile(glmSessDir{sessN},subj_name{s},'mask.nii'); % mask constructed in glm    
                
                 for i=1:numregions_surf
                    R{i+(h-1)*numregions_surf}.type='surf_nodes';
                    R{i+(h-1)*numregions_surf}.white=fullfile(caretSubjDir,hemName{h},[hem{h} '.WHITE.coord']);
                    R{i+(h-1)*numregions_surf}.pial=fullfile(caretSubjDir,hemName{h},[hem{h} '.PIAL.coord']);
                    R{i+(h-1)*numregions_surf}.topo=fullfile(caretSubjDir,hemName{h},[hem{h} '.CLOSED.topo']);
                    R{i+(h-1)*numregions_surf}.flat=fullfile(caretDir,'fsaverage_sym',hemName{h},[hem{h} '.FLAT.coord']);
                    
                    R{i+(h-1)*numregions_surf}.linedef=[10,0,1];
                    R{i+(h-1)*numregions_surf}.image=file;
                    R{i+(h-1)*numregions_surf}.name=[subj_name{s} '_' regname_cortex{i} '_' hem{h}];
                    R{i+(h-1)*numregions_surf}.location=find(C.data(:,1)==i);
                 end            
                          
            end;
                 
            R=region_calcregions(R);
            dircheck(regDir);
            cd(regDir);
            save([subj_name{s} '_regions.mat'],'R'); 
            
            fprintf('\nROIs have been defined for %s \n',subj_name{sn});
        end    
    case 'ROI_define'                                                       % STEP 5.1   :  Define ROIs

        vararginoptions(varargin,{'sn'});
        for s=sn
            R=[];
            for h=1:2
                C = caret_load(fullfile(caretDir,'fsaverage_sym',hemName{h},['ROI.paint']));
                caretSubjDir = fullfile(caretDir,['x' subj_name{s}]);  
               % suitSubjDir = fullfile(suitDir,'anatomicals',subj_name{s});

               file = fullfile(regDir,['mask_' subj_name{s} '.nii']); % mask constructed in mask_combine
                %file = fullfile(glmSessDir{sessN},subj_name{s},'mask.nii');
                
                 for i=1:numregions_surf
                    R{i+(h-1)*numregions_surf}.type='surf_nodes';
                    R{i+(h-1)*numregions_surf}.white=fullfile(caretSubjDir,hemName{h},[hem{h} '.WHITE.coord']);
                    R{i+(h-1)*numregions_surf}.pial=fullfile(caretSubjDir,hemName{h},[hem{h} '.PIAL.coord']);
                    R{i+(h-1)*numregions_surf}.topo=fullfile(caretSubjDir,hemName{h},[hem{h} '.CLOSED.topo']);
                    R{i+(h-1)*numregions_surf}.flat=fullfile(caretDir,'fsaverage_sym',hemName{h},[hem{h} '.FLAT.coord']);
                    
                    R{i+(h-1)*numregions_surf}.linedef=[10,0,1];
                    R{i+(h-1)*numregions_surf}.image=file;
                    R{i+(h-1)*numregions_surf}.name=[subj_name{s} '_' regname_cortex{i} '_' hem{h}];
                    R{i+(h-1)*numregions_surf}.location=find(C.data(:,1)==i);
                 end            
                          
            end;
                 
            R=region_calcregions(R);
            dircheck(regDir);
            cd(regDir);
            save([subj_name{s} '_regions.mat'],'R'); 
            
            fprintf('\nROIs have been defined for %s \n',subj_name{sn});
        end         
    case 'ROI_make_nii'                                                     % OPTIONAL   :  Convert ROI def (.mat) into multiple .nii files (to check!)
              
        vararginoptions(varargin,{'sn','sessN'});        
        
        for s=sn
            glmSubjDir = [glmSessDir{sessN} filesep subj_name{s}];
            %suitSubjDir = fullfile(suitDir,'anatomicals',subj_name{s});

            cd(glmSubjDir);
            % load ROI definition
            load(fullfile(regDir,sprintf('%s_regions.mat',subj_name{s})));

            % loop over rois
            for roi = 1:size(R,2)
                % mask volume
                mask = fullfile(glmSubjDir,'mask.nii');           
                % Save region file as nifti
                cd(regDir);
               % if sum(roi==[12:14 27:28])==1 % for cerebellar ROIs 
               %     mask = fullfile(suitSubjDir,'mask_suit.nii');
               % end
                region_saveasimg(R{roi},mask);      
            end
            
        end    
    case 'ROI_timeseries'                                                   % STEP 5.2   :  Extract onsets and events/trials - hrf
        % to check the model quality of the glm
        glm=2;
        vararginoptions(varargin,{'sn','sessN','glm'});

        pre=4;          % How many TRs before the trial onset
        post=16;        % How many TRs after the trial onset
        T=[];
        for s=sn
            fprintf('Extracting the onsets and events for subject %s, glm %d and session %d\n',subj_name{s},glm,sessN);
            load(fullfile(glmSessDir{sessN},subj_name{s},'SPM.mat')); 
            
            SPM=spmj_move_rawdata(SPM,fullfile(baseDir,'imaging_data', subj_name{s}));
            load(fullfile(regDir,[subj_name{s} '_regions.mat']));      % This is made in case 'ROI_define'
            [y_raw, y_adj, y_hat, y_res,B] = region_getts(SPM,R);      % Gets the time series data for the data
            
            % Create a structure with trial onset and trial type (event)
            D=spmj_get_ons_struct(SPM);     % Returns onsets in TRs, not secs
            % D.event - conditions (seqNumb: 1-12)
            % D.block - run
            for r=1:size(y_raw,2)   % regions
                S.block=D.block;
                for i=1:(size(S.block,1));  
                    S.y_adj(i,:)=cut(y_adj(:,r),pre,round(D.ons(i)),post,'padding','nan')';
                    S.y_hat(i,:)=cut(y_hat(:,r),pre,round(D.ons(i)),post,'padding','nan')';
                    S.y_res(i,:)=cut(y_res(:,r),pre,round(D.ons(i)),post,'padding','nan')';
                    S.y_raw(i,:)=cut(y_raw(:,r),pre,round(D.ons(i)),post,'padding','nan')';
                end;                
                S.event=D.event;
                S.sn=ones(length(S.event),1)*s;
                S.region=ones(length(S.event),1)*r; % region
                S.regType=regType(S.region)';
                S.regSide=regSide(S.region)';
                % indicate sequence type
                S.seqType=zeros(length(S.event),1);
                S.seqType(S.event<7)=1;
                S.seqType(S.event>6)=2;
                T=addstruct(T,S);
            end;
        end;
        cd(regDir);
        save(sprintf('hrf_%s_sess%d_glm%d.mat',subj_name{sn},sessN,glm),'-struct','T');
    case 'ROI_plot_timeseries'                                              % STEP 5.3   :  Plot estimated hrf by sequence type (trained/untrained)                     
        sn=1; 
        glm=2; 
        sessN=1;
        reg=5;
        regS=1; % 1 - LH, 2 - RH
        vararginoptions(varargin,{'sn','sessN','glm','reg','regS'});
        T=load(fullfile(regDir,sprintf('hrf_%s_sess%d_glm%d.mat',subj_name{sn},sessN,glm)));
        
        traceplot([-4:16],T.y_adj,'errorfcn','stderr','subset',T.regSide==regS & T.regType==reg,'split',T.seqType,'leg','auto');
        hold on;
        traceplot([-4:16],T.y_hat,'subset',T.regSide==regS & T.regType==reg,'linestyle',':','split',T.seqType);
        hold off;
        xlabel('TR');
        ylabel('activation');
        drawline(0); 
    case 'ROI_timeseries_localizer'                                         % STEP 5.4   :  Extract onsets and events/trials for localizer - hrf
        % to check the model quality of the glm
        sessN=1;
        vararginoptions(varargin,{'sn','sessN'});

        pre=4;          % How many TRs before the trial onset
        post=16;        % How many TRs after the trial onset
        T=[];
        for s=sn
            fprintf('Extracting the onsets and events for subject %s and session %d\n',subj_name{s},sessN);
            load(fullfile(glmLocSessDir{sessN},subj_name{s},'SPM.mat'));
            
            SPM=spmj_move_rawdata(SPM,fullfile(baseDir,'imaging_data', subj_name{s})); % This accounts for shifting
            load(fullfile(regDir,[subj_name{s} '_regions.mat']));   % This is made in case 'ROI_define'
            [y_raw, y_adj, y_hat, y_res,B] = region_getts(SPM,R);      % Gets the time series data for the data
            
            % Create a structure with trial onset and trial type (event)
            D=spmj_get_ons_struct(SPM);     % Returns onsets in TRs, not secs
            % D.event - conditions (seqNumb: 1-10)
            % D.block - run
            for r=1:size(y_raw,2)   % regions
                for i=1:size(D.block,1);  % runs
                    D.y_adj(i,:)=cut(y_adj(:,r),pre,round(D.ons(i)),post,'padding','nan')';
                    D.y_hat(i,:)=cut(y_hat(:,r),pre,round(D.ons(i)),post,'padding','nan')';
                    D.y_res(i,:)=cut(y_res(:,r),pre,round(D.ons(i)),post,'padding','nan')';
                end;                
                D.sn=ones(size(D.event,1),1)*s;
                D.region=ones(size(D.event,1),1)*r; % region
                D.regType=regType(D.region)';
                D.regSide=regSide(D.region)';
                % indicate sequence type
                D.seqType=ones(size(D.event,1),1)*3; % localiser mapping - 3
                T=addstruct(T,D);
            end;
        end;
        cd(regDir);
        save(sprintf('hrf_%s_LOC_sess%d.mat',subj_name{sn},sessN),'-struct','T');
    case 'ROI_plot_timeseries_localizer'                                    % STEP 5.5   :  Plot estimated hrf for finger presses                    
        sn=7; 
        sessN=1; 
        reg=2;
        regS=1; % 1 - LH, 2 - RH
        vararginoptions(varargin,{'sn','sessN','reg','regS'});
        T=load(fullfile(regDir,sprintf('hrf_%s_LOC_sess%d.mat',subj_name{sn},sessN)));
        
        traceplot([-4:16],T.y_adj,'errorfcn','stderr','subset',T.regSide==regS & T.regType==reg,'leg','auto');
        hold on;
        traceplot([-4:16],T.y_hat,'subset',T.regSide==regS & T.regType==reg,'linestyle',':');
        hold off;
        xlabel('TR');
        ylabel('activation');
        drawline(0); 
      
    case 'ROI_getBetas'                                                     % STEP 5.6   :  Harvest betas from rois (raw, univ, multiv prewhit)
        
        sessN = 1;
        sn  = 1;    
        roi = [1:16];
        vararginoptions(varargin,{'sn','sessN','roi'});
        
        T=[];
            
        % harvest
        for s=sn % for each subj
            fprintf('\nSubject: %d\n',s) % output to user
            
            % load files
            load(fullfile(glmSessDir{sessN}, subj_name{s},'SPM.mat'));  % load subject's SPM data structure (SPM struct)
            load(fullfile(regDir,[subj_name{s} '_regions.mat']));        % load subject's region parcellation (R)

            V = SPM.xY.VY; 
            
            for r = roi % for each region
                % get raw data for voxels in region
                Y = region_getdata(V,R{r});  % Data Y is N x P 
                % estimate region betas
                [betaW,resMS,SW_raw,beta] = rsa.spm.noiseNormalizeBeta(Y,SPM,'normmode','overall');
                S.betaW                   = {betaW};                             % multivariate pw
                S.betaUW                  = {bsxfun(@rdivide,beta,sqrt(resMS))}; % univariate pw 
                S.betaRAW                 = {beta};
                S.resMS                   = {resMS};
                S.SN                      = s;
                S.region                  = r;
                T = addstruct(T,S);
                fprintf('%d.',r)
            end
        end
        % save T
        save(fullfile(regDir,sprintf('betas_sess%d.mat',sessN)),'-struct','T'); 
        fprintf('\n');    
    case 'ROI_getBetas_FoSEx'
        sessN = 1;
        sn  = 1;    
        roi = [1:16];
        vararginoptions(varargin,{'sn','sessN','roi'});
        
        T=[];
            
        % harvest
        for s=sn % for each subj
            fprintf('\nSubject: %d\n',s) % output to user
            
            % load files
            load(fullfile(glmFoSExDir{sessN}, subj_name{s},'SPM.mat'));  % load subject's SPM data structure (SPM struct)
            load(fullfile(regDir,[subj_name{s} '_regions.mat']));        % load subject's region parcellation (R)
            V = SPM.xY.VY; 
            
            for r = roi % for each region
                % get raw data for voxels in region
                Y = region_getdata(V,R{r});  % Data Y is N x P 
                % estimate region betas
                [betaW,resMS,SW_raw,beta] = rsa.spm.noiseNormalizeBeta(Y,SPM,'normmode','overall');
                S.betaW                   = {betaW};                             % multivariate pw
                S.betaUW                  = {bsxfun(@rdivide,beta,sqrt(resMS))}; % univariate pw 
                S.betaRAW                 = {beta};
                S.resMS                   = {resMS};
                S.SN                      = s;
                S.region                  = r;
                T = addstruct(T,S);
                fprintf('%d.',r)
            end
        end
        % save T
        save(fullfile(regDir,sprintf('betas_FoSEx_sess%d.mat',sessN)),'-struct','T'); 
        fprintf('\n');    
    case 'ROI_getBetas_LOC'
        % for localizer  
        sessN = 1;
        sn  = 1;    
        roi = [1:16];
        vararginoptions(varargin,{'sn','sessN','roi'});
        
        T=[];
            
        % harvest
        for s=sn % for each subj
            fprintf('\nSubject: %d  sess: %d\n',s,sessN) % output to user
            
            % load files
            load(fullfile(glmLocSessDir{sessN}, subj_name{s},'SPM.mat'));  % load subject's SPM data structure (SPM struct)
            load(fullfile(regDir,[subj_name{s} '_regions.mat']));          % load subject's region parcellation (R)

            V = SPM.xY.VY; 
            
            for r = roi % for each region
                % get raw data for voxels in region
                Y = region_getdata(V,R{r});  % Data Y is N x P 
                % estimate region betas
                [betaW,resMS,SW_raw,beta] = rsa.spm.noiseNormalizeBeta(Y,SPM,'normmode','overall');
                S.betaW                   = {betaW};                             % multivariate pw
                S.betaUW                  = {bsxfun(@rdivide,beta,sqrt(resMS))}; % univariate pw 
                S.betaRAW                 = {beta};
                S.resMS                   = {resMS};
                S.SN                      = s;
                S.region                  = r;
                T = addstruct(T,S);
                fprintf('%d.',r)
            end
        end
        % save T
        save(fullfile(regDir,sprintf('betas_LOC_sess%d.mat',sessN)),'-struct','T'); 
        fprintf('\n');  
    case 'ROI_stats'                                                        % STEP 5.8   :  Calculate stats/distances on activity patterns - train/untrain seq
        sessN = 1;
        sn  = [1:5];
        roi = [1:16];
        betaChoice = 'multi'; % uni, multi or raw
        vararginoptions(varargin,{'sn','sessN','roi','betaChoice'});
        
        T = load(fullfile(regDir,sprintf('betas_sess%d.mat',sessN))); % loads region data (T)
        
        % output structures
        Ts = [];
        To = [];
        
        % do stats
        for s = sn % for each subject
            D = load(fullfile(glmSessDir{sessN}, subj_name{s}, 'SPM_info.mat'));   % load subject's trial structure
            fprintf('\nSubject: %d session: %d\n',s,sessN)
            num_run = numruns_task_sess;
            
            for r = roi % for each region
                S = getrow(T,(T.SN==s & T.region==r)); % subject's region data
                fprintf('%d.',r)
                
                switch (betaChoice)
                    case 'uni'
                        betaW  = S.betaUW{1};
                    case 'multi'
                        betaW  = S.betaW{1};
                    case 'raw'
                        betaW  = S.betaRAW{1};
                end
                
                % % To structure stats (all seqNumb - 12 conditions)
                % crossval second moment matrix
                [G,Sig]     = pcm_estGCrossval(betaW(1:(12*num_run),:),D.run,D.seqNumb);
                So.IPM      = rsa_vectorizeIPM(G);
                So.Sig      = rsa_vectorizeIPM(Sig);
                % squared distances
                So.RDM_nocv = distance_euclidean(betaW',D.seqNumb)';
                So.RDM      = rsa.distanceLDC(betaW,D.run,D.seqNumb);
                % trained seq
                H=eye(6)-ones(6,6)./6;  % centering matrix!
                [G_train, Sig_train] = pcm_estGCrossval(betaW(D.seqType==1,:),D.run(D.seqType==1),D.seqNumb(D.seqType==1));   
                G_trainCent = H*G_train*H;  % double centered G matrix - rows and columns
                So.eigTrain = sort(eig(G_trainCent)','descend');    % sorted eigenvalues
                [G_untrain, Sig_untrain] = pcm_estGCrossval(betaW(D.seqType==2,:),D.run(D.seqType==2),D.seqNumb(D.seqType==2));
                G_untrainCent = H*G_untrain*H;  % double centered G matrix - rows and columns
                So.eigUntrain = sort(eig(G_untrainCent)','descend');
                % untrained seq
                % indexing fields
                So.SN       = s;
                So.region   = r;
                So.regSide  = regSide(r);
                So.regType  = regType(r);
                To          = addstruct(To,So);
                
            end; % each region
        end; % each subject

        % % save
        save(fullfile(regDir,sprintf('stats_%sPW_sess%d.mat',betaChoice,sessN)),'-struct','To');
        fprintf('\nDone.\n')    
    case 'ROI_stats_LOC'
        sessN = 1;
        sn  = [1:5];
        roi = [1:16];
        betaChoice = 'multi';
        vararginoptions(varargin,{'sn','sessN','roi','betaChoice'});
        
        T = load(fullfile(regDir,sprintf('betas_LOC_sess%d.mat',sessN))); % loads region data (T)
        
        % output structures
        Ts = [];
        To = [];
        
        % do stats
        for s = sn % for each subject
            D = load(fullfile(glmLocSessDir{sessN}, subj_name{s}, 'SPM_info.mat'));   % load subject's trial structure
            fprintf('\nSubject: %d session: %d\n',s, sessN)
            num_run = numruns_loc_sess;
            
            for r = roi % for each region
                S = getrow(T,(T.SN==s & T.region==r)); % subject's region data
                fprintf('%d.',r)
                
                switch (betaChoice)
                    case 'uni'
                        betaW  = S.betaUW{1};
                    case 'multi'
                        betaW  = S.betaW{1};
                    case 'raw'
                        betaW  = S.betaRAW{1};
                end
                
                % % TseqNumb structure stats (finger mapping - 5 conditions)
                % crossval second moment matrix
                [G,Sig]     = pcm_estGCrossval(betaW(1:(5*num_run),:),D.run,D.seqNumb);
                H=eye(5)-ones(5,5)./5;  % centering matrix!
                G_cent      = H*G*H;  % double centered G matrix - rows and columns
                So.eig      = sort(eig(G_cent)','descend');
                So.IPM      = rsa_vectorizeIPM(G);
                So.Sig      = rsa_vectorizeIPM(Sig);
                % squared distances
                So.RDM_nocv = distance_euclidean(betaW',D.seqNumb)';
                So.RDM      = rsa.distanceLDC(betaW,D.run,D.seqNumb);
                % indexing fields
                So.SN       = s;
                So.region   = r;
                So.regSide  = regSide(r);
                So.regType  = regType(r);
                To          = addstruct(To,So);
                
            end; % each region
        end; % each subject

        % % save
        save(fullfile(regDir,sprintf('stats_LOC_%sPW_sess%d.mat',betaChoice,sessN)),'-struct','To');
        fprintf('\nDone.\n')  
    case 'ROI_stats_FoSEx'
        sessN = 1;
        sn  = [1:5];
        roi = [1:16];
        betaChoice = 'multi'; % uni, multi or raw
        vararginoptions(varargin,{'sn','sessN','roi','betaChoice'});
        
        T = load(fullfile(regDir,sprintf('betas_FoSEx_sess%d.mat',sessN))); % loads region data (T)
        
        % output structures
        Ts = [];
        To = [];
        
        % do stats
        for s = sn % for each subject
            D = load(fullfile(glmFoSExDir{sessN}, subj_name{s}, 'SPM_info.mat'));   % load subject's trial structure
            fprintf('\nSubject: %d session: %d\n',s, sessN)
            num_run = numruns_task_sess;
            
            for r = roi % for each region
                S = getrow(T,(T.SN==s & T.region==r)); % subject's region data
                fprintf('%d.',r)
                
                for exe = 1:2   % FoSEx
                    switch (betaChoice)
                        case 'uni'
                            betaW  = S.betaUW{1}(D.FoSEx==exe,:);
                        case 'multi'
                            betaW  = S.betaW{1}(D.FoSEx==exe,:);
                        case 'raw'
                            betaW  = S.betaRAW{1}(D.FoSEx==exe,:);
                    end
                    
                    D_exe = getrow(D,D.FoSEx==exe);
                    
                    % % To structure stats (all seqNumb - 12 conditions)
                    % crossval second moment matrix
                    [G,Sig]     = pcm_estGCrossval(betaW(1:(12*num_run),:),D_exe.run,D_exe.seqNumb);
                    So.IPM      = rsa_vectorizeIPM(G);
                    So.Sig      = rsa_vectorizeIPM(Sig);
                    % squared distances
                    So.RDM_nocv = distance_euclidean(betaW',D_exe.seqNumb)';
                    So.RDM      = rsa.distanceLDC(betaW,D_exe.run,D_exe.seqNumb);
                    % trained seq
                    H=eye(6)-ones(6,6)./6;  % centering matrix!
                    [G_train, Sig_train] = pcm_estGCrossval(betaW(D_exe.seqType==1,:),D.run(D_exe.seqType==1),D.seqNumb(D_exe.seqType==1));
                    G_trainCent = H*G_train*H;  % double centered G matrix - rows and columns
                    So.eigTrain = sort(eig(G_trainCent)','descend');    % sorted eigenvalues
                    [G_untrain, Sig_untrain] = pcm_estGCrossval(betaW(D_exe.seqType==2,:),D.run(D_exe.seqType==2),D.seqNumb(D_exe.seqType==2));
                    G_untrainCent = H*G_untrain*H;  % double centered G matrix - rows and columns
                    So.eigUntrain = sort(eig(G_untrainCent)','descend');
                    % untrained seq
                    % indexing fields
                    So.SN       = s;
                    So.region   = r;
                    So.regSide  = regSide(r);
                    So.regType  = regType(r);
                    So.FoSEx    = exe;
                    To          = addstruct(To,So);
                    
                end; % FoSEx
            end; % each region
        end; % each subject

        % % save
        save(fullfile(regDir,sprintf('stats_FoSEx_%sPW_sess%d.mat',betaChoice,sessN)),'-struct','To');
        fprintf('\nDone.\n')  
        
    case 'ROI_beta_consist_witSess'                                           % OPTIONAL   :  Calculates pattern consistencies for each subject in roi across glms.
        % pattern consistency for specified roi
        % Pattern consistency is a measure of the proportion of explained
        % beta variance across runs within conditions. 
        % 
        % This stat is useful for determining which GLM model yields least
        % variable beta estimates. That GLM should be the one you use for
        % future analysis cases.
        %
        % enter sn, region, glm #, beta: 0=betaW, 1=betaUW, 2=raw betas
        % (1) Set parameters
        sessN = 1;
        sn  = 1;
        roi = 2; % default LH primary motor cortex
        betaChoice = 'uw';  % raw / uw / mw -> MW performs the best!
        removeMean = 'yes'; % are we removing pattern means for patternconsistency?
        vararginoptions(varargin,{'sn','glm','roi','betaChoice','removeMean'});
        
        if strcmp(removeMean,'yes')
             rm = 1; % we are removing the mean
        else rm = 0; % we are keeping the mean (yeilds higher consistencies but these are biased)
        end
  
        Rreturn=[];
        %========%
        for s=sessN
            T = load(fullfile(regDir,sprintf('betas_sess%d.mat',s))); % loads in struct 'T'
            for r=roi
                Rall=[]; %prep output variable
                for s=sn
                    S = getrow(T,(T.SN==s & T.region==r));
                    runs = 1:numruns_task_sess; % 8 func runs
                    switch(betaChoice)
                        case 'raw'
                            betaW  = S.betaW{1}; 
                        case 'uw'
                            betaW  = S.betaUW{1}; 
                        case 'mw'
                            betaW  = S.betaRAW{1}; 
                    end
                    
                    % make vectors for pattern consistency func
                    conditionVec = kron(ones(numel(runs),1),[1:12]');
                    partition    = kron(runs',ones(12,1));
                    % calculate the pattern consistency
                    R2   = rsa_patternConsistency(betaW,partition,conditionVec,'removeMean',rm);
                    Rall = [Rall,R2];
                end
                Rreturn = [Rreturn;Rall];
            end
        end
        varargout = {Rreturn};
        fprintf('The consistency for %s betas in region %s is',betaChoice,regname{roi});
        % output arranged such that each row is an roi, each col is subj
        
        %_______________    
    case 'ROI_beta_consist_betwSess'
        % evaluate consistency of measures (psc, beta, z-scores) across
        % sessions for finger mapping
        
        sn  = 1;
        reg = 1:7;
        removeMean = 'yes'; % are we removing pattern means for patternconsistency?
        betaChoice = 'multi'; % options: uni / multi / raw
        seq = 'untrained';
        vararginoptions(varargin,{'sn','reg','betaChoice','removeMean','seq'});
        
        if strcmp(removeMean,'yes')
             rm = 1; % we are removing the mean
        else rm = 0; % we are keeping the mean (yeilds higher consistencies but these are biased)
        end
        
       for  roi = reg;
        CS=[];  % separate per digit
        PS=[];  % across all digits
        for sessN = 1:4; % per session
            C=[];P=[];
            T = load(fullfile(regDir,sprintf('betas_sess%d.mat',sessN))); % loads region data (T)
        
            switch (betaChoice)
            case 'uni'
                beta = T.betaUW;
            case 'multi'
                beta = T.betaW;
            case 'raw'
                beta = T.betaRAW;
            end
        
            runs=1:numruns_task_sess;
            conditionVec = kron(ones(numel(runs),1),[1:12]');
            
            switch(seq)
                case 'trained'
                    idx=1:6;
                case 'untrained'
                    idx=7:12;
            end

            %C.beta=beta{roi};   
            for d = 1:6 %sequences
                C.beta_seq(d,:)=mean(beta{roi}(conditionVec==idx(d),:),1);  % beta values for each digit (avrg across blocks)
                C.psc_seq(d,:)=mean(beta{roi}(conditionVec==idx(d),:),1)./mean(beta{roi}(end-7:end,:),1).*100;
                C.zscore_seq(d,:) = (C.beta_seq(d,:)-mean(C.beta_seq(d,:)))./std(C.beta_seq(d,:));
            end
            
            %C.zscore_seq = bsxfun(@rdivide,C.beta_seq,sqrt(T.resMS{roi}));
           
            C.seq_ind=[1:6]';
            C.sessN=ones(6,1)*sessN;
            C.roi=ones(6,1)*roi;

            P.beta_mean=mean(C.beta_seq,1);   % mean pattern acros digit in each session
            P.zscore_mean=mean(C.zscore_seq,1);
            %P.zscore_mean=bsxfun(@rdivide,P.beta_mean,sqrt(T.resMS{roi}));
            P.sessN=sessN;
            P.roi=roi;
            
            CS=addstruct(CS,C);
            PS=addstruct(PS,P);
        end
        
        ind = indicatorMatrix('allpairs',([1:4]));  % betwSess indicator
        for n=1:numel(unique(CS.seq_ind))
            T = getrow(CS,CS.seq_ind==n);
            for i=1:size(ind,1)
                [i1 i2] = find(ind(i,:)~=0);
                if rm == 1
                    AcrSess_b(i)=corr(T.beta_seq(i1(2),:)',T.beta_seq(i2(2),:)');
                    AcrSess_z(i)=corr(T.zscore_seq(i1(2),:)',T.zscore_seq(i2(2),:)');
                    AcrSess_p(i)=corr(T.psc_seq(i1(2),:)',T.psc_seq(i2(2),:)');
                elseif rm == 0
                    AcrSess_b(i)=corrN(T.beta_seq(i1(2),:)',T.beta_seq(i2(2),:)');
                    AcrSess_z(i)=corrN(T.zscore_seq(i1(2),:)',T.zscore_seq(i2(2),:)');
                    AcrSess_z(i)=corrN(T.psc_seq(i1(2),:)',T.psc_seq(i2(2),:)');
                end
            end
            AcrSess_beta(n)=mean(AcrSess_b);
            AcrSess_zscore(n)=mean(AcrSess_z);
            AcrSess_psc(n)=mean(AcrSess_p);
        end
        Consist.beta_corr(roi,:) = AcrSess_beta;
        Consist.zscore_corr(roi,:) = AcrSess_zscore;
        Consist.psc_corr(roi,:) = AcrSess_psc;
        Consist.beta_RSA(roi,1) = rsa_patternConsistency(CS.beta_seq,CS.sessN,CS.seq_ind,'removeMean',rm);
        Consist.zscore_RSA(roi,1) = rsa_patternConsistency(CS.zscore_seq,CS.sessN,CS.seq_ind,'removeMean',rm);
        Consist.psc_RSA(roi,1) = rsa_patternConsistency(CS.psc_seq,CS.sessN,CS.seq_ind,'removeMean',rm);
        Consist.roi(roi,1) = roi;
        
       end
       
        figure(1)
        col=hsv(7);
        for i = reg
            a(i)=plot(Consist.beta_corr(i,:),'-o','Color',col(i,:));
            hold on;
            drawline(Consist.beta_RSA(i),'dir','horz','color',col(i,:));
        end
        title('Beta values')
        legend(a,regname(reg));
        xlabel('All across-session combinations');
        ylabel('Correlation / RSA consistency(line)')
        
        figure(2)
        for j=reg
            b(j)=plot(Consist.psc_corr(j,:),'-o','Color',col(j,:));
            hold on;
            drawline(Consist.psc_RSA(j),'dir','horz','color',col(j,:));
        end
        title('Percentage')
        legend(b,regname(reg));
        xlabel('All across-session combinations');
        ylabel('Correlation / RSA consistency(line)');
        
        keyboard;  
    case 'ROI_beta_consist_betwSess_LOC'
        % evaluate consistency of measures (psc, beta, z-scores) across
        % sessions for finger mapping
        
        sn  = 1;
        sessN = 1;
        reg = 1:7;
        keepmean=0;
        betaChoice = 'multi'; % options: uni / multi / raw
        vararginoptions(varargin,{'sn','sessN','reg','betaChoice','keepmean'});

        
       for  roi = reg;
        CS=[];  % separate per digit
        PS=[];  % across all digits
        for sessN = 1:4; % per session
            C=[];P=[];
            T = load(fullfile(regDir,sprintf('betas_LOC_sess%d.mat',sessN))); % loads region data (T)
        
            switch (betaChoice)
            case 'uni'
                beta = T.betaUW;
            case 'multi'
                beta = T.betaW;
            case 'raw'
                beta = T.betaRAW;
            end
        
            %C.beta=beta{roi};   % 12 betas x voxels (1-5, 1-5; 2 intercept)
            for d = 1:5 %digits
                C.beta_digit(d,:)=mean(beta{roi}([d,d+6],:),1);  % beta values for each digit (avrg across two blocks)
               % C.psc_digit(d,:)=mean(median(max(beta{roi}(d,:)))/median(max(beta{roi}(6,:))),...
               %     median(max(beta{roi}(d+6,:)))/median(max(beta{roi}(12,:))));  % mean of psc of two blocks - median response / intercept
            end
            
            C.zscore_digit = bsxfun(@rdivide,C.beta_digit,sqrt(T.resMS{roi}));
            C.digit_ind=[1:5]';
            C.sessN=ones(5,1)*sessN;
            C.roi=ones(5,1)*roi;
            
            
            P.beta_mean=mean(C.beta_digit,1);   % mean pattern acros digit in each session
            P.zscore_mean=bsxfun(@rdivide,P.beta_mean,sqrt(T.resMS{roi}));
            P.sessN=sessN;
            P.roi=roi;
            
            CS=addstruct(CS,C);
            PS=addstruct(PS,P);
        end
        
        O.betas(roi,:) = mean(PS.beta_mean,2)';    % one value per session
        O.zscore(roi,:) = mean(PS.zscore_mean,2)';
        O.roi(roi,1) = roi;
        
        ind = indicatorMatrix('allpairs',([1:4]));  % betwSess indicator
        for i=1:size(ind,1)
            [i1 i2] = find(ind(i,:)~=0);
            if keepmean == 0
                Consist.beta(roi,i)=corr(PS.beta_mean(i1(2),:)',PS.beta_mean(i2(2),:)');
                Consist.zscore(roi,i)=corr(PS.zscore_mean(i1(2),:)',PS.zscore_mean(i2(2),:)');
            elseif keepmean == 1
                Consist.beta(roi,i)=corrN(PS.beta_mean(i1(2),:)',PS.beta_mean(i2(2),:)');
                Consist.zscore(roi,i)=corrN(PS.zscore_mean(i1(2),:)',PS.zscore_mean(i2(2),:)');
            end
        end
        
        Consist.beta_RSA(roi,1) = rsa_patternConsistency(CS.beta_digit,CS.sessN,CS.digit_ind,'removeMean',keepmean);
        Consist.zscore_RSA(roi,1) = rsa_patternConsistency(CS.zscore_digit,CS.sessN,CS.digit_ind,'removeMean',keepmean);
        Consist.roi(roi,1) = roi;
        
       end
       
        figure(1)
        col=hsv(7);
        for i = reg
            a(i)=plot(Consist.beta(i,:),'-o','Color',col(i,:));
            hold on;
            drawline(Consist.beta_RSA(i),'dir','horz','color',col(i,:));
        end
        title('Beta values')
        legend(a,regname(reg));
        xlabel('All across-session combinations');
        ylabel('Correlation / RSA consistency(line)')
        
        figure(2)
        for j=reg
            b(j)=plot(Consist.zscore(j,:),'-o','Color',col(j,:));
            hold on;
            drawline(Consist.zscore_RSA(j),'dir','horz','color',col(j,:));
        end
        title('Z scores')
        legend(b,regname(reg));
        xlabel('All across-session combinations');
        ylabel('Correlation / RSA consistency(line)');
        
        keyboard;
    case 'ROI_beta_consist_witSess_LOC'
        % pattern consistency for specified roi
        % Pattern consistency is a measure of the proportion of explained
        % beta variance across runs within conditions. 
        % 
        % This stat is useful for determining which GLM model yields least
        % variable beta estimates. That GLM should be the one you use for
        % future analysis cases.
        %
        % enter sn, region, glm #, beta: 0=betaW, 1=betaUW, 2=raw betas
        % (1) Set parameters
        sessN = 1;
        sn  = 1;
        roi = 2; % default LH primary motor cortex
        betaChoice = 'uw';  % raw / uw / mw 
        keepmean = 0; % are we removing pattern means for patternconsistency?
        vararginoptions(varargin,{'sn','glm','roi','betaChoice','keepmean','sessN'});

        Rreturn=[];
        %========%
        for s=sessN
            T = load(fullfile(regDir,sprintf('betas_LOC_sess%d.mat',s))); % loads in struct 'T'
            for r=roi
                Rall=[]; %prep output variable
                for s=sn
                    S = getrow(T,(T.SN==s & T.region==r));
                    runs = 1:numruns_loc_sess; % 2 func runs
                    switch(betaChoice)
                        case 'raw'
                            betaW  = S.betaW{1}; 
                        case 'uw'
                            betaW  = S.betaUW{1}; 
                        case 'mw'
                            betaW  = S.betaRAW{1}; 
                    end
                    
                    % make vectors for pattern consistency func
                    conditionVec = kron(ones(numel(runs),1),[1:5]');
                    partition    = kron(runs',ones(5,1));
                    % calculate the pattern consistency
                    R2   = rsa_patternConsistency(betaW,partition,conditionVec,'removeMean',keepmean);
                    Rall = [Rall,R2];
                end
                Rreturn = [Rreturn;Rall];
            end
        end
        varargout = {Rreturn};
        fprintf('The consistency for %s betas in region %s is',betaChoice,regname{roi});
        % output arranged such that each row is an roi, each col is subj
    case 'pattern_cosist'
         % evaluate consistency of measures (psc, beta, z-scores) across
        % sessions for finger mapping
        
        sn  = 1;
        reg = 1:8;
        betaChoice = 'uni'; % options: uni / multi / raw
        
        vararginoptions(varargin,{'sn','reg','betaChoice'});
        
        for  roi = reg;
            CS=[];  % separate per digit
            PS=[];  % across all digits
            for s = 1:numel(sn)
                for sessN = 1:4; % per session
                    C=[];P=[];
                    T = load(fullfile(regDir,sprintf('betas_sess%d.mat',sessN))); % loads region data (T)
                    
                    switch (betaChoice)
                        case 'uni'
                            beta = T.betaUW{T.SN==s&T.region==roi};
                        case 'multi'
                            beta = T.betaW{T.SN==s&T.region==roi};
                        case 'raw'
                            beta = T.betaRAW{T.SN==s&T.region==roi};
                    end
                    
                    
                    runs=1:numruns_task_sess;
                    conditionVec = kron(ones(numel(runs),1),[1:12]');
                    
                    split_run=1:4;  
                    splitRunVec = kron(ones(numel(split_run),1),[ones(12,1); ones(12,1).*2]); % split even and odd runs
                    
                    %C.beta=beta{roi};
                    for d = 1:12 %all sequences
                        C.beta_seq(d,:)=mean(beta(conditionVec==idx(d),:),1);  % beta values for each digit (avrg across blocks)
                    end
                    
                    %C.zscore_seq = bsxfun(@rdivide,C.beta_seq,sqrt(T.resMS{roi}));
                    
                    C.seq_ind=[1:6]';
                    C.sessN=ones(6,1)*sessN;
                    C.roi=ones(6,1)*roi;
                    
                    P.beta_mean=mean(C.beta_seq,1);   % mean pattern acros digit in each session
                    P.zscore_mean=mean(C.zscore_seq,1);
                    %P.zscore_mean=bsxfun(@rdivide,P.beta_mean,sqrt(T.resMS{roi}));
                    P.sessN=sessN;
                    P.roi=roi;
                    
                    CS=addstruct(CS,C);
                    PS=addstruct(PS,P);
                end
                
                ind = indicatorMatrix('allpairs',([1:4]));  % betwSess indicator
                for n=1:numel(unique(CS.seq_ind))
                    T = getrow(CS,CS.seq_ind==n);
                    for i=1:size(ind,1)
                        [i1 i2] = find(ind(i,:)~=0);
                        if rm == 1
                            AcrSess_b(i)=corr(T.beta_seq(i1(2),:)',T.beta_seq(i2(2),:)');
                            AcrSess_z(i)=corr(T.zscore_seq(i1(2),:)',T.zscore_seq(i2(2),:)');
                            AcrSess_p(i)=corr(T.psc_seq(i1(2),:)',T.psc_seq(i2(2),:)');
                        elseif rm == 0
                            AcrSess_b(i)=corrN(T.beta_seq(i1(2),:)',T.beta_seq(i2(2),:)');
                            AcrSess_z(i)=corrN(T.zscore_seq(i1(2),:)',T.zscore_seq(i2(2),:)');
                            AcrSess_z(i)=corrN(T.psc_seq(i1(2),:)',T.psc_seq(i2(2),:)');
                        end
                    end
                    AcrSess_beta(n)=mean(AcrSess_b);
                    AcrSess_zscore(n)=mean(AcrSess_z);
                    AcrSess_psc(n)=mean(AcrSess_p);
                end
            end
            Consist.beta_corr(roi,:) = AcrSess_beta;
            Consist.zscore_corr(roi,:) = AcrSess_zscore;
            Consist.psc_corr(roi,:) = AcrSess_psc;
            Consist.beta_RSA(roi,1) = rsa_patternConsistency(CS.beta_seq,CS.sessN,CS.seq_ind,'removeMean',rm);
            Consist.zscore_RSA(roi,1) = rsa_patternConsistency(CS.zscore_seq,CS.sessN,CS.seq_ind,'removeMean',rm);
            Consist.psc_RSA(roi,1) = rsa_patternConsistency(CS.psc_seq,CS.sessN,CS.seq_ind,'removeMean',rm);
            Consist.roi(roi,1) = roi;
            
        end
       
        
        keyboard;  
    case 'pattern_reliability'
        % Splits data for each session into two partitions (even and odd runs).
        % Calculates correlation coefficients between each condition pair 
        % between all partitions.
        % Default setup includes subtraction of each partition's mean
        % activity pattern (across conditions).
        % Conducts ttest comparing correlations within-conditions (within
        % subject) to those between-conditions (across subject). If stable,
        % within-condition corrs should be significantly larger than those
        % between.
        % Finally, plots within-condition correlations. Shaded region
        % reflects stderr across subjects.
        reg = [1:8]; 
        sn  = [1:5];
        figsess = 0;
        sessN = [1:4];
        subtract_mean = 1; % subtract
        partitions = [1:2:numruns_task_sess; 2:2:numruns_task_sess];
        numRuns    = 1:numruns_task_sess;
        numConds   = num_seq;
        conds   = repmat([numConds],1,length(numRuns));
        runNums = kron([numRuns],ones(1,length(numConds)));
        % Correlate patterns across even-odd run splits within subjects.

        vararginoptions(varargin,{'roi','figsess','sn','subtract_mean','sessN'});
        
        C=[];
        for ss = sessN
            D   = load(fullfile(regDir,sprintf('betas_sess%d.mat',ss)));
            splitcorrs = [];
            for roi = reg;
                T   = getrow(D,D.region==reg(roi));

                sindx      = 0;
                
                for s = sn % for each subject
                    t = getrow(T,T.SN==s);
                    sindx = sindx + 1; %per subject
                    
                    prepBetas = [];
                    tbetaUW{1} = [];
                    
                    if subtract_mean
                        for r=numRuns
                            tbetaUW{1}(runNums==r,:) = bsxfun(@minus,t.betaUW{1}(runNums==r,:),mean(t.betaUW{1}(runNums==r,:)));
                        end
                    else
                        tbetaUW{1}=t.betaUW{1};
                    end
                    % prep betas (harvest and subtract partition mean)
                    for i = 1:size(partitions,1)
                        partitionIdx = logical(ismember(runNums,partitions(i,:)))';
                        condIdx{i}   = conds(partitionIdx);
                         prepBetas{i} = tbetaUW{1}(partitionIdx,:);
                    end
                    
                    % correlate patterns across partitions, both within and across
                    % conditions
                    for c1 = numConds % for each condition
                        % condition mean activity pattern for this run partition
                        oddCon   = condIdx{1}==c1;
                        oddBetas = mean(prepBetas{1}(oddCon,:));
                        % condition mean activity pattern for the other run partition
                        evenCon   = condIdx{2}==c1;
                        evenBetas = mean(prepBetas{2}(evenCon,:));
                        % correlate condition patterns across partitions
                        tmp = corrcoef(evenBetas,oddBetas);
                        splitcorrs{roi}(sindx,c1) = tmp(1,2);
                    end
                    
                    Corr.sn = s;
                    Corr.reg = roi;
                    Corr.witSess = splitcorrs{roi}(s,:);
                    Corr.sessN = ss;
                    
                    C = addstruct(C,Corr);
                    
                end
                
                trained_corr{roi} = splitcorrs{roi}(:,[1:6]);
                untrained_corr{roi} = splitcorrs{roi}(:,[7:12]);
                % ttest within reliability for trained and untrained
                [h,p]=ttest2(trained_corr{roi}(:),untrained_corr{roi}(:));
               % fprintf('The average correlation for trained sequences is %d. \n',mean(mean(trained_corr{roi})));
               % fprintf('The average correlation for untrained sequences is %d. \n',mean(mean(untrained_corr{roi})));
               % fprintf('T-test for train vs untrain for session %d and region %s is %d with %d probability. \n \n',ss,regname{roi},h,p);
                
                % plot within-condition correlations (error across subjects)
                if figsess == 1
                    figure('Color',[1 1 1]);
                    traceplot(numConds,splitcorrs{roi},'errorfcn','stderr');
                    ylabel('correlation (corrcoef) of partition avg. patterns');
                    xlabel('sequence number');
                    ylim([0 1]);
                    xlim([0.5 max(numConds)+0.5]);
                end
            end
        end
        
        C.train = mean(C.witSess(:,[1:6]),2);
        C.untrain = mean(C.witSess(:,[7:12]),2);
        
        figure
        barplot(C.sessN, [C.train C.untrain],'leg',{'train','untrain'});
        
        figure
        for i=1:numel(sn)
            subplot(1,numel(sn),i)
             barplot(C.sessN, [C.train C.untrain],'leg',{'train','untrain'},'subset',C.sn==i);
        end
        
        figure
        for i=1:numel(reg)
            subplot(2,4,i)
            barplot(C.sessN,[C.train C.untrain],'leg',{'train','untrain'},'subset',C.reg==i);
            title(sprintf('%s',regname{i}));
            if i==1 | i==5
                ylabel('Correlation');
            else
                ylabel('');
            end
        end
        
        keyboard;
    case 'pattern_reliability_acrossSess'
        
        reg = [1:8]; 
        sn  = [1:5];
        fig = 1;
        sessN = 1;
        sess_combination = 'sequential'; % of 'altogether'
        subtract_mean = 1; % subtract
        partitions = [1:2:numruns_task_sess; 2:2:numruns_task_sess];
        numRuns    = 1:numruns_task_sess;
        numConds   = num_seq;
        conds   = repmat([numConds],1,length(numRuns));
        runNums = kron([numRuns],ones(1,length(numConds)));
        % Correlate patterns across even-odd run splits within subjects.

        vararginoptions(varargin,{'roi','fig','sn','subtract_mean','sessN','sess_combination'});
        
        switch(sess_combination)
            case 'altogether'
                ss_comb = [1 1 1 2 2 3; 2 3 4 3 4 4];
            case 'sequential'
                ss_comb = [1 2 3; 2 3 4];
        end
        C = [];
        for ss = 1:size(ss_comb,2)

            D1   = load(fullfile(regDir,sprintf('betas_sess%d.mat',ss_comb(1,ss))));
            D2   = load(fullfile(regDir,sprintf('betas_sess%d.mat',ss_comb(2,ss))));
            
            for roi = reg;
                T1   = getrow(D1,D1.region==reg(roi));
                T2   = getrow(D2,D2.region==reg(roi));
                sindx      = 0;
                
                for s = sn % for each subject
                    t1 = getrow(T1,T1.SN==s);
                    t2 = getrow(T2,T2.SN==s);
                    sindx = sindx + 1; %per subject
                    
                    prepBetas1 = [];
                    prepBetas2 = [];
                    t1betaUW{1}=[];
                    t2betaUW{1}=[];
                    
                    if subtract_mean
                        for r=numRuns
                            t1betaUW{1}(runNums==r,:) = bsxfun(@minus,t1.betaUW{1}(runNums==r,:),mean(t1.betaUW{1}(runNums==r,:)));
                            t2betaUW{1}(runNums==r,:) = bsxfun(@minus,t2.betaUW{1}(runNums==r,:),mean(t2.betaUW{1}(runNums==r,:)));
                        end
                        %    prepBetas1{i} = bsxfun(@minus,t1.betaUW{1}(partitionIdx,:),mean(t1.betaUW{1}(partitionIdx,:)));
                        %    prepBetas2{i} = bsxfun(@minus,t2.betaUW{1}(partitionIdx,:),mean(t2.betaUW{1}(partitionIdx,:)));
                    else
                        t1betaUW{1}=t1.betaUW{1};
                        t2betaUW{1}=t2.betaUW{1};
                        %    prepBetas1{i} = t1.betaUW{1}(partitionIdx,:);
                        %   prepBetas2{i} = t2.betaUW{1}(partitionIdx,:);
                    end
                    
                    % prep betas (harvest and subtract partition mean)
                    for i = 1:size(partitions,1)
                        partitionIdx = logical(ismember(runNums,partitions(i,:)))';
                        condIdx{i}   = conds(partitionIdx);

                        
                        prepBetas1{i} = t1betaUW{1}(partitionIdx,:);
                        prepBetas2{i} = t2betaUW{1}(partitionIdx,:);
                      
                    end
                    
                    oddBetas1=[]; oddBetas2=[]; evenBetas1=[]; evenBetas2=[];
                    % correlate patterns within / across sessions
                    for c1 = numConds % for each condition
                        % condition mean activity pattern for this run partition
                        oddCon   = condIdx{1}==c1;
                        oddBetas1(c1,:) = mean(prepBetas1{1}(oddCon,:));
                        oddBetas2(c1,:) = mean(prepBetas2{1}(oddCon,:));
                        % condition mean activity pattern for the other run partition
                        evenCon   = condIdx{2}==c1;
                        evenBetas1(c1,:) = mean(prepBetas1{2}(evenCon,:));
                        evenBetas2(c1,:) = mean(prepBetas2{2}(evenCon,:));
                        
                    end
                    
%                     if subtract_mean
%                             oddBetas1 = bsxfun(@minus,oddBetas1,mean(oddBetas1));
%                             oddBetas2 = bsxfun(@minus,oddBetas2,mean(oddBetas2));
%                             evenBetas1 = bsxfun(@minus,evenBetas1,mean(evenBetas1));
%                             evenBetas2 = bsxfun(@minus,evenBetas2,mean(evenBetas2));
%                     end
                    
                    for c1 = numConds
                        % correlate condition patterns within both sessions
                        % their geometric product is the ceiling for
                        % patterns across sessions
                        tmpW1 = corrcoef(evenBetas1(c1,:),oddBetas1(c1,:));
                        tmpW2 = corrcoef(evenBetas2(c1,:),oddBetas2(c1,:));
                        ceilingWitSess(c1) = ssqrt(tmpW1(1,2)*tmpW2(1,2));

                        % correlate condition patterns across sessions
                        tmpAc1 = corrcoef(evenBetas1(c1,:),oddBetas2(c1,:));
                        tmpAc2 = corrcoef(oddBetas1(c1,:),evenBetas2(c1,:));
                        tmpAc3 = corrcoef(oddBetas1(c1,:),oddBetas2(c1,:));
                        tmpAc4 = corrcoef(evenBetas1(c1,:),evenBetas2(c1,:));
                        corrAcrSess(c1) = mean([tmpAc1(1,2),tmpAc2(1,2),tmpAc3(1,2),tmpAc4(1,2)]);
                    end
                    
                    Corr.sn = s;
                    Corr.reg = roi;
                    Corr.witSess = ceilingWitSess;
                    Corr.acrSess = corrAcrSess;
                    if sess_combination == 'sequential' 
                        Corr.sess_comb = ss;
                    end
                    C = addstruct(C,Corr);
                end
 
            end
        end; % ss_comb
        
        C.trainWit = mean(C.witSess(:,[1:6]),2);
        C.untrainWit = mean(C.witSess(:,[7:12]),2);
        C.trainAcr = mean(C.acrSess(:,[1:6]),2);
        C.untrainAcr = mean(C.acrSess(:,[7:12]),2);
        
        figure;
        if sess_combination == 'altogether'
            barplot(C.reg,[C.trainWit C.untrainWit C.trainAcr C.untrainAcr],'leg',{'Train within','Untain within','Train across','Untrain across'});
        else
            for i = 1:size(ss_comb,2)
                subplot(1,size(ss_comb,2),i)
                barplot(C.reg,[C.trainWit C.untrainWit C.trainAcr C.untrainAcr],'leg',{'Train within','Untain within','Train across','Untrain across'},'subset',C.sess_comb==i);
            end
            figure;
            barplot(C.sess_comb,[C.trainWit C.untrainWit C.trainAcr C.untrainAcr],'leg',{'Train within','Untain within','Train across','Untrain across'});
            
        end
        
        figure
        for i=1:numel(reg)
            subplot(2,4,i)
            barplot(C.sess_comb,[C.trainAcr C.untrainAcr],'leg',{'train','untrain'},'subset',C.reg==i & C.sn==4);
            title(sprintf('%s',regname{i}));
            if i==1 | i==5
                ylabel('Correlation');
            else
                ylabel('');
            end
        end
        
            keyboard;   
    case 'simulate_reliability'
        
        D1   = load(fullfile(regDir,sprintf('betas_sess%d.mat',1)));
        
        T1   = getrow(D1,D1.region==1);
        t1 = getrow(T1,T1.SN==1);
        prepBetas = [];
        noiseLevel = 0.3;   % 10%
        % prep true pattern
        
        X = bsxfun(@minus,t1.betaUW{1}(1:12,:),mean(t1.betaUW{1}(1:12,:)));
        
        err = mvnrnd(zeros(size(X,2),size(X,1)),ones(size(X,1),size(X,1)).*noiseLevel)';
        
        evenBetas1 = X + mvnrnd(zeros(size(X,2),size(X,1)),ones(size(X,1),size(X,1)).*noiseLevel)';
        oddBetas1 = X + mvnrnd(zeros(size(X,2),size(X,1)),ones(size(X,1),size(X,1)).*noiseLevel)';
        evenBetas2 = X + mvnrnd(zeros(size(X,2),size(X,1)),ones(size(X,1),size(X,1)).*noiseLevel)';
        oddBetas2 = X + mvnrnd(zeros(size(X,2),size(X,1)),ones(size(X,1),size(X,1)).*noiseLevel)';
        
        
        % within session
        tmpW1 = corrcoef(evenBetas1,oddBetas1);
        tmpW2 = corrcoef(evenBetas2,oddBetas2);
        ceilingWitSess = ssqrt(tmpW1(1,2)*tmpW2(1,2));
        
        % correlate condition patterns across sessions
        tmpAc1 = corrcoef(evenBetas1,oddBetas2);
        tmpAc2 = corrcoef(oddBetas1,evenBetas2);
        tmpAc3 = corrcoef(oddBetas1,oddBetas2);
        tmpAc4 = corrcoef(evenBetas1,evenBetas2);
        corrAcrSess = mean([tmpAc1(1,2),tmpAc2(1,2),tmpAc3(1,2),tmpAc4(1,2)]);
        
        keyboard;
    case 'ROI_dimensionality'
        % estimating the dimensionality of patterns 
        % cumulative sum of eig of G
        sn=1;
        reg=3;
        sessN=4;
        betaChoice = 'multiPW';
        vararginoptions(varargin,{'sn','reg','sessN','betaChoice'});
        for s = 1:sessN;    % sessions
            To = load(fullfile(regDir,sprintf('stats_%s_sess%d.mat',betaChoice,s)));
            T = getrow(To,To.region==reg & To.SN==sn);
            eigTrain = T.eigTrain(1:5);
            eigUntrain = T.eigUntrain(1:5);
            eigTrain_sum = cumsum(eigTrain);
            eigUntrain_sum = cumsum(eigUntrain);
            
            figure(2)
            subplot(2,4,s)
            title(sprintf('Session %d',s));
            hold on;
            plot(eigTrain_sum,'-o','Color','b');
            legend('trained','Location','northwest');
            subplot(2,4,4+s)
            plot(eigUntrain_sum,'-o','Color','r');
            legend('untrained','Location','northwest');
        end
    case 'ROI_dim_LOC'
        % estimating the dimensionality of patterns 
        % cumulative sum of eig of G
        sn=1;
        reg=2;
        betaChoice='multiPW';
        vararginoptions(varargin,{'sn','reg','betaChoice'});
        for s = 1:4;    % all sessions
            To = load(fullfile(regDir,sprintf('stats_LOC_%s_sess%d.mat',betaChoice,s)));
            T = getrow(To,To.region==reg & To.SN==sn);
            eig_fing = T.eig;
            eigfing_sum = cumsum(eig_fing);
             
            figure(1)
            subplot(2,2,s)
            title(sprintf('Session %d',s));
            plot(eigfing_sum,'-o','Color','b');
            legend('finger');
        end
    case 'ROI_act_dist'
        
        sn = [1:5];
        roi = [1:8];
        sessN = 1:4;
        seq = 'trained';
        betaChoice = 'multiPW';
        fig = 0;
        vararginoptions(varargin,{'sn','roi','seq','sessN','betaChoice','fig'});

        Stats = [];
        
        for ss = sessN % do per session number
            D = load(fullfile(regDir,sprintf('stats_%s_sess%d.mat',betaChoice,ss))); % loads region data (D)
            T = load(fullfile(regDir,sprintf('betas_sess%d.mat',ss))); % loads region data (T)
            
            switch (betaChoice)
                case 'uniPW'
                    beta = T.betaUW;
                case 'multiPW'
                    beta = T.betaW;
                case 'raw'
                    beta = T.betaRAW;
            end
            
            runs=1:numruns_task_sess;
            conditionVec = kron(ones(numel(runs),1),[1:12]');
            
            
            indx_train = 1:6;
            indx_untrain = 7:12;

            
            for s=1:numel(sn)
                for r=roi
                    
                    clear C;
                    for d = 1:6 %sequences
                        C.beta_seq_train(d,:)=mean(beta{T.SN==s & T.region==r}(conditionVec==indx_train(d),:),1);  % beta values for each digit (avrg across blocks)
                        C.beta_seq_untrain(d,:)=mean(beta{T.SN==s & T.region==r}(conditionVec==indx_untrain(d),:),1);
                        %C.psc_seq(d,:)=mean(beta{T.SN==s & T.region==r}(conditionVec==seq_indx(d),:),1)./mean(beta{T.SN==s & T.region==r}(end-7:end,:),1).*100;
                    end
                                   
                    AllDist = ssqrt(rsa_squareRDM(D.RDM(D.region==r & D.SN==sn(s),:)));
                    SeqTrain = triu(AllDist(indx_train,indx_train));
                    SeqUntrain = triu(AllDist(indx_untrain,indx_untrain));
                    SeqCross = triu(AllDist(indx_train,indx_untrain));
                    SeqTrainAll = SeqTrain(SeqTrain~=0);
                    SeqUntrainAll = SeqUntrain(SeqUntrain~=0);
                    SeqCrossAll = SeqCross(SeqCross~=0);
                    
                    switch (fig)
                        case 1
                            figure(r)
                            subplot(1,max(sessN),ss)
                            imagesc(AllDist);
                            drawline(6.5,'dir','vert');
                            drawline(6.5,'dir','horz');
                            colorbar; caxis([-0.02 0.04]);
                            if ss == 4; set(gcf,'PaperPosition',[2 2 20 4],'Color',[1 1 1]); wysiwyg; end;
                            title(sprintf('Subject %d session %d region %s',s,ss,regname{r}));
                    end
                    
                    S.sn=s;
                    S.roi=r;
                    S.dist_train=mean(SeqTrainAll); 
                    S.dist_untrain=mean(SeqUntrainAll);
                    S.dist_cross=mean(SeqCrossAll);
                    S.beta_train=mean(mean(C.beta_seq_train));
                    S.beta_untrain=mean(mean(C.beta_seq_untrain));
                    S.sessN=ss;
                    Stats=addstruct(Stats,S);
                end
            end
        end
        Stats.sessIndx = [ones(120,1); ones(40,1)*2];
        
        a = [Stats.sessIndx; Stats.sessIndx];
        b = [Stats.sessN; Stats.sessN];
        
        keyboard;
        figure
        for f = 1:numel(roi)
            subplot(1,numel(roi),f);
            lineplot([a b],[Stats.dist_untrain;Stats.dist_train],'split',[ones(length(Stats.sessN),1);ones(length(Stats.sessN),1)*2],'style_thickline','subset',[Stats.roi;Stats.roi]==f,'leg',{'untrained','trained'});
            ylim([0 0.07])
            if f==1
                ylabel('Distances')
            else
                ylabel('')
            end
            title(sprintf('%s',regname{f}))
        end
        
        figure
        for f = 1:numel(roi)
            subplot(1,numel(roi),f);
            lineplot([Stats.sessIndx Stats.sessN],Stats.dist_cross,'style_thickline','subset',Stats.roi==f);
            ylim([0 0.07])
            if f==1
                ylabel('Distance between sequence sets')
            else
                ylabel('')
            end
            title(sprintf('%s',regname{f}))
        end
        
        figure
        for f = 1:numel(roi)
            subplot(1,numel(roi),f);
            lineplot([a b],[Stats.beta_untrain;Stats.beta_train],'split',[ones(length(Stats.sessN),1);ones(length(Stats.sessN),1)*2],'style_thickline','subset',[Stats.roi;Stats.roi]==f,'leg',{'untrained','trained'});
            ylim([0 0.07])
            if f==1
                ylabel('Betas')
            else
                ylabel('')
            end
            title(sprintf('%s',regname{f}))
        end
        
        keyboard;
       
        figure;
        subplot(1,3,1)
        lineplot(Stats.sessN,Stats.dist_train,'split',Stats.roi,'style_thickline','subset',Stats.roi~=6,'leg',regname([1:5,7,8])); hold on;
        drawline(0,'dir','horz');
        title('Distance trained');
        
        subplot(1,3,2)
        lineplot(Stats.sessN,Stats.dist_untrain,'split',Stats.roi,'style_thickline','subset',Stats.roi~=6,'leg',regname([1:5,7,8])); hold on;
        drawline(0,'dir','horz');
        title('Distance untrained');
        
        subplot(1,3,3)
        lineplot(Stats.sessN,Stats.dist_cross,'split',Stats.roi,'style_thickline','subset',Stats.roi~=6,'leg',regname([1:5,7,8])); hold on;
        drawline(0,'dir','horz');
        title('Distance cross-seq');
        
        figure;
        subplot(1,2,1)
        lineplot(Stats.sessN,Stats.beta_train,'split',Stats.roi,'style_thickline','subset',Stats.roi~=6,'leg',regname([1:5,7,8])); hold on;
        drawline(0,'dir','horz');
        title('Betas trained');
        
        subplot(1,2,2)
        lineplot(Stats.sessN,Stats.beta_untrain,'split',Stats.roi,'style_thickline','subset',Stats.roi~=6,'leg',regname([1:5,7,8])); hold on;
        drawline(0,'dir','horz');
        title('Betas untrained');
        
       % [Stats.dist_train Stats.dist_untrain Stats.dist_cross]
        keyboard;      
    case 'ROI_act_dist_FoSEx'
        
        sn = [1:5];
        roi = [1:8];
        sessN = 1:4;
        seq = 'trained';
        betaChoice = 'multiPW';
        subjfig = 0;
        regfig = 0;
        vararginoptions(varargin,{'sn','roi','seq','sessN','betaChoice','fig'});

        Stats = [];
        
        for ss = sessN % do per session number
            D = load(fullfile(regDir,sprintf('stats_FoSEx_%s_sess%d.mat',betaChoice,ss))); % loads region data (D)
            T = load(fullfile(regDir,sprintf('betas_FoSEx_sess%d.mat',ss))); % loads region data (T)
            
            runs=1:numruns_task_sess;
            conditionVec = kron(ones(numel(runs),1),[1:12]');
            
            
            indx_train = 1:6;
            indx_untrain = 7:12;

            
            for s=1:length(sn)
                SI = load(fullfile(glmFoSExDir{ss}, subj_name{sn(s)}, 'SPM_info.mat'));   % load subject's trial structure
                for r=roi
                    for exe=1:2;    % FoSEx
                       D_exe = getrow(D,D.FoSEx==exe); 
                        switch (betaChoice)
                            case 'uniPW'
                                beta = T.betaUW{T.SN==sn(s) & T.region==r}(SI.FoSEx==exe,:);
                            case 'multiPW'
                                beta = T.betaW{T.SN==sn(s) & T.region==r}(SI.FoSEx==exe,:);
                            case 'raw'
                                beta = T.betaRAW{T.SN==sn(s) & T.region==r}(SI.FoSEx==exe,:);
                        end
                        
                        clear C;
                        for d = 1:6 %sequences
                            C.beta_seq_train(d,:)=mean(beta(conditionVec==indx_train(d),:),1);  % beta values for each digit (avrg across blocks)
                            C.beta_seq_untrain(d,:)=mean(beta(conditionVec==indx_untrain(d),:),1);
                        end
                        
                        AllDist = ssqrt(rsa_squareRDM(D_exe.RDM(D_exe.region==r & D_exe.SN==sn(s),:)));
                        SeqTrain = triu(AllDist(indx_train,indx_train));
                        SeqUntrain = triu(AllDist(indx_untrain,indx_untrain));
                        SeqCross = triu(AllDist(indx_train,indx_untrain));
                        SeqTrainAll = SeqTrain(SeqTrain~=0);
                        SeqUntrainAll = SeqUntrain(SeqUntrain~=0);
                        SeqCrossAll = SeqCross(SeqCross~=0);
                        
                        switch (subjfig)
                            case 1
                                figure(r)
                                subplot(2,max(sessN),(exe-1)*max(sessN)+ss)
                                imagesc(AllDist);
                                drawline(6.5,'dir','vert');
                                drawline(6.5,'dir','horz');
                                colorbar; caxis([-0.02 0.04]);
                                if ss == 4; set(gcf,'PaperPosition',[2 2 20 8],'Color',[1 1 1]); wysiwyg; end;
                                title(sprintf('Subject %d session %d region %s exe %d',sn(s),ss,regname{r},exe));
                        end
                        
                        S.sn=s;
                        S.roi=r;
                        S.dist_train=mean(SeqTrainAll);
                        S.dist_untrain=mean(SeqUntrainAll);
                        S.dist_cross=mean(SeqCrossAll);
                        S.beta_train=mean(mean(C.beta_seq_train));
                        S.beta_untrain=mean(mean(C.beta_seq_untrain));
                        S.sessN=ss;
                        S.FoSEx=exe;
                        if S.sessN<4
                            S.speed=1;
                        else
                            S.speed=2;
                        end
                        Stats=addstruct(Stats,S);
                    end; % FoSEx
                end; % roi
            end; % sn
        end
        
        switch(regfig)
            case 1
                figure
                subplot(3,1,1)
                lineplot([Stats.speed Stats.sessN],Stats.dist_train,'split',Stats.FoSEx,'style_thickline','leg',{'1st','2nd'}); title('trained dist');
                subplot(3,1,2)
                lineplot([Stats.speed Stats.sessN],Stats.dist_untrain,'split',Stats.FoSEx,'style_thickline','leg',{'1st','2nd'}); title('untrained dist');
                subplot(3,1,3)
                lineplot([Stats.speed Stats.sessN],Stats.dist_cross,'split',Stats.FoSEx,'style_thickline','leg',{'1st','2nd'}); title('cross dist');
                
                figure
                subplot(2,1,1)
                lineplot([Stats.speed Stats.sessN],Stats.beta_train,'split',Stats.FoSEx,'style_thickline','leg',{'1st','2nd'}); title('trained betas');
                subplot(2,1,2)
                lineplot([Stats.speed Stats.sessN],Stats.beta_untrain,'split',Stats.FoSEx,'style_thickline','leg',{'1st','2nd'}); title('untrained betas');
        end
       % [Stats.dist_train Stats.dist_untrain Stats.dist_cross]
       
       col_sess = {'r','b','g','k'};
       mark_seq = {'o','*'};
       
       for r=1:numel(roi)
           figure
           title(sprintf('Beta values in %s', regname{r})); xlabel('2nd execution'); ylabel('1st execution');
           gc1 = gca; hold on;
           
        %   figure
         %  title(sprintf('Distance in %s',regname{r})); xlabel('2nd execution'); ylabel('1st execution');
          % gc2 = gca; hold on;
           for ss=1:length(sessN)
               for seq=1:2   % trained / untrained
                   if seq == 1
                       dist = Stats.dist_train;
                       beta = Stats.beta_train;
                   elseif seq == 2
                       dist = Stats.dist_untrain;
                       beta = Stats.beta_untrain;
                   end
                   
                   plot(gc1,S(Stats.FoSEx==2 & Stats.sessN==ss & Stats.roi==roi(r)),beta(Stats.FoSEx==1 & Stats.sessN==ss & Stats.roi==roi(r)),mark_seq{seq},'Color',col_sess{ss},'linewidth',2); hold on; axis equal; hold on; grid on;
                   hold on; plot([0:0.01:0.07],[0:0.01:0.07],'--');
                  % plot(gc2,dist(Stats.FoSEx==2 & Stats.sessN==ss & Stats.roi==roi(r)),dist(Stats.FoSEx==1 & Stats.sessN==ss & Stats.roi==roi(r)),mark_seq{seq},'Color',col_sess{ss},'linewidth',2); hold on; axis equal; hold on; grid on;
               end
           end; % session

           legend(gc1,'Sess1-train','Sess1-untrain','Sess2-train','Sess2-untrain','Sess3-train','Sess3-untrain','Sess4-train','Sess4-untrain','Location','SouthEast');
           %legend(gc2,'Sess1-train','Sess1-untrain','Sess2-train','Sess2-untrain','Sess3-train','Sess3-untrain','Sess4-train','Sess4-untrain','Location','SouthEast');
       end; % for each roi
       
       keyboard;
       figure
       for f = 1:numel(roi)
           subplot(1,numel(roi),f);
           lineplot([Stats.speed Stats.sessN],Stats.dist_train,'split',Stats.FoSEx,'subset',Stats.roi==f,'style_thickline','leg',{'1st','2nd'});
           ylim([0 0.07])
           if f==1
               ylabel('Distances trained')
           else
               ylabel('')
           end
           title(sprintf('%s',regname{f}))
       end
      
       figure
       for f = 1:numel(roi)
           subplot(1,numel(roi),f);
           lineplot([Stats.speed Stats.sessN],Stats.dist_untrain,'split',Stats.FoSEx,'subset',Stats.roi==f,'style_thickline','leg',{'1st','2nd'});
           ylim([0 0.07])
           if f==1
               ylabel('Distances untrained')
           else
               ylabel('')
           end
           title(sprintf('%s',regname{f}))
       end
       
       figure
       for f = 1:numel(roi)
           subplot(1,numel(roi),f);
           lineplot([Stats.speed Stats.sessN],Stats.dist_cross,'split',Stats.FoSEx,'subset',Stats.roi==f,'style_thickline','leg',{'1st','2nd'});
           ylim([0 0.07])
           if f==1
               ylabel('Distance between seq sets')
           else
               ylabel('')
           end
           title(sprintf('%s',regname{f}))
       end
       
       figure
       for f = 1:numel(roi)
           subplot(1,numel(roi),f);
           lineplot([Stats.speed Stats.sessN],Stats.beta_train,'split',Stats.FoSEx,'subset',Stats.roi==f,'style_thickline','leg',{'1st','2nd'});
           ylim([0 0.07])
           if f==1
               ylabel('Betas trained')
           else
               ylabel('')
           end
           title(sprintf('%s',regname{f}))
       end
       
       figure
       for f = 1:numel(roi)
           subplot(1,numel(roi),f);
           lineplot([Stats.speed Stats.sessN],Stats.beta_untrain,'split',Stats.FoSEx,'subset',Stats.roi==f,'style_thickline','leg',{'1st','2nd'});
           ylim([0 0.07])
           if f==1
               ylabel('Betas untrained')
           else
               ylabel('')
           end
           title(sprintf('%s',regname{f}))
       end
       
       keyboard;
    
    case 'SURF_dist'
        % number of vertices above a certain threshold
        vararginoptions(varargin,{'sn'});
        thres = 0.001;
        T=[];
        for s=sn;
            for ss = 1:sess_sn(s)
                for hem = 1:2
                    
                    caretSubjDir = fullfile(caretDir,sprintf('x%s',subj_name{s}),hemName{hem});
                    cd(caretSubjDir);
                    surf=caret_load(sprintf('%s_sess%d_dist.metric',subj_name{s},ss));
                    C = caret_load(fullfile(caretDir,'fsaverage_sym',hemName{h},['ROI.paint']));
                    dist_train=surf.data(:,2);
                    dist_untrain=surf.data(:,3);
                    A.hem(1:2,:)=hem;
                    A.sn(1:2,:)=s;
                    A.sessN(1:2,:)=ss;
                    A.vert(1,:)=sum(dist_train>thres);
                    A.vert(2,:)=sum(dist_untrain>thres);
                    A.dist_pattern(1,:)=dist_train';
                    A.dist_pattern(2,:)=dist_untrain';
                    A.seqType=[1,2]';
                    T=addstruct(T,A);
                end
            end
            
            B_train=getrow(T,T.sn==s & T.hem==1 & T.seqType==1);
            B_untrain=getrow(T,T.sn==s & T.hem==1 & T.seqType==2);
            for ss1=1:4
                for ss2=1:4
                    Corr_train(ss1,ss2)=corr(B_train.dist_pattern(ss1,:)',B_train.dist_pattern(ss2,:)','rows','pairwise');
                    Corr_untrain(ss1,ss2)=corr(B_untrain.dist_pattern(ss1,:)',B_untrain.dist_pattern(ss2,:)','rows','pairwise');
                end
            end
            Corr.all((s-1)*6+1,:)=Corr_train(1,2); % sess1-2
            Corr.all((s-1)*6+2,:)=Corr_train(2,3); % sess2-3
            Corr.all((s-1)*6+3,:)=Corr_train(3,4); % sess3-4
            Corr.all((s-1)*6+4,:)=Corr_untrain(1,2);
            Corr.all((s-1)*6+5,:)=Corr_untrain(2,3);
            Corr.all((s-1)*6+6,:)=Corr_untrain(3,4);
            Corr.sess([(s-1)*6+1,(s-1)*6+4],:)=1;
            Corr.sess([(s-1)*6+2,(s-1)*6+5],:)=2;
            Corr.sess([(s-1)*6+3,(s-1)*6+6],:)=3;
            Corr.indx((s-1)*6+1:(s-1)*6+3,:)=1; %train
            Corr.indx((s-1)*6+4:(s-1)*6+6,:)=2; %untrain
            Corr.sn((s-1)*6+1:(s-1)*6+6,:)=s; %sn
        end
        keyboard;
        figure;
        lineplot(T.sessN,T.vert,'split',T.seqType,'subset',T.hem==1,'style_thickline','leg',{'train','untrain'});
        title('All subjects')
        
        figure;
        for s=1:numel(sn)
            subplot(1,numel(sn),s)
            lineplot(T.sessN,T.vert,'split',T.seqType,'subset',T.hem==1 & T.sn==s,'style_thickline','leg',{'train','untrain'});
            title(sprintf('subject %d',s));
        end
        
        figure;
        for s=1:numel(sn)
            subplot(1,numel(sn),s)
            barplot(Corr.sess,Corr.all,'split',Corr.indx,'subset',Corr.sn==s,'leg',{'train','untrain'});
            title(sprintf('subject %d',s));
        end
        
    case 'PLOT_FingDist'
        sessN=1;    % per session
        vararginoptions(varargin,{'sessN'});
        
        Ts = load(fullfile(regDir,sprintf('sess%d_LOC_reg_statsAllSeq.mat',sessN))); % loads region data (Ts)
        for j = 1:2 % S1/M1
            for i = 1:max(Ts.SN)
                AllDist = rsa_squareRDM(Ts.RDM(Ts.region==j & Ts.SN==i,:));
                Digit = triu(AllDist);
                DigitStr = Digit(Digit~=0);
                
                figure(1)
                hold on
                subplot(max(Ts.SN),1,i)
                plot(ssqrt(DigitStr),'linewidth',2)
                
                DigitStrNorm = DigitStr./mean(DigitStr);
                
                figure(2)
                hold on
                subplot(max(Ts.SN),1,i)
                plot(ssqrt(DigitStrNorm),'linewidth',2)
                
                if j==2
                    figure(1)
                    legend('S1','M1');
                    figure(2)
                    legend('S1','M1');                  
                end
                
                figure(3)
                subplot(2,1,j)
                imagesc(AllDist);
                title(sprintf('RDM %s',regname{j}));
                
            end
        end
    case 'PLOT_SeqDist'
        
        roi = [3,5]; % PMd, PMv, SMA, SPLa, SPLp
        sn = 1;
        seq = 'new';
        sessN=1;
        vararginoptions(varargin,{'sn','roi','seq','sessN'});
        
        Ts = load(fullfile(regDir,sprintf('sess%d_reg_statsAllSeq.mat',sessN))); % loads region data (Ts)

        switch(seq)
            case 'learnt'
                seq_indx = [1:6];
            case 'new'
                seq_indx = [7:12];
        end
        
        for r=roi
            for s=sn
                AllDist = rsa_squareRDM(Ts.RDM(Ts.region==r & Ts.SN==s,:));
                Seq = AllDist(seq_indx,seq_indx);
                
                figure(r);
                %subplot(max(sn),1,s);
                imagesc(Seq);     
            end
        end
      %  keyboard;
    case 'CALC_SeqDist'
        
        roi = [1:5]; % S1, M1, PMd, PMv, SMA, V12, SPLa, SPLp
        sn = 1;
        seq = 'trained';
        plotRDM = 1;
        sessN = 1:2;
        vararginoptions(varargin,{'sn','roi','seq','plotRDM','sessN'});
        
        for ss = sessN % do per session number
        Ts = load(fullfile(regDir,sprintf('sess%d_reg_statsAllSeq.mat',ss))); % loads region data (T)
        
        switch(seq)
            case 'trained'
                seq_indx = [1:6];
            case 'untrained'
                seq_indx = [7:12];
        end
        
        for r=roi
            for s=1:numel(sn)
                AllDist = rsa_squareRDM(Ts.RDM(Ts.region==r & Ts.SN==sn(s),:));
                
                Seq = triu(AllDist(seq_indx,seq_indx));
                SeqAll = Seq(Seq~=0);
                
                Dist(s,r)=mean(ssqrt(SeqAll));  
                
                switch(plotRDM)
                    case 1
                        figure(r)
                        subplot(2,2,s);
                        imagesc(AllDist(seq_indx,seq_indx));
                        title(regname{r});

                    case 0
                end
            end
        end 
        end
        figure;
        myboxplot([],Dist);
        keyboard;
       
    case 'CALC_FingDist'                                                    % CALC average distance (trained, untrained seq), plot as RDM, boxplot
        
        roi = [1:14]; % S1, M1, PMd, PMv, SMA, SPLa, SPLp
        sn = [7:8];
        plotRDM = 1;
        glm = 2;
        vararginoptions(varargin,{'sn','roi','plotRDM','glm'});
        
        Ts = load(fullfile(regDir,sprintf('glm%d_reg_T_FingMap_NEWDESIGN.mat',glm))); % loads region data (T)
        
        
        for r=roi
            for s=1:numel(sn)
                AllDist = rsa_squareRDM(Ts.RDM(Ts.region==r & Ts.SN==sn(s),:));
                
                Seq = triu(AllDist);
                SeqAll = Seq(Seq~=0);
                
                Dist(s,r)=mean(ssqrt(SeqAll));  
                
                switch(plotRDM)
                    case 1
                        figure(r)
                        subplot(max(numel(sn)),1,s);
                        imagesc(AllDist);
                        title(regname{r});

                    case 0
                end
            end
        end 
        myboxplot([],Dist);
        keyboard;    
    case 'CALC_SeqPairDist'                                                 % CALC average distance (finger presses), plot as RDM, boxplot
        
        roi = [1:7]; % S1, M1, PMd, PMv, SMA, SPLa, SPLp
        sn = 1:5;
        seqpair = 'trained_untrained';
        plotRDM = 0;
        glm = 2;
        
        vararginoptions(varargin,{'sn','roi','seq','plotRDM','glm'});
        
        Ts = load(fullfile(regDir,sprintf('glm%d_reg_TallSeq.mat',glm))); % loads region data (T)

        switch(seqpair)
            case 'trained_untrained'
                seq_indx1 = [1:6];
                seq_indx2 = [7:10];
            case 'trained_otherhand'
                seq_indx1 = [1:6];
                seq_indx2 = [11:14];
        end
        
        for r=roi
            for s=sn
                AllDist = rsa_squareRDM(Ts.RDM(Ts.region==r & Ts.SN==s,:));
                
                SeqPair = AllDist(seq_indx1,seq_indx2);
                
                Dist(r,s)=mean(ssqrt(SeqPair(:)));  
                
                switch(plotRDM)
                    case 1
                        figure(r)
                        title(regname{r})
                        subplot(max(sn),1,s)
                        imagesc(AllDist(seq_indx1,seq_indx2));
                    case 0
                end
            end
        end 
        
        keyboard;
    case 'RDM_consistency'                                                  % DEPRECIATED
        roi = 1; 
        sn = 1;
        seq = 'finger';
        plotRDM = 0;
        glm = 2;
        vararginoptions(varargin,{'sn','roi','seq','plotRDM','glm'});
        
        T = load(fullfile(regDir,sprintf('glm%d_reg_betas.mat',glm))); % loads region data (T)
         for reg = roi
            for s = sn
                D = load(fullfile(glmDir{glm}, subj_name{s}, 'SPM_info.mat'));   % load subject's trial structure
                betas = T.betaUW{T.SN==s & T.region==reg};
            end
         end
        
    otherwise
        disp('there is no such case.')
end;    % switch(what)
end


%  % Local functions

function dircheck(dir)
% Checks existance of specified directory. Makes it if it does not exist.

if ~exist(dir,'dir');
    %warning('%s didn''t exist, so this directory was created.\n',dir);
    mkdir(dir);
end
end