# Ray-Tracing
Computer Graphics 2018 Ben-Gurion University.

Original source code:

```rayTraserGLFW```

Modified files: 

```.\rayTraserGLFW\rayTraserGLFW\res\shaders\basicShader.glsl```


## Description
Generating an image by tracing the path of light through pixels in an image plane and simulating the effects of its 
encounters with virtual objects. 

The objective of this exercise is to implement a ray casting/tracing engine. A ray tracer shoots rays from the 
observer’s eye through a screen and into a scene of objects. It calculates the ray’s intersection with objects, 
finds the nearest intersection and calculates the color of the surface according to its material and lighting 
conditions.

### Feature set
* Background: Plain color background
* Display geometric primitives in space: Spheres and Planes
* Basic lighting: Directional lights, Spot lights, Ambient light, Simple materials (ambient, diffuse, specular...)
* Basic hard shadows
* One Reflection

### Screen
The screen is located on z=0 plane. The right up corner of the screen is located at (1,1,0) and the left bottom 
corner of the screen is located at (-1,-1,0). All in the scene coordinates.

### Input
Location of input file: 

```
.\rayTraserGLFW\rayTraserGLFW\res\scene.txt`
```

You will get one text file named scene.txt.
* The first line in the file will start with the letter "e" flowing by camera (eye) coordinates.
The fourth coordinate use as mode flag (1.0 for normal mode, 2.0  for Reflection mode, 3.0 for Transparent spheres mode).
* Second line starts with "a" followed by (R,G,B,A) coordinate represents the ambient
light.

From the third row we will describe the object and lights in scene:
* Light direction will describe by "d" letter followed by light direction (x, y, z, w). 'w' value
will be 0.0 for directional light and 1.0 for spotlight.
* For spotlights the position will appease afterwards after the letter "p" (x,y,z,w).
* Light intensity will describe by "i" followed by light intensity (R, G, B, A).
* Spheres and planes will description will appear after "o". For spheres (x,y,z,r) when
(x,y,z) is the center position and r is the radius (always positive, greater than zero). For
planes (a,b,c,d) which represents the coefficients of the plane equation when 'd' gets is
a non-positive value.
* The color of an object will appears after "c" and will represents the ambient and diffuse
values (R,G,B,A). 'A' represents the shininess parameter value.

Example of input file (scene.txt):
```
e 0.0 0.0 4.0 1.0
a 0.1 0.2 0.3 1.0
o 0.0 -0.5 -1.0 -3.5
o -0.7 -0.7 -2.0 0.5
o 0.6 -0.5 -1.0 0.5
c 0.0 1.0 1.0 10.0
c 1.0 0.0 0.0 10.0
c 0.6 0.0 0.8 10.0
d 0.5 0.0 -1.0 1.0
d 0.0 0.5 -1.0 0.0
p 2.0 1.0 3.0 0.6
i 0.2 0.5 0.7 1.0
i 0.7 0.5 0.0 1.0
```

### Output
![scene](https://github.com/lina994/Ray-Tracing/blob/master/res/mode1.png?raw=true)

## Installation:
* visual studio 2017


