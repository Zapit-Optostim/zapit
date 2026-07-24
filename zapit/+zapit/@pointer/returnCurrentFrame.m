function im = returnCurrentFrame(obj,nFrames)
    % Return the last recorded camera image and optionally the last n frames
    %
    % function im = zapit.pointer.returnCurrentFrame(nFrames)
    %
    % Purpose
    % Return the last frame and, if requested, the last n frames.
    %
    % Inputs
    % nFrames - [optional] 1 by default. If >1 this many frames are returned.
    %
    % Outputs
    % im - the image
    %
    %

    % TODO -- this is really slow right now if nFrames > 1 (since refactoring 21/12/2022)
    if nargin<2
        nFrames = 1;
    end

    im = obj.lastAcquiredFrame;

    if nFrames==1
        return
    end

    im = repmat(im,[1,1,nFrames]);
    lastFrameAcquired = obj.cam.vid.FramesAcquired; % The frame number

    % Collect frames as they arrive. This is inherently a blocking wait: the camera
    % produces frames at a fixed rate (~20 fps) so gathering nFrames takes about
    % nFrames/frameRate seconds no matter what. The pause is not cosmetic -- MATLAB
    % is single threaded, so without yielding here the frame-acquired callback that
    % updates lastAcquiredFrame can never run and we would collect stale duplicates.
    % It also stops the loop pegging a CPU core. We bail out (returning whatever we
    % have) if the camera stops or we wait too long, so this can never hang.
    indexToInsertFrameInto = 2;
    tWait = tic;
    while indexToInsertFrameInto < nFrames
        if ~obj.cam.isrunning || toc(tWait) > 5
            im = im(:,:,1:indexToInsertFrameInto-1); % return what we managed to collect
            break
        end

        pause(0.01) % yield so the frame-acquired callback can update lastAcquiredFrame

        % Add a new frame once the frame counter has incremented
        currentFramesAcquired = obj.cam.vid.FramesAcquired;
        if currentFramesAcquired > lastFrameAcquired
            im(:,:,indexToInsertFrameInto) = obj.lastAcquiredFrame;
            lastFrameAcquired = currentFramesAcquired;
            indexToInsertFrameInto = indexToInsertFrameInto +1;
        end
    end
end % returnCurrentFrame
