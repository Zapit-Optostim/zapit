function setUpFigure(obj)
    % Set up the figure window
    %
    % Maja Skretowska - SWC 2021

    obj.hFig = figure(7824);
    obj.hFig.NumberTitle='off';
    obj.hImAx=axes(obj.hFig);
    
    obj.hImLive = image(zeros(obj.imSize),'Parent',obj.hImAx);
    % Set up a callback function to run each time the user clicks on the axes
    obj.hImLive.ButtonDownFcn = @obj.pointBeamToLocationInImage;
    
    colormap gray
    axis tight equal
    
    obj.cam.vid.FramesAcquiredFcn = @obj.dispFrame;
    obj.cam.vid.FramesAcquiredFcnCount=1; %Run frame acq fun every N frames
    obj.cam.startVideo;
    
    % Overlay an invisible red circle
    hold on
    obj.hLastPoint = plot(nan,nan,'or','MarkerSize',8,'LineWidth',1);
    hold off


    % Call the class destructor when figure is closed. This ensures all
    % the hardware tasks are stopped.
    obj.hFig.CloseRequestFcn = @obj.delete;
end
