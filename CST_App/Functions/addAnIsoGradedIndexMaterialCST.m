function [outputArg1,outputArg2] = addAnIsoGradedIndexMaterialCST(CST,X,Y,Exx,Eyy,Ezz,map,scaleFactor)
%ADDGRADEDINDEXMATERIAL Summary of this function goes here
%   Detailed explanation goes here

if nargin == 7
    scaleFactor = [1 1 1]; %(X_dim,Y_dim,Z_dim) in mm
end
    
if ~isnumeric(scaleFactor) || numel(scaleFactor) ~= 3
    error('the 8th argument, scaleFactor, must contain 3 numeric entries')
end

I = size(X,1);
J = size(X,2);

%Determine the average permittivity of each block, based on the X-Y
%coordinates from previous determination

ExxMin = min(min(Exx));
ExxMax = max(max(Exx));

EyyMin = min(min(Eyy));
EyyMax = max(max(Eyy));

EzzMin = min(min(Ezz));
EzzMax = max(max(Ezz));

% map = hFig.Colormap;
% map = jet(16);
nMap = length(map)-1;

CRange = EzzMax - EzzMin;
C_Step = CRange/nMap; %Color range in Z-tensor

XRange = ExxMax - ExxMin;
YRange = EyyMax - EyyMin;
ZRange = CRange;

X_Step = XRange/nMap;
Y_Step = YRange/nMap;
Z_Step = ZRange/nMap;

%Create materials with Er,Mue for each value in map:
ii = 0;

for i = 1:length(map)
    ii = ii+1;
    Er_x = ExxMin + (i-1)*X_Step;
    Mue_x = ExxMin + (i-1)*X_Step;
    Er_y = EyyMin + (i-1)*Y_Step;
    Mue_y = EyyMin + (i-1)*Y_Step;
    Er_z = EzzMin + (i-1)*Z_Step;
    Mue_z = EzzMin + (i-1)*Z_Step;
    
%     if Er_x == 0 
%         Er = 0.001;  %No Er or Mue = 0
%     end
%     if Mue == 0
%         Mue = 0.001; %No Er or Mue = 0
%     end
    C = (map(i,:));

    dirStr = 'Anisotripic';
    Er_Tensor = [Er_x,Er_y,Er_z];
    Mue_Tensor = [Mue_x,Mue_y,Mue_z];

    name = ['Material',dirStr,'_',num2str(i)];
    CST.AddAnisotropicMaterial(name,Er_Tensor,Mue_Tensor,C);
end



idx = false(size(Exx));
for i = 1:length(idx)
   isub = i-1;
   idx(i,i:end-i) = true;
end
idx = idx | rot90(idx,2);
materialIndex = cell(size(idx));
materialIndex(idx) = {'X'};
materialIndex(~idx) = {'Y'};

ii = 0;
for i = 1:I-1
    for j = 1:J-1
        
        ii = ii+1;
        Xblock = [X(j,i) X(j,i+1)]*scaleFactor(1)/2;
        Yblock = [Y(j,i) Y(j+1,i)]*scaleFactor(2)/2;
        Zblock = [-1 1]*scaleFactor(3)/2;
        name = ['Brick',num2str(ii)];
       % z_Av = (Z2(i,j) + Z2(i+1,j) + Z2(i,j+1) + Z2(i+1,j+1))/4;
        C_idx = round((Exx(i,j)-EzzMin)./CRange * nMap) + 1;
        material = ['Material',materialIndex{i,j},'_',num2str(C_idx)];
        CST.AddBrick(Xblock,Yblock,Zblock,name,'component1',material);
    end
end






