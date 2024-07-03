function dup=find_duplicates(list,singlets)

% Find duplicate entries in a list
% Example:
% dup=find_duplicates([1 1 2 2 2 3]);
% dup(1)
% ans =
%     val: 1
%     loi: [1 2]
% dup(2)
% ans =
%     val: 2
%     loi: [3 4 5]


dup=[];

% Function argument parser
if (nargin < 1) | (nargin > 2)
   error('Argument number mismatch. Usage: dup=find_duplicates(list, [singlets]). With singlets=1 also single occurrences are returned.');
end

threshold=1;
if exist('singlets','var') & (singlets==1), threshold=0; end
if any(isnan(list)), error('No NaNs please.'), end

list=double(list);
un=unique(list);
dupval=[];
hc=histc(list,un);
tmp=un(hc>threshold);
for lv=1:length(tmp)
   dupval(lv,1).val=tmp(lv);
   dupval(lv,1).ind=find(list==tmp(lv));
   dupval(lv,1).length=length(dupval(lv,1).ind);
end
dup=dupval;

end

