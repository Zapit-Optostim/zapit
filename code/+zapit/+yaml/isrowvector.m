function result = isrowvector(obj)
    import zapit.yaml.*;
    result = isvector(obj) && size(obj,1) == 1 && size(obj,2) > 1 && ndims(obj) == 2;
end
