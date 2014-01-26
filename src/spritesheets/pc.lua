return {
  numCellsX = 4,
  numCellsY = 6,
  cellRect = {x1 = -24, y1 = -24, x2 = 24, y2 = 24},
  animations = {
    idle = {
      frames = {
        {delay = 0.5, idx = 1},
      }
    },
    up = {
      frames = {
        {delay = 0.1, idx = 3},
        {delay = 0.1, idx = 7},
        {delay = 0.1, idx = 11},
        {delay = 0.1, idx = 15},
        {delay = 0.1, idx = 19},
        {delay = 0.1, idx = 23}
      }
    },
    down = {
      frames = {
        {delay = 0.1, idx = 1},
        {delay = 0.1, idx = 5},
        {delay = 0.1, idx = 9},
        {delay = 0.1, idx = 13},
        {delay = 0.1, idx = 17},
        {delay = 0.1, idx = 21}
      }
    },
    left = {
      frames = {
        {delay = 0.1, idx = 2},
        {delay = 0.1, idx = 6},
        {delay = 0.1, idx = 10},
        {delay = 0.1, idx = 14},
        {delay = 0.1, idx = 18},
        {delay = 0.1, idx = 22}
      }
    },
    right = {
      frames = {
        {delay = 0.1, idx = 4},
        {delay = 0.1, idx = 8},
        {delay = 0.1, idx = 12},
        {delay = 0.1, idx = 16},
        {delay = 0.1, idx = 20},
        {delay = 0.1, idx = 24}
      }
    }
  },
  imageFilename = "images/mac.png"
}
