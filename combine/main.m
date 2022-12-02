clear all;
close all;
clc
% earliest_frame=65;
% start_frame=120;               %read from 89th frame, can be changed to other 
% box_x=20; %interest_region box size
% box_y=20;
% for second video
earliest_frame=60;
start_frame=61;
end_frame=70;
box_x=30; %interest_region box size
box_y=30;
% %for pink pig
% earliest_frame=1;
% start_frame=26;
% end_frame=30;
% box_x=90; %interest_region box size
% box_y=90;

%% farneback
% Returns [y coordinate, x coordinate, frame number]


    willPlot = true;
    
%     fileName = '315347705_8362364153805063_7853812457404860863_n.mp4';
    fileName = 'Animation Reference Footage VolleyBall Drop (reference).mp4'
% fileName = 'Peppa_Pig_Ball_Animation.mp4'


    source=VideoReader(fileName);
    height=source.H;
    width=source.W;
    framenum=source.NumberOfFrames;
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
%         Im=im2gray(fr);
        Im=rgb2gray(fr);
        flow = estimateFlow(opticFlow, Im);
        [maxInColumn, maxInColumnIndex] = max(flow.Magnitude);
        [maxElement, colIndex] = max(maxInColumn);
        rowIndex = maxInColumnIndex(colIndex);
        
        % If the optical flow is the greatest recorded so far
        if maxElement > maxOpticalFlow 
            maxOpticalFlow = maxElement;
            maxOpticalFlowCoords = [colIndex, rowIndex, l+start_frame];
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
%% meanshift


% fileName = '315347705_8362364153805063_7853812457404860863_n.mp4';
fileName = 'Animation Reference Footage VolleyBall Drop (reference).mp4';
% fileName = 'Peppa_Pig_Ball_Animation.mp4';
source=VideoReader(fileName);
height=source.H;
width=source.W;
framenum=source.NumberOfFrames;

start_frame=maxOpticalFlowCoords(3);               %read from 59th frame, can be changed to other (z frmae found by optical flow)
fr=read(source,start_frame);            
I=fr;
figure(1);
imshow(I);

x=maxOpticalFlowCoords(1);
y=maxOpticalFlowCoords(2);
interest_region=[x-box_x, y-box_y, 2*box_x, 2*box_y];
[temp,rect]=imcrop(I,interest_region);
[a,b,c]=size(temp); 		%a:row,b:col
objectImage=insertShape(fr,'rectangle',interest_region,'Color','red', 'LineWidth',2);
figure; imshow(objectImage);
%%%%%%%%%%%calculate weigt matrix and normalization cofficient C of target object box%%%%%%%%%%
%once you find a target box in zth frame, the matrix and C is fixed in the follow code
y(1)=a/2;
y(2)=b/2;
tic_x=rect(1)+rect(3)/2;
tic_y=rect(2)+rect(4)/2;
m_wei=zeros(a,b);%weigt matrix
h=y(1)^2+y(2)^2 ;


for i=1:a
    for j=1:b
        dist=(i-y(1))^2+(j-y(2))^2;
        m_wei(i,j)=1-dist/h; %epanechnikov profile
    end
end
C=1/sum(sum(m_wei));%normalization cofficient C



%Calculate color histogram of target object box: hist1 also fixed
hist1=zeros(1,4096);
for i=1:a
    for j=1:b
        %rgb color process
        q_r=fix(double(temp(i,j,1))/16);  
        q_g=fix(double(temp(i,j,2))/16);
        q_b=fix(double(temp(i,j,3))/16);
        q_temp=q_r*256+q_g*16+q_b;            
        hist1(q_temp+1)= hist1(q_temp+1)+m_wei(i,j);    %histgoram of target
    end
