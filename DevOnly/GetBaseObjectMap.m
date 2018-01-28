function [ map ] = GetBaseObjectMap
%GETBASEOBJECTMAP For debug mode: gives map of all existing BaseObjects

handle = BaseObject.allObjects;
map = handle.wrapped;

end

