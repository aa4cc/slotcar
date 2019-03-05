classdef imu < realtime.internal.SourceSampleTime ...
        & coder.ExternalDependency ...
        & matlab.system.mixin.Propagates ...
        & matlab.system.mixin.CustomIcon
    % System object block for getting accelerometer & gyro data from Beaglebone Blue.

    
    properties
        % Public, tunable properties.
    end
    
    properties (Nontunable)
        numOutputs = 6;   % Default value
    end
    
    properties (Access = private)
        % Pre-computed constants.
    end
    
    methods
        % Constructor
        function obj = Source(varargin)
            % Support name-value pair arguments when constructing the object.
            setProperties(obj,nargin,varargin{:});
        end
    end
    
    
    methods (Access=protected)
        function setupImpl(obj) 
            if isempty(coder.target)
                % Place simulation setup code here
            else
                % Call C-function implementing device initialization
                coder.cinclude('imu.h');
                % Call C-function implementing device initialization                
                coder.ceval('imu_setup');
            end
        end
        
        
        function varargout = stepImpl(~)
            if isempty(coder.target)
                varargout{1} = single(1);
                varargout{2} = single(2);
                varargout{3} = single(3);
                varargout{4} = single(4);
                varargout{5} = single(5);
                varargout{6} = single(6);
            else
                % Call C-function implementing device output
                coder.ceval('imu_measure');
                temp = single(0);
                temp = coder.ceval('return_accel_x');
                varargout{1} = temp;
                temp = coder.ceval('return_accel_y');
                varargout{2} = temp;
                temp = coder.ceval('return_accel_z');
                varargout{3} = temp;
                temp = coder.ceval('return_gyro_x');
                varargout{4} = temp;
                temp = coder.ceval('return_gyro_y');
                varargout{5} = temp;
                temp = coder.ceval('return_gyro_z');
                varargout{6} = temp;
            end
        end
        
        function releaseImpl(obj) %#ok<MANU>
            if isempty(coder.target)
                % Place simulation termination code here
            else
                % Call C-function implementing device termination
                coder.ceval('imu_terminate');
            end
        end
    end
    
    methods (Access=protected)
        %% Define output properties
        function num = getNumInputsImpl(~)
            num = 0;
        end
        
        function num = getNumOutputsImpl(~)
            num = 6;
        end
        
        function flag = isOutputSizeLockedImpl(~,~)
            flag = true;
        end
        
        function varargout = isOutputFixedSizeImpl(~,~)
            varargout{1} = true;
            varargout{2} = true;
            varargout{3} = true;
            varargout{4} = true;
            varargout{5} = true;
            varargout{6} = true;
        end
        
        function flag = isOutputComplexityLockedImpl(~,~)
            flag = true;
        end
        
        function varargout = isOutputComplexImpl(~)
            varargout{1} = false;
            varargout{2} = false;
            varargout{3} = false;
            varargout{4} = false;
            varargout{5} = false;
            varargout{6} = false;
        end
        
        function varargout = getOutputSizeImpl(~)
            varargout{1} = [1,1];
            varargout{2} = [1,1];
            varargout{3} = [1,1];
            varargout{4} = [1,1];
            varargout{5} = [1,1];
            varargout{6} = [1,1];
        end
        
        function varargout = getOutputDataTypeImpl(~)
            varargout{1} = 'single';
            varargout{2} = 'single';
            varargout{3} = 'single';
            varargout{4} = 'single';
            varargout{5} = 'single';
            varargout{6} = 'single';
        end
        
        function icon = getIconImpl(obj)
            % Define a string as the icon for the System block in Simulink.
            % icon = sprintf('IR LED current: %d mA\n', obj.current);
        end
        
        %pri zavreni nastaveni blocku
        function validatePropertiesImpl(obj)

        end
      
    
    end
    
    methods (Static, Access=protected)
        function simMode = getSimulateUsingImpl(~)
            simMode = 'Interpreted execution';
        end
        
        function isVisible = showSimulateUsingImpl
            isVisible = false;
        end
        
    end
    
    methods (Static)
        function name = getDescriptiveName()
            %name = sprintf('IR LED current: %d mA\n', obj.current);
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
        function updateBuildInfo(buildInfo, context)
            if context.isCodeGenTarget('rtw')
                % Update buildInfo
                srcDir = fullfile(fileparts(mfilename('fullpath')),'src'); 
                includeDir = fullfile(fileparts(mfilename('fullpath')),'include');
                addIncludePaths(buildInfo,includeDir);
                % Use the following API's to add include files, sources and
                % linker flags
                addIncludeFiles(buildInfo,'imu.h',includeDir);
                addSourceFiles(buildInfo,'imu.c',srcDir);
                %addLinkFlags(buildInfo,{'-lSource'});
                %addLinkObjects(buildInfo,'sourcelib.a',srcDir);
                %addCompileFlags(buildInfo,{'-D_DEBUG=1'});
                %addDefines(buildInfo,'MY_DEFINE_1')
            end
        end
    end
end
