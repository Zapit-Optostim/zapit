function im = returnCurrentFrame(obj,nFrames)
    % Return the last recorded camera image and optionally the last n frames
    %
    % function im = zapit.pointer.returnCurrentFrame(obj,nFrames)
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

    indexToInsertFrameInto = 2;
    while indexToInsertFrameInto < nFrames
        % If statment adds a new frame once the counter of number of frames
        % has incrememted
        currentFramesAcquired = obj.cam.vid.FramesAcquired;
        if currentFramesAcquired > lastFrameAcquired
            im(:,:,indexToInsertFrameInto) = obj.lastAcquiredFrame;
            lastFrameAcquired = currentFramesAcquired;
            indexToInsertFrameInto = indexToInsertFrameInto +1;
        end
    end
end % returnCurrentFrame
