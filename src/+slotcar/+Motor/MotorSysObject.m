classdef MotorSysObject < realtime.internal.SourceSampleTime ...
        & coder.ExternalDependency ...
        & matlab.system.mixin.Propagates ...
        & matlab.system.mixin.CustomIcon
    %
    % System object block for control of motors.
    % 

    %#codegen
    %#ok<*EMCA>
    

    properties
        % PWM frequency
        freq = 25000;
    end
    
    properties (Nontunable)
        
    end
    
    properties (Access = private)
        % Pre-computed constants.
    end
    
    methods
        % Constructor
        function obj = Distance(varargin)
            % Support name-value pair arguments when constructing the object.
            setProperties(obj,nargin,varargin{:});
        end
    end
    
    
    methods (Access=protected)
        function setupImpl(~) 
            if isempty(coder.target)
                % Place simulation setup code here
            else
                coder.cinclude('motor.h');
                % Call C-function implementing device initialization    
                coder.ceval('motor_init');
            end
        end
        
        function stepImpl(~, duty)
            if isempty(coder.target)
                % Place simulation output code here
            else
                coder.cinclude('motor.h');
                % Call C-function implementing device output
                coder.ceval('motor_set', duty);
            end
        end
        
        function releaseImpl(obj) 
            if isempty(coder.target)
                % Place simulation termination code here
            else
                % Call C-function implementing device termination
                coder.cinclude('motor.h');
                coder.ceval('motor_cleanup');
            end
        end
    end
    
    
    methods (Access=protected)
        %% Define output properties
        function num = getNumInputsImpl(~)
            num = 1;
        end
        
        function num = getNumOutputsImpl(~)
            num = 0;
        end
        
        function icon = getIconImpl(obj)
            % Define a string as the icon for the System block in Simulink.
            icon = 'DC';
        end
        
        %pri zavreni nastaveni blocku
        function validatePropertiesImpl(obj)
        end

        function validateInputsImpl(obj,duty)
            % Validate inputs to the step method at initialization
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
            name = sprintf('DC motor #%d', obj.ch);
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
                addIncludeFiles(buildInfo,'motor.h',includeDir);
                addSourceFiles(buildInfo,'motor.c',srcDir);
                addLinkFlags(buildInfo,{'-lrobotcontrol'});
            end
        end
    end
end
