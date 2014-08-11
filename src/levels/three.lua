return {
  behavior = {
    waves = {
       {
        { time = 1, N = {"Zombie"}, S = {"Bum"}, W = {"Bum"} },
        { time = 2.75, E = {"Bum"} },
        { time = 4.5, N = {"Bum"} },
        { time = 6.25, S = {"Bum"} },
        { time = 8, W = {"Bum"} },
        { time = 9.75, N = {"Bum"}, N = {"Zombie"} },
      },
      {
        { time = 1, N = {"Zombie"}, S = {"Zombie"} },
        { time = 2.75, W = {"Bum"} },
        { time = 4.5, E = {"Bum"} },
        { time = 6.25, S = {"Bum"} },
        { time = 8, W = {"Ninja"}, N = {"Zombie"} },
        { time = 9.75, N = {"Bum"} },
        { time = 11.5, S = {"Bum"} },
        { time = 13.25, E = {"Bum"} },
        { time = 15, N = {"Ninja"} },
        { time = 16.75, N = {"Bum"}, W = {"Bum"}, E = {"Bum"}, S = {"Zombie"} },
      },
       {
        { time = 1, E = {"Bum"}, W = {"Bum"}, N = {"Ninja"} },
        { time = 2.75, S = {"Zombie"} },
        { time = 4.5, E = {"Bum"}, W = {"Bum"}, },
        { time = 6.25, N = {"Zombie"} },
        { time = 8, E = {"Bum"}, W = {"Bum"}, S = {"Ninja"} },
        { time = 9.75, N = {"Bum"} },
        { time = 11.5, E = {"Bum"}, W = {"Bum"} },
        { time = 13.25, S = {"Bum"} },
        { time = 15, E = {"Zombie"}, W = {"Zombie"}, N = {"Ninja"}, S = {"Ninja"} },
      },
    },

    start = function(self, level)
      self.level = level

      self.currentWave = 1
      self.currentWaveDone = false

      self.totalWaves = #self.waves

      self.waveEndTimer = MOAITimer:new()
      self.waveEndTimer:setSpan(1)
      self.waveEndTimer:setMode(MOAITimer.LOOP)
      self.waveEndTimer:setListener(MOAITimer.EVENT_TIMER_BEGIN_SPAN, function()
        if self:waveIsClear() then
          if self.currentWave == self.totalWaves then
            self:success()
          else
            self:nextWave()
          end
        end
      end)

      level:loadPc()

      self:startWave()
      self.waveEndTimer:start()
    end,

    stop = function(self)
      self.waveEndTimer:stop()
      if self.waveTimer then
        self.waveTimer:stop()
      end
      if self.eventTimer then
        self.eventTimer:stop()
      end
    end,

    startWave = function(self)
      self.waveTimer = MOAITimer:new()
      self.currentWaveDone = false

      self.previousEventTime = 0
      self.currentEvent = 1
      self.currentWaveObj = self.waves[self.currentWave]

      self:runEvent()
    end,

    runEvent = function(self)
      local event = self.currentWaveObj[self.currentEvent]
      local span = event.time - self.previousEventTime
      print(span)

      self.previousEventTime = event.time

      local cb = function()
        self:spawnEnemiesForEvent(event)
        if self.currentEvent == #self.currentWaveObj then
          self:stopWave()
        else
          self.currentEvent = self.currentEvent + 1
          self:runEvent()
        end
      end

      if span == 0 then
        cb()
      else
        self.eventTimer = MOAITimer:new()
        self.eventTimer:setSpan(span)
        self.eventTimer:setListener(MOAITimer.EVENT_TIMER_END_SPAN, cb)

        self.eventTimer:start()
      end
    end,

    stopWave = function(self)
      self.currentWaveDone = true
    end,

    nextWave = function(self)
      self.currentWave = self.currentWave + 1
      self:startWave()
    end,

    success = function(self)
      self.waveEndTimer:stop()
      self.level:success({
        nextLevel = "three"
      })
    end,

    spawnEnemiesForEvent = function(self, event)
      if event.N then
        for k,v in pairs(event.N) do
          self.level:buildEnemy("actors/"..v, function(rig)
            rig.pos = {x = 0, y = 210}
          end)
        end
      end
      if event.W then
        for k,v in pairs(event.W) do
          self.level:buildEnemy("actors/"..v, function(rig)
            rig.pos = {x = -320, y = 0}
          end)
        end
      end
      if event.E then
        for k,v in pairs(event.E) do
          self.level:buildEnemy("actors/"..v, function(rig)
            rig.pos = {x = 320, y = 0}
          end)
        end
      end
      if event.S then
        for k,v in pairs(event.S) do
          self.level:buildEnemy("actors/"..v, function(rig)
            rig.pos = {x = 0, y = -250}
          end)
        end
      end
    end,

    waveIsClear = function(self)
      return self.currentWaveDone and #self.level.enemies == 0
    end
  },
  backgroundFilename = "images/Paddys.png",
    objects = {
      -- western walls
      {
        bb = {-300, 280, -350, 20}
      },
      {
        bb = {-300, -20, -350, -280}
      },
      {
        bb = {-370, 20, -350, -20}
      },
      {
        bb = {-300, 20, -350, -20},
        playerOnly = true
      },
      -- eastern walls
      {
        bb = {300, 280, 350, 20}
      },
      {
        bb = {300, -20, 350, -280}
      },
      {
        bb = {370, 20, 350, -20}
      },
      {
        bb = {300, 20, 350, -20},
        playerOnly = true
      },
      -- northern walls
      {
        bb = {-20, 190, -300, 230}
      },
      {
        bb = {20, 190, 300, 230}
      },
      {
        bb = {-20, 230, 20, 250}
      },
      {
        bb = {-20, 190, 20, 230},
        playerOnly = true
      },
      -- southern walls
      {
        bb = {-20, -230, -300, -270}
      },
      {
        bb = {20, -230, 300, -270}
      },
      {
        bb = {-20, -270, 20, -290}
      },
      {
        bb = {-20, -230, 20, -270},
        playerOnly = true
      },
      -- other junk
      {
        bb = {-270, 165, -70, 100}
      },
      {
        bb = {250, -175, 90, -85}
      }
    }
}
