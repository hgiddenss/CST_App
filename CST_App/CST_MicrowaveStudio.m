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
    %   Class Creator:
    %   CST_MicrowaveStudio
    %
    %   File Methods:
    %   save
    %   quit
    %   openFile (Static)
    %
    %   Simulation Methods:
    %   addDiscretePort   
    %   defineUnits
    %   setFreq
    %   setSolver
    %   setBoundaryConditions
    %   addFieldMonitor
    %   setBackgroundLimits
    %   addSymmetryPlane
    %   defineFloquetModes
    %   runSimulation
    %
    %   Build Methods:
    %   addNormalMaterial
    %   addAnisotropicMaterial
    %   addBrick
    %   addCylinder
    %   addPolygonBlock
    %   addSphere
    %   rotateObject
    %
    %   Result Methods:
    %   getSParameters
    %   
    %   For help on specific functions, type
    %   CST_MicrowaveStuio.FunctionName (e.g. "help CST_MicrowaveStudio.setBoundaryCondition")
    %
    %   Additional custom functions may be added to CST histroy list using
    %   the same VBA format below and calling:
    %   CST_MicrowaveStudioHandle.mws.invoke('AddToHistory','Action String identifier',VBA])
    %
    %   See Also: actxserver, addGradedIndexMaterialCST
    %
    %   Copyright: Henry Giddens 2018, Antennas and Electromagnetics
    %   Group, Queen Mary University London, 2018 (For further help,
    %   requests, and bug fixes contact h.giddens@qmul.ac.uk) 
    
    properties
        CST       % Handle to CST through actxserver
        folder    % Folder 
        filename  % Filename
        mws
    end
    properties (Hidden)
        
        ports = 0;
        solver = 't';
    end
    properties (Access = private)
       version = 1.0; 
    end
    methods
        function obj = CST_MicrowaveStudio(folder,filename)
            %CMWS_MODEL Construct an instance of this class
            
            obj.folder = folder;
            
            %Ensure file is .cst.
            [~,filename,~] = fileparts(filename);
            obj.filename = [filename,'.cst'];
            
            ff = fullfile(obj.folder,obj.filename);
            
            if exist(ff,'file') == 2
                %If file exists, open 
                [obj.CST,obj.mws] = CST_MicrowaveStudio.openFile(obj.folder,obj.filename);
                
            else %Create a new MWS session
            %Create a directory in 'folder' called
            %CST_MicrowaveStudio_Files which is added to .gitignore
            dirstring = fullfile(obj.folder,'CST_MicrowaveStudio_Files');
            obj.folder = dirstring;
            obj.CST = actxserver('CSTStudio.application');
            obj.mws = obj.CST.invoke('NewMWS');
            
            obj.defineUnits;
            obj.setFreq(11,13);
            
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
                        
            obj.mws.invoke('AddToHistory','define boundaries',VBA);
            
            VBA = sprintf(['With Material\n',...
                             '.Type "Normal\n',...
                             '.Colour "0.6", "0.6", "0.6"\n',...
                             '.ChangeBackgroundMaterial\n',...
                           'End With',...
                            ]);
            
            obj.mws.invoke('AddToHistory','Set Background Material',VBA);
            end
        end
        function save(obj)
            if ~exist(obj.folder,'file') == 7
               makedir(obj.folder); 
            end
            obj.mws.invoke('saveas',fullfile(obj.folder,obj.filename),'false');
        end
        function quit(obj,type)
            if strcmp(type,'all') % Close the application
                obj.CST.invoke('quit')
            else % Close the MWS project
               obj.mws.invoke('quit')
            end
        end
        function defineUnits(obj)
            
            VBA = sprintf(['With Units\n',...
                            '.Geometry "mm"\n',...
                            '.Frequency "GHz"\n',...
                            '.Time "s"\n',...
                            '.TemperatureUnit "Kelvin"\n',...
                            '.Voltage "V"\n',...
                            '.Current "A"\n',...
                            '.Resistance "Ohm"\n',...
                            '.Conductance "Siemens"\n',...
                            '.Capacitance "PikoF"\n',...
                            '.Inductance "NanoH"\n',...
                        'End With' ]);
        obj.mws.invoke('AddToHistory','Set Units',VBA);
            
        end 
        function addBrick(obj,X,Y,Z,name,component,material,varargin)
            p = inputParser;
            p.addParameter('color',[])
            
            p.parse(varargin{:});
            C = p.Results.color;
            C = C*128;
            
           %VBA = cell(0,1);
           
           VBA = sprintf(['With Brick\n',...
                            '.Reset\n',...
                            '.Name "%s"\n',...
                            '.Component "%s"\n',...
                            '.Material "%s"\n',...
                            '.XRange "%f", "%f"\n',...
                            '.YRange "%f", "%f"\n',...
                            '.ZRange "%f", "%f"\n',...
                            '.Create\n',...
                          'End With'],...
                          name,component,material,X(1),X(2),Y(1),Y(2),Z(1),Z(2));
            
            obj.mws.invoke('AddToHistory',['define brick: ',component,':',name],VBA);
            
            %Change color if required
            if ~isempty(C)
                s = obj.mws.invoke('Solid');
                s.invoke('SetUseIndividualColor',[component,':',name],'1');
                s.invoke('ChangeIndividualColor',[component,':',name],num2str(C(1)),num2str(C(2)),num2str(C(3)));
            end
        end
        function addNormalMaterial(obj,name,Eps,Mue,C)
            VBA =  sprintf(['With Material\n',...
                                '.Reset\n',...
                                '.Name "%s"\n',...
                                '.Type "Normal"\n',...
                                '.Epsilon "%f"\n',...
                                '.Mue "%f"\n',...
                                '.Colour "%f", "%f", "%f"\n',...
                                '.Create\n',...
                             'End With'],...
                             name,Eps,Mue,C(1),C(2),C(3));
            obj.mws.invoke('AddToHistory',['define material: ',name],VBA);
        end
        function addAnisotropicMaterial(obj,name,Eps,Mue,C)
             VBA =  sprintf(['With Material\n',...
                                '.Reset\n',...
                                '.Name "%s"\n',...
                                '.Type "Anisotropic"\n',...
                                '.EpsilonX "%f"\n',...
                                '.EpsilonY "%f"\n',...
                                '.EpsilonZ "%f"\n',...
                                '.MueX "%f"\n',...
                                '.MueY "%f"\n',...
                                '.MueZ "%f"\n',...
                                '.Colour "%f", "%f", "%f"\n',...
                                '.Create\n',...
                             'End With'],...
                             name,Eps(1),Eps(2),Eps(3),Mue(1),Mue(2),Mue(3),C(1),C(2),C(3));
            obj.mws.invoke('AddToHistory',['define material: ',name],VBA);
        end
        function addDiscretePort(obj,X,Y,Z,R,impedance,portNumber)
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
            
            %This avoids conflicts when adding new ports - we could (should?) get
            %next available port number interactively from the MWS file 
            if nargin < 7
                portNumber = obj.ports + 1; 
            end
            
            
            VBA =  sprintf(['With DiscretePort\n',...
                                '.Reset\n',...
                                '.Type "SParameter"\n',...
                                '.PortNumber "%d"\n'...
                                '.SetP1 "False", "%f", "%f", "%f"\n',...
                                '.SetP2 "False", "%f", "%f", "%f"\n',...
                                '.Impedance "%f"\n',...
                                '.Radius "%f"\n',...
                                '.Create\n',...
                             'End With'],...
                             portNumber, X(1),Y(1),Z(1),X(2),Y(2),Z(2),impedance,R);
             
             obj.mws.invoke('AddToHistory',['define discrete port: ',num2str(obj.ports+1)],VBA);
             
             obj.ports = obj.ports + 1; %Should this be obtained from the MWS file?
        end
        function addFieldMonitor(obj,fieldType,freq)
            % Add a field monitor at specified frequency
            % Examples:
            % CST.AddMonitor('Efield',2.4);
            % CST.AddMonitor('farfield',10);
            
            name = [fieldType,' (f=',num2str(freq),')'];
            
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
            obj.mws.invoke('AddToHistory',['define field monitor: ',name],VBA);
            
        end
        function setBackgroundLimits(obj,X,Y,Z)    
            %CST.setBackgroundLimits sets the backgroun limits in the model
            %in the +/-X, +/-Y, and +/-Z directions, as specified.
            
            %Limits should always be positive
            X = abs(X);
            Y = abs(Y);
            Z = abs(Z);
            
            VBA = sprintf(['With Background\n',...
                    '.XminSpace "%f"\n',...
                    '.XmaxSpace "%f"\n',...
                    '.YminSpace "%f"\n',...
                    '.YmaxSpace "%f"\n',...
                    '.ZminSpace "%f"\n',...
                    '.ZmaxSpace "%f"\n',...
                    '.ApplyInAllDirections "False"\n',...
                'End With'],...
                X(1),X(2),Y(1),Y(2),Z(1),Z(2));
            obj.mws.invoke('AddToHistory','define background',VBA);
            
        end
        function addSymmetryPlane(obj,planeNormal,symType)
            %addSymmetryPlane(planeNormal,symType) sets the specified plane
            %to the defined symmetry type.
            % Examples:
            % CST.addSymetryPlane('X','magnetic')
            
            VBA = sprintf(['With Boundary\n',...
                            '.%ssymmetry "%s"\n',...
                          'End With'],...
                            planeNormal,symType);
            obj.mws.invoke('AddToHistory',['define boundary: ',planeNormal,' normal'],VBA);
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
                    case 'open add space'
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
                        
            obj.mws.invoke('AddToHistory','define boundaries',VBA);
            
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
                   obj.mws.invoke('AddToHistory','define Floquet Port boundaries',VBA);        
                           
                               
            end
        end
        function rotateObject(obj,componentName,objectName,rotationAngles,rotationCenter,copy,repetitions)
            % Rotate an object in located in one of the components
            % 
            % 
            % 
            % Currently not possible to rotate ports, faces, curves etc...
            nameStr = [componentName,':',objectName];
            if nargin < 6
                copy = 'False';
            end
            
            if nargin < 7
                repetitions = 1;
            end
            
            if copy
                copyStr = 'True';
            else
                copyStr = 'False';
            end
            
            VBA = sprintf(['With Transform\n',...
                            '.Reset\n',...
                            '.Name "%s"\n',...
                            '.Origin "Free"\n',...
                            '.Center "%f", "%f", "%f"\n',...
                            '.Angle "%f", "%f", "%f"\n',...
                            '.MultipleObjects "%s"\n',...
                            '.GroupObjects "False"\n',...
                            '.Repetitions "%d"\n',...
                            '.MultipleSelection "False"\n',...
                            '.Transform "Shape", "Rotate"\n',...
                            'End With'],...
                            nameStr,rotationCenter(1),rotationCenter(2),rotationCenter(3),...
                            rotationAngles(1),rotationAngles(2),rotationAngles(3),...
                            copyStr,repetitions);
              
             obj.mws.invoke('AddToHistory',['transform: rotate ',nameStr],VBA);
            
        end
        function addPolygonBlock(obj,points,height,name,component,material,varargin)
            %At the moment the block can only be in the x-y plane extending
            %along the z-axis
            p = inputParser;
            p.addParameter('color',[])
            
            p.parse(varargin{:});
            C = p.Results.color;
            C = C*128;
            
           %VBA = cell(0,1);
           
           VBA = sprintf(['With Extrude\n',...
                            '.Reset\n',...
                            '.Name "%s"\n',...
                            '.Component "%s"\n',...
                            '.Material "%s"\n',...
                            '.Mode "pointlist"\n',...
                            '.Height "%f"\n',...
                            '.Twist "0.0"\n',...
                            '.Taper "0.0"\n',...
                            '.Origin "0.0", "0.0", "0.0"\n',...
                            '.Uvector "1.0", "0.0", "0.0"\n',...
                            '.Vvector "0.0", "1.0", "0.0"\n',...
                            '.Point "%f", "%f"\n'],...
                          name,component,material,height,points(1,1),points(1,2));
            
             VBA2 = [];
            for i = 2:length(points)
                VBA2 = [VBA2,sprintf('.LineTo "%f", "%f"\n', points(i,1),points(i,2))]; %#ok<AGROW>
            end
            VBA = [VBA,VBA2,sprintf('.create\nEnd With')];
            
            obj.mws.invoke('AddToHistory',['define brick: ',component,':',name],VBA);
            
            %Change color if required
            if ~isempty(C)
                s = obj.mws.invoke('Solid');
                s.invoke('SetUseIndividualColor',[component,':',name],'1');
                s.invoke('ChangeIndividualColor',[component,':',name],num2str(C(1)),num2str(C(2)),num2str(C(3)));
            end
            
        end
        function addCylinder(obj,R1,R2,orientation,X,Y,Z,name,component,material)
            if ~strcmpi(orientation,'z')
                warning('Only Z-orientated cylinders are currently allowed')
                return
            end
            VBA = sprintf(['With Cylinder\n',... 
                            '.Reset\n',... 
                            '.Name "%s"\n',... 
                            '.Component "%s"\n',... 
                            '.Material "%s"\n',... 
                            '.OuterRadius "%f"\n',...
                            '.InnerRadius "%f"\n',...
                            '.Axis "%s"\n',...
                            '.Zrange "%f", "%f"\n',...
                            '.Xcenter "%f"\n',...
                            '.Ycenter "%f"\n',...
                            '.Segments "0"\n',...
                            '.Create\n',...
                            'End With'],...
                            name,component,material,R1,R2,lower(orientation),Z(1),Z(2),X,Y);
                        
             obj.mws.invoke('AddToHistory',['define cylinder:',component,':',name],VBA);

        end
        function addSphere(obj,X,Y,Z,R1,R2,R3,name,component,material,varargin)
            if R2 > R1 || R3 > R1
                warning('Center Radius (R1) must be larger than top (R2) and bottom (R3) radii\nExiting without adding sphere');
                return
            end
            
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
                            '.Center "%f", "%f", "%f"\n',...  
                            '.Segments "%d"\n',...  
                            '.Create\n',...  
                           'End With'],...
                           name,component,material,orientation,R1,R2,R3,X,Y,Z,segments);
            
            obj.mws.invoke('AddToHistory',['define sphere:',component,':',name],VBA);
            
        end
        function setFreq(obj,F1,F2)
           obj.mws.invoke('AddToHistory','Component1:Block1',sprintf('Solver.FrequencyRange "%f", "%f"',F1,F2)); 
        end

        function setSolver(obj,solver)
            switch lower(solver)
                case {'frequency','f','freq'}
                    VBA = 'ChangeSolverType "HF Frequency Domain"';
                    obj.solver = 'f';
                case {'time','time domain','td'}
                    VBA = 'ChangeSolverType "HF Time Domain" ';
                    obj.solver = 't';
            end
            obj.mws.invoke('AddToHistory','change solver type',VBA);
            
        end
        function defineFloquetModes(nModes)
            
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
                   obj.mws.invoke('AddToHistory','define Floquet Port boundaries',VBA);   
        end
        function runSimulation(obj)
            switch obj.solver
                case 'f'
                    s = obj.mws.invoke('FDSolver'); % handle to frequency domain solver
                case 't'
                    s = obj.mws.invoke('Solver');   % handle to time domain solver
            end
            s.invoke('Start');
        end
        function [freq,sparam,sFileType] = getSParameters(obj,sParamType)
            %Get the Sparameters from the 1D results in CST
            % CST.getSParameters will return all available S-Parameters
            % CST.getSParameters('S11') will return the S1,1 value in the
            % 1D result tree.
            % CST.getSParameters('SZmax(1)Zmax(1)') will return the
            % reflection coefficient of mode 1 at the ZMax port for a unit
            % cell type simulation
            
            
            if nargin == 2
                %sParamType
            end
            obj.mws.invoke('SelectTreeItem','1D Results\S-Parameters');
            
            p = obj.mws.invoke('Plot1D');
            nCurves = p.invoke('GetNumberOfCurves');
            sFileType = cell(0,1);
            %freq = zeros(nCurves,0);
            %sparam = zeros(nCurves,0);
            
            for i = 1:nCurves
                fname = p.invoke('GetCurveFileName',i-1);
                
                [~,sFileType{end+1},~] = fileparts(fname); %#ok<AGROW>
                %remove the c in sFileType - is this always the case?
                sFileType{end} = sFileType{end}(2:end);
                if nargin == 2
                    %test is sFileType is the same as SType,
                    
                    
                    if ~strcmp(sFileType{end},sParamType)
                        continue
                    else 
                        i = 1; %#ok<FXSET>
                    end
                    
                end
                
                r = obj.mws.invoke('Result1DComplex',fname);
                try
                    freq(:,i) = r.invoke('GetArray','x'); %#ok<AGROW> %This will fail if curves have different numbers of points
                    s_real = r.invoke('GetArray','yre');
                    s_im = r.invoke('GetArray','yim');
                    
                    sparam(:,i) = s_real + 1i*s_im; %#ok<AGROW>
                    if nargin == 2
                        sFileType = sFileType{1};
                        break;
                    end
                catch err
                    warning('Error Occurred when fetching sparameter data - maybe the vectors contain a different number of frequency points');
                    rethrow(err);
                end
            end
        end
    end
    methods (Static)
        function [CST,mws] = openFile(folder,filename)
            
            CST = actxserver('CSTStudio.application');
            mws = CST.invoke('OpenFile',fullfile(folder,filename));
            
        end
    end
end

