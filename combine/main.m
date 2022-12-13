clear all;
close all;
clc

% video 1, earpods

 fileName = 'Videos/vid1_trim.mp4';
 earliest_frame=65;
 start_frame=90;               %read from 89th frame, can be changed to other
 end_frame=120;
 frame_for_canny_start=110;
 frame_for_canny_end=115;
 box_x=20; %interest_region box size
 box_y=20;


%{
% video 2, volleyball bouncing

fileName = 'Videos/vid2_trim.mp4';
earliest_frame=1;
start_frame=2;
end_frame=20;
frame_for_canny_start=140;
frame_for_canny_end=145;
box_x=30; %interest_region box size
box_y=30;



% video 3, clear ball boucing
fileName = 'Videos/vid3_trim.mp4';
earliest_frame=1;
start_frame=100;
end_frame=161;
frame_for_canny_start=140;
frame_for_canny_end=145;
box_x=90; %interest_region box size
box_y=90;


% video 4, peppa pig
fileName = 'Videos/vid4.mp4'
earliest_frame=1;
start_frame=26;
end_frame=30;
frame_for_canny_start=140;
frame_for_canny_end=145;
box_x=90; %interest_region box size
box_y=90;
%}

%% farneback
% Returns [y coordinate, x coordinate, frame number]
maxOpticalFlowCoords = farneback(fileName,start_frame,end_frame);

%% meanshift
source=VideoReader(fileName);
height=source.H;
width=source.W;
framenum=source.NumberOfFrames;

start_frame=maxOpticalFlowCoords(3);               
fr=read(source,start_frame);            
I=fr;
figure;
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
        figure(4);
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
    title('forward object track result and trajctory');
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
        figure(5);
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
    title('backward object track result and trajctory');
    hold on;
    plot([v1,v1+v3],[v2,v2],[v1,v1],[v2,v2+v4],[v1,v1+v3],[v2+v4,v2+v4],[v1+v3,v1+v3],[v2,v2+v4],'LineWidth',2,'Color','r');
    plot(tic_x,tic_y,'LineWidth',2,'Color','b');
    
    v_whole_b(l,:)=[v1 v2 v3 v4];
    ticx_whole_b=[rect(1)+rect(3)/2;ticx_whole_b];
    ticy_whole_b=[rect(2)+rect(4)/2;ticy_whole_b];
end
%% combine back and forward to whole process

% ticy_whole_b(end)=[];
% ticx_whole_b(end)=[];
ticx_whole=[ticx_whole_b;ticx_whole_f];
ticy_whole=[ticy_whole_b;ticy_whole_f];
v_whole=[flipdim(v_whole_b,1);v_whole_f];

i=1;
for l=earliest_frame:framenum-1
    fr=read(source,l);
    Im=fr;    
    figure(6);
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

%% RANSAC
% returns the predicted image coordinates happening next 
% with length of time being same as the input video
[xFuture, yFuture] = predictPathRANSAC(v_whole, box_x);

%% edge detection
[pixelBinary, pixels] = object_pixels(fileName,frame_for_canny_start,frame_for_canny_end);

%% Prediction showing the future trace on image
figure(6);
title('final object track result and prediction trajctory');
% fr=read(source,1);
% image(fr);
hold on;
prediction_Im = Im; % Image on which we place the prediction object locations

for i=1:fix(size(xFuture,2)/5) % every 5 frames
    max_y = fix(yFuture(5*i)+size(pixels,1)-1);
    max_x = fix(xFuture(5*i)+size(pixels,2)-1);
    % If the predicted object location is outside of the image, stop
    if (max_y > height || max_x > width)
        break
    end

    % The following code takes the object and places it on the image, while
    % using a mask to ensure only the object pixels are placed on the image

    % Background image where the object will be placed
    bg_image = prediction_Im(fix(yFuture(5*i)):max_y,fix(xFuture(5*i)):max_x,:);
    % Get the pixel binary in 3D (to indicate whether the pixel in the 
    % rectangle is the object or not)
    pixelBinary_3D = reshape([pixelBinary,pixelBinary,pixelBinary],[size(pixels,1), size(pixels,2), 3]);
    % Using pixelBinary_3D as a mask, place the object onto the background
    combined = pixels.*uint8(pixelBinary_3D) + bg_image.*uint8(~pixelBinary_3D); 
    % Insert this rectangle back into the full image
    prediction_Im(fix(yFuture(5*i)):max_y,fix(xFuture(5*i)):max_x,:) = combined;

end
imshow(prediction_Im);


%% Generating the final video

% exact background image
source=VideoReader(fileName);
%{
subplot(221); imshow(uint8(getBackGrnd(fileName, 10, 'mean')));
subplot(222); imshow(uint8(getBackGrnd(fileName, 10, 'median')));
subplot(223); imshow(uint8(getBackGrnd(fileName, 50, 'mean')));
subplot(224); imshow(uint8(getBackGrnd(fileName, 50, 'median')));
%}

figure;
% no need to use the entire clip, but a few frames, 
% due to stationary camera
backGrnd = uint8(getBackGrnd(fileName, end_frame/10, 'median'));
imshow(backGrnd);
title("Extracted background image using a median filter");

% output the future video, until the output has the same length as the input video, or the
% object exits the frame
futureAvi = futureSeer(xFuture, yFuture, fileName, backGrnd, pixelBinary, pixels);

%% Combine predicted video with the original




