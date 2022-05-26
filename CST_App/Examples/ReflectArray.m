% Reflect Array with Width of the Patch proportional to the radial position
%   Copyright: Henry Giddens 2022, Antennas and Electromagnetics
%   Group, Queen Mary University London, 2022 (For further help,
%   functionality requests, and bug fixes contact h.giddens@qmul.ac.uk)


%get X and Y grid
x = -10:10;
y = -10:10;
[X,Y] = meshgrid(x,y);

%I do not have any relation between unit cell size and reflection pahse so I will just generate an array with varying
%unit cell width based on the radial position. The phase gradient and design of the unit cell would normally be carried
%out before building the full reflect array
unitCellWidth = 10;
pixelWidth = zeros(size(X));
r_total = 8;
r_min = 1;
for iX = 1:numel(x)
    for iY = 1:numel(y)
        r = sqrt(X(iX,iY).^2 + Y(iX,iY).^2);
        if r > r_total
            r = r - r_total;
        end
            pixelWidth(iX,iY) = unitCellWidth*0.9*(10 - r)./10;
    end
end

figure; 
surf(X,Y,pixelWidth,'FaceColor','flat');
view([0 90]);
colorbar;
%%
CST = CST_MicrowaveStudio(cd,'reflectArrayExample.cst');

%Add a dielectric for the substrate material
CST.addNormalMaterial('substrate_dielectric',2.7,1,[0.8 0.2 0.3]);

substrateHeight = 1.6;
%Add substrate and groun plane
xBoard = [x(1) x(end)]*unitCellWidth;
yBoard = [y(1) y(end)]*unitCellWidth;
CST.addBrick(xBoard,yBoard,[0 0],'Ground','component1','PEC');
CST.addBrick(xBoard,yBoard,[0 substrateHeight],'Substrate','component1','substrate_dielectric');

% build array
for iX = 1:numel(x)-1
    for iY = 1:numel(y)-1
        if pixelWidth(iX,iY) > 0
            xC = (x(iX) + x(iX+1))*unitCellWidth/2;
            yC = (y(iY) + y(iY+1))*unitCellWidth/2;
            xPix = [-0.5 0.5]*pixelWidth(iX, iY) + xC;
            yPix = [-0.5 0.5]*pixelWidth(iX,iY) + yC;
            name = ['pix',num2str(iX),'_',num2str(iY)];
            CST.addBrick(xPix,yPix,[substrateHeight substrateHeight],name,'component2','PEC');
        end
    end
end

%Merge the pixels to a single peice:
CST.mergeCommonSolids('component2');
