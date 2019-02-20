%Create a continuous graded index profile in the X-direction with both
%epsilon and mue

[X,Y] = meshgrid(1:0.05:10,-10:20:10);

n = X;

ax = axes('parent',figure);
s = surf(X,Y,n);
view([0 90])
s.EdgeColor = 'none';
cbar = colorbar;
drawnow
pause(0.1)


CST = CST_MicrowaveStudio(cd,'GradedIndex.cst');  %Note - file will only be saved if CST.save is called

map = cbrewer('div','Spectral',length(n));
for i = 1:length(n)
    C = (map(i,:));
    material = ['Material',num2str(i)];
    CST.addNormalMaterial(material,sqrt(n(i)),sqrt(n(i)),C);
end

Z = [-5 5];
[J,I] = size(X);

for i = 1:I-1
    if ~any(isnan([X(1,i), X(1,i+1), Y(2,i), Y(2,i),]))
        Xblock = [X(1,i) X(1,i+1)];
        Yblock = [Y(1,i) Y(2,i)];
        name = ['Brick',num2str(i)];
        material = ['Material',num2str(i)];
        CST.addBrick(Xblock,Yblock,Z,name,'Component 1',material);
    end
end



