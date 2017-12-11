function [ s ] = ste( data , dim )
%STE returns the standard error of the data

sz = size(data);
if ~exist('dim','var')
    dim = find(sz>1, 1, 'first');
    if isempty(dim)
        s = 0;
        return
    end
end
    m = mean(data,dim);
    n = sz(dim);
    resid = (data - m)/n;
    s = sqrt(sum(resid.^2));
end

