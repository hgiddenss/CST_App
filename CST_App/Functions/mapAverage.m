function [Cav] = mapAverage(C,X,Y)
%MAPAVERAGE Convert a colormap to return a map which is the acerage of each
%four nodes with size(C) - 1
if nargin == 1
I = size(C,1);
J = size(C,2);

if I == 1 && J == 1
   Cav = C;
    
elseif I == 1 || J == 1
   I = max([I,J]); 
   C = C(:);
   Cav = zeros(length(C)-1,1);
   for i = 1:I-1
       Cav(i) = (C(i)+C(i+1))/2;
   end
    
else
Cav = zeros(I-1,J-1);
for i = 1:I-1
    for j = 1:J-1
        Cav(i,j) = (C(i,j) + C(i+1,j) + C(i,j+1) + C(i+1,j+1))/4;
    end
end

Cav(end+1,:) = Cav(end,:); %pad last column;
Cav(:,end+1) = Cav(:,end); % pad last row;
end

else
    
    
    
    
end

end

