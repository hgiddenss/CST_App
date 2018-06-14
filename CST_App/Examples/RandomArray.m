% Copyright Henry Giddens, 2018

%Generate a number of normally distributed randomly positioned scatterers
nScatter = 300;
R = randn(nScatter,3);

pointsize = 5;
figure;
m = scatter3(R(:,1), R(:,2), R(:,3), pointsize,'k');
m.MarkerFaceColor = 'k';
axis equal

CST = CST_MicrowaveStudio(cd,'RandomScatter.cst'); 

R = R*10; %standard deviation of 10
radius = 1; %radius of each sphere

for i = 1:nScatter
    name = ['solid',num2str(i)];
    component = ['component1'];
    material = ['PEC'];
    CST.addSphere(R(i,1),R(i,2),R(i,3),radius,0,0,name,component,material)
end

CST.save
