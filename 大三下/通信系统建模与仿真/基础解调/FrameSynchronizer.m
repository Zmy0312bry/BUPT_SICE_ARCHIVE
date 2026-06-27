classdef (StrictDefaults)FrameSynchronizer < matlab.System & matlab.system.mixin.Propagates & ...
        matlab.system.mixin.CustomIcon
    %FrameSynchronizer Frame Synchronizer
    %   This System object converts fixed-size or variable-size inputs into
    %   fixed-size output frames with a specified length, which is the first
    %   output of the step function call. The second output of the step
    %   function call is a boolean signal indicating if the first output is a
    %   valid frame. A valid frame at the first output always starts with a
    %   preamble.
    %
    %   Limitations:
    %   1) Only the first preamble (for Bit Input) or the best preamble
    %   (for Symbol Input) in the IDX input is handled. Rest of the
    %   preambles are neglected.
    %   2) The internal buffer length is (5 * OutputFrameLength). The input
    %   length must be less than or equal to this.
    
    % Copyright 2016-2018 The MathWorks, Inc.
    
    %#codegen
    %#ok<*EMCA>
    
    properties (Nontunable)
        %Input Input
        %   Specify the type of input as one of 'Symbol' | 'Bit'. The
        %   default value is 'Symbol'. 'Bit' specifies that input is bit
        %   valued and each input element is either 1 or 0. For all other
        %   types of input, use 'Symbol'.
        Input = 'Symbol';
        %OutputFrameLength Output frame length
        %   Specify the output frame length as a numeric, real, positive
        %   integer scalar. The default value of this property is 100.
        OutputFrameLength = 100
        %PreambleLength Preamble length
        %   Specify the preamble length as a numeric, real, positive integer
        %   scalar. The default value of this property is 4.
        PreambleLength = 4
    end
    
    properties (Constant, Access = private)
        pNumOutFramesInBuffer = 5  % Buffer length in number of frames
    end
    
    properties (Access = private, Nontunable)
        pIsBitInput = false % Input='Bit'
        pBufferLength       % Buffer length
        pPrbIdxBufferLength % Preamble index buffer length
        pStepFcn            % Function pointer to perform frame sync or not (streaming)
    end
    
    properties (Access = private)
        pPrbLenOffset         % offset to get Preamble start index from end index
        pBuffer               % Internal circular buffer
        pNBuffer              % Number of elements in buffer
        pBufferStartIdx       % 0-based index i.e. pBufferStartIdx=0 points to the first element
        pBufferEndIdx         % 1-based index i.e. pBufferEndIdx=10 means the last element is at 10th position
        pPrbIdxBuffer         % 1-based index of Preamble start location in buffer
        pNPrbIdxBuffer        % Number of preambles in buffer
        pPrbIdxBufferStartIdx % 1-based index i.e. pPrbIdxBufferStartIdx=1 points to the first element
    end
    
    properties(Constant, Hidden)
        InputSet = matlab.system.StringSet({ ...
            'Symbol', 'Bit'});
    end

    methods
        function obj = FrameSynchronizer(varargin)
            setProperties(obj, nargin, varargin{:});
        end
        
        function set.Input(obj, inp)
            obj.pIsBitInput = strcmpi(inp, 'Bit'); %#ok<MCSUP>
            obj.Input = inp;
        end

        function set.OutputFrameLength(obj, outFrmLen)
            propName = 'OutputFrameLength';
            validateattributes(outFrmLen, {'numeric'}, ...
                {'real','scalar','positive','integer','finite'}, ...
                [class(obj) '.' propName], propName);
            
            obj.OutputFrameLength = outFrmLen;
        end
        
        function set.PreambleLength(obj, prbLen)
            propName = 'PreambleLength';
            validateattributes(prbLen, {'numeric'}, ...
                {'real','scalar','positive','integer','finite'}, ...
                [class(obj) '.' propName], propName);
            
            obj.PreambleLength = prbLen;
        end
    end
    
    methods (Access = protected)
        function validatePropertiesImpl(obj)
            coder.internal.errorIf(obj.OutputFrameLength < obj.PreambleLength, ...
                'comm:FrameSynchronizer:OutFrmLenLenLessPrbLen');
        end
        
        function validateInputsImpl(obj, varargin)
            % Only floating-point supported for now.
            validateattributes(varargin{1}, {'double','single'}, ...
                {'finite', 'column'}, [class(obj) '.' 'Input'], 'Input');
            validateattributes(varargin{2}, {'double'}, ...
                {'finite', 'column'}, [class(obj) '.' 'Index'], 'Index');
            if length(varargin) == 3
                validateattributes(varargin{3}, {'double', 'single'}, ...
                    {'finite', 'column'}, [class(obj) '.' 'Detection Metric'], 'Detection Metric');
            end
        end
        
        function setupImpl(obj, varargin)
            if obj.pIsBitInput
                obj.pStepFcn = @stepBitInput;
            else
                obj.pStepFcn = @stepSymbolInput;
            end
            obj.pBufferLength = obj.pNumOutFramesInBuffer * obj.OutputFrameLength; % Fixed buffer length
            obj.pBuffer = zeros(obj.pBufferLength, 1, 'like', varargin{1});
            obj.pPrbLenOffset = obj.PreambleLength - 1;
            obj.pPrbIdxBufferLength = obj.pNumOutFramesInBuffer;
        end
        
        function resetImpl(obj)
            % Initialize internal buffer and related properties
            obj.pNBuffer = 0;
            obj.pBufferStartIdx = 0;
            obj.pBufferEndIdx = 0;
            obj.pPrbIdxBuffer = zeros(obj.pPrbIdxBufferLength, 1);
            obj.pNPrbIdxBuffer = 0;
            obj.pPrbIdxBufferStartIdx = 1;
        end
        
        function [y, validFrm] = stepImpl(obj, varargin)            
            [y, validFrm] = obj.pStepFcn(obj, varargin{:});
        end
        
        function releaseImpl(~)
        end
        
        function flag = isInactivePropertyImpl(~, ~)
            flag = false;
        end
        
        function s = saveObjectImpl(obj)
            s = saveObjectImpl@matlab.System(obj);
            if isLocked(obj)
                s.pBufferLength         = obj.pBufferLength;
                s.pStepFcn              = obj.pStepFcn;
                s.pBuffer               = obj.pBuffer;
                s.pIsBitInput           = obj.pIsBitInput;
                s.pNBuffer              = obj.pNBuffer;
                s.pBufferStartIdx       = obj.pBufferStartIdx;
                s.pBufferEndIdx         = obj.pBufferEndIdx;
                s.pPrbLenOffset         = obj.pPrbLenOffset;
                s.pPrbIdxBufferLength   = obj.pPrbIdxBufferLength;
                s.pPrbIdxBuffer         = obj.pPrbIdxBuffer;
                s.pNPrbIdxBuffer        = obj.pNPrbIdxBuffer;
                s.pPrbIdxBufferStartIdx = obj.pPrbIdxBufferStartIdx;                
            end
        end
        
        function loadObjectImpl(obj, s, wasLocked)
            if wasLocked
                obj.pBufferLength         = s.pBufferLength;
                obj.pStepFcn              = s.pStepFcn;
                obj.pBuffer               = s.pBuffer;
                obj.pIsBitInput           = s.pIsBitInput;
                obj.pNBuffer              = s.pNBuffer;
                obj.pBufferStartIdx       = s.pBufferStartIdx;
                obj.pBufferEndIdx         = s.pBufferEndIdx;
                obj.pPrbLenOffset         = s.pPrbLenOffset;
                obj.pPrbIdxBufferLength   = s.pPrbIdxBufferLength;
                obj.pPrbIdxBuffer         = s.pPrbIdxBuffer;
                obj.pNPrbIdxBuffer        = s.pNPrbIdxBuffer;
                obj.pPrbIdxBufferStartIdx = s.pPrbIdxBufferStartIdx;
            end
            loadObjectImpl@matlab.System(obj, s);
        end
        
        function num = getNumInputsImpl(obj)
            if ~obj.pIsBitInput
                num = 3;
            else
                num = 2;
            end
        end
        
        function num = getNumOutputsImpl(~)
            num = 2;
        end
        
        function flag = isInputSizeLockedImpl(~,~)
            flag = false;
        end
        
        function flag = isInputComplexityLockedImpl(~,~)
            flag = true; % Complexity locked for now
        end
        
        function flag = isOutputComplexityLockedImpl(~,~)
            flag = true;
        end
        
        function varargout = isOutputFixedSizeImpl(~)
            varargout = {true, true};
        end
        
        function varargout = getOutputSizeImpl(obj)
            % Return size for each output port
            
            % Input must be empty, scalar or column vector.
            inSigMaxDim = propagatedInputSize(obj, 1);
            coder.internal.errorIf((length(inSigMaxDim) ~= 2) || ...
                (inSigMaxDim(2) ~= 1), 'comm:FrameSynchronizer:InvalidInputDims');
            
            % Input length must be less than or greater than output frame
            % length.
            coder.internal.errorIf(inSigMaxDim(1) < obj.OutputFrameLength, ...
                'comm:FrameSynchronizer:InputLenLessThanOutFrmLen');
            
            varargout = {[obj.OutputFrameLength 1], [1 1]};
        end
        
        function varargout = getOutputDataTypeImpl(obj)
            varargout = {propagatedInputDataType(obj, 1), 'logical'};
        end
        
        function varargout = isOutputComplexImpl(obj)
            varargout = {propagatedInputComplexity(obj, 1), false};
        end
        
        function icon = getIconImpl(~)
            icon = sprintf('Frame\nSynchronizer');
        end
        
        function varargout = getInputNamesImpl(obj)
            if obj.pIsBitInput
                varargout = {'u','idx'};
            else
                varargout = {'u','idx','dtMt'};
            end
        end
        
        function varargout = getOutputNamesImpl(~)
            varargout = {'Frame', 'Valid'};
        end
    end
    
    methods(Static, Access = protected)
        function header = getHeaderImpl
            header = matlab.system.display.Header('FrameFormation', ...
                'ShowSourceLink', true, ...
                'Title', 'Frame Synchronizer', 'Text', ...
                ['Generate fixed-size output frames from variable-size or ', ...
                'fixed-size inputs. The second output is a boolean value ', ...
                'indicating if the first output is a valid frame. A valid ', ...
                'always starts with a preamble.']);
        end
        
        function groups = getPropertyGroupsImpl
            params = matlab.system.display.Section(...
                'Title', 'Parameters',...
                'PropertyList', {'Input', 'OutputFrameLength', 'PreambleLength'});
            groups = params;
        end
    end
    
    methods(Access = private)
        
        function setBuffer(obj, x, preambleEndIdx)            
            
            if ~isempty(x)
                % Process x
                xLen = length(x);
                linearIdx = (obj.pBufferStartIdx + obj.pNBuffer) + (1:xLen);
                circularIdx = mod(linearIdx - 1, obj.pBufferLength) + 1;
                obj.pBuffer(circularIdx, 1) = x;
                oldNBuffer = obj.pNBuffer;
                obj.pNBuffer = obj.pNBuffer + xLen;
                obj.pBufferEndIdx = circularIdx(end);
                if obj.pNBuffer > obj.pBufferLength
                    % Buffer overflow. Data at the beginning of the buffer
                    % overwritten with new data.
                    obj.pNBuffer = obj.pBufferLength;
                    obj.pBufferStartIdx = circularIdx(end);
                    
                    for k = obj.pNPrbIdxBuffer : -1 : 1
                        linIdx = obj.pPrbIdxBufferStartIdx - 1 + k;
                        cirIdx = mod(linIdx - 1, obj.pPrbIdxBufferLength) + 1;
                        if obj.pPrbIdxBuffer(cirIdx) <= circularIdx(end)
                            obj.pPrbIdxBuffer(cirIdx) = 0;
                            obj.pNPrbIdxBuffer = obj.pNPrbIdxBuffer - 1;
                        end
                    end
                end
                
                % Process preambleEndIdx
                if ~isempty(preambleEndIdx)
                    prbStartIdx = preambleEndIdx(1) - obj.pPrbLenOffset;
                    linearPrbStartIdx = obj.pBufferStartIdx + oldNBuffer + prbStartIdx;
                    if (linearPrbStartIdx > 0)
                        circularPrbStartIdx = mod(linearPrbStartIdx - 1, obj.pBufferLength) + 1;
                        
                        linIdx = obj.pPrbIdxBufferStartIdx + obj.pNPrbIdxBuffer;
                        cirIdx = mod(linIdx - 1, obj.pPrbIdxBufferLength) + 1;
                        obj.pPrbIdxBuffer(cirIdx) = circularPrbStartIdx;
                        obj.pNPrbIdxBuffer = obj.pNPrbIdxBuffer + 1;
                        if obj.pNPrbIdxBuffer > obj.pPrbIdxBufferLength
                            % Buffer overflow. Data at the beginning of the buffer
                            % overwritten with new data.
                            obj.pNPrbIdxBuffer = obj.pPrbIdxBufferLength;
                            obj.pPrbIdxBufferStartIdx = mod(cirIdx, obj.pPrbIdxBufferLength) + 1;
                        end
                    end
                end
            end
        end
        
        function [y, validFrm] = getBuffer(obj)
            
            y = zeros(obj.OutputFrameLength, 1, 'like', obj.pBuffer);
            validFrm = false;
            
            if obj.pNPrbIdxBuffer > 0
                % Buffer has a preamble
                
                nValid = obj.pBufferEndIdx - obj.pPrbIdxBuffer(obj.pPrbIdxBufferStartIdx) + 1;
                if nValid < 1
                    nValid = obj.pNBuffer - (obj.pPrbIdxBuffer(obj.pPrbIdxBufferStartIdx) - obj.pBufferStartIdx - 1);
                end
                if nValid >= obj.OutputFrameLength
                    % Enough valid data in the buffer to output
                    nInvalid = obj.pNBuffer - nValid;
                    linearIdx = obj.pPrbIdxBuffer(obj.pPrbIdxBufferStartIdx) + (0 : obj.OutputFrameLength-1);
                    circularIdx = mod(linearIdx - 1, obj.pBufferLength) + 1;
                    y(1:obj.OutputFrameLength, 1) = obj.pBuffer(circularIdx);
                    validFrm = true;
                    % Update buffer states
                    obj.pPrbIdxBuffer(obj.pPrbIdxBufferStartIdx) = 0;
                    obj.pNPrbIdxBuffer = obj.pNPrbIdxBuffer - 1;
                    obj.pPrbIdxBufferStartIdx = mod(obj.pPrbIdxBufferStartIdx, obj.pPrbIdxBufferLength) + 1;
                    obj.pBufferStartIdx = circularIdx(end);
                    obj.pNBuffer = obj.pNBuffer - obj.OutputFrameLength - nInvalid;
                end
            end
        end
        
        function [y, validFrm] = stepBitInput(obj, x, idx)
            
            obj.setBuffer(x, idx);
            [y, validFrm] = obj.getBuffer();
            
        end
        
        function [y, validFrm] = stepSymbolInput(obj, x, idx, dtMt)
            if ~isempty(idx)
                [~, maxIdx] = max(dtMt(idx));
                bestIdx = idx(maxIdx);
            else
                bestIdx = idx;
            end
            [y, validFrm] = stepBitInput(obj, x, bestIdx);            
        end
    end
    
end

% [EOF]
