function [u,v]=lk(img1,img2,wsize);
[fx,fy,ft]=deriv(img1,img2);
u=zeros(size(img1));
v=zeros(size(img2));
half_w=floor(wsize/2);
for i=half_w+1:size(fx,1)-half_w
    for j=half_w+1:size(fx,2)-half_w
        curx=fx(i-half_w:i+half_w,j-half_w:j+half_w);
        cury=fy(i-half_w:i+half_w,j-half_w:j+half_w);
        curt=ft(i-half_w:i+half_w,j-half_w:j+half_w);
        curx=curx';
        cury=cury';
        curt=curt';
        curx=curx(:);
        cury=cury(:);
        curt=-curt(:);
        a=[curx,cury];
        UV=pinv(a'*a)*a'*curt;
        u(i,j)=UV(1);
        v(i,j)=UV(2);
    end;
end;
u(isnan(u))=0;
v(isnan(v))=0;

function [fx,fy,ft]=deriv(img1,img2);
fx=conv2(img1,0.25*[-1,1;-1,1])+conv2(img2,0.25*[-1,1;-1,1]);
fy=conv2(img1,0.25*[-1,-1;1,1])+conv2(img2,0.25*[-1,-1;1,1]);
ft=conv2(img1,0.25*ones(2))+conv2(img2,-0.25*ones(2));

fx=fx(1:size(fx,1)-1,1:size(fx,2)-1);
fy=fy(1:size(fy,1)-1,1:size(fy,2)-1);
ft=ft(1:size(ft,1)-1,1:size(ft,2)-1);