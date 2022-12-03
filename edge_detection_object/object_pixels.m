function [pixels, pixelShape] = getObjectPixels()

    movementThreshold = 1;
    
    fileName = '315347705_8362364153805063_7853812457404860863_n.mp4';
    source=VideoReader(fileName);
    global height
    height=source.H;
    global width
    width=source.W;
    
    % Get image when the object is moving the fastest
    maxOpticalFlowCoords = farneback()
    fr=read(source,maxOpticalFlowCoords(3));
    Im=rgb2gray(fr);
    
    % Detect edges
    global edges
    edges = edge(Im,'Canny', [0.3]);
    imshow(edges);
    hold on
    plot(maxOpticalFlowCoords(1),maxOpticalFlowCoords(2), 'ro', 'MarkerSize', 1, 'LineWidth', 1);
    
    % Remove edges in which the corresponding optical flow isn't above a certain threshold
    opticFlow = opticalFlowFarneback("NeighborhoodSize",16, "FilterSize", 40);
    flow = estimateFlow(opticFlow, Im);
    flowMag = flow.Magnitude;
    for i = 1:height
        for j = 1:width
            if flowMag(i,j) < movementThreshold
                edges(i,j) = 0;
            end
        end
    end
    
    
    global pixelBinary
    pixelBinary = zeros(height, width);
    
    % Fill in the shape, crop the sides, remove any lines in the middle of the shape
    recursiveFill(ceil(maxOpticalFlowCoords(2)),ceil(maxOpticalFlowCoords(1)));
    [yOffset, xOffset] = cropImage();
    removeLines();
    pixels = fr(yOffset:(yOffset+size(pixelBinary,1)),xOffset:(xOffset+size(pixelBinary,2)),:);
    
    figure
    imshow(pixelBinary);
    figure
    imshow(pixels)
    
    
    % Create pixelBinary, which indicates the shape of the object by
    % recursively "filling" the area surrounded by the object's edges
    function recursiveFill(y,x)
        global pixelBinary;
        global edges;
        for k = 1:4
            if k == 1
                first = y+1;
                second = x;
            elseif k == 2
                first = y-1;
                second = x;
            elseif k == 3
                first = y;
                second = x+1;
            elseif k == 4
                first = y;
                second = x-1;
            end
            if edges(first, second) == 0 && pixelBinary(first, second) == 0
                pixelBinary(first,second) = 1;
                recursiveFill(first, second);
            else
            end
        end
    end
    
    % Crop pixelBinary so it's only the shape of the object
    function [yOffset, xOffset] = cropImage()
        global pixelBinary
        yOffset = 0;
        xOffset = 0;
        while(max(pixelBinary(:,end)) == 0)
            pixelBinary(:,end) = [];
        end
        while(max(pixelBinary(end,:)) == 0)
            pixelBinary(end,:) = [];
        end
        while(max(pixelBinary(:,1)) == 0)
            pixelBinary(:,1) = [];
            xOffset = xOffset + 1;
        end
        while(max(pixelBinary(1,:)) == 0)
            pixelBinary(1,:) = [];
            yOffset = yOffset + 1;
        end
    end
    
    % Clever function that removes any lines in the shape
    function removeLines()
        global pixelBinary
        for i = 1:size(pixelBinary,1)
            if max(pixelBinary(i,:) > 0)
                startIndex = 1;
                endIndex = size(pixelBinary,2);
                startInObject = false;
                endInObject = false;
                for j = 1:size(pixelBinary,2)
                    if (pixelBinary(i,startIndex) == 1)
                        startInObject = true;
                    end
                    if (pixelBinary(i,endIndex) == 1)
                        endInObject = true;
                    end
                    if startInObject && ~endInObject
                        endIndex = endIndex - 1;
                    end
                    if ~startInObject && endInObject
                        startIndex = startIndex + 1;
                    end
                    if startInObject == endInObject
                        startIndex = startIndex + 1;
                        endIndex = endIndex - 1;
                    end
                    if startInObject && endInObject             
                        pixelBinary(i,startIndex) = 1;
                        pixelBinary(i,endIndex) = 1;
                    end
                    if startIndex >= endIndex
                        break
                    end
                end
            end
        end
    end
