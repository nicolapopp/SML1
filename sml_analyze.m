function varargout=sml_analyze (what, varargin)

prefix = 'sml1_';
baseDir = '/Users/eberlot/Documents/Data/SuperMotorLearning';
behDir  = fullfile(baseDir,'behavioral_data');
subj_name  = {'s01','s02','s03','s04','s05'};
cd(behDir)

switch what
    case 'all_subj'         % create .mat structure for each subject from .dat file    
        for i=1:length(subj_name) 
            sml_subj(subj_name{i}); 
        end; 
    case 'make_alldat'      % load all subjects dat files, concatenate them - one structure for all subjects 
        T=[]; 
        for i=1:length(subj_name) 
            load(fullfile(behDir,'analyze',[prefix '_' subj_name{i} '_.mat'])); 
            D.SN=ones(size(D.BN))*i; 
            T=addstruct(T,D); 
        end; 
        save(fullfile(behDir,'analyze','alldata.mat'),'-struct','T'); 
    case 'SL_MT'            % plot learning curve (MT) for seqLearn blocks
        figure
        for i=1:length(subj_name)
            load(fullfile(behDir,'analyze',['sml1_' subj_name{i} '.mat']));
            subplot(1,length(subj_name),i);
            lineplot(D.BN,D.MT,'subset',D.blockType==6);
            xlabel('Block number'); ylabel('Movement time');
            hold on
        end
    case 'SL_error_points'
        figure
        for i=1:length(subj_name)
            load(fullfile(behDir,'analyze',['sml1_' subj_name{i} '.mat']));
            subplot(2,length(subj_name),i);
            histogram(D.points(D.blockType==6),'Normalization','probability')
            xlabel('Points'); ylabel('Proportion');
            subplot(2,length(subj_name),i+3)
            histogram(D.isError(D.blockType==6),'Normalization','probability')
            xlabel('Error'); ylabel('Proportion');
            hold on
        end
    case 'CL_MT'            % plot learning curve (MT) for chunkLearn blocks
        figure
        for i=1:length(subj_name)
            load(fullfile(behDir,'analyze',['sml1_' subj_name{i} '.mat']));
            subplot(1,length(subj_name),i);
            lineplot(D.BN,D.MT,'subset',D.blockType==5);
            xlabel('Block number'); ylabel('Movement time');
            hold on
        end
    case 'CL_error_points'
        figure
        for i=1:length(subj_name)
            load(fullfile(behDir,'analyze',['sml1_' subj_name{i} '.mat']));
            subplot(2,length(subj_name),i);
            histogram(D.points(D.blockType==6),'Normalization','probability')
            xlabel('Points'); ylabel('Proportion');
            subplot(2,length(subj_name),i+3)
            histogram(D.isError(D.blockType==6),'Normalization','probability')
            xlabel('Error'); ylabel('Proportion');
            hold on
        end
    case 'SeqTest'
        vararginoptions(varargin,{'sn'});
        
        for i=1:length(sn)
            load(fullfile(behDir,'analyze',['sml1_' subj_name{sn(i)} '.mat']));
            R = getrow(D,D.blockType==11);
            figure
            subplot(1,length(sn),i)
            lineplot(R.BN,R.MT,'split',R.seqType,'style_thickline','leg',{'train','chunks','random'},'leglocation','northeast');
            xlabel('Block number'); ylabel('Movement time');
            hold on;
        end
    case 'FoSEx'
        vararginoptions(varargin,{'sn'});
        
        for i=1:length(sn)
            load(fullfile(behDir,'analyze',['sml1_' subj_name{sn(i)} '.mat']));
            R = getrow(D,D.blockType==11);
            figure(1)
            subplot(1,length(sn),i)
            lineplot(R.BN,R.MT,'split',R.FoSEx,'style_thickline','leg',{'first','second'},'leglocation','northeast');
            xlabel('Block number'); ylabel('Movement time');
            hold on;
        end
    case 'OtherHand'
       vararginoptions(varargin,{'sn'});
        
        for i=1:length(sn)
            load(fullfile(behDir,'analyze',['sml1_' subj_name{sn(i)} '.mat']));
            R = getrow(D,D.blockType==12);
            figure(1)
            subplot(1,length(sn),i)
            lineplot(R.BN,R.MT,'split',R.seqType,'style_thickline','leg',{'Train-intr','Train-extr','Rand-intr','Rand-intr'},'leglocation','northeast');
            xlabel('Block number'); ylabel('Movement time');
            hold on;
        end
        
        
    otherwise 
        fprintf('No such case');
        
end