# Snake Game in x86 Assembly (Irvine32)

## Overview

This is a classic **Snake Game** implemented in **x86 Assembly** using the **Irvine32 library**. The game runs in a console window and features a grid-based play area with walls, a growing snake, and randomly spawning food. The player controls the snake with arrow keys, aiming to eat as much food as possible without colliding with the walls or itself.

---

## Features

- **Arrow Key Controls:** Move the snake in four directions (up, down, left, right).  
- **Score Tracking:** Points increase each time the snake eats food.  
- **Growing Snake:** The snake grows longer each time it consumes food.  
- **Random Food Placement:** Food spawns at random positions, avoiding the snake’s body.  
- **Collision Detection:** Game ends if the snake hits a wall or itself.  
- **Colorful Display:** Uses colors for snake head, body, food, and walls.  
- **Start Screen:** Shows instructions before the game starts.  
- **Game Over Screen:** Displays final score and waits for user input before exiting.  

---

## Controls

| Key          | Action              |
|--------------|-------------------|
| Arrow Up     | Move snake up      |
| Arrow Down   | Move snake down    |
| Arrow Left   | Move snake left    |
| Arrow Right  | Move snake right   |
| ESC / Q / q  | Quit the game      |
| Enter        | Confirm exit       |

---

## How to Run

1. Open the project in **Visual Studio** or any IDE that supports x86 assembly with Irvine32.  
2. Ensure `Irvine32.inc` and `Irvine32.lib` are included in your project directory.  
3. Build the project.  
4. Run the executable (`.exe`) in a console window.  
5. Follow on-screen instructions to start the game.  

---

## Code Structure

- **Main Procedure (`main PROC`)**  
  Handles initialization, start screen, main game loop, and exit.

- **InitializeSnake**  
  Sets the initial position, length, and direction of the snake.

- **SpawnFood**  
  Places food at a random location, ensuring it does not overlap the snake.

- **RenderFrame**  
  Draws the game grid, walls, snake, food, and score.

- **CheckPosition**  
  Determines what to render at each grid cell (snake head, body, food, or empty space).

- **ProcessInput**  
  Reads keyboard input and updates snake direction.

- **UpdateSnake**  
  Moves the snake, checks collisions, grows snake when food is eaten, and handles game over.

---

## Constants

| Constant        | Value | Description                        |
|-----------------|-------|------------------------------------|
| `GRID_WIDTH`    | 40    | Width of the game area              |
| `GRID_HEIGHT`   | 20    | Height of the game area             |
| `MAX_SNAKE`     | 250   | Maximum length of the snake         |
| `GAME_DELAY`    | 90    | Delay (ms) between frames           |
| `DIR_RIGHT`     | 0     | Snake moves right                   |
| `DIR_DOWN`      | 1     | Snake moves down                    |
| `DIR_LEFT`      | 2     | Snake moves left                    |
| `DIR_UP`        | 3     | Snake moves up                      |

---

## Notes

- The game uses **Irvine32 library functions** like `RandomRange`, `Delay`, `ClrScr`, `Gotoxy`, `SetTextColor`, `WriteString`, and `ReadKey`.  
- The console window must be large enough to fit the game grid.  
- The snake grows dynamically but cannot exceed `MAX_SNAKE` segments.  

---

## Author

**Abbad Hasan**
