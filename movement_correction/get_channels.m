function [tiffs_ch00, tiffs_ch01, tiffs_ch02, single_channel] = get_channels(folder)

single_channel = false;
all_tiffs = dir([strcat(folder,'\'),'*.tif']);
      
ratio = zeros(length(all_tiffs),1);
ch00  = zeros(length(all_tiffs),1);
ch01  = zeros(length(all_tiffs),1);
ch02  = zeros(length(all_tiffs),1); 

for j=1:length(all_tiffs)    
   if (length(regexpi(all_tiffs(j).name,'RATIO')>0)) ratio(j)=1; end
   if (length(regexpi(all_tiffs(j).name,'ch00')>0) && ratio(j)==0) ch00(j)=1; end
   if (length(regexpi(all_tiffs(j).name,'ch01')>0) && ratio(j)==0) ch01(j)=1; end
   if (length(regexpi(all_tiffs(j).name,'ch02')>0) && ratio(j)==0) ch02(j)=1; end
end
  
 tiffs_ch00  = {all_tiffs(find(ch00==1)).name};
 tiffs_ch01  = {all_tiffs(find(ch01==1)).name};
 tiffs_ch02  = {all_tiffs(find(ch02==1)).name};

 % if we cannot find two channels, take all the Tiffs:
 l0 = 0; if(length(tiffs_ch00)>0) l0=1; end 
 l1 = 0; if(length(tiffs_ch01)>0) l1=1; end 
 l2 = 0; if(length(tiffs_ch02)>0) l2=1; end 
 L = l0+l1+l2;
 if L==1
    tiffs_ch00 = {all_tiffs.name};
    tiffs_ch01 = {all_tiffs.name};
    tiffs_ch02 = {all_tiffs.name};
    single_channel = true;
 else
     %also allow the case ch01/ch02 
     if length(tiffs_ch00)==0 && length(tiffs_ch02)>0
         tiffs_ch00 = tiffs_ch01
         tiffs_ch01 = tiffs_ch02;
     end
 end