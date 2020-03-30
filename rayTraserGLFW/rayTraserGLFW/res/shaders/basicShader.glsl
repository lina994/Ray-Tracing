 #version 130 

uniform vec4 eye;
uniform vec4 ambient;
uniform vec4[20] objects;
uniform vec4[20] objColors;
uniform vec4[10] lightsDirection;
uniform vec4[10] lightsIntensity;
uniform vec4[10] lightPosition;
uniform ivec3 sizes; //number of objects & number of lights

in vec3 position1;

/*******************************************************
mod:
eye.w = 1  normal mode
eye.w = 2  mirror mode
eye.w = 3  Transparent spheres mode
********************************************************/


/* if t< 0.0 there are not intersection, else return parameter t of closer intersection with sphere */
float sphereIntersection(int objIndex,vec3 sourcePoint,vec3 ray)
{
	float t = -1.0;
	vec4 currentObject = objects[objIndex];
	vec3 l = currentObject.xyz - sourcePoint;		// vector from sourcePoint to sphere center
	float tm = dot(l, ray);							// the length from sourcePoint to normal that vertical to ray
	float l_length = length(l);						// length of vector l
	float d_2 = pow(l_length, 2)-pow(tm, 2);		// a^2 + b^2 = c^2
	if(d_2 > pow(currentObject.w, 2))				// check if intersection between ray and sphere
		return t;									//there are not intersection
	float th = sqrt(pow(currentObject.w, 2)-d_2);	// a^2 + b^2 = c^2
	float t1=tm-th;									// first intersection point
	float t2=tm+th;									// second intersection point
	if(t1>0.0001 && t2>0.0001)						// take min t>0
		t = min(t1, t2);
	else if(t1>0.0001)
		t=t1;
	else if(t2>0.0001)
		t=t2;
	return t;
}

/* Place a point (p0=p+tv) in the plane equation */
float planeIntersection(int i, vec3 sourcePoint,vec3 ray)
{
	vec3 obj = normalize(objects[i].xyz);
	if(dot(obj,ray)==0.0)		//check that not parallel
		return -1.0;
	float t = (-(objects[i].w + obj.x*sourcePoint.x + obj.y*sourcePoint.y + obj.z*sourcePoint.z)) /(obj.x*ray.x + obj.y*ray.y + obj.z*ray.z);
	return t;
}

vec2 intersection(vec3 sourcePoint,vec3 v, int transparent)
{
	float t = -1.0;											//t for closer object (ray = sourcePoint+tV)
	float t_temp= -1.0;
	int index = 0;											//index of closer object

    for (int i = 0; i < sizes.x; i++){						//check all objects //check if sphere or plane(check d for positive or negative)
		if(objects[i].w < 0.0)								//plane					
			t_temp=planeIntersection(i, sourcePoint, v);
		else if(transparent == 1)
			continue;
		else												//sphere
			t_temp = sphereIntersection(i, sourcePoint, v);

		if(t_temp > 0.0001 && t>0 && t_temp < t)
		{
			t =t_temp;
			index = i;
		}
		else if(t_temp > 0.0001 && t<0)
		{
			t = t_temp;
			index = i;
		}
	}
    return vec2(t, index);  
}

vec3 calculateIntersectionPoint(vec3 sourcePoint, vec3 direction, float t){
	vec3 point = sourcePoint+(t*direction);
	return point;
}

int checkDirectionalLightBlocked(vec3 intersectionPoint, int objIndex, int lightIndex, int transparent)		//0 if ray is blocked, 1 otherwise
{
	vec3 directionToLight = -1*normalize(lightsDirection[lightIndex].xyz);
	float t = intersection(intersectionPoint, directionToLight, transparent).x;							//(t, objIndex)
	if (t <= 0.0001) 
		return 1;
	else
		return 0;
}

