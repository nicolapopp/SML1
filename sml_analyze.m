function varargout=sml_analyze (what, varargin)

prefix = 'sml1_';
baseDir = '/Users/eberlot/Documents/Data/SuperMotorLearning';
baseDir = '/Users/nicola/Documents/Data/SuperMotorLearning';
behDir  = fullfile(baseDir,'behavioral_training');
subj_name = {'new_test'}; 
cd(behDir)

switch what
    case 'all_subj' 
        for i=1:length(subj_name) 
            sml_subj(subj_name{i}); 
        end; 
    case 'make_alldat' % load all subjects dat files, concatenate them. 
        T=[]; 
        for i=1:length(subj_name) 
            load(fullfile(behDir,'analyze',[prefix '_' subj_name{i} '_.mat'])); 
            D.SN=ones(size(D.BN))*i; 
            T=addstruct(T,D); 
        end; 
        save(fullfile(behDir,'analyze','alldata.mat'),'-struct','T'); 
        
    otherwise 
        fprintf('No such case');
        
end