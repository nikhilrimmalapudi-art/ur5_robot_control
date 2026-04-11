# UR5 Pick and Place using CoppeliaSim (Lua + IK)

This project implements a **pick and place robotic system** using a **UR5 robotic arm** in CoppeliaSim.  
The robot picks a cuboid object and places it into a bowl using **inverse kinematics (IK)** and **gripper control**.

---

## 🚀 Features

- Smooth robotic arm motion using IK
- Gripper open/close control
- Object pick and attach
- Controlled placement into bowl
- Collision-safe release (no hitting bowl edges)

---

## 🛠️ Technologies Used

- CoppeliaSim
- Lua scripting
- Inverse Kinematics (simIK module)

---

## ⚙️ Working

1. Robot moves above the cuboid  
2. Gripper closes and picks the object  
3. Object is attached to the gripper  
4. Robot lifts the object  
5. Moves above the bowl  
6. Releases object inside bowl  
7. Returns to home position  

---

---

## ▶️ How to Run

1. Open CoppeliaSim
2. Load your scene with UR5, cuboid, and bowl
3. Attach this Lua script to the UR5 robot
4. Click **Play**

---

## ⚠️ Requirements

Make sure these objects exist in your scene:

- `/UR5`
- `/Cuboid`
- `/Bowl`
- `/UR5/BarrettHand`
- `/UR5/attachPoint`

---

## 🔧 Key Concepts Used

- **Inverse Kinematics (IK)** for smooth movement
- **Linear interpolation (lerp)** for trajectory
- **Gripper joint control**
- **Object parenting (attach/detach)**

---

## 📌 Output

The robot successfully picks the cuboid and places it into the bowl smoothly without collision.

---

## 🔮 Future Improvements

- Vision-based detection (OpenCV)
- Multi-object handling
- Sorting system
- Real robot implementation

---

## 👨‍💻 Author

Robotics Simulation Project using UR5 in CoppeliaSim
