ncdk.LayerData = {}
local LayerData = ncdk.LayerData

ncdk.LayerData_metatable = {}
local LayerData_metatable = ncdk.LayerData_metatable
LayerData_metatable.__index = LayerData

LayerData.new = function(self)
	local layerData = {}
	
	layerData.timeData = ncdk.TimeData:new()
	layerData.spaceData = ncdk.SpaceData:new()
	layerData.noteDataSequence = ncdk.NoteDataSequence:new()
	
	layerData.timeData.layerData = layerData
	layerData.spaceData.layerData = layerData
	layerData.noteDataSequence.layerData = layerData
	
	setmetatable(layerData, LayerData_metatable)
	
	return layerData
end

LayerData.compute = function(self)
	self.timeData:sort()
	self.spaceData:sort()
	self.noteDataSequence:sort()
	
	self:updateZeroTimePoint()
	self:computeTimePoints()
	self:computeNoteData()
end

LayerData.computeTimePoints = function(self)
	local zeroTimePoint = self:getZeroTimePoint()
	
	self.timePoints = self.timeData:computeTimePoints()
	
	local firstTimePoint = self.timePoints[1]
	local baseZeroClearVisualTime = 0
	
	local globalTime = 0
	local targetTimePointIndex = 1
	local targetTimePoint = self.timePoints[targetTimePointIndex]
	local leftTimePoint = firstTimePoint
	
	for currentVelocityDataIndex = 1, self.spaceData:getVelocityDataCount() do
		local currentVelocityData = self.spaceData:getVelocityData(currentVelocityDataIndex)
		local nextVelocityData = self.spaceData:getVelocityData(currentVelocityDataIndex + 1)
		
		while targetTimePointIndex <= #self.timePoints do
			if not nextVelocityData or targetTimePoint < nextVelocityData.timePoint then
				targetTimePoint.velocityData = currentVelocityData
				targetTimePoint.zeroClearVisualTime = globalTime + self.spaceData:getVelocityDataVisualDuration(currentVelocityDataIndex, leftTimePoint, targetTimePoint)
				if targetTimePoint == zeroTimePoint then
					baseZeroClearVisualTime = targetTimePoint.zeroClearVisualTime
				end
				targetTimePointIndex = targetTimePointIndex + 1
				targetTimePoint = self.timePoints[targetTimePointIndex]
			else
				break
			end
		end
		
		if nextVelocityData then
			globalTime = globalTime + self.spaceData:getVelocityDataVisualDuration(
				currentVelocityDataIndex,
				leftTimePoint,
				nextVelocityData.timePoint
			)
			leftTimePoint = currentVelocityData.timePoint
		end
	end
	
	for _, timePoint in ipairs(self.timePoints) do
		timePoint.zeroClearVisualTime = timePoint.zeroClearVisualTime - baseZeroClearVisualTime
	end
end

LayerData.computeNoteData = function(self)
	for noteDataIndex = 1, self.noteDataSequence:getNoteDataCount() do
		local noteData = self.noteDataSequence:getNoteData(noteDataIndex)
		
		noteData.zeroClearVisualTime = noteData.timePoint.zeroClearVisualTime
		noteData.currentVisualTime = noteData.zeroClearVisualTime
	end
end

LayerData.setSignature = function(self, ...) return self.timeData:setSignature(...) end
LayerData.getSignature = function(self, ...) return self.timeData:getSignature(...) end
LayerData.setSignatureTable = function(self, ...) return self.timeData:setSignatureTable(...) end
LayerData.addTempoData = function(self, ...) return self.timeData:addTempoData(...) end
LayerData.getTempoData = function(self, ...) return self.timeData:getTempoData(...) end
LayerData.addStopData = function(self, ...) return self.timeData:addStopData(...) end
LayerData.getStopData = function(self, ...) return self.timeData:getStopData(...) end
LayerData.getTimePoint = function(self, ...) return self.timeData:getTimePoint(...) end

LayerData.addVelocityData = function(self, ...) return self.spaceData:addVelocityData(...) end
LayerData.removeLastVelocityData = function(self, ...) return self.spaceData:removeLastVelocityData(...) end
LayerData.getVelocityDataByTimePoint = function(self, ...) return self.spaceData:getVelocityDataByTimePoint(...) end
LayerData.getVisualMeasureTime = function(self, ...) return self.spaceData:getVisualMeasureTime(...) end
LayerData.getVisualTime = function(self, ...) return self.spaceData:getVisualTime(...) end
LayerData.computeVisualTime = function(self, ...) return self.spaceData:computeVisualTime(...) end
LayerData.updateZeroTimePoint = function(self) return self.spaceData:updateZeroTimePoint() end
LayerData.getZeroTimePoint = function(self) return self.spaceData:getZeroTimePoint() end

LayerData.getColumnCount = function(self) return self.noteDataSequence:getColumnCount() end
LayerData.addNoteData = function(self, ...) return self.noteDataSequence:addNoteData(...) end
LayerData.getNoteData = function(self, ...) return self.noteDataSequence:getNoteData(...) end
LayerData.getNoteDataCount = function(self) return self.noteDataSequence:getNoteDataCount() end
