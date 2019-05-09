classdef ProximitySysObject < realtime.internal.SourceSampleTime ...
        & coder.ExternalDependency ...
        & matlab.system.mixin.Propagates ...
        & matlab.system.mixin.CustomIcon
    %
    % System object block for i2c IR LED proximity sensor.
    % 

    %#codegen
    %#ok<*EMCA>
    
    properties
        % Bus
        Bus = 0;
        % Lowpass time constant 
        TC = 0.016;
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
        function setupImpl(obj) 
            if isempty(coder.target)
                % Place simulation setup code here
            else
                % Call C-function implementing device initialization
                coder.cinclude('vcnl4000.h');
                % Call C-function implementing device initialization    
                disp(obj.SampleTime)
                coder.ceval('i2c_setup', obj.Bus, obj.getSampleTime, obj.TC);
            end
        end
        
        function prox = stepImpl(obj)
            prox = double(0);
            if isempty(coder.target)
                % Place simulation output code here
            else
                % Call C-function implementing device output
                prox = coder.ceval('i2c_measure', obj.Bus);
            end
        end
        
        function releaseImpl(obj) 
            if isempty(coder.target)
                % Place simulation termination code here
            else
                % Call C-function implementing device termination
                coder.ceval('i2c_cleanup', obj.Bus);
            end
        end
    end
    
    methods (Access=protected)
        %% Define output properties
        function num = getNumInputsImpl(~)
            num = 0;
        end
        
        function num = getNumOutputsImpl(~)
            num = 1;
        end
        
        function flag = isOutputSizeLockedImpl(~,~)
            flag = true;
        end
        
        function varargout = isOutputFixedSizeImpl(~,~)
            varargout{1} = true;
        end
        
        function flag = isOutputComplexityLockedImpl(~,~)
            flag = true;
        end
        
        function varargout = isOutputComplexImpl(~)
            varargout{1} = false;
        end
        
        function varargout = getOutputSizeImpl(~)
            varargout{1} = [1,1];
        end
        
        function varargout = getOutputDataTypeImpl(~)
            varargout{1} = 'double';
        end
        
        function icon = getIconImpl(obj)
            % Define a string as the icon for the System block in Simulink.
            icon = 'VCNL4010';
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
            name = sprintf('IR LED current: %d mA\n', obj.current);
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
                addIncludeFiles(buildInfo,'vcnl4000.h',includeDir);
                addSourceFiles(buildInfo,'vcnl4000.c',srcDir);
                addLinkFlags(buildInfo,{'-lrobotcontrol'});
            end
        end
    end
end
