% Copyright Henry Giddens, 2018

% This example shows how to assign parameters to various different
% objects/materials as you build a CST project programtically

%Start a new CST project
CST = CST_MicrowaveStudio(cd,'AssignParameters.CST');

%Use the "addParameter" method to assign a new parameter:
% The first argument is a string representing a valid parameter name (it
% must start with a character, not number), the second argument is numeric
% and represents the value of the parameter. Strings (dependent parameters)
% are not supported for the second argument

CST.addParameter('Er',2.2);
CST.addParameter('Mue',1);

CST.addNormalMaterial('Material_1',2.2,1,[1 0 0])
CST.addNormalMaterial('Material_2','Er','Mue',[0 0 1]);

CST.addBrick([-5 5],[-5 5],[-5 5],'Brick1','Component1','Material_1');
CST.addBrick([-5 5]+11,[-5 5],[-5 5],'Brick2','Component1','Material_2');

%Change the parameters:
CST.changeParameterValue('Mue',7);
CST.changeParameterValue('Er',1);

%%
% Check if parameter exists...
if CST.isParameter('Er')
    disp('Parameter Exists!')
else
    disp('Parameter does not exist!');
end

%%

if CST.isParameter('Mu')
    disp('Parameter Exists!')
else
    disp('Parameter does not exist!');
end

%% Do some more...
try
CST.deleteObject('component','Component1');
end

CST.addParameter('x1',-5);
CST.addParameter('x2',5);
CST.addParameter('y1',-5);
CST.addParameter('z2',5);

%You can use parameters for most objects where the coordinates typically
%should be entered numerically, as long as the parameter has already been
%added to the project
CST.addBrick({'x1','x2'},{'y1' 5},[-5 5],'Brick1','Component1','Material_1');
CST.addBrick([-5 5]+11,{-5 5},{-5 'z2'},'Brick2','Component1','Material_2');

% This line would cause an error as 'z3' does not exist
% CST.addBrick([-5 5]+11,{-5 5},{-5 'z3'},'Brick3','Component1','Material_2');
pause(5)
CST.changeParameterValue('x1',-10);
pause(5)
CST.addParameter('xshift',17);
CST.translateObject('Component1:Brick1','xshift',0,1,0,'destination','Component1');
pause(5)
CST.changeParameterValue('xshift',27)
pause(2)
CST.addParameter('rot',45)
CST.rotateObject('Component1','Brick2',{0 0 'rot'},[0 0 0],false)
pause(2)

%querey parameter
Er = CST.getParameterValue('Er');
Mue = CST.getParameterValue('Mue');

fprintf('Er = %.2f\nMue = %.2f\n',Er,Mue)
