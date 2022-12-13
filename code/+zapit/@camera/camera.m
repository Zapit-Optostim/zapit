classdef camera < handle
    % zapit.camera
    %
    % Purpose
    % This class acts as an interface between the zapit.pointer class and the MATLAB
    % image acquisition toolbox. This is necessary to provide consistent behavior across
    % different camera drivers.
    %


    properties
        vid   % Holds the camera object
        src   % Holds the camera-specific properties
    end


    % The following properties are used for getters and setters to interface
    % with camera properties that could change between drivers.
    properties
        exposure
    end





    methods
        function obj = camera(camToStart)
            if nargin<1 || isempty(camToStart)
                camToStart=[];
            end

            % Find which adapters are installed
            cams=imaqhwinfo;
            if isempty(cams.InstalledAdaptors)
                fprintf('NO CAMERAS FOUND by dws.camera\n');
                return
            end

            % Loop through each combination of camera and formats and build commands to start each
            constructorCommands = {};
            for ii=1:length(cams.InstalledAdaptors)
                tDevice = imaqhwinfo(cams.InstalledAdaptors{ii});
                if isempty(tDevice.DeviceIDs)
                    continue
                end
                formats = tDevice.DeviceInfo.SupportedFormats;
                for jj=1:length(formats)
                    tCom = tDevice.DeviceInfo.VideoInputConstructor; % command to connect to device
                    tCom = strrep(tCom,')',[', ''',formats{jj},''')'] );
                    constructorCommands = [constructorCommands,tCom];
                end

            end

            constructorCommand=[];
            if length(constructorCommands)==1
                constructorCommand = constructorCommands{1};
            elseif length(constructorCommands)>1 && isempty(camToStart)
                for ii=1:length(constructorCommands)
                    fprintf('%d  -  %s\n',ii,constructorCommands{ii})
                end
                IN='';
                fprintf('\n')
                while isempty(IN) | IN<0 | IN>length(constructorCommands)
                    IN = input('Enter device number and press return: ','s');
                    IN = str2num(IN);
                end
                constructorCommand = constructorCommands{IN};

            elseif length(constructorCommands)>1 && length(camToStart)==1
                fprintf('Available interfaces:\n')
                for ii=1:length(constructorCommands)
                    fprintf('%d  -  %s\n',ii,constructorCommands{ii})
                end
                fprintf('\nConnecting to number %d\n', camToStart)
                constructorCommand = constructorCommands{camToStart};
            else
                fprintf('NO CAMERAS FOUND by dws.camera\n');             
            end


            %Runs one of the camera functions in the camera private sub-directory
            if ~isempty(constructorCommand)
                obj.vid = eval(constructorCommand);
                obj.src = getselectedsource(obj.vid);

                % Set up the camera so that it is manually triggerable an 
                % unlimited number of times. 
                triggerconfig(obj.vid,'manual')
                vid.TriggerRepeat=inf;
                obj.vid.FramesPerTrigger = inf;
                obj.vid.FramesAcquiredFcnCount=1; %Run frame acq fun every frame
            else
                obj.demoMode
            end
            
            % set gain to maximum
            obj.src.Gain = 10;

        end % close constructor


        function delete(obj)
            if isa(obj.vid,'videoinput')
                fprintf('Disconnecting from camera\n')
                stop(obj.vid)
                delete(obj.vid)
            end
        end % close destructor
    end


    % The following methods are involved in starting and stopping the video feed
    methods

        function startVideo(obj)
            if isa(obj.vid,'videoinput')
                start(obj.vid)
                trigger(obj.vid)
            end
        end % startVideo

        function stopVideo(obj)
            if isa(obj.vid,'videoinput')
                stop(obj.vid)
                flushdata(obj.vid)
            end
        end % stopVideo

        function flushdata(obj)
            if isa(obj.vid,'videoinput')
                flushdata(obj.vid)
            end
        end % flushdata

        function lastFrame=getLastFrame(obj)
            if isa(obj.vid,'videoinput')
                lastFrame=squeeze(peekdata(obj.vid,1));
            end
        end % getLastFrame

        function vidRunning=isrunning(obj)
            if isa(obj.vid,'videoinput')
                vidRunning=isrunning(obj.vid);
            else
                vidRunning = false;                
            end
        end % isrunning

        function nFrm=framesAcquired(obj)
            if isa(obj.vid,'videoinput')
                nFrm=obj.vid.FramesAcquired;
            else
                nFrm=0;
            end
        end % framesAcquired

    end % video feed methods


    % The following methods are getters and setters for camera properties
    %
    % With the generic MATLAB package:
    %  SourceName = input1
    %    Type = videosource
    methods
        function exposure = get.exposure(obj)
            if contains(obj.vid.Name,'gentl') % TODO: is this the correct thing to reference?
                exposure = obj.src.ExposureTime;
            else
                exposure = obj.src.Exposure;
            end
        end % get.exposure

        function set.exposure(obj, exposure)
            if contains(obj.vid.Name,'gentl') % TODO: is this the correct thing to reference?
                obj.src.ExposureTime = exposure;
            else
                obj.src.Exposure = exposure;
            end
        end % set.exposure
    end % getters and setters

end % pointer