end
hist1=hist1*C; %normalize histgoram
rect(3)=ceil(rect(3));
rect(4)=ceil(rect(4));
%% variable to store v1 v2 v3 v4 ticx tic y for the whole process
% v_whole=zeros(framenum,4);
ticx_whole_f=tic_x;
ticy_whole_f=tic_y;
%% going forwards 
lengthfile=framenum-start_frame;  
for l=1:lengthfile
    fr=read(source,l+start_frame);
    Im=fr;
    num=0;
    Y=[2,2];
    
    
    %%%%%%%mean shift iteration
    while((Y(1)^2+Y(2)^2>0.5)&num<20)  %iteration condtion
        num=num+1;
        temp1=imcrop(Im,rect);
        %calcluate color histogram of region to find: hist2 will change every frame
        hist2=zeros(1,4096);
        for i=1:a
            for j=1:b %rgb color process
                q_r=fix(double(temp1(i,j,1))/16);
                q_g=fix(double(temp1(i,j,2))/16);
                q_b=fix(double(temp1(i,j,3))/16);
                q_temp1(i,j)=q_r*256+q_g*16+q_b;
                hist2(q_temp1(i,j)+1)= hist2(q_temp1(i,j)+1)+m_wei(i,j); %histogram of region to find
            end
        end
        hist2=hist2*C;
        figure(2);
        subplot(1,2,1);
        plot(hist2);
        hold on;
        
        w=zeros(1,4096);
        for i=1:4096
            if(hist2(i)~=0) 
                w(i)=sqrt(hist1(i)/hist2(i)); %compare hist1 and hist2
            else
                w(i)=0;
            end
        end
        
        
        %calculate meanshift vecotr (means the shift of x and y of position to be added)
        sum_w=0;
        xw=[0,0];
        for i=1:a;
            for j=1:b
                sum_w=sum_w+w(uint32(q_temp1(i,j))+1);
                xw=xw+w(uint32(q_temp1(i,j))+1)*[i-y(1)-0.5,j-y(2)-0.5];
            end
        end
        Y=xw/sum_w;
        %update center position
        rect(1)=rect(1)+Y(2);
        rect(2)=rect(2)+Y(1);
    end
    
    %%%tracking box%%%
    tic_x=[tic_x;rect(1)+rect(3)/2];
    tic_y=[tic_y;rect(2)+rect(4)/2];
    
    v1=rect(1);
    v2=rect(2);
    v3=rect(3);
    v4=rect(4);
     %%%display%%%
    subplot(1,2,2);
    imshow(uint8(Im));
    title('object track result and trajctory');
    hold on;
    plot([v1,v1+v3],[v2,v2],[v1,v1],[v2,v2+v4],[v1,v1+v3],[v2+v4,v2+v4],[v1+v3,v1+v3],[v2,v2+v4],'LineWidth',2,'Color','r');
    plot(tic_x,tic_y,'LineWidth',2,'Color','b');
    
    v_whole_f(l,:)=[v1 v2 v3 v4];
    ticx_whole_f=[ticx_whole_f;rect(1)+rect(3)/2];
    ticy_whole_f=[ticy_whole_f;rect(2)+rect(4)/2];
    
end

%% going backwards
[temp,rect]=imcrop(I,interest_region);
% [a,b,c]=size(temp); 		
%a:row,b:col
a=2*box_x;
b=2*box_y;
y(1)=a/2;
y(2)=b/2;
tic_x=rect(1)+rect(3)/2;
tic_y=rect(2)+rect(4)/2;
ticx_whole_b=tic_x;
ticy_whole_b=tic_y;
lengthfile=start_frame;  
for l=1:(lengthfile-earliest_frame)
    fr=read(source,start_frame-l);
    Im=fr;
    num=0;
    Y=[2,2];
%     if((rect(1))<0||(rect(2)<0))
%             break;
%     end
    
    %%%%%%%mean shift iteration
    while((Y(1)^2+Y(2)^2>0.5)&num<20)  %iteration condtion
