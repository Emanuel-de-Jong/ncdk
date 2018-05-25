bms.NoteChartImporter = {}
local NoteChartImporter = bms.NoteChartImporter

bms.NoteChartImporter_metatable = {}
local NoteChartImporter_metatable = bms.NoteChartImporter_metatable
NoteChartImporter_metatable.__index = NoteChartImporter

NoteChartImporter.new = function(self)
	local noteChartImporter = {}
	
	noteChartImporter.channelDataSequence = bms.ChannelDataSequence:new()
	noteChartImporter.wavDataSequence = {}
	noteChartImporter.bpmDataSequence = {}
	noteChartImporter.stopDataSequence = {}
	
	setmetatable(noteChartImporter, NoteChartImporter_metatable)
	
	return noteChartImporter
end

NoteChartImporter.import = function(self, noteChartString)
	self.foregroundLayerData = self.noteChart.layerDataSequence:requireLayerData(1)
	self.backgroundLayerData = self.noteChart.layerDataSequence:requireLayerData(2)
	self.backgroundLayerData.invisible = true
	
	self.foregroundLayerData.timeData:setMode(ncdk.TimeData.Modes.Measure)
	self.backgroundLayerData.timeData:setMode(ncdk.TimeData.Modes.Measure)
	
	for _, line in ipairs(noteChartString:split("\n")) do
		self:processLine(line:trim())
	end
	
	self:importTimingData()
	self.foregroundLayerData:updateZeroTimePoint()
	
	self:importVelocityData()
	self:importNoteData()
end

NoteChartImporter.processLine = function(self, line)
	if line:find("^#WAV.. .+$") then
		local index, fileName = line:match("^#WAV(..) (.+)$")
		self.wavDataSequence[index] = fileName
	elseif line:find("^#BPM.. .+$") then
		local index, tempo = line:match("^#BPM(..) (.+)$")
		self.bpmDataSequence[index] = tonumber(tempo)
	elseif line:find("^#STOP.. .+$") then
		local index, duration = line:match("^#STOP(..) (.+)$")
		self.stopDataSequence[index] = tonumber(duration)
	elseif line:find("^#%d+:.+$") then
		local measureIndex, channelIndex, indexDataString = line:match("^#(%d%d%d)(%d%d):(.+)$")
		measureIndex = tonumber(measureIndex)
		
		if bms.ChannelEnum[channelIndex] then
			local channelData = self.channelDataSequence:requireChannelData(measureIndex, channelIndex)
			channelData:addIndexData(indexDataString)
		end
	elseif line:find("^#[.%S]+ .+$") then
		self:processHeaderLine(line)
	end
end

NoteChartImporter.processHeaderLine = function(self, line)
	if line:find("^#BPM %d+$") then
		self.baseTempo = tonumber(line:match("^#BPM (.+)$"))
	end
end

NoteChartImporter.importTimingData = function(self)
	if self.baseTempo then
		local measureTime = ncdk.Fraction:new(-1, 6)
		local tempoData = ncdk.TempoData:new(measureTime, self.baseTempo)
		self.foregroundLayerData:addTempoData(tempoData)
	end
	
	self:importSignature()
	self:importTempoData()
	self:importStopData()
end

NoteChartImporter.importSignature = function(self)
	for measureIndex, channelDatas in pairs(self.channelDataSequence.data) do
		for channelIndex, channelData in pairs(channelDatas) do
			if bms.ChannelEnum[channelIndex].name == "Signature" then
				self.foregroundLayerData:setSignature(
					measureIndex,
					ncdk.Fraction:new():fromNumber(channelData.value * 4, 32768)
				)
			end
		end
	end
end

