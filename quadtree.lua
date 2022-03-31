QuadTree = {}
function QuadTree.new(boundary, capacity)
    local boundary_left = boundary.center.x - boundary.size.x/2
    local boundary_right = boundary.center.x + boundary.size.x/2
    local boundary_top = boundary.center.y - boundary.size.y/2
    local boundary_bottom = boundary.center.y + boundary.size.y/2
    local boundary_width = boundary.size.x
    local boundary_height = boundary.size.y
    
    
    return setmetatable(
    {
        center   =  vector2(boundary_left + boundary_width/2, boundary_top + boundary_height/2),
        width  =  boundary_width,
        height =  boundary_height,
        size = vector2(boundary_width, boundary_height),
        capacity = capacity or 4,
        points = {},
        circles = {},
        boxes = {},
        polygons = {},
        isdivided = false
    }, {
        __index = QuadTree,
        __tostring = function(self)
            return "QuadTree: center: "..self.center.x.." "..self.center.y.." width: "..self.width.." height: "..self.height.." capacity: "..self.capacity.." points: "..#self.points.. " boxes: "..#self.boxes.. " polygons: "..#self.polygons.. " isdivided: "..tostring(self.isdivided)
            
        end
    })
end

function QuadTree:inner_subdivide()
    local parentcenter = self.center
    local parentwidth = self.width
    local parentheight = self.height
    local childwidth = parentwidth/2
    local childheight = parentheight/2

    --create new quadtrees in 4 sub-regions
    self.topright = QuadTree.new({
        center = vector2(parentcenter.x + childwidth/2, parentcenter.y - childheight/2),
        size = vector2(childwidth, childheight)
    }, self.capacity)
    self.bottomright = QuadTree.new({
        center = vector2(parentcenter.x + childwidth/2, parentcenter.y + childheight/2),
        size = vector2(childwidth, childheight)
    }, self.capacity)
    self.bottomleft = QuadTree.new({
        center = vector2(parentcenter.x - childwidth/2, parentcenter.y + childheight/2),
        size = vector2(childwidth, childheight)
    }, self.capacity)
    self.topleft = QuadTree.new({
        center = vector2(parentcenter.x - childwidth/2, parentcenter.y - childheight/2),
        size = vector2(childwidth, childheight)
    }, self.capacity)

    self.isdivided = true
        
end

function QuadTree:inner_intersects(rectrange)
    local rectcenter = rectrange.center
    local rectsize = rectrange.size
    local rectwidth = rectsize.x
    local rectheight = rectsize.y
    return not (rectcenter.x + rectwidth/2 < self.center.x - self.width/2 or rectcenter.x - rectwidth/2 > self.center.x + self.width/2 or rectcenter.y + rectheight/2 < self.center.y - self.height/2 or rectcenter.y - rectheight/2 > self.center.y + self.height/2)
end

function QuadTree:inner_point_contains (point, radius)
    local radius = radius or 0.0
    return point.x >= self.center.x - self.width/2 - radius and point.x <= self.center.x + self.width/2 + radius and point.y >= self.center.y - self.height/2 - radius and point.y <= self.center.y + self.height/2 + radius
end

function QuadTree:insert_point(point)
    if not self:inner_point_contains(point) then
        return false
    end
    if #self.points < self.capacity then
        table.insert(self.points, point)
        return true
    else 
        if not self.isdivided then
            self:inner_subdivide()
        end
        if self.topright:insert_point(point) then
            return true
        elseif self.bottomright:insert_point(point) then
            return true
        elseif self.bottomleft:insert_point(point) then
            return true
        elseif self.topleft:insert_point(point) then
            return true
        end
    end
end

function QuadTree:query_points_by_rectangle(rectrange, found)
    found = found or {}
    if not self:inner_intersects(rectrange) then
        return found
    end
    for i, point in ipairs(self.points) do
        table.insert(found, point)
    end
    if self.isdivided then
        self.topright:query_points_by_rectangle(rectrange, found)
        self.bottomright:query_points_by_rectangle(rectrange, found)
        self.bottomleft:query_points_by_rectangle(rectrange, found)
        self.topleft:query_points_by_rectangle(rectrange, found)
    end
    return found
end


