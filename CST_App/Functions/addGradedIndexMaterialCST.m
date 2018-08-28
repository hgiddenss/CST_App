function [ii] = addGradedIndexMaterialCST(CST,X,Y,Z,EpsilonMap,map,varargin)
%ADDGRADEDINDEXMATERIAL This function takes the X,Y,and Z positions of 

p = inputParser;
p.addParameter('materialStart',0)
p.addParameter('ignoreMaterial',false); %Use existing materials/do not create new ones.
p.addParameter('scaleFactor',[1 1 1]); %(X_dim,Y_dim,Z_dim) in mm
p.addParameter('rotateAngle',[0 0 0]);
p.addParameter('component','component1');
p.parse(varargin{:});

component = p.Results.component;

scaleFactor = p.Results.scaleFactor;
ignoreMaterial = p.Results.ignoreMaterial;

rotationAngle = p.Results.rotateAngle;

if numel(Z) == 1
    Z = ones(size(X)).*Z;
end

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

I = size(X,2);
J = size(X,1);

%Determine the average permittivity of each block, based on the X-Y
%coordinates from previous determination


ZMin = min(min(EpsilonMap));
ZMax = max(max(EpsilonMap));

% map = hFig.Colormap;
% map = jet(16);
nMap = length(map)-1;

CRange = ZMax -ZMin;
C_Step = CRange/nMap;

%Create materials with Er,Mue for each value in map:
if ~ignoreMaterial
ii = p.Results.materialStart;
for i = 1:length(map)
    ii = ii+1;
    Er = ZMin + (i-1)*C_Step;
    %Mue = ZMin + (i-1)*C_Step;
    Mue = 1;
    if Er == 0 
        Er = 0.001;  %No Er or Mue = 0
    end
    if Mue == 0
        Mue = 0.001; %No Er or Mue = 0
    end
    C = (map(i,:));
    name = ['Material',num2str(i)];
    CST.addNormalMaterial(name,Er,Mue,C);
end
    
end

ii = p.Results.materialStart;
for i = 1:I-1
    for j = 1:J-1
        if ~any(isnan([X(j,i), X(j,i+1), Y(j,i), Y(j+1,i), EpsilonMap(j,i)]))
            ii = ii+1;
            Xblock = [X(j,i) X(j,i+1)]*scaleFactor(1)/2;
            Yblock = [Y(j,i) Y(j+1,i)]*scaleFactor(2)/2;
            Zblock = [-1 1]*scaleFactor(3)/2;
            name = ['Brick',num2str(ii)];
       % z_Av = (Z2(i,j) + Z2(i+1,j) + Z2(i,j+1) + Z2(i+1,j+1))/4;
            C_idx = round((EpsilonMap(j,i)-ZMin)./CRange * nMap) + 1;
            material = ['Material',num2str(C_idx)];
            CST.addBrick(Xblock,Yblock,Zblock,name,component,material);
            if ~(all(rotationAngle == 0))
                CST.rotateObject(component,name,rotationAngle,[0, 0, 0],false,1)
                
            end
        end
    end
end






