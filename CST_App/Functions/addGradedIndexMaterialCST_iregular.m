function [ii] = addGradedIndexMaterialCST_iregular(CST,X,Y,Er,map,height,varargin)
%ADDGRADEDINDEXMATERIAL Summary of this function goes here
%   Detailed explanation goes here

% Currently only allows 2D shapes extruding up from the Z = 0 plane

p = inputParser;
p.addParameter('materialStart',0)
p.addParameter('ignoreMaterial',false); %Use existing materials/do not create new ones.
p.addParameter('scaleFactor',[1 1 1]); %(X_dim,Y_dim,Z_dim) in mm
p.addParameter('rotateAngle',[0 0 0]);
p.addParameter('component','component1');
p.addParameter('CRange',[])
p.addParameter('MatchedImpedance',false); %The value in Er will be set to both Er and Mue
p.parse(varargin{:});

component = p.Results.component;

scaleFactor = p.Results.scaleFactor;
ignoreMaterial = p.Results.ignoreMaterial;

rotationAngle = p.Results.rotateAngle;
CRange = p.Results.CRange;
% if nargin == 5
%     scaleFactor = [1 1 1]; %(X_dim,Y_dim,Z_dim) in mm
% end
% 
% if nargin < 7
%     ignoreMaterial = false;
% end
    
if ~isnumeric(scaleFactor) || numel(scaleFactor) ~= 3
    error('the 6th argument, scaleFactor, must contain 3 numeric entries')
end

if ~p.Results.MatchedImpedance
   Er = Er.^2; 
    
end

I = size(X,2);
J = size(X,1);

%Determine the average permittivity of each block, based on the X-Y
%coordinates from previous determination
nMap = length(map)-1;
if isempty(CRange)
    ErMin = min(min(Er));
    ErMax = max(max(Er));
else
    ErMin = CRange(1).^2;
    ErMax = CRange(2).^2;
end
CRange = ErMax - ErMin;
C_Step = CRange/nMap;

% if p.Results.MatchedImpedance
%     ErMin = sqrt(ErMin);
%     ErMax = sqrt(ErMax);
%     
% end

%Create materials with Er,Mue for each value in map:

if ~ignoreMaterial
ii = p.Results.materialStart;
for i = 1:length(map)
    ii = ii+1;
    Er_val = ErMin + (i-1)*C_Step;
    %Mue = ZMin + (i-1)*C_Step;
    Mue = 1;
    if Er_val == 0 
        Er_val = 0.001;  %No Er or Mue = 0
    end
    if Mue == 0
        Mue = 0.001; %No Er or Mue = 0
    end
    if p.Results.MatchedImpedance
        %Er_val = sqrt(Er_val);
        Mue = Er_val;
    end
    C = (map(i,:));
    name = ['Material',num2str(i)];
    CST.addNormalMaterial(name,Er_val,Mue,C);
end
    
end

X = X*scaleFactor(1);
Y = Y*scaleFactor(2);

% Er(Er < ErMin) = ErMin;
% Er(Er > ErMax) = ErMax;

ii = p.Results.materialStart;
for i = 1:I-1
    for j = 1:J-1
        if ~any(isnan([X(j,i), X(j,i+1), Y(j,i), Y(j+1,i), Er(j,i)]))
            ii = ii+1;
            
            points = [X(j,i),Y(j,i); X(j,i+1),Y(j,i+1); X(j+1,i+1),Y(j+1,i+1); X(j+1,i),Y(j+1,i); X(j,i),Y(j,i)];
            
            h = height*scaleFactor(3);
            name = ['Brick',num2str(ii)];
       % z_Av = (Z2(i,j) + Z2(i+1,j) + Z2(i,j+1) + Z2(i+1,j+1))/4;
            C_idx = round((Er(j,i)-ErMin)./CRange * nMap) + 1;
            material = ['Material',num2str(C_idx)];
            CST.addPolygonBlock(points,h,name,component,material);
            if ~(all(rotationAngle == 0))
                CST.rotateObject(component,name,rotationAngle,[0, 0, 0],false,1)
            end
        end
    end
end






