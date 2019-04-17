%This example takes a while to run, and is quite slow, but it is a pretty
%cool way to add 3D surfaces. If you give the surface a thickness, then it
%can be used to intersect solids and create nice shapes on the surface of
%different materials

%Create a sufrave which varies sinusoidally in the radial axis away from the center point

th = 0:pi/4/5:pi/4;
r = 0:0.05:1;   %Add more resolution if you can be prepared to wait for CST to build
r1 = 0.01:0.99/20:1; %Inner radius doesnt start at 0 to avoid singularity
[R,TH] = meshgrid(r1,th);
z = repmat((sin(r*3*pi)),6,1);

[X,Y,Z] = pol2cart(TH,R,z);
X = X*100;
Y = Y*100;
Z = (Z*10);

figure; hold on;
for i = 1:8
    [X,Y] = rotateMatrix(X,Y,45);
surf(X,Y,Z,'facecolor',[0.8 0.8 0.8]); 
end
axis equal;

%%
%Use the add3DSurface function. add3DSurfaceCST triangulates the surface
%with each triangle lying in the same plane. This then calls a method
%called addPolygonBlock3D from the CST_MicrowaveStudio class.
CST = CST_MicrowaveStudio(cd,'test.cst');
CST.setUpdateStatus(false);
add3DSurfaceCST(CST,X,Y,Z,0,'PEC','component1');
CST.addToHistory;
CST.setUpdateStatus(true);

%%
%Copy the surface and transforom so it has a thickness. We cannot simply
%extrude each triangle as they are all at different angles
CST.addComponent('component2');
CST.translateObject('component1',0,0,1,1,'destination','component2');

%Connect the two surfaces using the matching faces
CST.setUpdateStatus(false); %Turn auto update off to make this faster
for i = 1:200
component1 = 'component1'; face1 = ['Brick',num2str(i)];
component2 = 'component2'; face2 = ['Brick',num2str(i)]; name = ['Solid',num2str(i)];
connectFaces(CST,component1,face1,component2,face2,'component3',name,'PEC'); 
end
CST.addToHistory;
CST.setUpdateStatus(true);

CST.mergeCommonSolids('component3')
%%
CST.rotateObject('component3:Solid1',[0 0 45],[0 0 0],'copy',true,'repetitions',7);

CST.addCylinder(0.05*101,0,'z',0,0,[Z(1),Z(1)+1],'cylinder1','component3','PEC')
CST.mergeCommonSolids('component3') %This will mearge everything into a single solid block

%You could now delete components 1 and 2 as they are not needed
CST.deleteObject('component','component1');
CST.deleteObject('component','component2');