NoteChartImporter.importTempoData = function(self)
	for measureIndex, channelDatas in pairs(self.channelDataSequence.data) do
		for channelIndex, channelData in pairs(channelDatas) do
			for indexDataIndex, indexData in ipairs(channelData.indexDatas) do
				if bms.ChannelEnum[channelIndex].name == "Tempo" then
					self.foregroundLayerData:addTempoData(
						ncdk.TempoData:new(
							measureIndex + indexData.measureTimeOffset,
							tonumber(indexData.value, 16)
						)
					)
				elseif bms.ChannelEnum[channelIndex].name == "ExtendedTempo" then
					self.foregroundLayerData:addTempoData(
						ncdk.TempoData:new(
							measureIndex + indexData.measureTimeOffset,
							self.bpmDataSequence[indexData.value]
						)
					)
				end
			end
		end
	end
	
	self.foregroundLayerData.timeData.tempoDataSequence:sort()
end

NoteChartImporter.importStopData = function(self)
	for measureIndex, channelDatas in pairs(self.channelDataSequence.data) do
		for channelIndex, channelData in pairs(channelDatas) do
			for indexDataIndex, indexData in ipairs(channelData.indexDatas) do
				if bms.ChannelEnum[channelIndex].name == "Stop" then
					local measureTime = measureIndex + indexData.measureTimeOffset
					local measureDuration = ncdk.Fraction:new(self.stopDataSequence[indexData.value], 192)
					
					local stopData = ncdk.StopData:new(measureTime, measureDuration)
					
					local currentTempoData = self.foregroundLayerData.timeData.tempoDataSequence:getTempoDataByMeasureTime(measureTime)
					local dedicatedDuration = currentTempoData:getBeatDuration() * 4
					
					stopData.duration = measureDuration:tonumber() * dedicatedDuration
					
					self.foregroundLayerData:addStopData(stopData)
				end
			end
		end
	end
	
	self.foregroundLayerData.timeData.stopDataSequence:sort()
end

NoteChartImporter.importVelocityData = function(self)
	local measureTime = ncdk.Fraction:new(0)
	local timePoint = self.foregroundLayerData:getTimePoint(measureTime, 1)
	local velocityData = ncdk.VelocityData:new(timePoint)
	self.foregroundLayerData:addVelocityData(velocityData)
end

NoteChartImporter.importNoteData = function(self)
	local longNoteDataSwitch = false
	for measureIndex, channelDatas in pairs(self.channelDataSequence.data) do
		for channelIndex, channelData in pairs(channelDatas) do
			for indexDataIndex, indexData in ipairs(channelData.indexDatas) do
				local channelInfo = bms.ChannelEnum[channelIndex]
				
				if channelInfo and (channelInfo.name == "Note" or channelInfo.name == "BGM") then
					local measureTime = measureIndex + indexData.measureTimeOffset
					local timePoint = self.foregroundLayerData:getTimePoint(measureTime, 1)
					timePoint.velocityData = self.foregroundLayerData:getVelocityDataByTimePoint(timePoint)
					
					noteData = ncdk.NoteData:new(timePoint)
					noteData.inputType = channelInfo.inputType
					noteData.inputIndex = channelInfo.inputIndex
					
					noteData.soundFileName = self.wavDataSequence[indexData.value]
					noteData.zeroClearVisualTime = self.foregroundLayerData:getVisualTime(timePoint, self.foregroundLayerData:getZeroTimePoint(), true)
					noteData.currentVisualTime = noteData.zeroClearVisualTime
					
					if channelInfo.inputType == "auto" then
						noteData.noteType = "SoundNote"
						self.backgroundLayerData:addNoteData(noteData)
					elseif channelInfo.long then
						if not longNoteDataSwitch then
							noteData.noteType = "LongNoteStart"
							longNoteDataSwitch = true
						else
							noteData.noteType = "LongNoteEnd"
							longNoteDataSwitch = false
						end
						self.foregroundLayerData:addNoteData(noteData)
					else
						noteData.noteType = "ShortNote"
						self.foregroundLayerData:addNoteData(noteData)
					end
				end
			end
		end
	end
	
	self.backgroundLayerData.noteDataSequence:sort()
	self.foregroundLayerData.noteDataSequence:sort()
end