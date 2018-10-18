%% AutoUpdateMode
% This example shows how to use the autoUpdate feature and how around 40-50%
% improvements in speed can be gained by adding all commands from a loop to
% the history list at once before updating the project, rather than looping
% through. 

%% Prepare the simulation file:

%Create a pretty pattern 

width = 30;
nStep = 30;

x = -width/2:width/(nStep):width/2;
y = -width/2:width/(nStep):width/2;

[X,Y] = meshgrid(x,y);

Map = randi(2,sum(1:nStep/2),1) - 1;

A = zeros(nStep/2);
ii = 0;
for i = 1:nStep/2
    iStart = (i-1)*nStep/2 + i;
    iStop = iStart + nStep/2 - i;
    
    ii = ii +iStop-iStart+1;
    iiStart = ii - (iStop-iStart);
    iiStop = iiStart + nStep/2 - i;
    A(iStart:iStop) = Map(iiStart:iiStop);
end
    
A = (A+A') - eye(size(A,1)).*diag(A);
%Map = A;
Map = round([A fliplr(A); flipud(A) rot90(A,2)]);

figure; surf(Map);
view(2); axis equal;
%% Conventional update mode 
CST = CST_MicrowaveStudio(cd,'autoUpdate.cst');
[I,J] = size(Map);

tStart = tic;
ii = 0;
for i = 1:I
    for j = 1:J
         if Map(j,i)
                ii = ii+1;
                Xblock = [X(j,i) X(j,i+1)];
                Yblock = [Y(j,i) Y(j+1,i)];
                Zblock = [0 0];
                name = ['Brick',num2str(ii)];
                CST.addBrick(Xblock,Yblock,Zblock,name,'Component1','PEC');
        end 
    end
end
tStop = toc(tStart);
fprintf('Time taken in conventional mode %.2f seconds\n',tStop);
pause(5)
% Test the time taken to rebuild the project
tStart = tic; CST.parameterUpdate; tStop = toc(tStart);
fprintf('Time taken to rebuild history list in conventional mode %.2f seconds\n',tStop);

%% Auto update mode 
CST = CST_MicrowaveStudio(cd,'BuildAtOnce.cst');
CST.setUpdateStatus(false)

[I,J] = size(Map);

tStart = tic;
ii = 0;
for i = 1:I
    for j = 1:J
         if Map(j,i)
                ii = ii+1;
                Xblock = [X(j,i) X(j,i+1)];
                Yblock = [Y(j,i) Y(j+1,i)];
                Zblock = [0 0];
                name = ['Brick',num2str(ii)];
                CST.addBrick(Xblock,Yblock,Zblock,name,'Component1','PEC'); %Note - you must always use unique names 
        end 
    end
end

%If autoUpdate has been turned off, you must call the addToHistory method
CST.addToHistory;
tStop = toc(tStart);
fprintf('Time taken in Build-At-Once mode %.2f seconds\n',tStop);
pause(5);
% Test the rebuild time
tStart = tic; CST.parameterUpdate; tStop = toc(tStart);
fprintf('Time taken to rebuild history list in Build-At-Onc mode %.2f seconds\n',tStop);
