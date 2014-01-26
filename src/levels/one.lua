return {
  behavior = {
    start = function(level)
      level:loadPc()

    end
  },
  backgroundFilename = "images/background.jpg",
    objects = {
      {
        bb = {-300, 280, -350, -280}
      },
      {
        bb = {300, 280, 350, -280}
      },
      {
        bb = {300, 210, -300, 210}
      },
      {
        bb = {300, -210, -300, -210}
      },
      {
        bb = {-200, 50, -100, 20}
      }
    }
}
