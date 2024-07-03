
% input multiple registration mat files 
% in this example:
% transforms1_50Match.mat, transforms50_100Match.mat,
% transforms100_150Match.mat,  transforms150_200MatchFast100.mat'

% output one registration file (both mat and json)
% transforms1_200.mat transforms1_200.json

data_path = '/Users/lbrown/Documents/PosfaiLab/3DStardist/GataNanog/HaydenJan22Set/';
FinalRegistrationName = 'transforms1_200.mat';


% read in mat file
RegistrationFileName ='transforms1_50Match.mat';
transforms = load(strcat(data_path,RegistrationFileName));

RegistrationFileName ='transforms50_100Match.mat';
transforms50_100 = load(strcat(data_path,RegistrationFileName));
for i = 50: 100
    transforms.store_registration{i,1} = transforms50_100.store_registration{i,1};
end

RegistrationFileName ='transforms100_150Match.mat';
transforms100_150 = load(strcat(data_path,RegistrationFileName));
for i = 100: 149
    transforms.store_registration{i,1} = transforms100_150.store_registration{i,1};
end

RegistrationFileName ='transforms150_200MatchFast100.mat';
transforms150_200 = load(strcat(data_path,RegistrationFileName));
for i = 150: 199
    transforms.store_registration{i,1} = transforms150_200.store_registration{i,1};
end

figure;
hold on;
 for i=1:199
     s(i) = transforms.store_registration{i,1}.minSigma;
 end
 plot(1:199,s,'LineWidth',4,'Color','b');


store_registration = transforms.store_registration;
save(strcat(data_path,FinalRegistrationName), 'store_registration');


% output json version  for python reading
jH = jsonencode(store_registration);

n = length(FinalRegistrationName);
json_RegistrationFileName = strcat(RegistrationFileName(1:n-3),'json');
fid = fopen(strcat(data_path,json_RegistrationFileName),'w');
fprintf(fid, jH);
fclose(fid);