int checkSpotLightBlocked(vec3 intersectionPoint, int objIndex, int lightIndex, int spotLightCount, int transparent)				//0 if ray is blocked, 1 otherwise
{
	vec3 lightDirection = normalize(lightsDirection[lightIndex].xyz);
	vec3 directionToObject = normalize(intersectionPoint-lightPosition[spotLightCount].xyz);
	float cos_angle =  dot(lightDirection, directionToObject);
	if(cos_angle<lightPosition[spotLightCount].w)
		return 0;
	else
	{
		vec3 directionToLight = -1*directionToObject;
		float t = intersection(intersectionPoint, directionToLight, transparent).x;						//(t, objIndex)
		if (t <= 0.0001) 
			return 1;
		else
		{
			float distToLight = distance(intersectionPoint, lightPosition[spotLightCount].xyz);
			vec3 newT = calculateIntersectionPoint(intersectionPoint, directionToLight, t);
			float distToAnotherObj = distance(intersectionPoint, newT);
			if(distToLight<distToAnotherObj)
				return 1;
			return 0;

		}
	}	
}

float diffuseReflection(vec3 intersectionPoint, float t, int objIndex, int lightIndex, int spotLightCount, int isMirror)		//Kd(N*Li)
{
	vec3 normalToObject;
	//vec3 directionToLight;
	vec3 directionToLight= -1*normalize(lightsDirection[lightIndex].xyz);
	float cos_angle;

	float diffuse = 1;

	if(objects[objIndex].w < 0.0 && isMirror==0){													//plane
		normalToObject = normalize(objects[objIndex].xyz);						//???-

		if(mod(int(1.5*intersectionPoint.x),2)== mod(int(1.5*intersectionPoint.y),2))
			if((intersectionPoint.x>=0 && intersectionPoint.y>=0) ||(intersectionPoint.x<=0 && intersectionPoint.y<=0))
				diffuse=0.5;
		if(mod(int(1.5*intersectionPoint.x),2)!= mod(int(1.5*intersectionPoint.y),2))
			if((intersectionPoint.x<0 && intersectionPoint.y>0) ||(intersectionPoint.x>0 && intersectionPoint.y<0))
				diffuse=0.5;


	} 
	else																			//sphere
		normalToObject = normalize(intersectionPoint-objects[objIndex].xyz);

	cos_angle =abs(dot(normalToObject, directionToLight));		//?????abs
	return diffuse*cos_angle;
	

}

float materialSpecular(vec3 intersectionPoint, float t, int objIndex, int lightIndex, int spotLightCount)
{
	float x = 0.7;	// The specular value of an object is always (0.7,0.7,0.7,1.0)
	vec3 directionToEye=normalize(eye.xyz-intersectionPoint);
	vec3 directionOfLight;
	vec3 normalToObject;

	if(lightsDirection[lightIndex].w == 0.0)									//directional light
		directionOfLight= normalize(lightsDirection[lightIndex].xyz);
	else																		//spot light
		directionOfLight= normalize(intersectionPoint-lightPosition[spotLightCount].xyz);
	if(objects[objIndex].w < 0.0)												//plane
		normalToObject = normalize(objects[objIndex].xyz);
	else																		//sphere
		normalToObject = normalize(intersectionPoint-objects[objIndex].xyz);

	vec3 r=normalize(reflect(directionOfLight, normalToObject));				//reflectionVector

	float eye_r = max(0,dot(directionToEye, r));
	int shininess = int(objColors[objIndex].w);

	return 0.7*pow(eye_r,shininess);  
}

vec4 calcSumKd(vec3 sourcePoint,vec3 intersectionPoint, float t, int objIndex, int isMirror, int transparent) //problem
{
	vec4 result=vec4(0,0,0,0);
	int spotLightCount=0;
	for(int i = 0; i <sizes.y; i++){

		int isBlocked = 1;								//0 if ray is blocked, 1 otherwise

		if(lightsDirection[i].w == 0.0)					//directional light
			isBlocked =checkDirectionalLightBlocked(intersectionPoint, objIndex, i, transparent);				//si
		else											//spot light
		{
			isBlocked =checkSpotLightBlocked(intersectionPoint, objIndex, i, spotLightCount, transparent);		//si
			spotLightCount +=1;
		}

		if(isBlocked == 1)		//is not blocked
		{
			float diffuse_1 = diffuseReflection(intersectionPoint, t, objIndex, i, spotLightCount-1, isMirror);
			result+=(diffuse_1*lightsIntensity[i]);

		}
	}
	return result;  //vec4(1,1,1,1)
}


