% Returns [y coordinate, x coordinate, frame number]
function maxOpticalFlowCoords = farneback()

    willPlot = true;
    
    fileName = '315347705_8362364153805063_7853812457404860863_n.mp4';
    source=VideoReader(fileName);
    height=source.H;
    width=source.W;
    framenum=source.NumberOfFrames;
    start_frame=152;               %read from 59th frame, can be changed to other 
    end_frame = 158; % framenum;
    fr=read(source,start_frame);            
    I=fr;
    lengthfile=end_frame-start_frame;  
    
    % The parameters at the end are super important. Otherwise, it's too noisy
    opticFlow = opticalFlowFarneback("NeighborhoodSize",16, "FilterSize", 40);
    
    if willPlot
        h = figure;
        movegui(h);
        hViewPanel = uipanel(h,'Position',[0 0 1 1],'Title','Plot of Optical Flow Vectors');
        hPlot = axes(hViewPanel);
    end
    
    
    % The following are some variables used to find the maximum optical flow.
    % Basically, if the maximum optical flow is greater than the previously recorded one,
    % we're not sure yet whether it's valid. It might be an outlier. On the next frame, we check to see
    % whether the max optical flow is within 1 of the previous. If it is, then
    % we know it's a real max optical flow. If it's not, then it's probably an
    % outlier and we can just get rid of it.
    
    isConfirmedValid = false; % Whether the optical flow max is an outlier or not
    opticalFlowThreshold = 1; % The number to compare for deciding if an outlier
    prevMaxOpticalFlow = 0;
    prevMaxOpticalFlowCoords = [1,1,1];
    maxOpticalFlow = 0;
    maxOpticalFlowCoords = [1,1,1];
    
    for l=1:lengthfile
        fr=read(source,l+start_frame);
        Im=im2gray(fr);
    
        flow = estimateFlow(opticFlow, Im);
        [maxInColumn, maxInColumnIndex] = max(flow.Magnitude);
        [maxElement, colIndex] = max(maxInColumn);
        rowIndex = maxInColumnIndex(colIndex);
        
        % If the optical flow is the greatest recorded so far
        if maxElement > maxOpticalFlow 
            maxOpticalFlow = maxElement;
            % Search the local neighbourhood to calculate the average
            % position of the flow
            totalFlow = 0;
            middleOfObject = [0 0];
            flowMag = flow.Magnitude;
            for i = max(colIndex-40,1):1:min(colIndex+40, width)
                for j = max(rowIndex-40,1):1:min(rowIndex+40, height)
                    totalFlow = totalFlow + flowMag(j,i);
                    middleOfObject = [middleOfObject(1)+i*flowMag(j,i), middleOfObject(2)+j*flowMag(j,i)];
                end
            end
            middleOfObject = middleOfObject/totalFlow
            maxOpticalFlowCoords = [middleOfObject(1), middleOfObject(2), l+start_frame];
            isConfirmedValid = false;
        % If we confirm that the previously recorded max optical flow is valid
        elseif isConfirmedValid == false && abs(maxElement-maxOpticalFlow) < opticalFlowThreshold
            isConfirmedValid = true;
            prevMaxOpticalFlow = maxOpticalFlow;
            prevMaxOpticalFlowCoords = maxOpticalFlowCoords;
        % If we determine that the previously recorded max optical flow is an outlier
        elseif isConfirmedValid == false && abs(maxElement-maxOpticalFlow) > opticalFlowThreshold
            isConfirmedValid = true;
            maxOpticalFlow = prevMaxOpticalFlow;
            maxOpticalFlowCoords = prevMaxOpticalFlowCoords;
        end
    
        if willPlot
            imshow(fr)
            hold on
            plot(flow,'DecimationFactor',[5 5],'ScaleFactor',2,'Parent',hPlot);
            plot(maxOpticalFlowCoords(1),maxOpticalFlowCoords(2), 'ro', 'MarkerSize', 10, 'LineWidth', 1);
            hold off
            pause(10^-3)
        end
        
    end
    
    if willPlot
        fr=read(source,maxOpticalFlowCoords(3));
        imshow(fr)
        hold on
        plot(maxOpticalFlowCoords(1),maxOpticalFlowCoords(2), 'ro', 'MarkerSize', 10, 'LineWidth', 1);
    end

% % Edge Detector Code
%     BW1 = edge(Im,'Canny', [0.3]);
%     imshow(BW1);

