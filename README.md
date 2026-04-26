# PONG VGA Game

## Description
This project implements a hardware-based **Pong game** for two players, designed to generate a standard **VGA signal (640x480 @ 60 Hz)**. The entire game logic, including collision detection, paddle movement, and video synchronization, is handled by dedicated digital logic without the use of a microcontroller or CPU.

## Features
* **Standard VGA Output:** Generates HSync and VSync signals for CRT or LCD monitors.
* **Dual Player Controls:** Real-time paddle movement for two players.
* **Dynamic Collision Physics:** Detects ball collisions with walls and paddles.
* **Visual Elements:**
    * Two vertical paddles.
    * Mobile ball with velocity logic.
    * Boundary rendering.
* **Fully Digital Architecture:** Modular design using a custom HV-Sync generator.

## Interface

### Inputs
| Pin | Name | Description |
|:--- |:--- |:--- |
| `clk` | Clock | System clock (Target: **25.175 MHz**). |
| `rst_n` | Reset | Active-low asynchronous reset. |
| `ui_in[3:0]` | Control | Movement inputs for both players. |

### Control Mapping (`ui_in`)
| Bits | Function | Description |
|:--- |:--- |:--- |
| **ui_in[0]** | **P1 Up** | Moves the left paddle upwards. |
| **ui_in[1]** | **P1 Down** | Moves the left paddle downwards. |
| **ui_in[2]** | **P2 Up** | Moves the right paddle upwards. |
| **ui_in[3]** | **P2 Down** | Moves the right paddle downwards. |

### Output
| Pin | Name | Description |
|:--- |:--- |:--- |
| **uo_out[7]** | **HSYNC** | Horizontal synchronization pulse (VGA Pin 13). |
| **uo_out[3]** | **VSYNC** | Vertical synchronization pulse (VGA Pin 14). |
| **uo_out[6:4, 2:0]**| **RGB** | 2-bit per channel digital color output. |

## Operation
The design utilizes an internal **HV-Sync Generator** to track the current pixel position $(X, Y)$. 

1. **Game Logic:** During the Vertical Blanking interval, the ball and paddle positions are updated based on user input and collision flags.
2. **Video Generation:** During the Active Video region, a comparator-based logic determines if the current pixel belongs to a paddle, the ball, or the background, and outputs the corresponding RGB values.

## Usage
The output is designed to be connected to:
* A VGA monitor via a **DB15 connector**.
* A simple **DAC** (like an R-2R ladder) for the color bits.
* An **FPGA development board** (like the Altera Cyclone II) for real-time validation.

## Applications
* **Digital Logic Education:** Demonstrates state machines and timing.
* **Hardware Games:** Retro-gaming implementation on silicon.
* **VGA Controllers:** Base architecture for video generation systems.