vec4 calcSumKs(vec3 sourcePoint,vec3 intersectionPoint, float t, int objIndex, int transparent)
{
	vec4 result=vec4(0,0,0,0);
	int spotLightCount=0;
	for(int i = 0; i <sizes.y; i++){
		int isBlocked = 1;								//0 if ray is blocked, 1 otherwise
		if(lightsDirection[i].w == 0.0)					//directional light
			isBlocked =checkDirectionalLightBlocked(intersectionPoint, objIndex, i,  transparent);				//si
		else											//spot light
		{
			isBlocked =checkSpotLightBlocked(intersectionPoint, objIndex, i, spotLightCount, transparent);		//si
			spotLightCount +=1;
		}

		if(isBlocked == 1)		//is not blocked
		{
			float specular_1 = materialSpecular(intersectionPoint,t, objIndex, i, spotLightCount-1);
			result+=(specular_1*lightsIntensity[i]);

		}
	}
	return result;
}

/*
vec4 calcSumLight(vec3 sourcePoint,vec3 intersectionPoint, float t, int objIndex){
	vec4 result=vec4(0,0,0,0);
	int spotLightCount=0;
	for(int i = 0; i <sizes.y; i++){
		int isBlocked = 1;								//0 if ray is blocked, 1 otherwise

		if(lightsDirection[i].w == 0.0)					//directional light
			isBlocked =checkDirectionalLightBlocked(intersectionPoint, objIndex, i);				//si
		else											//spot light
		{
			isBlocked =checkSpotLightBlocked(intersectionPoint, objIndex, i, spotLightCount);		//si
			spotLightCount +=1;
		}

		if(isBlocked == 1)		//is not blocked
		{
			result+=(lightsIntensity[i]);
		}
	}
	return result;
}
*/

vec3 calcSnellsLaw(vec3 l_ray, vec3 norm, float n1, float n2)
{
	float n = n1/n2;
	float c1 = dot(norm,l_ray);
	float c2 = sqrt(1 - pow(n, 2)*(1-pow(c1, 2)));
	vec3 result = normalize((n*c1-c2)*norm - n*l_ray);
	return result;
}

vec3 colorCalc(vec3 sourcePoint,vec3 intersectionPoint, float t, int index, int transparent)
{
    vec3 color = vec3(0,0,0);  //original
	vec4 sumKd = calcSumKd(sourcePoint, intersectionPoint, t, index, 0, transparent);		// Diffuse and Specular calculations
	vec4 sumKs = calcSumKs(sourcePoint, intersectionPoint, t, index, transparent);
	color = objColors[index].rgb*(ambient.rgb+sumKd.rgb)+sumKs.rgb;								//vec3(0.1, 0.2, 0.3)    vec3(0.2, 0.1, 0.0) vec3(0.2 ,0.2, 0.3) global ambient 
    return color;
}

vec3 colorCalcOfMirror(vec3 sourcePoint,vec3 intersectionPoint,vec3 ray1, float t, int index)
{
	//vec3 color = vec3(clamp(colorCalc(position1.xyz, intersectionPoint, t, index, 0),0.0,1.0));
	vec3 color = vec3(0.0,0.0,0.0);											//vec3(0.8,0.8,0.8); grey
	vec3 normalToObject = normalize(objects[index].xyz);					//normal to plane
	vec3 ray2 =normalize(reflect(ray1, normalToObject));					//direction of reflection vector
	vec2 intersec2 = intersection(intersectionPoint,ray2, 0);
	float t2= intersec2.x;

	if(t2 > 0.0)																//there is object
	{
		vec3 intersectionPoint2= calculateIntersectionPoint(intersectionPoint, ray2, t2);
		int index2 = int(intersec2.y);
		vec4 sumKd = calcSumKd(sourcePoint, intersectionPoint, t, index, 1, 0);		// Diffuse and Specular calculations
		vec4 sumKs = calcSumKs(sourcePoint, intersectionPoint, t, index, 0);
		color = objColors[index2].rgb*(ambient.rgb+sumKd.rgb)+sumKs.rgb;	
		color+= vec3(clamp(colorCalc(intersectionPoint, intersectionPoint2, t2, index2, 0),0.0,1.0));
		color = clamp(color,0.0,1.0);
	}
    return color;
}

