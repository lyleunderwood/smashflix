return {
  behavior = {
    start = function(self, level)
      self.level = level

      self.currentWave = 1
      self.currentWaveDone = false

      self.waveEndTimer = MOAITimer:new()
      self.waveEndTimer:setSpan(1)
      self.waveEndTimer:setMode(MOAITimer.LOOP)
      self.waveEndTimer:setListener(MOAITimer.EVENT_TIMER_BEGIN_SPAN, function()
        if self:waveIsClear() then
          self:nextWave()
        end
    end)

      level:loadPc()

      self:startWave()
      self.waveEndTimer:start()
    end,

    startWave = function(self)
      self.waveTimer = MOAITimer:new()
      self.currentWaveDone = false

      self.waveTimer:setSpan(1)
      self.waveTimer:setMode(MOAITimer.LOOP)
      self.waveTimer:setListener(MOAITimer.EVENT_TIMER_BEGIN_SPAN, function()
        self:newBum()
        if self.waveTimer:getTimesExecuted() == 9 then
          self:stopWave()
        end
      end)

      self.waveTimer:start()
    end,

    stopWave = function(self)
      self.waveTimer:stop()
      self.currentWaveDone = true
    end,

    nextWave = function(self)
      self.currentWave = self.currentWave + 1
      self:startWave()
    end,

    newBum = function(self)
      if self.currentWave == 1 then
        self.level:buildEnemy("actors/Bum", function(rig)
          rig.pos = {x = 0, y = 200}
        end)
      elseif self.currentWave == 2 then
        self.level:buildEnemy("actors/Bum", function(rig)
          rig.pos = {x = 0, y = 200}
        end)
        self.level:buildEnemy("actors/Bum", function(rig)
          rig.pos = {x = -280, y = 0}
        end)
      elseif self.currentWave == 3 then
        self.level:buildEnemy("actors/Bum", function(rig)
          rig.pos = {x = 0, y = 200}
        end)
        self.level:buildEnemy("actors/Bum", function(rig)
          rig.pos = {x = -280, y = 0}
        end)
        self.level:buildEnemy("actors/Bum", function(rig)
          rig.pos = {x = 280, y = 0}
        end)
      elseif self.currentWave >= 4 then
        self.level:buildEnemy("actors/Bum", function(rig)
          rig.pos = {x = 0, y = 200}
        end)
        self.level:buildEnemy("actors/Bum", function(rig)
          rig.pos = {x = -280, y = 0}
        end)
        self.level:buildEnemy("actors/Bum", function(rig)
          rig.pos = {x = 280, y = 0}
        end)
        self.level:buildEnemy("actors/Bum", function(rig)
          rig.pos = {x = 0, y = -180}
        end)
      end
       

    end,

    waveIsClear = function(self)
      return self.currentWaveDone and #self.level.enemies == 0
    end
  },
  backgroundFilename = "images/Paddys.png",
    objects = {
      {
        bb = {-300, 280, -350, -280}
      },
      {
        bb = {300, 280, 350, -280}
      },
      {
        bb = {300, 200, -300, 230}
      },
      {
        bb = {300, -230, -300, -250}
      },
      {
        bb = {-270, 165, -70, 100}
      },
      {
        bb = {250, -175, 90, -85}
      }
    }
}
