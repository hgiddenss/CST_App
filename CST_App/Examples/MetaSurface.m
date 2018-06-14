% Copyright Henry Giddens, 2018

%Generate a pixelated metasurface where metal is represented by 1. Place
%the array on an FR-4 substrate with thickness of 0.8mm, use floguet boundaries in the x and y
%directions. Select the frequency fomain solver:

%First generate the random pattern with size nPix-x-nPix
nPix = 10;
pixels = logical(randi(2,nPix)-1);

unitCellSize = 5; %unit cell 5 x 5 mm
subHeight = 0.8;

[x,y] = meshgrid(0:unitCellSize/nPix:unitCellSize,0:unitCellSize/nPix:unitCellSize);

%Build CST Model
CST = CST_MicrowaveStudio(cd,'MetaSurface');
CST.setSolver('frequency');
CST.setBoundaryCondition('xmin','unit cell','xmax','unit cell','ymin','unit cell','ymax','unit cell')
%define the first 2 modes of the floquet port
CST.defineFloquetModes(2)
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
CST.save;

%Run the simulation
CST.runSimulation

%Retrieve the SParameters and Plot in CST
[freq,S,SType] = CST.getSParameters;

ax = axes('parent',figure('Position',[680 576 780 402]));
hold on
for i = 1:numel(SType)
    plot(ax,freq(:,i),20*log10(abs(S(:,i))))
end
legend(SType,'location','eastoutside')

