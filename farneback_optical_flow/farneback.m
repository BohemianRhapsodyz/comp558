% function [] = farneback()

close all;
clear all;

fileName = '315347705_8362364153805063_7853812457404860863_n.mp4';
source=VideoReader(fileName);
height=source.H;
width=source.W;
framenum=source.NumberOfFrames;
start_frame=59;               %read from 59th frame, can be changed to other 
fr=read(source,start_frame);            
I=fr;
lengthfile=framenum-start_frame;  

% The parameters at the end are super important. Otherwise, it's too noisy
opticFlow = opticalFlowFarneback("NeighborhoodSize",16, "FilterSize", 40);

h = figure;
movegui(h);
hViewPanel = uipanel(h,'Position',[0 0 1 1],'Title','Plot of Optical Flow Vectors');
hPlot = axes(hViewPanel);


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
        maxOpticalFlow = maxElement
        maxOpticalFlowCoords = [colIndex, rowIndex, l+start_frame]
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

    imshow(fr)
    hold on
    plot(flow,'DecimationFactor',[5 5],'ScaleFactor',2,'Parent',hPlot);
    plot(maxOpticalFlowCoords(1),maxOpticalFlowCoords(2), 'ro', 'MarkerSize', 10, 'LineWidth', 1);
    hold off
    pause(10^-3)
    
end

% % Edge Detector Code
%     BW1 = edge(Im,'Canny', [0.3]);
%     imshow(BW1);

