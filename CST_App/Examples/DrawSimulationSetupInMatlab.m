% This example shows how CST_MicrowaveStudio can be used to plot the
% simulation space in CST_MicrowaveStudio
% 
% This works by saving each object as an STL file and reading in the
% triangulated mesh. It is not perfect in all scenarious, and occassionally
% there are bugs which mean some .stl objects are not read in correctly.
% This could just be a problem with the way the object is drawn in CST.
% Please let me know if there are any problems and I can help with
%
% Copyright Henry Giddens, 2018

%Create a new CST session
CST = CST_MicrowaveStudio(cd,'DrawInMatlabExample.cst');

%Create some gemoeteries
nPix = 15;
pixels = logical(randi(2,nPix)-1);
unitCellSize = 20; %unit cell 20 x 20 mm
subHeight = 0.8;

[x,y] = meshgrid(0:unitCellSize/nPix:unitCellSize,0:unitCellSize/nPix:unitCellSize);

CST.addNormalMaterial('FR4',4.3,1,[0.8941 0.1020 0.1098]);
CST.addBrick([0 unitCellSize],[0 unitCellSize],[0 0.8],'substrate','component1','FR4');

Z = [subHeight subHeight];
CST.setUpdateStatus(false);
ii = 0;
for i = 1:nPix
    for j = 1:nPix
        if pixels(i,j)
            ii = ii+1;
            Xblock = [x(j,i) x(j,i+1)];
            Yblock = [y(j,i) y(j+1,i)];
            name = ['Brick',num2str(ii)];
            CST.addBrick(Xblock,Yblock,Z,name,'component1','PEC');
        end
    end
end
CST.mergeCommonSolids('component1');
CST.addToHistory;
CST.setUpdateStatus(true);

CST.addNormalMaterial('ABS',2.7,1,[0.2157 0.4941 0.7216])
CST.addSphere(10,10,7.5,2.5,0,0,'Sphere1','component2','ABS','orientation','x')

CST.addCylinder(5,4,'z',10,10,[3 10],'Cylinder1','component2','ABS')

CST.save; %We need to save file for this to work
%%

hAx = axes('parent',figure);
s = CST.drawObjectMatlab('axes',hAx);

hAx.XLim = [-1 21];
hAx.YLim = [-1 21];
hAx.ZLim = [-1 11];
axis off


% Play around with lighting effects...
hlink = linkprop(s,{'FaceLighting','AmbientStrength','DiffuseStrength',...
    'SpecularStrength','SpecularExponent','BackFaceLighting'});


lightangle(0,-30)
s(1).FaceLighting = 'gouraud';
s(1).AmbientStrength = 0.3;
s(1).DiffuseStrength = 0.8;
s(1).SpecularStrength = 0.9;
s(1).SpecularExponent = 25;
s(1).BackFaceLighting = 'lit';

hAx.View = [-100  25];
L = light(hAx);
L.Position = [-1 -1 -0.5];
%% Plot some more objects but exclude the blue sphere

CST.addNormalMaterial('flubber',2.7,1,[0 1 0])
const = 4;
for i = 1:5
    for j = 1:5
        name = ['Sphere',num2str(i),num2str(j)];
        CST.addSphere(10+i*2+rand*const,10+j*2+rand*const,15+rand,2.5,0,0,[name,'1'],'component3','flubber','orientation','x')
        CST.addSphere(10-i*2-rand*const,10+j*2+rand*const,15+rand,2.5,0,0,[name,'2'],'component3','flubber','orientation','x')
    end
end
CST.mergeCommonSolids('component3');
%
fig = figure('color',[1 1 1]);
hAx = axes('parent',fig);
s = CST.drawObjectMatlab('axes',hAx,'excludeObject',{'component2:Sphere1'},'alpha',1,'boundingBox',false);

axis off

hlink = linkprop(s,{'FaceLighting','AmbientStrength','DiffuseStrength',...
    'SpecularStrength','SpecularExponent','BackFaceLighting'});

lightangle(10,30)
lightangle(10,-30)
s(1).FaceLighting = 'gouraud';
s(1).AmbientStrength = 0.5;
s(1).DiffuseStrength = 0.4;
s(1).SpecularStrength = 0.9;
s(1).SpecularExponent = 25;
s(1).BackFaceLighting = 'lit';

hAx.View = [-100  25];


