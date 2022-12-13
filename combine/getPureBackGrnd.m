function backGrnd = getPureBackGrnd(filename, nTest, method)
    % this exact background image using mean or median filter
    % tic
    if nargin < 2, nTest = 20; end
    if nargin < 3, method = 'median'; end
    v = VideoReader(filename);
    nChannel = size(readFrame(v), 3);
    tTest = linspace(0, v.Duration-1/v.FrameRate , nTest);
    % allocate room for buffer
    buff = NaN([v.Height, v.Width, nChannel, nTest]);
    for fi = 1:nTest
        v.CurrentTime =tTest(fi);
        % read current frame and update model
        buff(:, :, :, mod(fi, nTest) + 1) = readFrame(v);
    end

    % if fi < B (i.e., you processed less than B frames) 
    % the background model is not stable.
    % I am using NaNs as default values for the buffer and these values are ignored when background model is estimated 
    % --> this is the reason why I use nanmedian and nanmean instead of simply median and mean
    switch lower(method)
        case 'median'
            backGrnd = nanmedian(buff, 4);
        case 'mean'
            backGrnd = nanmean(buff, 4);
    end
    % toc
end