vec3 colorCalcOfTransparent(vec3 sourcePoint,vec3 intersectionPoint,vec3 ray1, float t, int index)
{
	if(objects[index].w < 0.0)
			return colorCalc(position1.xyz, intersectionPoint, t, index, 1);

	vec3 color = vec3(clamp(colorCalc(position1.xyz, intersectionPoint, t, index, 0),0.0,1.0));
	vec3 norm = normalize(intersectionPoint-objects[index].xyz);
	vec3 innerRay = calcSnellsLaw(-1*normalize(ray1), norm, 1.0, 1.5);

	vec2 intersec2 = intersection(intersectionPoint,innerRay, 0);		//vec2(t, index); 
	float t2= intersec2.x;
	if(t2<=0)											//no intersections
		gl_FragColor = vec4(vec3(0,0,0), 1);

	vec3 intersectionPoint2= calculateIntersectionPoint(intersectionPoint, innerRay, t2);

	if(int(intersec2.y)!=index)
		return vec3(clamp(colorCalc(intersectionPoint, intersectionPoint2, t2, int(intersec2.y), 1),0.0,1.0));

	else
	{
		vec3 norm2 = normalize(objects[index].xyz-intersectionPoint2);
		vec3 ray2 = calcSnellsLaw(-1*innerRay, norm2, 1.5, 1.0);
		vec2 intersec3 = intersection(intersectionPoint2,ray2, 0);
		float t3= intersec3.x;
		if(t3<=0)											//no intersections
			gl_FragColor = vec4(vec3(0,0,0), 1);

		vec3 intersectionPoint3= calculateIntersectionPoint(intersectionPoint2, ray2, t3);
		return vec3(clamp(colorCalc(intersectionPoint2, intersectionPoint3, t3, int(intersec3.y),1 ),0.0,1.0));

	}

	

    return color;
}



void main()
{  
	int indexOfMirror=-1;
	vec2 intersec;										//(t, objIndex)
	float t = 0.0;
	int index = 0;
	vec3 direction = normalize(position1 - eye.xyz);	//direction of current vector

	if(eye.w==2)										//if mirror mode-find first plane
	{
		for(int i = 0; i <sizes.x && indexOfMirror==-1; i++){
			if(objects[i].w < 0.0)						//plane
				indexOfMirror = i;
		}
	}

	intersec=intersection(position1,direction, 0);
	t= intersec.x;


	if(t<=0)											//no intersections
		gl_FragColor = vec4(vec3(1,0,1), 1);
	else												//intersections
	{
		index = int(intersec.y);
		vec3 intersectionPoint= calculateIntersectionPoint(position1, direction, t);

		if(eye.w!=2.0 && eye.w!=3.0)									//normal mode
			gl_FragColor = vec4(clamp(colorCalc(position1.xyz, intersectionPoint, t, index, 0),0.0,1.0),1);
		
		else if(eye.w==2.0)								//mirror mode
		{
			if(indexOfMirror==-1 || index != indexOfMirror)
				gl_FragColor = vec4(clamp(colorCalc(position1.xyz, intersectionPoint, t, index, 0),0.0,1.0),1);
			else
				gl_FragColor = vec4(clamp(colorCalcOfMirror(position1.xyz, intersectionPoint, direction, t, index),0.0,1.0),1);
		}
		else if(eye.w==3.0)								//Transparent spheres
		{
				gl_FragColor = vec4(clamp(colorCalcOfTransparent(position1.xyz, intersectionPoint, direction, t, index),0.0,1.0),1);
		
		}
		
	
	}
}
 


