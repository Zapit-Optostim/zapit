function result = issingle(obj)
    import zapit.yaml.*;
    result = all(size(obj) == 1) ;
end
