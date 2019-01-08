function [outputArg1,outputArg2] = add3DSurfaceCST(CST,X,Y,Z,thickness,material,component)
%ADD3DSURFACECST adds a 3-dimenoinal surface defined by surf(x,y,z) to the
%CST_MirowaveStudio object.
%   add3DSurface(CST,X,Y,Z,thickness,material,component)
%   Detailed explanation goes here

[I,J] = size(X);

ii = 0;
for j = 1:J-1
    for i = 1:I-1
    points = [X(i,j),Y(i,j),Z(i,j);...
              X(i,j+1),Y(i,j+1),Z(i,j+1);...
              X(i+1,j+1),Y(i+1,j+1),Z(i+1,j+1);...
              X(i+1,j),Y(i+1,j),Z(i+1,j);...
              X(i,j),Y(i,j), Z(i,j)];
    for k = 1:2
        ii = ii+1;
        name = ['Brick',num2str(ii)];
        if k == 1
            points1 = points([1,2,3,5],:);
        elseif k ==2
            points1 = points([1,3,4,5],:);
        end
        CST.addPolygonBlock3D(points1,thickness,name,component,material);
    end
    end
end


end

