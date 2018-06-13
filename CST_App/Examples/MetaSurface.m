%Generate a pixelated metasurface where metal is represented by 1. Place
%the array on an FR-4 substrate with thickness of 0.8mm, use floguet boundaries in the x and y
%directions. Select the frequency fomain solver:

%First generate the pattern with size nPix-x-nPix
nPix = 10;
pixels = logical(randi(2,nPix)-1);

unitCellSize = 5; %unit cell 5 x 5 mm
subHeight = 0.8;

[x,y] = meshgrid(0:unitCellSize/nPix:unitCellSize,0:unitCellSize/nPix:unitCellSize);

CST = CST_MicrowaveStudio(cd,'MetaSurface');
CST.setSolver('frequency');
CST.setBoundaryCondition('xmin','unit cell','xmax','unit cell','ymin','unit cell','ymax','unit cell')
CST.setFreq(9, 11);

CST.addNormalMaterial('FR4',4.3,1,[0.8 0.8 0.3]);
CST.addBrick([0 unitCellSize],[0 unitCellSize],[0 0.8],'substrate','Component1','FR4');

Z = [subHeight subHeight];

ii = 0;
for i = 1:nPix
    for j = 1:nPix
        if pixels(i,j)
            ii = ii+1;
            Xblock = [x(j,i) x(j,i+1)];
            Yblock = [y(j,i) y(j+1,i)];
            name = ['Brick',num2str(ii)];
            CST.addBrick(Xblock,Yblock,Z,name,'Component1','PEC');
        end
    end
end

CST.setFreq(9, 11);
