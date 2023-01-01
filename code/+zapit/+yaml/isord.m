function result = isord(obj)
import zapit.yaml.*;
result = ~iscell(obj) && any(size(obj) > 1);
end
