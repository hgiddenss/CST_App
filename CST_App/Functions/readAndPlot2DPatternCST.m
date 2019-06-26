function [varargout] = readAndPlot2DPatternCST(CST,f,theta,phi,pAx)
%READANDPLOTPATTERNCST Summary of this function goes here
%   Detailed explanation goes here

if numel(phi) > 1
    
end

[Eabs] = CST.getFarField(f,theta,phi,'units','directivity');


Eabs(Eabs < -15) = -15;

if nargin == 4
    pAx = polaraxes('parent',figure);
end

polarplot(pAx,deg2rad(phi),Eabs,'-');

pAx.RLim = [-15 15];

if nargout> 0
    varargout{1} = pAx;
end
if nargout > 1
    varargout{2} = Eabs;
end

end

