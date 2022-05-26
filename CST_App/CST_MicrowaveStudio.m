classdef CST_MicrowaveStudio < handle
    %CST_MicrowaveStudio creates a CST_MicrowaveStudio object which acts as
    %an interface between MATLAB and CST Microwave Studio.
    %   CST_MicrowaveStudio(folder,filename) creates a new CST MWS session
    %   in a subfolder in the specified file location. The subfolder is
    %   called '/CST_MicrowaveStudio_Files' and is only created when the
    %   CST file is saved. CST_MicrowaveStudio contains a number of
    %   functions to perform regular operations in CST mathematically. All
    %   steps are added to the history tree as if the user had created the
    %   model interactively.
    %
    %   -----Methods Overview-----
    %
    %   --Class Creator--
    %   CST_MicrowaveStudio
    %
    %   --File Methods--
    %   save
    %   quit
    %   openFile (Static)
    %
    %   --Paremeter Methods (**Needs Updating 23/06/2021**)
    %   addParameter
    %   changeParemeter
    %   parameterUpdate
    %   getParameterValue
    %
    %   --Simulation Methods--
    %   addDiscretePort
    %   defineUnits
    %   setFreq
    %   setSolver
    %   setBoundaryCondition
    %   addFieldMonitor
    %   setBackgroundLimits
    %   addSymmetryPlane
    %   defineFloquetModes
    %   runSimulation
    %
    %   --Build Methods--
    %   addNormalMaterial
    %   addAnisotropicMaterial
    %   addDispersiveMaterial
    %   addBrick
    %   addCylinder
    %   addPolygonBlock
    %   addPolygonBlock3D
    %   addSphere
    %   rotateObject
    %   translateObject
    %   connectFaces
    %   mergeCommonSolids
    %   deleteObject
    %
    %   --Result Methods--
    %   getSParameters
    %   getPortSignals
    %   getFarfield
    %   getEFieldVector
    %   getMeshInfo
    %   getFieldIDStrings
    %
    %   --Plotting methods--
    %   drawObjectMatlab
    %
    %   --Other--
    %   addToHistory
    %   setUpdateStatus
    %   update
    %
    %   For help on specific functions, type
    %   CST_MicrowaveStuio.FunctionName (e.g. "help CST_MicrowaveStudio.setBoundaryCondition")
    %
    %   Additional custom functions may be added to CST histroy list using
    %   the same VBA format below and calling:
    %   CST_MicrowaveStudioHandle.mws.invoke('AddToHistory','Action String identifier',VBA])
    %
    %   See Also: actxserver, addGradedIndexMaterialCST, CST_App\Examples
    %
    %   Latest Versions Available:
    %   https://uk.mathworks.com/matlabcentral/fileexchange/67731-hgiddenss-cst_app
    %   https://github.com/hgiddenss/CST_App
    %
    %   Links: https://www.cst.com/products/cstmws
    %
    %   Copyright: Henry Giddens 2018, Antennas and Electromagnetics
    %   Group, Queen Mary University London, 2018 (For further help,
    %   functionality requests, and bug fixes contact h.giddens@qmul.ac.uk)
    
    properties
        CST       % Handle to CST through actxserver
        folder    % Folder
        filename  % Filename
        mws       % Handle to the microwave studio project
    end
    properties (Hidden)
        solver = 't';
        listeners
    end
    properties (SetAccess = private)
        autoUpdate = true %If true, each relevant command will be added to history once function finishes executing
        VBAstring = [];     %If false, the VBA commands will be added to the VBAstring property, and the addToHistory Method must be called.
        %All commands will be added in same action and it is sometimes fast when dealing with large loops.
    end
    properties(Access = private)
        version = '1.2.25'
    end
    methods
        function obj = CST_MicrowaveStudio(folder,filename)
            %CST_MicrowaveStudio with no input parameters will construct an
            % instance of CST_MicrowaveStudio related to the currently open
            % project in CST.
            %
            % CST_MicrowaveStudio(folder,filename) will either create a new
            % CST mws project, or will open an existing project (if it
            % exists).
            %
            % Examples:
            % To create a new microwave studio project
            % CST = CST_MicrowaveStudio(cd,'New_MWS_Simulation.cst');
            %
            % CST = CST_MicrowaveStudio; %Return the currently active MWS
            % project
            
            if nargin == 0
                %Get the current MWS session
                obj.CST = actxserver('CSTStudio.application');
                obj.mws = obj.CST.Active3D;
                if isempty(obj.mws)
                    error('CSTMicrowaveStudio:NoFileOpen',...
                        'I tried to return the active microwave studio session, but it appears that no proects are currently open');
                end
                [obj.folder,obj.filename] = fileparts(obj.mws.invoke('GetProjectPath','Project'));
                
                obj.installMacros; %Check for and install new macros if new download has happened
                
                fprintf('CST_MicrowaveStudio Successfully opened. Active microwave studio project is:\n%s\\%s.cst\n',obj.folder,obj.filename)
                return
                
            end
            
            obj.folder = folder;
            
            %Ensure file has .cst extension.
            [~,filename,ext] = fileparts(filename);
            
            if ~isempty(ext)
                if ~strcmpi('.cst',ext)
                    error('CST_MicrowaveStudio:wrongFileExtension','File extension must be .CST')
                end
            end
            obj.filename = filename;
            
            ff = fullfile(obj.folder,[obj.filename,ext]);
            
            if exist(ff,'file') == 2
                %If file exists, open
                [obj.CST,obj.mws] = CST_MicrowaveStudio.openFile(obj.folder,[obj.filename,ext]);
                fprintf('Microwave studio project was successfully opened\n')
            else %Create a new MWS session
                %Create a directory in 'folder' called
                %CST_MicrowaveStudio_Files which is added to .gitignore
                fprintf('Creating new microwave studio session\n');
                dirstring = fullfile(obj.folder,'CST_MicrowaveStudio_Files');
                obj.folder = dirstring;
                obj.CST = actxserver('CSTStudio.application');
                obj.mws = obj.CST.invoke('NewMWS');
                
                % For Future Version - allow user to store some values as
                % object properties, such as the frequency, which update in the
                % MWS model whenever they are updated in Matlab
                % obj.listeners = addlistener(obj,{'F1','F2'},'PreSet',@obj.setFreqListenerResp);
                
                %Set up some default simulation parameters:
                obj.defineUnits;
                obj.setFreq(1,10);
                
                %Boundaries:
                VBA = sprintf(['With Boundary\n',...
                    '.Xmin "expanded open"\n',...
                    '.Xmax "expanded open"\n',...
                    '.Ymin "expanded open"\n',...
                    '.Ymax "expanded open"\n',...
                    '.Zmin "expanded open"\n',...
                    '.Zmax "expanded open"\n',...
                    'End With',...
                    ]);
                
                obj.mws.invoke('addToHistory','define boundaries',VBA);
                
                VBA = sprintf(['With Material\n',...
                    '.Type "Normal\n',...
                    '.Colour "0.6", "0.6", "0.6"\n',...
                    '.Epsilon "1"\n',...
                    '.Mu "1"\n',...
                    '.ChangeBackgroundMaterial\n',...
                    'End With',...
                    ]);
                
                obj.mws.invoke('addToHistory','Set Background Material',VBA);
                
                %Turn off the the working plane (which isnt needed for programatic control of CST)
                plot = obj.mws.invoke('plot');
                plot.invoke('DrawWorkplane','false');
                
            end
            
            obj.installMacros; %Check for and install new macros if new download has happened
        end
        function setUpdateStatus(obj,status)
            %CST.setUpdateStatus sets the status of the addToHistoryList property
            if status == 1 || status == 0
                status = logical(status);
            end
            if ~islogical(status)
                error('CST_MicrowaveStudio:incorrectParameterType','Input parameter "status" must be of boolean/logical type');
            end
            if nargin == 2
                obj.autoUpdate = status;
            end
            
        end
        function addToHistory(obj,commandString,VBAstring)
            %CST.addToHistoryList(commandString,VBAstring) adds the commands in
            %VBAstring to the history list. They must be correctly
            %formatted else errors in CST will occur, halting the execution
            %of any code.
            %CST.addToHistory(commandString) will add any strings stored in
            %the object property VBAstring. commandString will be the
            %string shown in the history list. consecutive commandStrings
            %should never be the same as this may cause errors when the CST
            %history list is updated
            if nargin < 2 
                commandString = ['CST_update_',datestr(now(),"HHMMSSddmmyyyy")]; %A unique string based on current time
            end
            if nargin < 3
                VBAstring = obj.VBAstring;
                obj.VBAstring = [];
            end
            obj.mws.invoke('addToHistory',commandString,VBAstring);
        end
        function save(obj)
            if ~exist(obj.folder,'file') == 7
                makedir(obj.folder);
            end
            obj.mws.invoke('saveas',fullfile(obj.folder,[obj.filename,'.cst']),'false');
        end
        function closeProject(obj)
            obj.mws.invoke('quit');
        end
        function quit(obj)
            % Close the application
            obj.CST.invoke('quit');
        end
        function addParameter(obj,name,value)
            % CST_MicrowaveStudio.addParameter(name,value)
            % Add a new parameter to the project. Value must be a
            % double
            
            if obj.isParameter(name)
                obj.changeParameterValue(name,value)
            else
                obj.mws.invoke('StoreDoubleParameter',name,value);
            end
            
        end
        function deleteParameter(obj,name)
            % CST_MicrowaveStudio.deleteParameter(name)
            % Delete the named parameter from CST project
            
            if obj.isParameter(name)
                obj.mws.invoke('DeleteParameter',name)
            end
        end
        function changeParameterValue(obj,varargin)
            % CST_MicrowaveStudio.changeParameterValue(name,value)
            % Change the value of an existing parameter. Value must be a
            % double
            
            if rem(numel(varargin),2) == 1
                error('Odd number of Name/Value pair input arguments detected');
            end
            
            name = varargin(1:2:end);
            value = varargin(2:2:end);
            for i = 1:numel(name)
                if ~obj.isParameter(name{i})
                    addParameter(obj,name{i},value{i})
                else
                    obj.mws.invoke('StoreDoubleParameter',name{i},value{i});
                end
            end
            obj.parameterUpdate;
        end
        function parameterUpdate(obj)
            % CST_MicrowaveStudio.parameterUpdate
            % Update the history list
            %obj.mws.invoke('Rebuild');
            obj.mws.invoke('RebuildOnParametricChange',false,false);
        end
        function out = isParameter(obj,name)
            % CST_MicrowaveStudio.isParameter(name)
            % Check if a parameter exists
            out = obj.mws.invoke('DoesParameterExist',char(name));
        end
        function val = getParameterValue(obj,name)
            %Returns the value of the named parameter. val is returned
            %empty if the parameter does not exist
            val = [];
            if obj.isParameter(name)
                val = obj.mws.invoke('RestoreDoubleParameter',name);
            end
        end
        function defineBackgroundMaterial(obj,materialType,varargin)
            %defineBackgroundMaterial(materialType,varargin)
            % Define the background material for a model
            % materialType can be one of the following options:
            % 'Vacuum'  'PEC'  'Dielectric'
            % If Dielectric, then optional parameter/value arguments should be included
            % 'Er' (default = 1), 'Mu' (default = 1), 'tand' (default = 0), 'sigma' (default = 0), 
            % 'tandM' (default = 0), 'sigmaM' (default = 0)
            %
            
            p = inputParser;
            p.addParameter('Er',1);
            p.addParameter('Mu',1);
            p.addParameter('tand',0);
            p.addParameter('sigma',0);
            p.addParameter('tandM',0);
            p.addParameter('sigmaM',0);
            p.parse(varargin{:});
            
            switch lower(materialType)
                case 'vacuum'
                    VBA = sprintf(['With Material\n',...
                    '.Type "Normal"\n',...
                    '.Colour "0.6", "0.6", "0.6"\n',...
                    '.Epsilon "1"\n',...
                    '.Mu "1"\n',...
                    '.ChangeBackgroundMaterial\n',...
                    'End With',...
                    ]);
                case 'pec'
                    VBA = sprintf(['With Material\n',...
                    '.Type "Pec"\n',...
                    '.Colour "0.6", "0.6", "0.6"\n',...
                    '.Epsilon "1"\n',...
                    '.Mu "1"\n',...
                    '.ChangeBackgroundMaterial\n',...
                    'End With',...
                    ]);
                case 'dielectric'
                    VBA = sprintf(['With Material\n',...
                    '.Type "Normal"\n',...
                    '.Colour "0.6", "0.6", "0.6"\n',...
                    '.Epsilon "%.3f"\n',...
                    '.Mu "%.3f"\n',...
                    '.tand "%.3f"\n',...
                    '.sigma "%.3f"\n',...
                    '.tandM "%.3f"\n',...
                    '.sigmaM "%.3f"\n',...
                    '.ChangeBackgroundMaterial\n',...
                    'End With',...
                    ],p.Results.Er,p.Results.Mu,p.Results.tand,p.Results.sigma,p.Results.tandM,p.Results.sigmaM);
                otherwise
                    
            end
                    
           obj.mws.invoke('addToHistory','Set Background Material',VBA);
            
        end
        function defineUnits(obj,varargin)
            %defineUnits(Parameter,value) - Define the units used in the CST_MicrowaveStudio
            %simulation. The default parameters and units arelisted below.
            %Any wrong arguments for value will currently resutl in a CST
            %error, and wont be picked up by matlab, so be careful! If a
            %particular parameter isnt set, it will be reset to its default
            %value as specified below
            %
            % --Parameter--          --Value-- (default) in parenthesis
            %   Geometry             'm' 'cm' ('mm') 'um' 'nm' 'ft' 'mil' 'in'
            %   Frequency            'Hz' 'kHz' 'MHz' 'GHz' 'THz' 'pHz'
            %   Time                 ('s') 'ms' 'us' 'ns' 'ps' 'fs'
            %   Temperature          ('Kelvin') 'Celsius' 'Farenheit'
            %   Voltage              ('V') % These 6 values apear to be fixed in microwave studio, so cannot be changed here either
            %   Current              ('A') %
            %   Resistance           ('Ohm') %
            %   Conductance          ('Siemens') %
            %   Capacitance          ('PikoF') %
            %   Inductance           ('NanoH') %
            %
            % Example:
            % CST.defineUnits('Frequency','THz','Geometery','nm');
            
            %Should these eventually be stored as class properties, or
            %persistant variable, else you have to define all units every
            %time they are changed or else the defaults below will be reset?
            
            p = inputParser;
            p.addParameter('Geometry','mm');
            p.addParameter('Frequency','GHz');
            p.addParameter('Time','S');
            p.addParameter('Temperature','Kelvin');
            p.addParameter('Votlage','V');
            p.addParameter('Current','A');
            p.addParameter('Resistance','Ohm');
            p.addParameter('Conductance','Siemens');
            p.addParameter('Capacitance','PiKoF');
            p.addParameter('Inductance','NanoH');
            
            p.parse(varargin{:});
            [geom,freq,time,temp] = deal(p.Results.Geometry,...
                p.Results.Frequency,p.Results.Time,p.Results.Temperature);
            
            VBA = sprintf(['With Units\n',...
                '.Geometry "%s"\n',...
                '.Frequency "%s"\n',...
                '.Time "%s"\n',...
                '.TemperatureUnit "%s"\n',...
                '.Voltage "V"\n',...
                '.Current "A"\n',...
                '.Resistance "Ohm"\n',...
                '.Conductance "Siemens"\n',...
                '.Capacitance "PikoF"\n',...
                '.Inductance "NanoH"\n',...
                'End With' ],geom,freq,time,temp);
            
            obj.update('Set Units',VBA);
            
        end
        function addBrick(obj,X,Y,Z,name,component,material,varargin)
            p = inputParser;
            p.addParameter('color',[])
            
            p.parse(varargin{:});
            C = p.Results.color;
            C = C*128;
            
            X = obj.checkParam(X);
            Y = obj.checkParam(Y);
            Z = obj.checkParam(Z);
            
            VBA = sprintf(['With Brick\n',...
                '.Reset\n',...
                '.Name "%s"\n',...
                '.Component "%s"\n',...
                '.Material "%s"\n',...
                '.XRange "%s", "%s"\n',...
                '.YRange "%s", "%s"\n',...
                '.ZRange "%s", "%s"\n',...
                '.Create\n',...
                'End With'],...
                name,component,material,X(1),X(2),Y(1),Y(2),Z(1),Z(2));
            
            obj.update(['define brick: ',component,':',name],VBA);
            
            %Change color if required
            if ~isempty(C)
                s = obj.mws.invoke('Solid');
                s.invoke('SetUseIndividualColor',[component,':',name],'1');
                s.invoke('ChangeIndividualColor',[component,':',name],num2str(C(1)),num2str(C(2)),num2str(C(3)));
            end
        end
        function mergeCommonSolids(obj,component)
            %CST.mergeCommonSolids(component) will merge all solids in the
            % named components that share the same material. It seems to be
            % much quicker than calling booleanAdd for each pair of
            % individually.
            % See SinusoidSurface example for extra information
            obj.update(['Merge Common Materials:',component],['Solid.MergeMaterialsOfComponent "',component,'"']);
        end
        function insertObject(obj,object1,object2)
            %Insert objects into each other
            VBA = sprintf('Solid.Insert "%s", "%s"',object1,object2);
            obj.update(sprintf('Boolean Insert Shapes:%s,%s',object1,object2),VBA);
            
        end
        function subtractObject(obj,object1,object2)
            %Insert objects into each other
            VBA = sprintf('Solid.Subtract "%s", "%s"',object1,object2);
            obj.update(sprintf('Boolean Subtract Shapes:%s,%s',object1,object2),VBA);
            
        end
        function intersectObjects(obj,object1,object2)
            %Insert objects into each other
            VBA = sprintf('Solid.Intersect "%s", "%s"',object1,object2);
            obj.update(sprintf('Boolean Intersect Shapes:%s,%s',object1,object2),VBA);
            
        end
        function addNormalMaterial(obj,name,Eps,Mue,C,varargin)
            %addNormalMaterial(obj,name,Eps,Mue,C)
            %Add a new 'Normal' material to the CST project
            %Optional arguments are 'tand', 'sigma', 'tandM', 'sigmaM', all of which have a default value of 0
            %Any of the arguments can be CST parameters and can be input as strings, as long as they already exist in
            %the CST Parameter List
            
            p = inputParser;
            p.addParameter('tand',0);
            p.addParameter('sigma',0);
            p.addParameter('tandM',0);
            p.addParameter('sigmaM',0);
            p.parse(varargin{:});
            
            tandGiven = 'False';
            tandMGiven = 'False';
            if p.Results.tand ~= 0; tandGiven = 'True'; end
            if p.Results.tandM ~= 0; tandMGiven = 'True'; end
            
            %Check if input args are parameters or strings
            Eps = obj.checkParam(Eps);
            Mue = obj.checkParam(Mue);
            tand = obj.checkParam(p.Results.tand);
            sigma = obj.checkParam(p.Results.sigma);
            tandM = obj.checkParam(p.Results.tandM);
            sigmaM = obj.checkParam(p.Results.sigmaM);
                       
            VBA =  sprintf(['With Material\n',...
                '.Reset\n',...
                '.Name "%s"\n',...
                '.Type "Normal"\n',...
                '.Epsilon "%s"\n',...
                '.Mue "%s"\n',...
                '.TanD "%s"\n',...
                '.TanDFreq "0.0"\n',...
                '.TanDGiven "%s"\n',...
                '.TanDModel "ConstTanD"\n',...
                '.Sigma "%s"\n',...
                '.TanDM "%s"\n',...
                '.TanDMFreq "0.0"\n',...
                '.TanDMGiven "%s"\n',...
                '.TanDMModel "ConstTanD"\n',...
                '.SigmaM "%s"\n',...
                '.Colour "%f", "%f", "%f"\n',...
                '.Create\n',...
                'End With'],...
                name,Eps,Mue,tand,tandGiven,sigma,tandM,tandMGiven,sigmaM,C(1),C(2),C(3));
            obj.update(['define material: ',name],VBA);
        end
        function addAnisotropicMaterial(obj,name,Eps,Mue,C)
            Eps = obj.checkParam(Eps);
            Mue = obj.checkParam(Mue);
            VBA =  sprintf(['With Material\n',...
                '.Reset\n',...
                '.Name "%s"\n',...
                '.Type "Anisotropic"\n',...
                '.EpsilonX "%s"\n',...
                '.EpsilonY "%s"\n',...
                '.EpsilonZ "%s"\n',...
                '.MueX "%s"\n',...
                '.MueY "%s"\n',...
                '.MueZ "%s"\n',...
                '.Colour "%f", "%f", "%f"\n',...
                '.Create\n',...
                'End With'],...
                name,Eps(1),Eps(2),Eps(3),Mue(1),Mue(2),Mue(3),C(1),C(2),C(3));
            obj.update(['define material: ',name],VBA);
        end
        function addDispersiveMaterial(obj,name,F,Eps,tanD,delta,C,varargin)
            %addDispersiveMaterial(obj,name,Eps,Mue,C)
            %Add a material with user-defined dispersive properties to the CST project
            %F, Eps, tanD and delta are arrays with the same number of elements representing the frequency points, real
            %permittivity, loss tangent, and weighting values of the dispersive material
            %Optional arguments are 'N', 'errorLimit', which have a default value of 10 and 0.1
            %Currently only working for dielectric materials
            
            p = inputParser;
            p.addParameter('N',10);
            p.addParameter('errorLimit',0.1);
            p.parse(varargin{:});
            
                       
            VBA1 =  sprintf(['With Material\n',...
                '.Reset\n',...
                '.Name "%s"\n',...
                '.DispModelEps "None"\n',...
                '.DispModelMu "None"\n',...
                '.DispersiveFittingSchemeEps "Nth Order"\n',...
                '.MaximalOrderNthModelFitEps "%d"\n',...
                '.ErrorLimitNthModelFitEps "%.2f"\n',...
                '.UseOnlyDataInSimFreqRangeNthModelEps "False"\n',...
                '.DispersiveFittingSchemeMu "Nth Order"\n',...
                '.MaximalOrderNthModelFitMu "%d"\n',...
                '.ErrorLimitNthModelFitMu "%.2f"\n',...
                '.UseOnlyDataInSimFreqRangeNthModelMu "False"\n',...
                '.DispersiveFittingFormatEps "Real_Tand"\n',...
                '.Colour "%f", "%f", "%f"\n',...
                ],...
                name,p.Results.N,p.Results.errorLimit,p.Results.N,p.Results.errorLimit,C(1),C(2),C(3));
            
            VBA2 = [];
            for i = 1:numel(F)
            VBA2 = [VBA2,...
                sprintf('.AddDispersionFittingValueEps "%.3f", "%.3f", "%.3f", "%.2f"\n',F(i),Eps(i),tanD(i),delta(i))]; %#ok<AGROW>
            end
            
            VBA = sprintf([VBA1,VBA2,...
            '.UseGeneralDispersionEps "True"\n',...
            '.UseGeneralDispersionMu "False"\n',...
            '.Create\n',...
                'End With']);
            
            obj.update(['define material: ',name],VBA);
            
        end
        function addDiscretePort(obj,X,Y,Z,R,impedance)
            %Add a discrete line source in the positions defined by the X, Y and Z
            %inputs, with radius, R, and impedance defined by the other
            %input arguments
            %
            % Example:
            % %Add a Z-directed line source of 20 units long at point XY = [0,5]
            % CST.addDiscretePort([0 0], [5 5], [-10 10], 1, 50)
            if nargin  < 5
                R = 0;
            end
            if nargin <6
                impedance = 50;
            end
            
            X = obj.checkParam(X);
            Y = obj.checkParam(Y);
            Z = obj.checkParam(Z);
            R = obj.checkParam(R);
            impedance = obj.checkParam(impedance);
            
            
            %Get the total next available port number
            p = obj.mws.invoke('Port');
            portNumber = p.invoke('StartPortNumberIteration') + 1;
            
            VBA =  sprintf(['With DiscretePort\n',...
                '.Reset\n',...
                '.Type "SParameter"\n',...
                '.PortNumber "%d"\n'...
                '.SetP1 "False", "%s", "%s", "%s"\n',...
                '.SetP2 "False", "%s", "%s", "%s"\n',...
                '.Impedance "%s"\n',...
                '.Radius "%s"\n',...
                '.Create\n',...
                'End With'],...
                portNumber, X(1),Y(1),Z(1),X(2),Y(2),Z(2),impedance,R);
            
            obj.update(['define discrete port: ',num2str(portNumber)],VBA);
        end
        function addWaveguidePort(obj,orientation,X,Y,Z,varargin)
            % Add a wave guide port to the simulation file.
            % CST.addWaveguidePort(orientation,X,Y,Z) adds a wavegiude port
            % oriented in one of the X,Y,Z planes. Orientation can
            % be one of the following strings:
            % 'xmin' 'xmax', 'ymin', 'ymax', 'zmin', 'zmax'
            % The port should be in the direction away from the defined
            % orientation (an 'xmin' orineted port will propogate towards
            % the xmax boundary). The cooridnates associated with the
            % plane of the port should contain two equal values, or a
            % single values indicating the position of the port.
            % Examples:
            % % Add a 5 x 10 (X x Y) units port at the z=5 position propagating towards zmin.
            % CST = CST_MicrowaveStudio(cd,'test');
            % CST.addWaveguidePort('zmax',(0 5),(0 10), 5)
            %
            % portNumber is obsolete and will be removed in future release
            
            %Orientation defines the direction of the port
            switch lower(orientation)
                case{'xmin','xmax'}
                    if numel(X) == 1
                        X(2) = X(1);
                    end
                    
                case {'ymin','ymax'}
                    if numel(Y) == 1
                        Y(2) = Y(1);
                    end
                case {'zmin','zmax'}
                    if numel(Z) == 1
                        Z(2) = Z(1);
                    end
                otherwise
                    warning('Invalid port orientation')
                    return
            end
            
            X = obj.checkParam(X);
            Y = obj.checkParam(Y);
            Z = obj.checkParam(Z);
            
            p = obj.mws.invoke('Port');
            portNumber = p.invoke('StartPortNumberIteration') + 1;
            
            VBA = sprintf(['With Port\n'...
                '.Reset\n'...
                '.PortNumber "%d"\n'...
                '.Label ""\n'...
                '.Folder ""\n'...
                '.NumberOfModes "1"\n'...
                '.AdjustPolarization "False"\n'...
                '.PolarizationAngle "0.0"\n'...
                '.ReferencePlaneDistance "0"\n'...
                '.TextSize "50"\n'...
                '.TextMaxLimit "1"\n'...
                '.Coordinates "Free"\n'...
                '.Orientation "%s"\n'...
                '.PortOnBound "False"\n'...
                '.ClipPickedPortToBound "False"\n'...
                '.Xrange "%s", "%s"\n'...
                '.Yrange "%s", "%s"\n'...
                '.Zrange "%s", "%s"\n'...
                '.XrangeAdd "0.0", "0.0"\n'...
                '.YrangeAdd "0.0", "0.0"\n'...
                '.ZrangeAdd "0.0", "0.0"\n'...
                '.SingleEnded "False"\n'...
                '.WaveguideMonitor "False"\n'...
                '.Create\n'...
                'End With'],...
                portNumber,orientation,X(1),X(2),Y(1),Y(2),Z(1),Z(2));
            
            obj.update(['define waveguide port: ',num2str(portNumber)],VBA);
        end
        function addFieldMonitor(obj,fieldType,freq)
            % Add a field monitor at specified frequency
            % Field type can be one of the following strings:
            % 'Efield', 'Hfield', 'Surfacecurrent', 'Powerflow', 'Current',
            % 'Powerloss', 'Eenergy', 'Elossdens', 'Lossdens', 'Henergy',
            % 'Farfield', 'Temperature', 'Fieldsource', 'Spacecharge',
            % 'ParticleCurrentDensity' or 'Electrondensity'.
            % Examples:
            % CST = CST_MicrowaveStudio(cd,'test');
            % CST.AddMonitor('Efield',2.4);
            % CST.AddMonitor('farfield',10);
            
            %Try to implment default CST naming strings
            switch lower(fieldType)
                case 'efield'
                    name = ['e-field',' (f=',num2str(freq),')'];
                case 'hfield'
                    name = ['h-field',' (f=',num2str(freq),')'];
                otherwise
                    name = [fieldType,' (f=',num2str(freq),')'];
            end
            
            VBA =  sprintf(['With Monitor\n',...
                '.Reset\n',...
                '.Name "%s"\n',...
                '.Dimension "Volume"\n',...
                '.Domain "Frequency"\n',...
                '.FieldType "%s"\n',...
                '.Frequency "%f"\n',...
                '.UseSubVolume "False"\n',...
                '.Create\n',...
                'End With'],...
                name,fieldType,freq);
            obj.update(['define field monitor: ',name],VBA);
            
        end
        function setBackgroundLimits(obj,X,Y,Z)
            %CST.setBackgroundLimits sets the backgroun limits in the model
            %in the +/-X, +/-Y, and +/-Z directions, as specified.
            
            %Limits should always be positive
            X = abs(X);
            Y = abs(Y);
            Z = abs(Z);
            
            X = obj.checkParam(X);
            Y = obj.checkParam(Y);
            Z = obj.checkParam(Z);
            
            VBA = sprintf(['With Background\n',...
                '.XminSpace "%s"\n',...
                '.XmaxSpace "%s"\n',...
                '.YminSpace "%s"\n',...
                '.YmaxSpace "%s"\n',...
                '.ZminSpace "%s"\n',...
                '.ZmaxSpace "%s"\n',...
                '.ApplyInAllDirections "False"\n',...
                'End With'],...
                X(1),X(2),Y(1),Y(2),Z(1),Z(2));
            obj.update('define background',VBA);
            
        end
        function addSymmetryPlane(obj,planeNormal,symType)
            %addSymmetryPlane(planeNormal,symType) sets the specified plane
            %to the defined symmetry type.
            % Examples:
            % CST = CST_MicrowaveStudio(cd,'test');
            % CST.addSymetryPlane('X','magnetic')
            
            VBA = sprintf(['With Boundary\n',...
                '.%ssymmetry "%s"\n',...
                'End With'],...
                planeNormal,symType);
            obj.update(['define boundary: ',planeNormal,' normal'],VBA);
        end
        function setBoundaryCondition(obj,varargin)
            %Set the boundary conditions for CST MWS simulation:
            % Examples:
            % CST.setBoundaryCondition('Xmin','Open add space')
            % CST.setBoundaryCondition('YMin','Electric Wall','YMin','Magnetic Wall')
            % CST.setBoundaryCondition('ZMin','Periodic')
            %
            % Options:
            % Boundaries - 'Xmin','Xmax','Ymin','Ymax','Zmin','Zmax'
            % Boundary Type - 'Open','Open add space','Electric',
            % 'Magnetic','Periodic','Unit cell','conducting wall'
            % Note: 'Unit Cell boundaries can only be applied in X and Y
            % directions'
            
            boundaries = {'Xmin','Xmax','Ymin','Ymax','Zmin','Zmax'};
            str = '';
            for i = 1:2:numel(varargin)
                
                boundary = [upper(varargin{i}(1)),lower(varargin{i}(2:end))];
                
                if any(strcmp(boundary,boundaries))
                    
                    switch lower(varargin{i+1})
                        case {'open add space','open (add space)'}
                            boundaryType = 'expanded open';
                        otherwise
                            boundaryType = varargin{i+1};
                    end
                    
                    str = [str,'.',boundary,' "',boundaryType,'"\n']; %#ok<AGROW>
                else
                    warning('Unrecognised boundary "%s". Boundary condition ignored', boundary);
                end
            end
            VBA = sprintf(['With Boundary\n',...
                str,...
                'End With',...
                ]);
            
            obj.update('define boundaries',VBA);
            
            if any(strcmpi(varargin,'unit cell'))
                %Set Floquet port mode to 2 (default - 18)
                VBA = sprintf(['With FloquetPort\n',...
                    '.Reset\n',...
                    '.SetDialogTheta "0"\n',...
                    '.SetDialogPhi "0"\n',...
                    '.SetPolarizationIndependentOfScanAnglePhi "0.0", "False"\n',...
                    '.SetSortCode "+beta/pw"\n',...
                    '.SetCustomizedListFlag "False"\n',...
                    '.Port "Zmin"\n',...
                    '.SetNumberOfModesConsidered "2"\n',...
                    '.SetDistanceToReferencePlane "0.0"\n',...
                    '.SetUseCircularPolarization "False"\n',...
                    '.Port "Zmax"\n',...
                    '.SetNumberOfModesConsidered "2"\n',...
                    '.SetDistanceToReferencePlane "0.0"\n',...
                    '.SetUseCircularPolarization "False"\n',...
                    'End With']);
                obj.update('define Floquet Port boundaries',VBA);
                
                
            end
        end
        function addPolygonBlock(obj,points,height,name,component,material,varargin)
            %add a polygon with any number of sides to the simulations
            %space. Polygon will be aligned in the x-y plane
            p = inputParser;
            p.addParameter('color',[])
            p.addParameter('zmin',0)
            p.parse(varargin{:});
            C = p.Results.color;
            C = C*128;
            zmin = p.Results.zmin;
            %VBA = cell(0,1);
            
            height = obj.checkParam(height);
            zmin = obj.checkParam(zmin);
            
            VBA = sprintf(['With Extrude\n',...
                '.Reset\n',...
                '.Name "%s"\n',...
                '.Component "%s"\n',...
                '.Material "%s"\n',...
                '.Mode "pointlist"\n',...
                '.Height "%s"\n',...
                '.Twist "0.0"\n',...
                '.Taper "0.0"\n',...
                '.Origin "0.0", "0.0", "%s"\n',...
                '.Uvector "1.0", "0.0", "0.0"\n',...
                '.Vvector "0.0", "1.0", "0.0"\n',...
                '.Point "%f", "%f"\n'],...
                name,component,material,height,zmin,points(1,1),points(1,2));
            
            VBA2 = [];
            for i = 2:length(points)
                VBA2 = [VBA2,sprintf('.LineTo "%f", "%f"\n', points(i,1),points(i,2))]; %#ok<AGROW>
            end
            VBA = [VBA,VBA2,sprintf('.create\nEnd With')];
            
            obj.update(['define brick: ',component,':',name],VBA);
            
            %Change color if required
            if ~isempty(C)
                s = obj.mws.invoke('Solid');
                s.invoke('SetUseIndividualColor',[component,':',name],'1');
                s.invoke('ChangeIndividualColor',[component,':',name],num2str(C(1)),num2str(C(2)),num2str(C(3)));
            end
            
        end
        function addPolygonBlock3D(obj,points,thickness,name,component,material,varargin)
            %Add a block in any plane using 3-column coordinates
            p = inputParser;
            p.addParameter('color',[])
            p.addParameter('curve','3dpolygon1')
            p.addParameter('curveName','curve1')
            p.parse(varargin{:});
            C = p.Results.color;
            C = C*128;
            thickness = obj.checkParam(thickness);
            %VBA = cell(0,1);
            
            VBA = sprintf(['With Polygon3D\n',...
                '.Reset\n',...
                '.Name "%s"\n',...
                '.Curve "%s"\n',...
                '.Point "%f", "%f", "%f"\n'],...
                p.Results.curve,p.Results.curveName,points(1,1),points(1,2),points(1,3));
            
            VBA2 = [];
            for i = 2:length(points)
                VBA2 = [VBA2,sprintf('.Point "%f", "%f", "%f"\n', points(i,1),points(i,2),points(i,3))]; %#ok<AGROW>
            end
            VBA = [VBA,VBA2,sprintf('.create\nEnd With')];
            
            obj.update(['define curve: ',p.Results.curve,':',p.Results.curveName],VBA);
            
            VBA = sprintf(['With ExtrudeCurve\n',...
                '.Reset\n',...
                '.Name "%s"\n',...
                '.Component "%s"\n',...
                '.Material "%s"\n',...
                '.Thickness  "%s"\n',...
                '.Twistangle "0.0"\n',...
                '.Taperangle "0"\n',...
                '.DeleteProfile "True"\n',...
                '.Curve "%s:%s"\n',...
                '.Create\nEnd With'],...
                name,component,material,thickness,p.Results.curveName,p.Results.curve);
            
            obj.update(['define extrudeprofile: ',component,':',name],VBA);
            
            %Change color if required
            if ~isempty(C)
                s = obj.mws.invoke('Solid');
                s.invoke('SetUseIndividualColor',[component,':',name],'1');
                s.invoke('ChangeIndividualColor',[component,':',name],num2str(C(1)),num2str(C(2)),num2str(C(3)));
            end
        end
        function addCurve3D(obj,points,varargin)
            p = inputParser;
            p.addParameter('curve','3dpolygon1')
            p.addParameter('curveName','curve1')
            p.parse(varargin{:});
            
            VBA = sprintf(['With Polygon3D\n',...
                '.Reset\n',...
                '.Name "%s"\n',...
                '.Curve "%s"\n',...
                '.Point "%f", "%f", "%f"\n'],...
                p.Results.curve,p.Results.curveName,points(1,1),points(1,2),points(1,3));
            
            VBA2 = [];
            for i = 2:length(points)
                VBA2 = [VBA2,sprintf('.Point "%f", "%f", "%f"\n', points(i,1),points(i,2),points(i,3))]; %#ok<AGROW>
            end
            VBA = [VBA,VBA2,sprintf('.create\nEnd With')];
            
            obj.update(['define curve: ',p.Results.curve,':',p.Results.curveName],VBA);
        end
        function addHelix(obj,r0,h,n,h1,r1,name,component,material,varargin)
            %Add a helix with radius r0, turn height h, number of turns n, base height h1 and wire radius r1 to the CST
            %model
            
            p = inputParser;
            p.addParameter('curve','3dpolygon1')
            p.addParameter('curveName','helix1')
            p.addParameter('nTheta',37)
            p.parse(varargin{:});
            
            nTheta = p.Results.nTheta;
            theta = deg2rad(0:360/(nTheta-1):360);
            Z = 0:h/(nTheta-1):h;
            R = ones(1,numel(theta))*r0;

            theta(end) = [];
            Z(end) = [];
            R(end) = [];

            theta = repmat(theta,1,n)';
            R = repmat(R,1,n)';
            Z = repmat(Z,n,1)';
            for i = 1:n
                Z(:,i) = Z(:,i)+(i-1)*h;
            end
            Z = Z(:);
            
            theta(end+1) = deg2rad(360);
            R(end+1) = r0;
            Z(end+1) = n*h;
            
            [X,Y,Z] = pol2cart(theta,R,Z);
            
            X = [X(1);X]; 
            Y = [Y(1);Y]; 
            Z = Z+h1;
            Z = [0;Z]; 
            
            obj.addCurve3D([X,Y,Z],'curve',p.Results.curve,'curveName',p.Results.curveName);
            
            VBA = sprintf(['With Circle\n',...
                '.Reset\n',...
                '.Name "helix_circle1"\n',...
                '.Curve "curve1"\n',...
                '.Radius "%f"\n',...
                '.Xcenter "%f"\n',...
                '.Ycenter "%f"\n',...
                '.Segments "0"\n',...
                '.Create\n',...
                'End With'],r1,X(1),Y(1));
            obj.update('define curveCircle: curve1:helix_circle1',VBA);
            
            obj.sweepCurve([p.Results.curveName,':',p.Results.curve],'curve1:helix_circle1',name,component,material);
        end
        function sweepCurve(obj,sweepPath,sweepCurve,name,component,material,varargin)
            
            
            p = inputParser;
            p.addParameter('twistAngle',0);
            p.addParameter('taperAngle',0);
            
            p.parse(varargin{:});
            
            VBA = sprintf(['With SweepCurve\n',...
                '.Reset\n',...
                '.Name "%s"\n',...
                '.Component "%s"\n',...
                '.Material "%s"\n',...
                '.Twistangle "%.1f"\n',...
                '.Taperangle "%.1f"\n',...
                '.ProjectProfileToPathAdvanced "True"\n',...
                '.CutEndOff "True"\n',...
                '.DeleteProfile "True"\n',...
                '.DeletePath "True"\n',...
                '.Path "%s"\n',...
                '.Curve "%s"\n',...
                '.Create\n',...
                'End With'],name,component,material,p.Results.twistAngle',p.Results.taperAngle,sweepPath,sweepCurve);
            
            obj.update(['define sweepProfile: ',[component,':',name]],VBA);
            
        end
        function connectFaces(obj,component1,face1,component2,face2,component,name,material)
            %Connect two face to form a solid block. This is useful if
            %trying to create 3D surfaces with thickness > 0. See Sinusoid
            %Surface Example
            
            VBA = sprintf('Pick.PickFaceFromId "%s:%s", "1" ',component1,face1);
            obj.update('pick face',VBA);
            VBA = sprintf('Pick.PickFaceFromId "%s:%s", "1" ',component2,face2);
            obj.update('pick face',VBA);
            
            VBA = sprintf(['With Loft\n',...
                '.Reset\n',...
                '.Name "%s"\n',...
                '.Component "%s"\n',...
                '.Material "%s"\n',...
                '.Tangency "0.0"\n',...
                '.Minimizetwist "true"\n',...
                '.CreateNew\n',...
                'End With',...
                ],name,component,material);
            
            obj.update(['define loft: ',component,':',name],VBA);
        end
        function addCylinder(obj,R1,R2,orientation,X,Y,Z,name,component,material)
            
            R1 = obj.checkParam(R1);
            R2 = obj.checkParam(R2);
            X = obj.checkParam(X);
            Y = obj.checkParam(Y);
            Z = obj.checkParam(Z);
            
            VBA = sprintf(['With Cylinder\n',...
                '.Reset\n',...
                '.Name "%s"\n',...
                '.Component "%s"\n',...
                '.Material "%s"\n',...
                '.OuterRadius "%s"\n',...
                '.InnerRadius "%s"\n',...
                '.Axis "%s"\n'],...
                name,component,material,R1,R2,lower(orientation));
            
            switch lower(orientation)
                case 'z'
                    VBA2 = sprintf([VBA,...
                        '.Zrange "%s", "%s"\n',...
                        '.Xcenter "%s"\n',...
                        '.Ycenter "%s"\n',...
                        '.Segments "0"\n',...
                        '.Create\n',...
                        'End With'],...
                        Z(1),Z(2),X,Y);
                case 'y'
                    VBA2 = sprintf([VBA,...
                        '.Yrange "%s", "%s"\n',...
                        '.Xcenter "%s"\n',...
                        '.Zcenter "%s"\n',...
                        '.Segments "0"\n',...
                        '.Create\n',...
                        'End With'],...
                        Y(1),Y(2),X,Z);
                case 'x'
                    VBA2 = sprintf([VBA,...
                        '.Xrange "%s", "%s"\n',...
                        '.Ycenter "%s"\n',...
                        '.Zcenter "%s"\n',...
                        '.Segments "0"\n',...
                        '.Create\n',...
                        'End With'],...
                        X(1),X(2),Y,Z);
            end
            
            obj.update(['define cylinder:',component,':',name],VBA2);
            
            %obj.update(['define cylinder:',component,':',name],VBA);
            
        end
        function addECylinder(obj,R1,R2,orientation,X,Y,Z,name,component,material)
            if ~strcmpi(orientation,'z')
                warning('Only Z-orientated cylinders are currently allowed')
                return
            end
            R1 = obj.checkParam(R1);
            R2 = obj.checkParam(R2);
            X = obj.checkParam(X);
            Y = obj.checkParam(Y);
            Z = obj.checkParam(Z);
            VBA = sprintf(['With ECylinder\n',...
                '.Reset\n',...
                '.Name "%s"\n',...
                '.Component "%s"\n',...
                '.Material "%s"\n',...
                '.XRadius "%s"\n',...
                '.YRadius "%s"\n',...
                '.Axis "%s"\n',...
                '.Zrange "%s", "%s"\n',...
                '.Xcenter "%s"\n',...
                '.Ycenter "%s"\n',...
                '.Segments "0"\n',...
                '.Create\n',...
                'End With'],...
                name,component,material,R1,R2,lower(orientation),Z(1),Z(2),X,Y);
            obj.update(['define ECylinder:',component,':',name],VBA);
            
            %obj.update(['define cylinder:',component,':',name],VBA);
            
        end
        function addSphere(obj,X,Y,Z,R1,R2,R3,name,component,material,varargin)
            if R2 > R1 || R3 > R1
                warning('Center Radius (R1) must be larger than top (R2) and bottom (R3) radii\nExiting without adding sphere');
                return
            end
            
            X = obj.checkParam(X);
            Y = obj.checkParam(Y);
            Z = obj.checkParam(Z);
            
            p = inputParser;
            p.addParameter('orientation','z');
            p.addParameter('segments',0);
            p.parse(varargin{:})
            
            %add the following to input parser
            orientation = p.Results.orientation;
            segments = p.Results.segments;
            
            VBA = sprintf(['With Sphere\n',...
                '.Reset \n',...
                '.Name "%s"\n',...
                '.Component "%s"\n',...
                '.Material "%s"\n',...
                '.Axis "%s"\n',...
                '.CenterRadius "%f"\n',...
                '.TopRadius "%f"\n',...
                '.BottomRadius "%f"\n',...
                '.Center "%s", "%s", "%s"\n',...
                '.Segments "%d"\n',...
                '.Create\n',...
                'End With'],...
                name,component,material,orientation,R1,R2,R3,X,Y,Z,segments);
            
            obj.update(['define sphere:',component,':',name],VBA);
            
        end
        function addSParamMaterialThinPanel(obj,name,S11,S21,freq,impedance,c)
            
            %S11_r = real(S11);
            %S11_i = imag(S11);
            %S21_r = real(S21);
            %S21_i = imag(S21);
            
            VBA = sprintf(['With Material \n',...
                '.Reset\n',...
                '.Name "%s"\n',...
                '.Folder ""\n',...
                '.ThinPanel "True"\n',...
                '.ReferenceCoordSystem "Global"\n',...
                '.CoordSystemType "Cartesian"\n',...
                '.SetCoatingTypeDefinition "SMATRIX_TABLE"\n',...
                '.ResetTabulatedCompactModelList\n',...
                '.MaximalOrderFitTabulatedCompactModel "6"\n',...
                '.ErrorLimitFitTabulatedCompactModel "0.01"\n',...
                '.UseOnlyDataInSimFreqRangeTabulatedCompactModel "True"\n',...
                '.SetSymmTabulatedCompactModelImpedance "%.2f"\n',... %impedance
                '.TabulatedCompactModelAnisotropic "False"\n',...
                '.NLAnisotropy "False"\n',...
                '.Colour "%.2f", "%.2f", "%.2f" \n',... %c(1) c(2) c(3)
                '.MaterialUnit "Frequency", "GHz"\n',...
                ],name,impedance,c(1),c(2),c(3));
            
            VBA2 = [];
            for i = 1:length(freq)
                S11_r = real(S11);
                S11_i = imag(S11);
                S21_r = real(S21);
                S21_i = imag(S21);
                
                VBA2 = [VBA2,sprintf('.AddSymmTabulatedCompactModelItem "%.2f", "%.2f", "%.2f", "%.2f", "%.2f", "1"\n',...
                    freq(i),S11_r,S11_i,S21_r,S21_i)]; %#ok<AGROW>
            end
            VBA = [VBA,VBA2,sprintf('.Create\nEnd With')];
            
            obj.update(['define Material:',name],VBA);
        end
        function translateObject(obj,name,x,y,z,copy,varargin)
            
            if copy
                copy = 'True';
            else
                copy = 'False';
            end
            
            p = inputParser;
            p.addParameter('repetitions',1);
            p.addParameter('material','');
            p.addParameter('destination','');
            p.parse(varargin{:})
            
            x = obj.checkParam(x);
            y = obj.checkParam(y);
            z = obj.checkParam(z);
            
            VBA = sprintf(['With Transform\n',...
                '.Reset \n',...
                '.Name "%s"\n',...
                '.Vector "%s", "%s", "%s"\n',...
                '.UsePickedPoints "False"\n',...
                '.InvertPickedPoints "False"\n',...
                '.MultipleObjects "%s"\n',...
                '.GroupObjects "False"\n',...
                '.Repetitions "%d"\n',...
                '.MultipleSelection "False"\n',...
                '.Destination "%s"\n',...
                '.Material "%s"\n',...
                '.Transform "Shape", "Translate"\n',...
                'End With'],...
                name,x,y,z,copy,p.Results.repetitions,p.Results.destination,p.Results.material);
            
            %Check for destination component?
            
            obj.update(['transform:',name],VBA);
        end
        function rotateObject(obj,varargin)
            % CST.rotateObject(objectName,rotationAngles,rotationCenter)
            % Rotates an object defined by objectname of the format
            % (componentName:objectName) by the rotation angle
            % in rotationAngles = [xrot, yrot, zrot] and the center of
            % rotation defined be rotationCenter = [xc, yc,zc];
            %
            % CST.rotateObject(componentName,objectName,rotationAngles,rotationCenter)
            % is the same as above with the component and object names
            % split
            %
            % CST.rotateObject(...,Parmaeter,Value) allows parameter/value
            % inputs of 'Copy' (true/false) and 'repetitions (number of
            % repetitions)
            %
            % This has changed since a previous version
            
            % Old input arg list...
            % (obj,componentName,objectName,rotationAngles,rotationCenter,varargin)
            
            warning('CST_MicrowaveStudio:rotateObject',...
                'The inputparameter list of rotateObject has recently changed and may cause errors. Please see help for correct way to use')
            
            if ischar(varargin{2})
                nameStr = [varargin{1},':',varargin{2}];
                varargin(2) = [];
            else
                nameStr = varargin{1};
            end
            [rotationAngles,rotationCenter] = deal(varargin{2:3});
            %remove varargin(1:3)
            varargin(1:3) = [];
            
            p = inputParser;
            p.addParameter('copy',false);
            p.addParameter('repetitions',1);
            p.parse(varargin{:});
            
            copy = p.Results.copy;
            repetitions = p.Results.repetitions;
            
            if copy
                copyStr = 'True';
            else
                copyStr = 'False';
            end
            
            rotationAngles = obj.checkParam(rotationAngles);
            rotationCenter = obj.checkParam(rotationCenter);
            
            VBA = sprintf(['With Transform\n',...
                '.Reset\n',...
                '.Name "%s"\n',...
                '.Origin "Free"\n',...
                '.Center "%s", "%s", "%s"\n',...
                '.Angle "%s", "%s", "%s"\n',...
                '.MultipleObjects "%s"\n',...
                '.GroupObjects "False"\n',...
                '.Repetitions "%d"\n',...
                '.MultipleSelection "False"\n',...
                '.Transform "Shape", "Rotate"\n',...
                'End With'],...
                nameStr,rotationCenter(1),rotationCenter(2),rotationCenter(3),...
                rotationAngles(1),rotationAngles(2),rotationAngles(3),...
                copyStr,repetitions);
            
            obj.update(['transform: rotate ',nameStr],VBA);
            
        end
        function deleteObject(obj,objectType,objectName)
            %deleteObject(objectType,objectName)
            % Object type is the VBA object type - currently only
            % 'component' and 'solid' are allowed
            % Objectname must include the full component reference, e.g.
            % component1:solid1
            % Example:
            % CST.addBrick([0 1],[0 1],[0 1],'Brick1','component1','PEC');
            % CST.addBrick([1 3],[1 4], [1 4],'Brick2','component2','PEC');
            % pause(3)
            % CST.deleteObject('component','component1');
            % pause(3)
            % CST.deleteObject('solid','component2:Brick2');
            
            
            switch lower(objectType)
                case{'component','solid'}
                    
                otherwise
                    error('You cannot currently delete %s programatically, please send a request to h.giddens@qmul.ac.uk',objectType);
            end
            
            obj.update(['delete ',objectType,': ',objectName],[objectType,'.Delete "',objectName,'" ']);
        end
        function addComponent(obj,component)
            %addComponent  add a new co
            obj.update(['new component:',component],['Component.New "',component,'"']);
        end
        function setFreq(obj,F1,F2)
            if nargin == 2
                F2 = F1(2);
                F1 = F1(1);
            end
            obj.update('SetFrequency',sprintf('Solver.FrequencyRange "%f", "%f"',F1,F2));
            %obj.F1 = F1;
            %obj.F2 = F2;
        end
        
        function setSolver(obj,solver)
            switch lower(solver)
                case {'frequency','f','freq'}
                    VBA = 'ChangeSolverType "HF Frequency Domain"';
                    obj.solver = 'f';
                case {'time','time domain','td','t'}
                    VBA = 'ChangeSolverType "HF Time Domain" ';
                    obj.solver = 't';
            end
            obj.update('change solver type',VBA);
            
        end
        function defineFloquetModes(obj,nModes)
            
            VBA = sprintf(['With FloquetPort\n',...
                '.Reset\n',...
                '.SetDialogTheta "0"\n',...
                '.SetDialogPhi "0"\n',...
                '.SetPolarizationIndependentOfScanAnglePhi "0.0", "False"\n',...
                '.SetSortCode "+beta/pw"\n',...
                '.SetCustomizedListFlag "False"\n',...
                '.Port "Zmin"\n',...
                '.SetNumberOfModesConsidered "%d"\n',...
                '.SetDistanceToReferencePlane "0.0"\n',...
                '.SetUseCircularPolarization "False"\n',...
                '.Port "Zmax"\n',...
                '.SetNumberOfModesConsidered "%d"\n',...
                '.SetDistanceToReferencePlane "0.0"\n',...
                '.SetUseCircularPolarization "False"\n',...
                'End With'],nModes,nModes);
            obj.update('define Floquet Port boundaries',VBA);
        end
        function runSimulation(obj)
            switch obj.solver
                case 'f'
                    s = obj.mws.invoke('FDSolver'); % handle to frequency domain solver
                case 't'
                    s = obj.mws.invoke('Solver');   % handle to time domain solver
            end
            tStart = tic;
            fprintf('Simulation Running...\n') 
            s.invoke('Start');
            fprintf('Simulation Finished\n');
            toc(tStart)
        end
        function [freq,sparam,sparamType] = getSParams(obj,varargin)
            %Get the S-Parameter results from CST
            % CST.getSParams on its own returns all sparam results for Run ID = 0
            % CST.getSParams(SParamType) returns the sparameters specified by the string SParamType for Run ID = 0.
            % CST.getSParams(RunID) returns all the sparameters specified by the number in RunID if it is available.
            
            % Examples:
            % [freq, sparams, stype] = CST.getSParams('s11') % returns only the s11 results for Run ID = 0
            % [freq, sparams, stype] = CST.getSParams('S11',4) % returns the s11 results for run ID 4 only
            % [freq, sparams, stype] = CST.getSParams(2) % returns all sparameter results for run ID 2 only
            % [freq, sparams, stype] = CST.getSParams(-1)% returns all sparameter results for all run IDs
            % [freq, sparams, stype] = CST.getSParams('s11',-1) % returns the s11 results for all run IDs
            %
            % To get a list of all available S-Parameters and the strings which should be used in the first argument use
            % CST.getSParamStrings. To get the Run IDs use CST.getRunIDs.
            % 
            % See Examples\ManagingSParameters.m for more help information.
            
            %First check input arguments
            numInputArgs = numel(varargin);
            
            if numInputArgs == 0
                %return all sparam results for run ID 0
                sparamstring = '';
                runID = 0;
            elseif numInputArgs == 1
                if isnumeric(varargin{1})
                    %All Sparams for RUN ID in varargin{1}
                    sparamstring = '';
                    runID = varargin{1};
                elseif isstring(varargin{1}) || ischar(varargin{1}) || iscell(varargin{1})
                    %Sparam specified in varargin{1} but for all RUN IDs
                    sparamstring = varargin{1};
                    runID = 0;
                end
            elseif numInputArgs == 2
                    % Both the Run ID and SParam type have been specified
                   sparamstring = varargin{1};
                   runID = varargin{2};
            elseif numInputArgs > 2 
                error('Too many input arguments have been specified');
            end
            
            %Search for all available s-parameters
            resultTree = obj.mws.invoke('resultTree');
            [sparamtype,fullSParamString] = obj.getSParamStrings; %#ok<ASGLU>
            
            %Determine number of RunIDs
            [resultIDs,resultIDStrings] = obj.getRunIDs; 
            
            if any(runID < 0) % negative number indicates output of all run IDs
                runID = resultIDs;
            end
            
            %Try to determine the s-parameter type from some commmon strings:
            if isempty(sparamstring) %output all sparam types
                sparamstring = sparamtype;
                
            elseif iscell(sparamstring)
                for iS = 1:numel(sparamstring)
                    if numel(sparamstring{iS}) == 3 %sparamstring likely input in format 's11', 's21', but we need a comma in between the numbers
                        sparamstring{iS} = upper([sparamstring{iS}(1:2),',',sparamstring{iS}(3)]);
                    end
                end
            elseif isstring(sparamstring) || ischar(sparamstring) 
                if numel(sparamstring) == 3 %sparamstring likely input in format 's11', 's21', but we need a comma in between the numbers
                    sparamstring = upper([sparamstring(1:2),',',sparamstring(3)]);
                end
                sparamstring = {sparamstring};
            end
            
            nS = numel(sparamstring);
            nRun = numel(runID);
            
            %Use the first RunID to get frequency and if it isnt available output error
            idx = runID(1) == resultIDs;
            if any(idx)
                result1D = resultTree.invoke('GetResultFromTreeItem',['1D Results\S-Parameters\',sparamstring{1}],resultIDStrings{idx});
            else
               error('CST_MicrowaveStudio:ResultsMissing','Results are missing for Run ID "%d" so an matrix of NaNs has been returned in its place',runID(1))
            end
            freq = result1D.invoke('GetArray','x');
            freq = freq(:);
            nFreq = numel(freq);
            
            sparam = zeros(nFreq,nS,nRun);
            sparamType = cell(1,nS,nRun);
            
            for iRun = 1:nRun
                for iS = 1:nS
                    idx = runID(iRun) == resultIDs; 
                    
                    try
                    result1D = resultTree.invoke('GetResultFromTreeItem',['1D Results\S-Parameters\',sparamstring{iS}],resultIDStrings{idx});
                    catch 
                        warning('CST_MicrowaveStudio:ResultsMissing','Results are missing for Run ID "%d" so an matrix of NaNs has been returned in its place',runID(iRun))
                        sparam(:,iS,iRun) = nan(nFreq,1,1);
                        sparamType{1, iS, iRun} = [sparamstring{iS},' - ', resultIDStrings{idx}];
                        continue
                    end
                    s_real = result1D.invoke('GetArray','yre');
                    s_im = result1D.invoke('GetArray','yim');
                    sparam(:,iS,iRun) = s_real + 1i*s_im;
                    sparamType{1, iS, iRun} = [sparamstring{iS},' - ', resultIDStrings{idx}];
                end
            end
            
            sparam = squeeze(sparam);
            
            if ndims(sparam) < 3 %#ok<ISMAT>
                sparamType = squeeze(sparamType);
                sparamType = sparamType(:)';
            end
        end
        function [sparamtype,fullTreeString] = getSParamStrings(obj)
            %getSParamTypes returns all available S-Parameter String Names
            resultTree = obj.mws.invoke('resultTree');
            fullTreeString{1} = resultTree.invoke('GetFirstChildName','1D Results\S-Parameters'); 
            i = 1;
            while ~isempty(resultTree.invoke('GetNextItemName',fullTreeString{i}))
                fullTreeString{i+1,1} = resultTree.invoke('GetNextItemName',fullTreeString{i});  %#ok<AGROW>
                i = i+1;
            end
            sparamtype = replace(fullTreeString,'1D Results\S-Parameters\','');
        end
        function [runIDs,runIDStrings] = getRunIDs(obj)
            %getRunIDs returns all the Run IDs and RunID Strings
            resultTree = obj.mws.invoke('resultTree');
            sparamtype = resultTree.invoke('GetFirstChildName','1D Results\S-Parameters'); 
            
            runIDStrings = resultTree.invoke('GetResultIDsFromTreeItem',sparamtype);
            runID = split(runIDStrings,':');
            if size(runID,2) == 1
                runID = runID(3);
            else
                runID = runID(:,3);
            end
            runIDs = str2double(runID);
        end
        function [freq,sparam,sFileType] = getSParameters(obj,sParamType,parSweepNum) 
            %Get the Sparameters from the 1D results in CST
            % CST.getSParameters with no extra input argument will return all available S-Parameters for runID 0
            % CST.getSParameters('S11') will return the S11 value for the latest Run ID
            % CST.getSParameters('S21',runID) will return the S21 value for the simulation result with Run ID specified
            % in the 2nd input argument. runID should be numeric.
            % CST.getSParameters on its own will return all sparameters
            % from simulation with Run ID 0 (assuming it is available).
            % CST.getSParameters('SZmax(1)Zmax(1)',3) will return the
            % reflection coefficient of mode 1 at the ZMax port for a unit
            % cell simulation with runID 3
            %
            % Examples:
            % %Open an existing simulation with results (e.g.)
            % CST = CST_MicrowaveStudio() %Get handle to current CST project
            % % read in all sparameters
            % [freq,sparam,stype] = CST.getSParameters;
            % % read in S11
            % [freq,s11,type] = CST.getSParameter('S11')
            % 
            % % read in s11 data from runID 2
            % [freq,s11,type] = CST.getSParameter('S11',2)
            
            
            %If an sparameter type has been specified, then try to guess the sparamstring from some common names
            try
                if nargin >= 2 
                    switch lower(sParamType)
                        case {'s11','s1,1'}
                            sparamstring = 'S1,1';
                        case {'s21','s2,1'}
                            sparamstring = 'S2,1';
                        case {'s12','s1,2'}
                            sparamstring = 'S1,2';
                        case {'s22','s2,2'}
                            sparamstring = 'S2,2'; 
                        case {'zmaxzmax','z11'}
                            sparamstring = 'SZmax(1),Zmax(1)'; %mode (1)
                       case {'zmaxzmin','z12'}
                            sparamstring = 'SZmax(1),Zmin(1)'; %mode (1)
                       case {'zminzmax','z21'}
                            sparamstring = 'SZmin(1),Zmax(1)'; %mode (1)
                       case {'zminzmin','z22'}
                            sparamstring = 'SZmin(1),Zmin(1)'; %mode (1)
                        otherwise
                            sparamstring = sParamType;
                    end
                    
                    obj.mws.invoke('SelectTreeItem',['1D Results\S-Parameters\',sparamstring]);
                    
                    resultTree = obj.mws.invoke('Resulttree');
                    resultIDs = resultTree.invoke('GetResultIDsFromTreeItem',['1D Results\S-Parameters\',sparamstring]);
                    
                    nCurves = numel(resultIDs);
                    
                    if nargin == 2 %If no ParSweepNum, then output the last sweep
                        parSweepNum = nCurves-1;
                    end
                    
                    runID = obj.getRunIDs;
                    
                    idx = runID == parSweepNum;
                    
                    resultID = resultIDs{idx};
                    
                    result1D = resultTree.invoke('GetResultFromTreeItem',['1D Results\S-Parameters\',sparamstring],resultID);
                    
                    freq = result1D.invoke('GetArray','x');
                    s_real = result1D.invoke('GetArray','yre');
                    s_im = result1D.invoke('GetArray','yim');
                    sparam = s_real + 1i*s_im;
                    sFileType = {sParamType, resultID};
                    
                    return %Results has been successfully obtained so return
                end
            catch err
                try 
                    errStr = err.message;
                    errStr = replace(errStr,'\','\\');
                    cprintf('SystemCommands',[errStr,'\n'])
                catch
                    display(err.message)
                end
                warning('The requested S-Param type "%s" with runID "%d" was not found. Attempting to fetch all available S-parameter data for "RunID 0"',sParamType,parSweepNum)
            end
            
            
            obj.mws.invoke('SelectTreeItem','1D Results\S-Parameters\');
            
            plot1D = obj.mws.invoke('Plot1D');
            nCurves = plot1D.invoke('GetNumberOfCurves');
            sFileType = cell(0,2);
            
            if nCurves == 0
               error('CSTMicrowaveSutdio:NoDataAvailable',...
                   'No S-Parameter data available for Run ID 0')
            end
            
            for i = 1:nCurves
                fname = plot1D.invoke('GetCurveFileName',i-1);
                
                [~,sFileType{end+1,1},~] = fileparts(fname); %#ok<AGROW>
                %remove the c in sFileType - is this always the case?
                sFileType{end,1} = sFileType{end,1}(2:end);
                sFileType{end,2} = '3D:RunID:0';
                result1D = obj.mws.invoke('Result1DComplex',fname);
                
                
                try
                    freq(:,i) = result1D.invoke('GetArray','x'); %This will fail if curves have different numbers of points
                    s_real = result1D.invoke('GetArray','yre');
                    s_im = result1D.invoke('GetArray','yim');
                    
                    sparam(:,i) = s_real + 1i*s_im; %%#ok<AGROW>
                    
                catch err
                    warning('CSTMicrowaveSutdio:NoDataAvailable','Error Occurred when fetching sparameter data - maybe the vectors contain a different number of frequency points');
                    rethrow(err);
                end
            end
            if numel(sFileType) == 1
                sFileType = sFileType{1};
            end
        end
        function [f,Eps,Eps_dash,tan_d] = getDispersiveMaterialProps(obj,varargin)
            % [f,Eps,Eps_dash,tan_d] = getDispersiveMaterialProps(obj,material) returns the dispersive material
            % properties of the material named in the second argument across the frequency range in the CST simulation.
            % [f,Eps,Eps_dash,tan_d] = getDispersiveMaterialProps(obj,material,nPoints) returns the material properties
            % in arrays of nPoints number of entries
            %New function - not fully tested and might fail if attempting to retrieve material properties from anything
            %other than 'normal' materials 
            
            materialName = varargin{1};
            
            if numel(varargin) == 1
                nPoints = 101;
            else
                nPoints = varargin{2};
            end
            
            obj.mws.invoke('SelectTreeItem',['1D Results\Materials\',materialName,'\Dispersive']);
            
            plot1D = obj.mws.invoke('Plot1D');
            nCurves = plot1D.invoke('GetNumberOfCurves');
            
            if nCurves == 0
                f = [];
                Eps = [];
                Eps_dash = [];
                tan_d = [];
                warning('CSTMicrowaveSutdio:NoDataAvailable','Material not detected - returning empty values')
                return
            end
            
            for i = 1:nCurves
                fname = plot1D.invoke('GetCurveFileName',i-1);
                [~,sigID,~] = fileparts(fname); 
                
                sigID = strsplit(sigID,'_');
                sigID = sigID{end};
                sigID = strsplit(sigID,' ');
                sigID = sigID{1};
                result1D = obj.mws.invoke('Result1D',fname);
                switch lower(sigID)
                    case 're'
                        f = result1D.invoke('GetArray','x'); % Assume all have same sampling rate - why wouldnt they?
                        Eps = result1D.invoke('GetArray','y');
                    case 'im'
                        Eps_dash = result1D.invoke('GetArray','y');
                    case 'tgd'
                        tan_d = result1D.invoke('GetArray','y');
                end
            end
            
            %remove any duplicate frequency points
            [f,iA,~] = unique(f);
            Eps = Eps(iA);
            Eps_dash = Eps_dash(iA);
            try
            tan_d = tan_d(iA);
            catch
                tan_d = Eps_dash./Eps;
            end
            f1 = f(1);
            f2 = f(end);
            
            fStep = (f2-f1)/(nPoints - 1);
            fv = f1:fStep:f2;
            
            Eps = interp1(f,Eps,fv)';
            Eps_dash = interp1(f,Eps_dash,fv)';
            tan_d = interp1(f,tan_d,fv)';
            f = fv';
            
        end
        function [time,signal,sigID] = getPortSignals(obj,varargin)
            % [time,signal,sigID] = getPortSignals(obj,varargin) returns
            % the time and singal data from all the port signals rom the
            % simulation along with the string data indicating the type of
            % signal. Sig
            %
            % Example
            % [time,signal,sigID] = CST.getPortSignals();
            % plot(time(:,1),signal(:,1));
            % hold on
            % plot(time(:,2),signal(:,2));
            % legend(sigID)
            %
            % See also: CST_MicrowaveStudio, getSParameters
            
            p = inputParser;
            p.addParameter('port',[])
            p.parse(varargin{:});
            
            obj.mws.invoke('SelectTreeItem','1D Results\Port signals');
            
            plot1D = obj.mws.invoke('Plot1D');
            nCurves = plot1D.invoke('GetNumberOfCurves');
            
            if nCurves == 0
                time = [];
                signal = [];
                sigID = [];
                warning('CSTMicrowaveSutdio:NoDataAvailable','No signals detected - returning empty values')
                return
            end
            
            sigID = cell(0,1);
            
            for i = 1:nCurves
                fname = plot1D.invoke('GetCurveFileName',i-1);
                
                [~,sigID{end+1},~] = fileparts(fname); %#ok<AGROW>
                %remove the c in sFileType - is this always the case?
                %pSignal{end} = pSignal{end}(2:end);
                result1D = obj.mws.invoke('Result1D',fname);
                
                try
                    time(:,i) = result1D.invoke('GetArray','x'); %#ok<AGROW>      %This will fail if curves have different numbers of points
                    signal(:,i) = result1D.invoke('GetArray','y'); %#ok<AGROW>    - but this is unlikely/impossible in TD simulation
                    
                catch err
                    warning('Error Occurred when fetching sparameter data - maybe the vectors contain a different number of frequency points');
                    rethrow(err);
                end
            end
            if numel(sigID) == 1
                sigID = sigID{1};
            end
            
            %if numel(uniquetol(time(:),1e-5)) == length(time)
            %    time = time(:,1)
            %end
            
        end
        function [Eabs,Etheta_am,Ephi_am,Etheta_ph,Ephi_ph] = getFarField(obj,freq,theta,phi,varargin)
            % CST.getFarField(freq,theta,phi) returns the Etheta and EPhi
            % farfield results at the specified frequency and polar angles
            % defined by theta and phi. the default units is 'directivity'.
            % CST.getFarField(freq,theta,phi,'property',value) to define
            % the units and the farfield result identifier
            %
            % Properties:
            % ffid: farfield identifier frequency (default: ['farfield (f=',num2str(freq),') [1]']
            % units: units of the farfield plot. Options are:
            %   'directivity' (default), 'gain', 'realized gain', 'efield',
            %   'epattern', 'hfield', 'pfield', 'rcs', 'rcsunits',' rcssw'
            %
            % See Examples\dipole for more
            
            %Future update to allow user to specify the field component
            %outputs that they require?
            
            % if a numerical input is defined for ffid, use the
            % conventional CST farfield naming format to define monitor,
            % otherwise the input should be a string defining the name of
            % the farfield monitor
            
            p = inputParser;
            p.addParameter('ffid',[])
            p.addParameter('units','directivity')
            
            %The [1] in ffid below is actually related to the 'simulation identifier' but most commonly refers to the port number, port 1 is most common
            p.addParameter('SimID',1) %This is ignored if the ffid string is input as an argument
            
            
            p.parse(varargin{:});
            
            ffid = p.Results.ffid;
            units = p.Results.units;
            SimID = p.Results.SimID;
            
            if isempty(ffid)
                ffid = ['farfield (f=',num2str(freq),') [',num2str(SimID),']']; %e.g. "farfield (f=2.4)[1]"
            end
            
            if ~obj.mws.invoke('SelectTreeItem',['Farfields\',ffid])
                error('CST_MicrowaveStudio:ResultFileDoesntExist',...
                    ['Farfield result does not exist. Please use getFieldIDStrings to determine the available 3D Field Results.\n',...
                    'Most FFID Strings are of the form "farfield (f=2.4)[1]". They are case sensitive.\n',...
                    'The value returned from getFieldIDStrings may be of the form "farfieLd (f=2.4)_1", which should be modified to read farfieLd (f=2.4) [1]',...
                    'before inputting as the parameter value for to ffid in the input argument list'])
            end
            
            
            ff = obj.mws.invoke('farfieldplot');
            ff.invoke('Reset');
            ff.invoke('setPlotMode',units);
            ff.invoke('plotType','3d');
            ff.invoke('plot');
            
            
            for p = phi
                for t = theta
                    ff.invoke('AddListEvaluationPoint',t, p, 0, 'spherical','frequency',freq);
                end
            end
            
            ff.invoke('CalculateList','');
            %These take quite a long time. We could speed things up by
            %allowing user to specify which data they want - if only EAbs
            %is required then it will be 5x quicker.
            %
            %As a temporary way to speed up data output, use nargout to
            %determine which patterns user has asked for...
            
            nTheta = numel(theta);
            nPhi = numel(phi);
            
            if nargout >= 1
                Eabs = ff.invoke('GetList','Spherical abs');
                Eabs = reshape(Eabs,nTheta,nPhi);
            end
            if nargout >= 2
                theta_am = ff.invoke('GetList','Spherical linear theta abs');
                Etheta_am = reshape(theta_am,nTheta,nPhi);
            end
            if nargout >= 3
                phi_am = ff.invoke('GetList','Spherical linear phi abs');
                Ephi_am = reshape(phi_am,nTheta,nPhi);
            end
            if nargout >= 4
                theta_ph = ff.invoke('GetList','Spherical linear theta phase');
                Etheta_ph = reshape(theta_ph,nTheta,nPhi);
            end
            if nargout >= 5
                phi_ph = ff.invoke('GetList','Spherical linear phi phase');
                Ephi_ph = reshape(phi_ph,nTheta,nPhi);
            end
            %position_theta = ff.invoke('GetList','Point_T');
            %position_phi   = ff.invoke('GetList','Point_P');
            
        end
        function [meshOut] = getMeshInfo(obj,type)
            if nargin == 1
                type = 'all';
            end
            
            if obj.solver == "f"
                if ~strcmpi(type,'limits')
                    error('CST_MicrowaveStudio:getMeshPoints:SolverTypeError',...
                        'This function is currently not available for results from the frequency domain solver');
                end
            end
            
            
            mesh = obj.mws.invoke('Mesh');
            nP = mesh.invoke('GetNP');
            
            if strcmpi(type,'limits')
                X(1) = mesh.invoke('GetXPos',0);
                Y(1) = mesh.invoke('GetYPos',0);
                Z(1) = mesh.invoke('GetZPos',0);
                
                X(2) = mesh.invoke('GetXPos',nP-1);
                Y(2) = mesh.invoke('GetYPos',nP-1);
                Z(2) = mesh.invoke('GetZPos',nP-1);
                
                meshOut = struct('X',X,'Y',Y,'Z',Z,'meshPoints',nP);
                return
            elseif ~strcmpi(type,'all')
                error('CST_MicrowaveStudio:unrecognisedCommand','The input argument "type" must be a string that is etiher "all" or "limits"')
            end
            X = zeros(nP,1);
            Y = zeros(nP,1);
            % If we just try to get every mesh point for each axis, it can
            % take a very long time. If we loop through X until it repeates
            % then we know nX. We can then loop through nY and nZ:
            % index = ix + iy*nx + iz*nx*ny < .GetLength = nx*ny*nz
            for i = 1:nP
                X(i) = mesh.invoke('GetXPos',i-1); %Mesh in CST is zero-indexed
                if X(i) == X(1) && i~= 1
                    X = X(1:i-1);
                    break
                end
            end
            nX = numel(X);
            for i = 1:nP
                idx = (i-1)*nX;
                Y(i) = mesh.invoke('GetYPos',idx);
                if Y(i) == Y(1) && i~= 1
                    Y = Y(1:i-1);
                    break
                end
            end
            nY = numel(Y);
            nZ = nP/nX/nY;
            Z = zeros(nZ,1);
            for i = 1:nZ
                idx = (i-1)*nX*nY;
                Z(i) = mesh.invoke('GetZPos',idx);
            end
            
            meshOut = struct('X',X,'Y',Y,'Z',Z,'nX',nX,'nY',nY,'nZ',nZ,'meshPoints',nP);
            
        end
        function [outputField,XPos,YPos,ZPos] = getEFieldVectorAll(obj,freq,fieldComponent,varargin)
            % 
            %
            
            if obj.solver == "f"
                error('CST_MicrowaveStudio:getEfieldVector:SolverTypeError',...
                    'This function is currently not available for results from the frequency domain solver');
            end
            
            p = inputParser;
            p.addParameter('ffid',[])
            %The [1] in SimID below is actually related to the 'simulation
            %identifier'. It most commonly refers to the port number, port
            %1 is most common. It can be found by looking at the
            %information in the square brackets after the field monitor
            %results in CST
            p.addParameter('SimID',1) %This is ignored if the ffid string is input as an argument
            
            p.parse(varargin{:});
            
            field_id = p.Results.ffid;
            SimID = p.Results.SimID;
            
            if isempty(field_id)
                %Update this for specified field type (E/H)
                field_id = ['^e-field (f=',num2str(freq),')_',num2str(SimID),'']; %e.g. "farfield (f=2.4)[1]"
                %A better solution would be to search through the available
                %.m3d files for any matching the frequency/sim id
                
            else
                field_id = ['^',field_id];
            end
            
            %For Future Info:
            %If the tetrahedral mesh is used, the field_id uses a different
            %string and different type of file with a string like this:
            % 'e-field (#0001)_1(1).m3t'
            %There appear to be some .m3m files which contain the field_id
            %filenames similar to the transient solver results as above,
            %which may contain the information
            
            
            try
                fieldObject = obj.mws.invoke('Result3D',field_id);
            catch
                try
                    %Sometimes there is a ',1' at the end of the file
                    %name...
                    fieldObject = obj.mws.invoke('Result3D',[field_id,',1']);
                catch
                    error('CST_MicrowaveStudio:ResultFileDoesntExist',...
                        'Farfield result does not exist. Please use getFieldIDStrings to determine the available 3D Field Results')
                end
            end
            %The 'get' methods are indexed using the following equation:
            % index = ix + iy*nx + iz*nx*ny < .GetLength = nx*ny*nz
            
            meshInfo = obj.getMeshInfo;
            [XPos,YPos,ZPos] = meshgrid(meshInfo.X,meshInfo.Y,meshInfo.Z);
            
            switch lower(fieldComponent)
                case {'ex','x'}
                    re =  fieldObject.invoke('GetArray','xre');
                    im =  fieldObject.invoke('GetArray','xim');
                    outputField = re+1i*im;
                case {'ey','y'}
                    re =  fieldObject.invoke('GetArray','yre');
                    im =  fieldObject.invoke('GetArray','yim');
                    outputField = re+1i*im;
                case {'ez','z'}
                    re =  fieldObject.invoke('GetArray','zre');
                    im =  fieldObject.invoke('GetArray','zim');
                    outputField = re+1i*im;
                case {'abs','eabs'}   %This is a problem when using closed boundaries and symmetery planes!
                    reX =  fieldObject.invoke('GetArray','xre');
                    imX =  fieldObject.invoke('GetArray','xim');
                    reY =  fieldObject.invoke('GetArray','yre');
                    imY =  fieldObject.invoke('GetArray','yim');
                    reZ =  fieldObject.invoke('GetArray','zre');
                    imZ =  fieldObject.invoke('GetArray','zim');
                    
                    Ex = reX + 1i*imX;
                    Ey = reY + 1i*imY;
                    Ez = reZ + 1i*imZ;
                    
                    if numel(Ex) ~= numel(Ey) || numel(Ex) ~= numel(Ez)
                        error("Exporting absolute field values is currently not working")
                    end
                    
                    re = (abs(Ex) + abs(Ey) + abs(Ez));
                    im = zeros(size(re));
                    
                    outputField = re+1i*im;
                    
                otherwise
                    error("The field component identifier ""%s"" is not recognised",fieldComponent)
            end
            
           outputField = reshape(outputField,meshInfo.nX,meshInfo.nY,meshInfo.nZ);
            
        end
        function [outputField,XPos,YPos,ZPos] = getEFieldVector(obj,freq,fieldComponent,plane,location,varargin)
            % [This function is not finalized and may change in a future
            % version. Follow the examples for information on how to use
            % the function correctly. There are currently quite a few bugs.
            % For example, you can only retreive the fields correctly in
            % all planes when open (PML) boundary conditions are applied in
            % all directions! This works for resutls from the Time Domain
            % solver only!]
            %
            % Get the Electric field strength and phase for a particular
            % component (Ex, Ey, Ez, or E_Abs) on a single plane (XY, XZ or YZ) at a
            % specified location in the simulation space. This is currently
            % limited to Electric Field only but will be updated to include
            % the opttion to specify H-field/Surface currents in future
            %
            % The location refers to the index of the mesh cell in the
            % specified plane. e.g. a 'location' = 0 in the 'XY' will
            % return the field at the first z point in the simulation
            % space. If the 'location' is negative, the field at the halfway
            % point in the specified plane will be returned. Use
            % getMeshInfo to determine the number of cells in each plane
            %
            % Version 1.2.8: Updated to deal with symmetery planes,
            % outputting the field accross the whole plane where a
            % symmetery plane has been defined.
            %
            % Examples:
            % %Get the absolute Electric field value from a monitor at 2.5
            % %GHz in the yz plane at the 10th mesh cell along the x axis
            % [Efield_abs,x,y,z] = CST.getEFieldVector(2.5,'abs','yz',10);
            %
            % Get Ez directed field at the middle mesh cell in the xy plane
            % [Ez,x,y,z] = CST.getEFieldVector(2.5,'Ez','xy',-1);
            %
            % See Examples\dipole for working examples
            %
            % NOTE: There are currently problems specifying the field
            % identifiers when simulation has been run with the frequency
            % domain solver, due to the way CST names the result files.
            % Furthermore, you cannot just retrieve the field from a plane
            % as tetrahedral meshing does not automatically just mesh a
            % single plane like the time domain hexahedral mesh. It will
            % probably be easier to save the fields using one of CSTs
            % readily available macros over the given plane, and then
            % import into matlab seperately
            %
            
            if obj.solver == "f"
                error('CST_MicrowaveStudio:getEfieldVector:SolverTypeError',...
                    'This function is currently not available for results from the frequency domain solver');
            end
            
            p = inputParser;
            p.addParameter('ffid',[])
            %The [1] in SimID below is actually related to the 'simulation
            %identifier'. It most commonly refers to the port number, port
            %1 is most common. It can be found by looking at the
            %information in the square brackets after the field monitor
            %results in CST
            p.addParameter('SimID',1) %This is ignored if the ffid string is input as an argument
            
            p.parse(varargin{:});
            
            field_id = p.Results.ffid;
            SimID = p.Results.SimID;
            
            if isempty(field_id)
                %Update this for specified field type (E/H)
                field_id = ['^e-field (f=',num2str(freq),')_',num2str(SimID),'']; %e.g. "farfield (f=2.4)[1]"
                %A better solution would be to search through the available
                %.m3d files for any matching the frequency/sim id
                
            else
                field_id = ['^',field_id];
            end
            
            %For Future Info:
            %If the tetrahedral mesh is used, the field_id uses a different
            %string and different type of file with a string like this:
            % 'e-field (#0001)_1(1).m3t'
            %There appear to be some .m3m files which contain the field_id
            %filenames similar to the transient solver results as above,
            %which may contain the information
            
            
            try
                fieldObject = obj.mws.invoke('Result3D',field_id);
            catch
                try
                    %Sometimes there is a ',1' at the end of the file
                    %name...
                    fieldObject = obj.mws.invoke('Result3D',[field_id,',1']);
                catch
                    error('CST_MicrowaveStudio:ResultFileDoesntExist',...
                        'Farfield result does not exist. Please use getFieldIDStrings to determine the available 3D Field Results')
                end
            end
            %The 'get' methods are indexed using the following equation:
            % index = ix + iy*nx + iz*nx*ny < .GetLength = nx*ny*nz
            
            nX = fieldObject.invoke('GetNx');
            nY = fieldObject.invoke('GetNy');
            nZ = fieldObject.invoke('GetNz');
            
            switch lower(plane)
                case 'xy'
                    ix = 0:nX-1;
                    iy = 0:nY-1;
                    iy = (iy*nX)';
                    index = iy+ix;
                    if location < 0 %Use the halfway mesh point
                        %index = index+(round(nZ/2)-1)*nX*nY;
                        index = index+(round(nZ/2))*nX*nY;
                    elseif location > nZ
                        warning('The specified Z location of the xy plane is larger than the number of z-plane mesh cells');
                    else
                        location = round(location);
                        index = index+location*nX*nY;
                    end
                case 'xz'
                    ix = 0:nX-1;
                    iz = 0:nZ-1;
                    iz = (iz*nX*nY)';
                    index = iz+ix;
                    if location < 0
                        %index = index+(round(nY/2)-1)*nY;
                        index = index+(round(nY/2)*nX);
                    elseif location > nY
                        warning('The specified Y location of the xz plane is larger than the number of y-plane mesh cells');
                    else
                        location = round(location);
                        index = index+location*nX;
                    end
                case 'yz'
                    iy = 0:nY-1;
                    iy = (iy*nX);
                    iz = 0:nZ-1;
                    iz = (iz*nX*nY)';
                    
                    index = iz+iy;
                    if location < 0
                        %index = index+(round(nX/2)-1);
                        index = index+(round(nX/2));
                    elseif location > nX
                        warning('The specified x location of the yz plane is larger than the number of x-plane mesh cells');
                    else
                        location = round(location);
                        index = index+location; %is this correct?
                    end
            end
            
            %there are a few ways to return the field values, but i dont
            %know the quickest way yet...
            %             re = zeros(numel(index),1);
            %             im = zeros(numel(index),1);
            %
            %             for iField = 1:numel(index)
            %                 re(iField) = fieldObject.invoke('GetXRe',index(iField));
            %                 im(iField) = fieldObject.invoke('GetXIm',index(iField));
            %             end
            
            switch lower(fieldComponent)
                case {'ex','x'}
                    re =  fieldObject.invoke('GetArray','xre');
                    im =  fieldObject.invoke('GetArray','xim');
                    re = re(index+1);
                    im = im(index+1);
                    outputField = re+1i*im;
                case {'ey','y'}
                    re =  fieldObject.invoke('GetArray','yre');
                    im =  fieldObject.invoke('GetArray','yim');
                    re = re(index+1);
                    im = im(index+1);
                    outputField = re+1i*im;
                case {'ez','z'}
                    re =  fieldObject.invoke('GetArray','zre');
                    im =  fieldObject.invoke('GetArray','zim');
                    re = re(index+1);
                    im = im(index+1);
                    outputField = re+1i*im;
                case {'abs','eabs'}   %This is a problem when using closed boundaries and symmetery planes!
                    reX =  fieldObject.invoke('GetArray','xre');
                    imX =  fieldObject.invoke('GetArray','xim');
                    reY =  fieldObject.invoke('GetArray','yre');
                    imY =  fieldObject.invoke('GetArray','yim');
                    reZ =  fieldObject.invoke('GetArray','zre');
                    imZ =  fieldObject.invoke('GetArray','zim');
                    
                    Ex = reX + 1i*imX;
                    Ey = reY + 1i*imY;
                    Ez = reZ + 1i*imZ;
                    
                    Ex = Ex(index+1);
                    Ey = Ey(index+1);
                    Ez = Ez(index+1);
                    
                    if numel(Ex) ~= numel(Ey) || numel(Ex) ~= numel(Ez)
                        error("Exporting absolute field values is currently not working")
                    end
                    
                    re = (abs(Ex) + abs(Ey) + abs(Ez));
                    im = zeros(size(re));
                    
                    outputField = re+1i*im;
                    
                otherwise
                    error("The field component identifier ""%s"" is not recognised",fieldComponent)
            end
            
            
            
            %Retrieve the actual XY,/XZ/YZ meshgrid coordinates so the
            %field can be plotted to scale
            %This can take quite a long time, so will only be output if the
            %user requests the coordinates as output options. May be a
            %better idea to use the getMeshInfo Method if repeated calls to
            %the function are required
            if nargout > 1
                mesh = obj.mws.invoke('Mesh');
                fprintf('Retrieving Mesh Coordinates...\n');
                switch lower(plane)
                    case {'xy'}
                        XPos = zeros(1,nX);
                        YPos = zeros(nY,1);
                        
                        for i = 1:nX
                            idx = index( (i-1)*nY + 1 );
                            XPos(i) = mesh.invoke('GetXPos',idx);
                        end
                        for i = 1:nY
                            YPos(i) = mesh.invoke('GetYPos',index(i));
                        end
                        ZPos = mesh.invoke('GetZPos',index(1));
                        if (XPos(1) > XPos(end)) || (YPos(1) > YPos(end))
                            warning('Something appears to have gone wrong reading in the field data. Coordinates are in the wrong order')
                        end
                    case {'xz'}
                        XPos = zeros(1,nX);
                        ZPos = zeros(nZ,1);
                        
                        for i = 1:nX
                            idx = index( (i-1)*nZ + 1 );
                            XPos(i) = mesh.invoke('GetXPos',idx);
                        end
                        for i = 1:nZ
                            ZPos(i) = mesh.invoke('GetZPos',index(i));
                        end
                        
                        YPos = mesh.invoke('GetYPos',index(1));
                        if (XPos(1) > XPos(end)) || (ZPos(1) > ZPos(end))
                            warning('Something appears to have gone wrong reading in the field data. Coordinates are in the wrong order')
                        end
                    case {'yz'}
                        YPos = zeros(1,nY);
                        ZPos = zeros(nZ,1);
                        
                        for i = 1:nY
                            idx = index( (i-1)*nZ + 1 );
                            YPos(i) = mesh.invoke('GetYPos',idx);
                        end
                        for i = 1:nZ
                            ZPos(i) = mesh.invoke('GetZPos',index(i));
                        end
                        XPos = mesh.invoke('GetXPos',index(1));
                        if (ZPos(1) > ZPos(end)) || (YPos(1) > YPos(end))
                            warning('Something appears to have gone wrong reading in the field data. Coordinates are in the wrong order')
                        end
                end
            end
            
            boundary = obj.mws.invoke('Boundary');
            % check symmetery:
            XSym = boundary.invoke('GetXSymmetry');
            YSym = boundary.invoke('GetYSymmetry');
            ZSym = boundary.invoke('GetZSymmetry');
            
            
            
            switch lower(plane)
                case 'xy' %check for x and y symmetery planes
                    if ~isequal('none',XSym)
                        outputField = [fliplr(outputField(:,2:end)), outputField];
                        if nargout > 1
                            X2 = fliplr(cumsum(diff((XPos)))*-1)+XPos(1);
                            XPos = [X2,XPos];
                        end
                    end
                    if ~isequal('none',YSym)
                        outputField = [flipud(outputField(2:end,:)); outputField];
                        if nargout > 1
                            Y2 = flipud(cumsum(diff((YPos)))*-1)+YPos(1);
                            YPos = [Y2;YPos];
                        end
                    end
                    if nargout > 1
                        ZPos = ones(numel(YPos),numel(XPos)).*ZPos;
                    end
                case 'xz'
                    if ~isequal('none',XSym)
                        outputField = [fliplr(outputField(:,2:end)), outputField];
                        if nargout > 1
                            X2 = fliplr(cumsum(diff((XPos)))*-1)+XPos(1);
                            XPos = [X2,XPos];
                        end
                    end
                    if ~isequal('none',ZSym)
                        outputField = [flipud(outputField(2:end,:)); outputField];
                        if nargout > 1
                            Z2 = flipud(cumsum(diff((ZPos)))*-1)+ZPos(1);
                            ZPos = [Z2;Zpos];
                        end
                    end
                    if nargout > 1
                        YPos = ones(numel(ZPos),numel(XPos)).*YPos;
                        XPos = repmat(XPos,size(YPos,1),1);
                        ZPos = repmat(ZPos,1,size(YPos,2));
                    end
                case 'yz'
                    if ~isequal('none',YSym)
                        outputField = [fliplr(outputField(:,2:end)), outputField];
                        if nargout > 1
                            Y2 = fliplr(cumsum(diff((YPos)))*-1)+YPos(1);
                            YPos = [Y2,YPos];
                        end
                    end
                    if ~isequal('none',ZSym)
                        outputField = [flipud(outputField(2:end,:)); outputField];
                        if nargout > 1
                            Z2 = flipud(cumsum(diff((ZPos)))*-1)+ZPos(1);
                            ZPos = [Z2;ZPos];
                        end
                    end
                    if nargout > 1
                        XPos = ones(numel(ZPos),numel(YPos)).*XPos;
                        YPos = repmat(YPos,size(XPos,1),1);
                        ZPos = repmat(ZPos,1,size(XPos,2));
                    end
            end
        end
        function showFarfieldCuts(obj)
           
            VBA = sprintf(['With FarfieldPlot\n'...
                    '.ClearCuts '' lateral=phi, polar=theta\n'...
                    '.AddCut "lateral", "0", "1"\n'...
                    '.AddCut "lateral", "90", "1"\n'...
                    '.AddCut "polar", "90", "1"\n'...
                    'End With']);
            obj.addToHistory('ShowFarfieldCuts',VBA);
        end
        
        function [idStrings] = getFieldIDStrings(obj,monitor)
            %getFieldIDStrings
            %   getFieldIDStrings returns a list of all the available 3D and
            %   farfield monitors, along with the identification strings which
            %   can be used as arguments in the getFarField and getEFieldVector
            %   functions
            %
            %   idStrings = getFieldIDStrings(monitor) returns the
            %   identidication strings for a particular type of field monitor.
            %   Acceptable strings for monitor are: 'farfield','3dfield' where
            %   'farfield' will return the identification strings for all
            %   farfield resutls (.ffm files), and 3dfield will return all
            %   e/h-field results (.m3d, Hexahederal Mesh Only)
            
            %We could use obj.folder, but this only really works when the
            %project has been saved. If a new file which hasnt yet been saved
            %and is stored in a CST temp directory is being used then this wont
            %work.
            %direc = fullfile(obj.folder,obj.filename,'Result');
            direc = obj.mws.invoke('GetProjectPath','Result');
            
            info = dir(direc);
            filenames = (arrayfun(@(x)x.name,info,'uni',false));
            f_strings = convertCharsToStrings(filenames);
            
            ffm = endsWith(f_strings,'.ffm');
            m3d = endsWith(f_strings,'.m3d');
            
            idStrings_FF = filenames(ffm);
            
            %Try to correct for the way the ffid and idstrings
            %change with the first underscore and brackets
            for i = 1:numel(idStrings_FF)
                idx = strfind(idStrings_FF{i},'_');
                if ~isempty(idx)
                    idStrings_FF{i} = [idStrings_FF{i}(1:idx(1)-1),' [',idStrings_FF{i}(idx(1)+1:end)];
                end
            end
            idStrings_FF = replace(idStrings_FF,'.ffm',']');
            
            idStrings_E = filenames(m3d);
            
            if nargin == 2
                switch lower(monitor)
                    case{'farfield','ffid','ffm','.ffm'}
                        idStrings = idStrings_FF;
                    case{'3dfield','efield','hfield','m3d','.m3d'}
                        idStrings = idStrings_E;
                end
            else
                idStrings = [idStrings_E;idStrings_FF];
            end
            
        end
        function [components] = getComponentObjects(obj)
           
             solid = obj.mws.invoke('Solid');
             numShapes = solid.invoke('GetNumberOfShapes');
             components = cell(numShapes,1);
             for iShape = 0:numShapes-1
                 components{iShape+1} = solid.invoke('GetNameOfShapeFromIndex',iShape);
             end
        end
        function [s,l] = drawObjectMatlab(obj,varargin)
            % drawObjectMatlab plots the CST_MicrowaveStudio geometery into
            % a matlab axes.
            % [s,l] = drawObjectMatlab() will plot all objects from all
            % components into the current matlab axes. s contains the
            % graphics surface objects of all children to the axes, and l
            % contains the line objects.
            % drawObjectMatlab(obj,paramName,value) accepts the following
            % parameter/value input arguments:
            %   Param               Value
            % 'ComponentName'      Name of CST Component. If called without
            %                      the 'ObjectName' argument, all objects
            %                      in the specified component will be
            %                      plotted.
            % 'ObjectName'         Name of a specific CST Object to be
            %                      plotted. Can only be called with the
            %                      'componentName' argument.
            % 'Color'              Color [R G B] to plot the specified object. If
            %                      no color is input, each material will be
            %                      plotted in the same color they appear in CST.
            % 'axes'               Handle to the axes to be plotted in
            % 'normalToerance'     The normal tolerance applied to curved objects
            %                      when importing into matlab (default =
            %                      25). This will affect the curvature of
            %                      objects such as spheres and cylinders
            % 'alpha'              The alpha value of all patch objects
            %                      that will be created. This is the same
            %                      as calling surface(...,'alpha',0.5).
            %                      (default = 0.5)
            % 'featureEdgeTol'     tolerance associated with plotting of
            %                      feature edges for objects (in radians,
            %                      default = pi/6)
            % 'boundingBox'        true/false value on whether to plot the
            %                      CST bounding box which terminates the
            %                      simulation space. Will only be plotted
            %                      in 'componentName' and 'ObjectName' are
            %                      empty. (default = true)
            % 'excludeObjects'     specify specific objects to be excluded
            %                      when calling CST.drawObjectMatlab.
            %                      e.g. CST.drawObjectMatlab('excludeObjects','component1:solid1');
            
            
            p = inputParser;
            p.addParameter('componentName',[]);
            p.addParameter('objectName',[]);
            p.addParameter('normalTolerance',25);
            p.addParameter('color',[]);
            p.addParameter('axes',gca);
            p.addParameter('alpha',0.5);
            p.addParameter('featureEdgeTol',pi/6);
            p.addParameter('boundingBox',true);
            p.addParameter('excludeObjects',[]);
            p.addParameter('edgeColor',[]);
            
            p.parse(varargin{:});
            
            hAx = p.Results.axes;
            hAx.NextPlot = 'add'; %hold on
            view(3);
            axis(hAx,'equal');
            f_aplha = p.Results.alpha;
            
            solid = obj.mws.invoke('Solid');
            numShapes = solid.invoke('GetNumberOfShapes');
            normalTolerance = p.Results.normalTolerance;
            
            %If the objectName is empty, then either draw all objects in a
            %particular component, or all objects in the entire project
            if isempty(p.Results.objectName)
                %if no objects specified, retrieve and plot the simulation
                %boundaries first, then loop through and plot all the
                %components and objects
                
                if strcmp(hAx.Visible,'on')
                    hAx.Visible = 'off';
                end
                
                allObjectNames = cell(numShapes,1);
                for iShape = 0:numShapes-1
                    allObjectNames{iShape+1} = solid.invoke('GetNameOfShapeFromIndex',iShape);
                end
                if isempty(p.Results.objectName) && p.Results.boundingBox
                    % Recursive calls will always contain an object name. Plot Bounding box if it
                    % has been requested.
                    [X,Y,Z] = obj.getBoundaryLimits;
                    plot3([X(1) X(1) X(2) X(2) X(1)],[Y(1) Y(2) Y(2) Y(1) Y(1)],[1 1 1 1 1].*Z(1),'linestyle','--','color',[0.4 0.4 0.4]);
                    plot3([X(1) X(1) X(2) X(2) X(1)],[Y(1) Y(2) Y(2) Y(1) Y(1)],[1 1 1 1 1].*Z(2),'linestyle','--','color',[0.4 0.4 0.4]);
                    plot3([X(1) X(1)],[Y(1) Y(1)],Z,'linestyle','--','color',[0.4 0.4 0.4]);
                    plot3([X(2) X(2)],[Y(1) Y(1)],Z,'linestyle','--','color',[0.4 0.4 0.4]);
                    plot3([X(1) X(1)],[Y(2) Y(2)],Z,'linestyle','--','color',[0.4 0.4 0.4]);
                    plot3([X(2) X(2)],[Y(2) Y(2)],Z,'linestyle','--','color',[0.4 0.4 0.4]);
                end
                for iShape = 1:numel(allObjectNames)
                    c = strsplit(allObjectNames{iShape},':');
                    
                    componentName = c{1};
                    objectName = c{2};
                    
                    %If no component name was input, loop through and draw
                    %all objects in the project.
                    if isempty(p.Results.componentName)
                        varargin{end+1} = 'componentName'; %#ok<AGROW>
                        varargin{end+1} = componentName; %#ok<AGROW>
                        varargin{end+1} = 'objectName'; %#ok<AGROW>
                        varargin{end+1} = objectName; %#ok<AGROW>
                        obj.drawObjectMatlab(varargin{:});
                        varargin(end-3:end) = [];
                    elseif strcmp(componentName,p.Results.componentName) %case sensitive
                        %If component name was input but object name
                        %wasnt, draw all objects in that component
                        varargin{end+1} = 'objectName'; %#ok<AGROW>
                        varargin{end+1} = objectName; %#ok<AGROW>
                        obj.drawObjectMatlab(varargin{:});
                        varargin(end-1:end) = [];
                    end
                end
                if nargout > 0
                    children = hAx.Children;
                    idx = arrayfun(@(x)isa(x,'matlab.graphics.chart.primitive.Line'),children);
                    s = children(~idx);
                    if nargout > 1
                        l = children(idx);
                    end
                end
                
                if strcmp(hAx.Visible,'off')
                    hAx.Visible = 'on';
                end
                return
            elseif isempty(p.Results.componentName)
                error('Missing component name');
            end %object name and component name must both be input in the inputparser, check that component exists and, if so draw...
            
            if ~isempty(p.Results.excludeObjects)
                %check if the current object is to be excluded
                if any(strcmp([p.Results.componentName,':',p.Results.objectName],p.Results.excludeObjects))
                    return
                end
                
            end
            
            if ~solid.invoke('DoesExist',[p.Results.componentName,':',p.Results.objectName])
                error(['"',p.Results.componentName,':',p.Results.objectName,'" does not exist in the CST microwave studio model'])
            end
            
            objectName = p.Results.objectName;
            componentName = p.Results.componentName;
            
            v = solid.invoke('getVolume',[componentName,':',objectName]);
            
            
            try
                stl = obj.exportSTLfile(componentName,objectName,'NormalTolerance',normalTolerance);
                TR = stlread(stl);
                delete(stl);
            catch
                try
                    %If couldnt read the previous STL file, try
                    %exporting with greater Accuracy
                    stl = obj.exportSTLfile(componentName,objectName,'NormalTolerance',10);
                    TR = stlread(stl);
                    delete(stl);
                catch
                    try  %#ok<TRYNC> in case error occurs in reading the stl file, not writing it, then delete the file...
                        delete(stl);
                    end
                    warning([componentName,':',objectName,' could not be read properly and there has not been plotted'])
                    return
                end
            end
            
            c = p.Results.color;
            if isempty(c)
                %plot based on material the matlab axis colororder
                %until i can work out how to extract color from CST
                
                materialName = solid.invoke('GetMaterialNameForShape',[componentName,':',objectName]);
                
                %add new properties for axis so the same materials are
                %always plotted in the same colors
                if ~isprop(hAx,'materials')
                    hAx.addprop('materials');
                    hAx.addprop('materialColors');
                    [materialNames,colors] =  obj.getMaterialColors;
                    hAx.materials = materialNames;
                    hAx.materialColors = colors;
                end
                
                previousMaterials = hAx.materials;
                idx = strcmpi(previousMaterials,materialName);
                c = hAx.materialColors(idx,:);                
            end
            
            if v == 0
                %Surfaces are often in the same plane as solids - e.g. patch on an antenna.
                % This is a hack that avoids z-fighting(https://en.wikipedia.org/wiki/Z-fighting)
                % by plotting the surface twice in two very close
                % planes. The results mainly seem to avoid z-fighting effects
                [F,P] = freeBoundary(TR);
                trisurf(F,P(:,1),P(:,2),P(:,3),'FaceColor','none','EdgeAlpha',0.9,'LineWidth',1); %Plot the outline of the surface
                s = trisurf(TR,'FaceColor',c,'EdgeColor','none','EdgeAlpha',0.4,'parent',hAx,'FaceAlpha',1); %plot surface
                s2 = trisurf(TR,'FaceColor',c,'EdgeColor','none','EdgeAlpha',0.4,'parent',hAx,'FaceAlpha',1); %replot surface
                
                if all(P(:,1))  %shift first column
                    s.Vertices(:,1) = s.Vertices(:,1)+0.01; %Shift vertices by a small amount
                    s2.Vertices(:,1) = s2.Vertices(:,1)-0.01; %Shift vertices by a small amount in other direction
                elseif all(P(:,2))
                    s.Vertices(:,2) = s.Vertices(:,2)+0.01; %Shift vertices by a small amount
                    s2.Vertices(:,2) = s2.Vertices(:,2)-0.01; %Shift vertices by a small amount in other direction
                elseif all(P(:,3))
                    s.Vertices(:,3) = s.Vertices(:,3)+0.01; %Shift vertices by a small amount
                    s2.Vertices(:,3) = s2.Vertices(:,3)-0.01; %Shift vertices by a small amount in other direction
                else
                    disp('Is this really a surface?');
                    s.Vertices(:,3) = s.Vertices(:,3)+0.01; %Shift vertices by a small amount
                    s2.Vertices(:,3) = s2.Vertices(:,3)-0.01; %Shift vertices by a small amount in other direction
                end
            else
                %Volumetric data - just plot as it is
                s = trisurf(TR,'FaceColor',c,'EdgeColor',[0.1 0.1 0.1],'EdgeAlpha',0,'parent',hAx,'FaceAlpha',f_aplha);
                x = TR.Points(:,1);
                y = TR.Points(:,2);
                z = TR.Points(:,3);
                F = featureEdges(TR,p.Results.featureEdgeTol)';
                
                edgeColor = p.Results.edgeColor; 
                if isempty(edgeColor)
                    edgeColor = [0 0 0 f_aplha];
                end
                %plot3(x(F),y(F),z(F),'LineWidth',1,'color',[0 0 0 f_aplha]);
                plot3(x(F),y(F),z(F),'LineWidth',1,'color',edgeColor);
            end
            if strcmp(hAx.Visible,'on')
                pause(0.01)
                drawnow;
            end
            
%             if nargout > 0
%                 children = hAx.Children;
%                 idx = arrayfun(@(x)isa(x,'matlab.graphics.chart.primitive.Line'),children);
%                 s = children(~idx);
%                 if nargout > 1
%                     l = children(idx);
%                 end
%             end
            
            
        end
        function [X,Y,Z ] = getBoundaryLimits(obj)
            obj.runMacro('CST_App Macros\getBoundaryLimits');
            boundaryFile = fullfile(obj.folder,obj.filename,'\Model\3D\boundaryLimits.txt');
            data = dlmread(boundaryFile);
            delete(boundaryFile);
            X = [data(1) data(2)];
            Y = [data(3) data(4)];
            Z = [data(5) data(6)];
        end
        function [materialNames,colors] = getMaterialColors(obj)
            obj.runMacro('CST_App Macros\getMaterialColors');
            materialColorFile = fullfile(obj.folder,obj.filename,'\Model\3D\materialColors.txt');
            materialData = importdata(materialColorFile);
            delete(materialColorFile);
            materialNames = materialData.textdata;
            colors = materialData.data;
        end
        function runMacro(obj,macroName)
            
            obj.mws.invoke('RunMacro',macroName);
        end
        function importSTLfile(obj,filename,componentName,objectName,varargin)
            
            p = inputParser;
            p.addParameter('units','m')
            
            p.parse(varargin{:});
            
            VBA = sprintf(['With STL\n',...
                '.Reset\n',... 
                '.Id "1"\n',...
                '.Name "%s"\n',...
                '.Component "%s"\n',...
                '.FileName "%s"\n',...
                '.ImportToActiveCoordinateSystem "True"\n',...
                '.ScaleToUnit "0"\n',...
                '.ImportFileUnits "%s"\n',...
                '.Read\n',...
                'End With'],...
                objectName,componentName,filename,p.Results.units);
            
            obj.update(['import stl file : ',filename],VBA);
            
        end
        
        function stlname = exportSTLfile(obj,componentName,objectName,varargin)
            
            p = inputParser;
            p.addParameter('stlname',[])
            p.addParameter('normalTolerance',30) %reduce for more accuracy or if error in the reading of STL file...
            p.parse(varargin{:});
            
            stlname = p.Results.stlname;
            normalTolerance = p.Results.normalTolerance;
            if isempty(stlname)  %To be improved in future to export as
                componentNameOut = strrep(componentName,'\','-');
                objectNameOut = strrep(objectName,'\','-');
                componentNameOut = strrep(componentNameOut,'/','-');
                objectNameOut = strrep(objectNameOut,'/','-');
                [~,fname] = fileparts(obj.filename); %Remove the extension if it is somehow included
                stlname = fullfile(fullfile(obj.folder,fname),[componentNameOut,'-',objectNameOut,'.stl']);
            else
                [direc,fname,~] = fileparts(stlname);
                if isempty(direc)
                    direc = fullfile(obj.folder,obj.filename);
                end
                stlname = fullfile(direc,[fname,'.stl']);
            end
            %This should not be added to history list so just call object
            %methods indivdually
            STL = obj.mws.invoke('STL');
            STL.invoke('Reset');
            STL.invoke('FileName',stlname);
            STL.invoke('Name',objectName);
            STL.invoke('Component',componentName);
            STL.invoke('ScaleToUnit',true);
            STL.invoke('ExportFileUnits','mm');
            STL.invoke('ExportFromActiveCoordinateSystem',false);
            STL.invoke('NormalTolerance',normalTolerance);
            try
                STL.invoke('Write'); %Write STL file
            catch
                %possibly an invalid filename if user has used '.' in the
                %name of the CST project path
                stlname = tempname;
                STL.invoke('FileName',stlname);
                STL.invoke('Write'); %Write STL file
            end
            
        end
    end
    methods (Hidden, Access = protected)
        function installMacros(obj)
            direc = obj.mws.invoke('GetMacroPathFromIndex',0);
            macroDir = fullfile(direc,'CST_App Macros');
            if ~isfolder(fullfile(direc,'CST_App Macros'))
                mkdir(macroDir)
                fprintf('New Macro Directory Created: \n%s\n',macroDir)
            end
            
            existingMacroInfo = dir(macroDir);
            existingMacroInfo(1:2) = [];
            macroFilePath = fileparts(mfilename('fullpath'));
            macroFilePath = fullfile(macroFilePath,'macros');
            if ~isfolder(macroFilePath)
                error('CST_MicrowaveStudio:MissingFolder',['I could not identify the /macros folder. ',...
                    'Make sure the CST_MicrowaveStudio.m file and the directory structure have not been altered. CST_App can be downloaded from ',...
                    'https://uk.mathworks.com/matlabcentral/fileexchange/67731-hgiddenss-cst_app']);
                
            end
            allMacros = dir(macroFilePath);
            
            allMacros(1:2) = [];
            existingMacroFilenames = cell(numel(existingMacroInfo),1);
            for i = 1:numel(existingMacroInfo)
                existingMacroFilenames{i} = existingMacroInfo(i).name;
            end
            for i = 1:numel(allMacros)
                if ~any(strcmp(allMacros(i).name,existingMacroFilenames))
                    [~,~,extension] = fileparts(allMacros(i).name);
                    if strcmpi(extension,'.mcr')
                        macroFileToCopy = fullfile(macroFilePath,allMacros(i).name);
                        copyfile(macroFileToCopy,macroDir); %Install macro in the path
                        fprintf('New Macro Installed: \n%s\n',allMacros(i).name)
                    end
                end
            end
        end
        function update(obj,commandString,VBAstring)
            if obj.autoUpdate
                obj.addToHistory(commandString,VBAstring);
            else
                obj.VBAstring = [obj.VBAstring,VBAstring,newline];
            end
        end
        function [out] = checkParam(obj,param,pClass)
            %Check to see if input argument is a string. If so, it is
            %intended to be assigned as a parameter value, but will only be
            %possible if the parameter already exists in the project.
            
            if nargin == 2
                if numel(param) > 1 && iscell(param) %cell array with more than 1 value
                    out = string(numel(param,1));
                    for i = 1:numel(param)
                        if ischar(param{i})
                            if ~obj.isParameter(param{i})
                                error("CST_MicrowaveStudio:ParameterDoesntExist",...
                                    "Parameter "+ param{i} +" does not exist. Please add it to the project before assigning it to the material property");
                            end
                        end
                        out(i) = string(param(i));
                    end
                elseif isnumeric(param) %numeric array/single value - output all as strings
                    out = string(param);
                else %single value, either char, cell
                    
                    if ~obj.isParameter(param)
                        error("CST_MicrowaveStudio:ParameterDoesntExist",...
                            "Parameter "+ param +" does not exist. Please add it to the project before assigning it to the material property");
                    end
                    
                    out = string(param);
                    
                end
            else
                %Check the input parameter is the correct type
                if ~isa(param,pClass)
                    error('CST_MicrowaveStudio:WrongInputParameter',['One of the input parameters is the wrong datatype, it should be a %s\n',...
                        'This May be because you have tried to add a parameter to an unsupported input argument'],pClass)
                end
            end
            
        end
    end
    methods (Static)
        function [CST,mws] = openFile(folder,filename)
            
            CST = actxserver('CSTStudio.application');
            CST.invoke('OpenFile',fullfile(folder,filename));
            mws = CST.Active3D;
        end
    end
end

