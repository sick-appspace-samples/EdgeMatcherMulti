
--Start of Global Scope---------------------------------------------------------
print('AppEngine Version: ' .. Engine.getVersion())

local DELAY = 1000 -- ms between visualization steps for demonstration purpose

-- Creating viewer
local viewer = View.create('viewer2D1')

-- Setting up graphical overlay attributes
local textDeco = View.TextDecoration.create() -- "Teach" or "Match" mode, top left corner
textDeco:setSize(30)
textDeco:setPosition(20, 30)

local text2Deco = View.TextDecoration.create() -- "Number of matches", top right corner
text2Deco:setSize(30)
text2Deco:setPosition(520, 30)

local decoration = View.ShapeDecoration.create() -- Color scheme for text and points
decoration:setPointSize(5)
decoration:setLineColor(0, 0, 230) -- Blue for "Teach" mode
decoration:setPointType('DOT')

-- Creating matcher
local matcher = Image.Matching.EdgeMatcher.create()
matcher:setEdgeThreshold(30)
local wantedDownsampleFactor = 2
matcher:setDownsampleFactor(wantedDownsampleFactor) 
matcher:setMaxMatches(10)

--End of Global Scope-----------------------------------------------------------

--Start of Function and Event Scope---------------------------------------------

-- Teaching
--@teach(img:Image)
local function teach(img)
  viewer:clear()
  local imageID = viewer:addImage(img)
  -- Add "Teach" text overlay
  viewer:addText('Teach', textDeco, nil, imageID)

  -- Defining teach region
  local teachRectCenter = Point.create(312, 235)
  local teachRect = Shape.createRectangle(teachRectCenter, 120, 110, 0)
  viewer:addShape(teachRect, decoration, nil, imageID)
  local teachRegion = teachRect:toPixelRegion(img)

  -- Check if wanted downsample factor is supported by device
  minDsf,_ = matcher:getDownsampleFactorLimits(img)
  if (minDsf > wantedDownsampleFactor) then
    print("Cannot use downsample factor " .. wantedDownsampleFactor .. " will use " .. minDsf .. " instead") 
    matcher:setDownsampleFactor(minDsf)
  end
  
  -- Teaching edge matcher
  local teachPose = matcher:teach(img, teachRegion)

  -- Viewing model points overlayed in teach image
  local modelPoints = matcher:getEdgePoints() -- Model points in model's local coord syst
  local teachPoints = Point.transform(modelPoints, teachPose)
  for _, point in ipairs(teachPoints) do
    viewer:addShape(point, decoration, nil, imageID)
  end
  viewer:present()
end

-- Matching
--@match(img:Image,i:int)
local function match(img, i)
  -- Changing color scheme to green for "Match" mode
  decoration:setLineColor(0, 210, 0)
  decoration:setLineWidth(5)
  viewer:clear()
  local imageID = viewer:addImage(img)
  -- Adding "Match #" text overlay
  viewer:addText('Match ' .. tostring(i), textDeco, nil, imageID)

  -- Finding object pose
  local poses,
    scores = matcher:match(img)

  -- Finding index of first match with score less than minimum score
  local minscore = 0.8 -- Minimum score to count as a found object
  local validScores = 0 -- Valid object counter

  -- Visualizing found objects
  for j = 1, #scores do
    if scores[j] >= minscore then
      local outlines = Shape.transform(matcher:getModelContours(), poses[j])
      for _, outline in ipairs(outlines) do
        viewer:addShape(outline, decoration, nil, imageID)
      end
      validScores = validScores + 1
    end
  end
  viewer:present()
  viewer:addText('# = ' .. tostring(validScores), text2Deco, nil, imageID)
  viewer:present()
  print('Valid Matches: ' .. validScores)
  Script.sleep(DELAY * 2) -- for demonstration purpose only
end

local function main()
  -- Loading Teach image from resources and calling teach() function
  local teachImage = Image.load('resources/Teach.bmp')
  teach(teachImage)
  Script.sleep(DELAY) -- for demonstration purpose only

  -- Loading images from resource folder and calling match() function
  for i = 1, 3 do
    local liveImage = Image.load('resources/' .. i .. '.bmp')
    match(liveImage, i)
    Script.sleep(DELAY) -- for demonstration purpose only
  end

  print('App finished.')
end
--The following registration is part of the global scope which runs once after startup
--Registration of the 'main' function to the 'Engine.OnStarted' event
Script.register('Engine.OnStarted', main)

--End of Function and Event Scope--------------------------------------------------