function QuadTree:query_points_by_point(point, radius, found)
    found = found or {}
    if not self:inner_point_contains(point, radius) then
        return found
    end
    for i, point in ipairs(self.points) do
        table.insert(found, point)
    end
    if self.isdivided then
        self.topright:query_points_by_point(point, radius, found)
        self.bottomright:query_points_by_point(point, radius, found)
        self.bottomleft:query_points_by_point(point, radius, found)
        self.topleft:query_points_by_point(point, radius, found)
    end
    return found
end

local GetMinMax = function(b)
   local min = vector2(b.center.x - b.size.x/2, b.center.y - b.size.y/2)
   local max = vector2(b.center.x + b.size.x/2, b.center.y + b.size.y/2)
   return min, max
end
function QuadTree:inner_box_contains(box,min,max)
    local min1, max1 = GetMinMax(self)
    local min2, max2 = GetMinMax(box)
    if min and max then min2 , max2 = min, max end
    return min1.x <= min2.x and max1.x >= max2.x and min1.y <= min2.y and max1.y >= max2.y
end

function QuadTree:insert_box(box,min,max)
    if not self:inner_box_contains(box,min,max) then
        return false
    end
    if #self.boxes < self.capacity then
        table.insert(self.boxes, box)
        return true
    else 
        if not self.isdivided then
            self:inner_subdivide()
        end
        if self.topright:insert_box(box) then
            return true
        elseif self.bottomright:insert_box(box) then
            return true
        elseif self.bottomleft:insert_box(box) then
            return true
        elseif self.topleft:insert_box(box) then
            return true
        end
    end
end

function QuadTree:query_boxes_by_rectangle(rectrange, found)
    found = found or {}
    if not self:inner_intersects(rectrange) then
        return found
    end
    for i, box in ipairs(self.boxes) do
        table.insert(found, box)
    end
    if self.isdivided then
        self.topright:query_boxes_by_rectangle(rectrange, found)
        self.bottomright:query_boxes_by_rectangle(rectrange, found)
        self.bottomleft:query_boxes_by_rectangle(rectrange, found)
        self.topleft:query_boxes_by_rectangle(rectrange, found)
    end
    return found
end

function QuadTree:query_boxes_by_point(point, radius, found)
    found = found or {}
    if not self:inner_point_contains(point, radius) then
        return found
    end
    for i, box in ipairs(self.boxes) do
        table.insert(found, box)
    end
    if self.isdivided then
        self.topright:query_boxes_by_point(point, radius, found)
        self.bottomright:query_boxes_by_point(point, radius, found)
        self.bottomleft:query_boxes_by_point(point, radius, found)
        self.topleft:query_boxes_by_point(point, radius, found)
    end
    return found
end

function QuadTree:inner_circle_contains (circle)
    return self:inner_point_contains(circle.center, circle.radius)
end

function QuadTree:insert_circle(circle)
    if not self:inner_circle_contains(circle) then
        return false
    end
    if #self.circles < self.capacity then
        table.insert(self.circles, circle)
        return true
    else 
        if not self.isdivided then
            self:inner_subdivide()
        end
        if self.topright:insert_circle(circle) then
            return true
        elseif self.bottomright:insert_circle(circle) then
            return true
        elseif self.bottomleft:insert_circle(circle) then
            return true
        elseif self.topleft:insert_circle(circle) then
            return true
        end
    end
end


function QuadTree:query_circles_by_rectangle(rectrange, found)
    found = found or {}
    if not self:inner_intersects(rectrange) then
        return found
    end
    for i, circle in ipairs(self.circles) do
        table.insert(found, circle)
    end
    if self.isdivided then
        self.topright:query_circles_by_rectangle(rectrange, found)
        self.bottomright:query_circles_by_rectangle(rectrange, found)
        self.bottomleft:query_circles_by_rectangle(rectrange, found)
        self.topleft:query_circles_by_rectangle(rectrange, found)
    end
    return found
end

function QuadTree:query_circles_by_point(point, radius, found)
    found = found or {}
    if not self:inner_point_contains(point, radius) then
        return found
    end
    for i, circle in ipairs(self.circles) do
        table.insert(found, circle)
    end
    if self.isdivided then
        self.topright:query_circles_by_point(point, radius, found)
        self.bottomright:query_circles_by_point(point, radius, found)
        self.bottomleft:query_circles_by_point(point, radius, found)
        self.topleft:query_circles_by_point(point, radius, found)
    end
    return found
end
