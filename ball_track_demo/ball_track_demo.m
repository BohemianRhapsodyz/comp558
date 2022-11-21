clear
close all
%%
fileName = '315347705_8362364153805063_7853812457404860863_n.mp4';
source=VideoReader(fileName);
height=source.H;
width=source.W;
framenum=source.NumberOfFrames;
i=0;
box_x=20; %interest_region box size
box_y=20;
%%
for n=1:framenum-1
    i=i+1;
    %read two frames
    fr=read(source,n);      
    fr_p=read(source,n+1);  
    fr = imresize(fr,[512,288]); % resize to accelerate computation
    fr_p = imresize(fr_p,[512,288]);
    fr_layer(:,:,:,i)=fr;  %save all frame
    imshow(fr_layer(:,:,:,i));
    fr=double(rgb2gray(fr));     %convert to grayscale img and double-precision
    fr_p=double(rgb2gray(fr_p)); 
    %calculate optical flow field
    [u,v]=lk(fr,fr_p,6);
    hold on
    opflow=opticalFlow(u,v);
    plot(opflow,'DecimationFactor',[20 20],'ScaleFactor',10);
    hold off
    disp(['calculate optical flow field, please wait. frame: ',num2str(i),'/',num2str(framenum)]); 
    V=sqrt(u.^2+v.^2);          %mantitude
    %smooth (optional)
    h=fspecial('gaussian');
    V=(filter2(h,V));
    V_layer(:,:,i)=V;  %save every mantitude
%     save('V_layer_j.mat','V_layer');
%     figure;
%     mesh(V);
end
%%
% load('V_layer_j.mat');
% find max mantitude and location
[max_val, position]=max(V_layer(:));
[y,x,z]=ind2sub(size(V_layer),position);
%for z+1'th frame£¬set an interest region, do edge detection
interest_region=[x-box_x, y-box_y, 2*box_x, 2*box_y];
objectImage=insertShape(fr_layer(:,:,:,z+1),'rectangle',interest_region,'Color','red');
figure; imshow(objectImage);
ed=edge(double(rgb2gray(fr_layer(:,:,:,z+1))),'canny',[],5);
figure; imshow(ed);
%find all edge position
[row,col]=find(ed==1); %x,y coordinate
j=1;
%find edge in interest region, that is the object shape.
for i=1:size(row)
if((row(i)>=(y-box_y)&&row(i)<=(y+box_y))&&(col(i)>=(x-box_x)&&col(i)<=(x+box_x)))
    object_position(j,:)=[col(i),row(i)];
    j=j+1;
end
end
height=size(fr,1);
width=size(fr,2);
%display object
imagee=zeros(height,width);
for i=1:size(object_position,1)
imagee(object_position(i,2),object_position(i,1))=1;
end
figure; imshow(imagee);
%center position
center_x=mean(object_position(:,1));
center_y=mean(object_position(:,2));

%%
%key point tracking (under developed)
points = detectMinEigenFeatures(rgb2gray(fr_layer(:,:,:,z+1)),'ROI',[max(1,x-box_x),max(1, y-box_y),2*box_x,2*box_y]);
pointImage = insertMarker(fr_layer(:,:,:,z+1),points.Location,'+','Color','white');
figure; imshow(pointImage);
tracker = vision.PointTracker('MaxBidirectionalError',1);
initialize(tracker,points.Location,fr_layer(:,:,:,z+1));

videoReader = VideoReader('315347705_8362364153805063_7853812457404860863_n.mp4');
videoPlayer = vision.VideoPlayer('Position',[100,100,680,520]);
frame_num=0;
while hasFrame(videoReader)
    frame_num=frame_num+1;
    frame = readFrame(videoReader);
    if (frame_num>=z+1)
%       frame = readFrame(videoReader);
      frame = imresize(frame,[512,288]);
      [points,validity] = tracker(frame);
      out = insertMarker(frame,points(validity, :),'+');
      videoPlayer(out);
    end
end
release(videoPlayer);





