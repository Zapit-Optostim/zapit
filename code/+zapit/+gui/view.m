classdef view < handle

    % zapit.gui.view is the main GUI window: that which first appears when the 
    % user starts the software. It'

    properties
        % Handles for plot elements. (THESE MAY GO ELSEWHERE. NOT SURE YET. OR INHERITED?)
        hFig  % GUI figure window
        hImAx % axes of image
        hImLive  %The image
        hLastPoint % plot handle with location of the last clicked point. TODO-- do we leave this here? It's a unique one. 
        plotOverlayHandles   % All plotted objects laid over the image should keep their handles here

        model % The ZP model object goes here

        listeners = {}; % All go in this cell array
    end



    methods

        function obj = view(hZP)
            if nargin>0
                obj.model = hZP;
            else
                fprintf('Can''t build zapit.gui.view please supply ZP model as input argument\n');
                return
            end

            % Add a listener to the sampleSavePath property of the BT model
            %% obj.listeners{end+1} = addlistener(obj.model, 'sampleSavePath', 'PostSet', @obj.updateSampleSavePathBox); % FOR EXAMPLE

        end %close constructor


        function delete(obj,~,~)
            fprintf('zapit.gui.view is cleaning up\n')
            cellfun(@delete,obj.listeners)

            delete(obj.model);
            obj.model=[];

            delete(obj.hFig);

            %clear from base workspace if present
            evalin('base','clear hZP hZPview')
        end %close destructor


        function closeZapit(obj,~,~)
            %Confirm and quit Zapit (also closing the model and so disconnecting from hardware)
            %This method runs when the user presses the close 
            choice = questdlg('Are you sure you want to quit Zapit?', '', 'Yes', 'No', 'No');

            switch choice
                case 'No'
                    %pass
                case 'Yes'
                    obj.delete
            end
        end
        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -



        %The following methods are callbacks from the menu TODO -- MAKE MENU
        function copyAPItoBaseWorkSpace(obj,~,~)
            fprintf('\nCreating API access components in base workspace:\nmodel: hBT\nview: hBTview\n\n')
            assignin('base','hZPview',obj)
            assignin('base','hZP',obj.model)
        end %copyAPItoBaseWorkSpace

    end


end % close classdef
