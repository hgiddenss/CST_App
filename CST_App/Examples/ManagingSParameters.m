% This demo shows how to read in S-Parameters from CST simulations with multiple simulations performaed via parameter
% sweep.
%
% Copyright Henry Giddens 2019
% H.Giddens@qmul.ac.uk

%Create a new project
CST = CST_MicrowaveStudio(cd,'ManagingSParameters.cst');
%%
%Build a multi-port structure
CST.addNormalMaterial('dielectric',4.5,1,[0.8 0.1 0]);
CST.addBrick([-15 15],[-25 25],[0 -1.6],'substrate','component1','dielectric');
CST.addBrick([-15 15],[-25 25],[-1.6 -1.6],'groundplane','component1','PEC');
CST.addBrick([-1.5 1.5],[-25 -10],[0 0],'trace1','component1','PEC');
CST.addBrick([-1.5 1.5],[10 25],[0 0],'trace2','component1','PEC');

CST.addParameter('r1',9.8);
CST.addParameter('r2',6.8);
CST.addCylinder('r1','r2','z',0,0,[0 0],'filter1','component1','PEC');

CST.addWaveguidePort('ymin',[-4.5 4.5],[-25 -25],[-1.6 3.2]);
CST.addWaveguidePort('ymax',[-4.5 4.5],[25 25],[-1.6 3.2]);

CST.setFreq(0,10);
%%
CST.runSimulation;
%
CST.changeParameterValue('r1',9.2);
CST.runSimulation;
CST.changeParameterValue('r1',8.8);
CST.runSimulation;

%%
% Retrieve the S-21 parameter for the first run:
[freq,sparams,stype] = CST.getSParams('s21',1); %First argument is a string representing the s-parameter type, second argument is numeric value representing runID
figure; hold on; ylabel('S-parameter (dB)'); xlabel('Frequency (GHz)');
L = plot(freq,20*log10(abs(sparams)));
display(stype{1}); %Stype shows the s-parameter and runID returned in sparams

% Retrieve the S-11 parameter for the first run:
[freq,sparams,stype] = CST.getSParams('s11',1);
L = plot(freq,20*log10(abs(sparams)));
display(stype{1});

%% retrieve all s-parameters for run 2
[freq,sparams,stype] = CST.getSParams(2); %if all s-params are required, only the runID as input is needed
figure; ylabel('S-parameter (dB)'); xlabel('Frequency (GHz)');
L = plot(freq,20*log10(abs(sparams)));
stype  %Stype shows the s-parameter and runID returned in sparams

%% retrieve s21 for all runs
[freq,sparams,stype] = CST.getSParams('s21',-1); %Negative run ID will return all available results
figure; ylabel('S-parameter (dB)'); xlabel('Frequency (GHz)');
L = plot(freq,20*log10(abs(sparams)));
stype %4 arrays are returned, including Run ID = 0 (the most recent run)

%% retrieve s22 for runs 3, 1, 2
[freq,sparams,stype] = CST.getSParams('s22',[3 1 2]); %array of run ids will return s-parameters in that order
figure; ylabel('S-parameter (dB)'); xlabel('Frequency (GHz)');
L = plot(freq,20*log10(abs(sparams)));
legend('r = 8.8','r = 9.8','r = 9.2');
stype %

%% retrieve s11 and s21 only from runs 0 and 1
[freq,sparams,stype] = CST.getSParams({'s11','s21'},[0 1]); %cell array of sparameter names can be used. 
figure; hold on; ylabel('S-parameter (dB)'); xlabel('Frequency (GHz)');
L = plot(freq,20*log10(abs(sparams(:,1,1)))); %S11, Run ID = 0
L = plot(freq,20*log10(abs(sparams(:,2,1)))); %S21, Run ID = 0
L = plot(freq,20*log10(abs(sparams(:,1,2)))); %S11, Run ID = 1
L = plot(freq,20*log10(abs(sparams(:,2,2)))); %S21, Run ID = 1
stype % we now have a 3-dimensional matrix - The stype matrix is also 3-dimeionsal with each value indicating what is in the column of the sparams matrix of the same location
legend(stype{1,1,1},stype{1,2,1},stype{1,1,2},stype{1,1,2})


%% retrieve s11 for most recent run
[freq,sparams,stype] = CST.getSParams('S1,1'); %The s-parameter name should match up to that displayed in the navigation tree in CST. This is essential for unusual names eg (SZmax(1),Zmax(2))
figure; hold on; ylabel('S-parameter (dB)'); xlabel('Frequency (GHz)');
L = plot(freq,20*log10(abs(sparams))); %S11, Run ID = 0
stype % we now have a 3-dimensional matrix - The stype matrix is also 3-dimeionsal with each value indicating what is in the column of the sparams matrix of the same location

%% retrieve s11 for most recent run
[freq,sparams,stype] = CST.getSParams(); %On its own will return all sparameters for most recent simulations
figure; hold on; ylabel('S-parameter (dB)'); xlabel('Frequency (GHz)');
L = plot(freq,20*log10(abs(sparams))); %S11, Run ID = 0
legend(stype)
stype % we now have a 3-dimensional matrix - The stype matrix is also 3-dimeionsal with each value indicating what is in the column of the sparams matrix of the same location


%%

close all;