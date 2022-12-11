function [xFuture, yFuture] = predictPathRANSAC(v_whole, box_x)
    x=v_whole(:,1);
    y=v_whole(:,2);
    
    N = 2;           % second-degree polynomial
    maxDistance = box_x/2; % maximum allowed distance for a point to be inlier
    
    %total number of trials being 200 times of the total number of points
    [P, inlierIdx] = fitPolynomialRANSAC([x,y], N, maxDistance, MaxSamplingAttempts=size(x,1)*200);
    
    % generate the next frames, first get the average distance between points
    first_x = x(1);
    flipped_x = flip(x);
    last_x = flipped_x(1);
    
    % dist_between_pts that 
    dist_between_pts = (last_x-first_x)/size(x,1);
    
    %total_number of points that will be generated
    xFuture=((last_x+dist_between_pts):(dist_between_pts):(last_x+dist_between_pts*size(x,1)));
    yFuture = polyval(P,xFuture);
    
    % PLOT INLIERS, OUTLIERS & CURVE
    yRecoveredCurve = polyval(P,x);
    figure;
    plot(x,yRecoveredCurve,'-g','LineWidth',3)
    hold on;
    plot(x(inlierIdx),y(inlierIdx),'.',x(~inlierIdx),y(~inlierIdx),'ro');
    plot(xFuture,yFuture,'-y','LineWidth',3);
    legend('Fit polynomial','Inlier points','Outlier points','Future path');
    title("Future Path in x,y coordinates (y axis will be flipped in image coordinates)");
    hold off;

end