%         if((rect(1))<0||(rect(2)<0))
%             break;
%         end
        num=num+1;
        temp1=imcrop(Im,rect);
        if (size(temp1,2)<b)
            break;
        end
        %calcluate color histogram of region to find: hist2 will change every frame
        hist2=zeros(1,4096);
        for i=1:a
            for j=1:b %rgb color process
                q_r=fix(double(temp1(i,j,1))/16);
                q_g=fix(double(temp1(i,j,2))/16);
                q_b=fix(double(temp1(i,j,3))/16);
                q_temp1(i,j)=q_r*256+q_g*16+q_b;
                hist2(q_temp1(i,j)+1)= hist2(q_temp1(i,j)+1)+m_wei(i,j); %histogram of region to find
            end
        end
        hist2=hist2*C;
        figure(3);
        subplot(1,2,1);
        plot(hist2);
        hold on;
        
        w=zeros(1,4096);
        for i=1:4096
            if(hist2(i)~=0) 
                w(i)=sqrt(hist1(i)/hist2(i)); %compare hist1 and hist2
            else
                w(i)=0;
            end
        end
        
        
        %calculate meanshift vecotr (means the shift of x and y of position to be added)
        sum_w=0;
        xw=[0,0];
        for i=1:a;
            for j=1:b
                sum_w=sum_w+w(uint32(q_temp1(i,j))+1);
                xw=xw+w(uint32(q_temp1(i,j))+1)*[i-y(1)-0.5,j-y(2)-0.5];
            end
        end
        Y=xw/sum_w;
        %update center position
        rect(1)=rect(1)+Y(2);
        rect(2)=rect(2)+Y(1);
    end
    
    %%%tracking box%%%
    tic_x=[tic_x;rect(1)+rect(3)/2];
    tic_y=[tic_y;rect(2)+rect(4)/2];
    
    v1=rect(1);
    v2=rect(2);
    v3=rect(3);
    v4=rect(4);
     %%%display%%%
    subplot(1,2,2);
    imshow(uint8(Im));
    title('object track result and trajctory');
    hold on;
    plot([v1,v1+v3],[v2,v2],[v1,v1],[v2,v2+v4],[v1,v1+v3],[v2+v4,v2+v4],[v1+v3,v1+v3],[v2,v2+v4],'LineWidth',2,'Color','r');
    plot(tic_x,tic_y,'LineWidth',2,'Color','b');
    
    v_whole_b(l,:)=[v1 v2 v3 v4];
    ticx_whole_b=[rect(1)+rect(3)/2;ticx_whole_b];
    ticy_whole_b=[rect(2)+rect(4)/2;ticy_whole_b];
end
%% combine back and forward to whole process
%删除ticy_whole_b最后一行
% ticy_whole_b(end)=[];
% ticx_whole_b(end)=[];
ticx_whole=[ticx_whole_b;ticx_whole_f];
ticy_whole=[ticy_whole_b;ticy_whole_f];
v_whole=[flipdim(v_whole_b,1);v_whole_f];

%画图
i=1;
for l=earliest_frame:framenum-1
    fr=read(source,l);
    Im=fr;    
    figure(5);
    imshow(uint8(Im));
    hold on;
    title('final object track result and trajctory');
    plot([v_whole(i,1),v_whole(i,1)+v_whole(i,3)],[v_whole(i,2),v_whole(i,2)],...
        [v_whole(i,1),v_whole(i,1)],[v_whole(i,2),v_whole(i,2)+v_whole(i,4)],[v_whole(i,1),v_whole(i,1)+v_whole(i,3)],...
        [v_whole(i,2)+v_whole(i,4),v_whole(i,2)+v_whole(i,4)],[v_whole(i,1)+v_whole(i,3),v_whole(i,1)+v_whole(i,3)],[v_whole(i,2),v_whole(i,2)+v_whole(i,4)],...
        'LineWidth',2,'Color','r');
    plot(ticx_whole(1:i),ticy_whole(1:i),'LineWidth',2,'Color','b');
    i=i+1;
end