
//Vars
import controlP5.*;
ControlP5 cp5;
ControlWindow window;


float mouX;
float mouY;
float radius= 150; //starting zoom radius
float wheelVal; 
float gridSize;
int rows;
int cols;
int rand;
boolean avalanche = false;
float heightMod;
float snowThresh;
color snow = color(255, 255, 255);
color grass = color(143, 170, 64);
color rock = color(135, 135, 135);
color dirt = color(160, 126, 84);
color water = color(0, 75, 200);
String file;


cameraControl cam = new cameraControl(); //camera object creation
terrain land = new terrain();

void setup(){
    //frameRate(20);
    colorMode(RGB);
    noStroke();
    cp5 = new ControlP5(this);

    fill(255,255,255); //starting info
    size(1200, 800, P3D);
    perspective(radians(50.0f), width/(float)height, 0.1, 1000);
    
    rows = 75;
    cols = 75;
    gridSize = 20;
    land.loadTerrain(gridSize,rows,cols);
    camera();

    cp5.addButton("Generate").setPosition(25,30).setSize(75,25);
    cp5.addButton("Avalanche").setPosition(25,60).setSize(75,25);
}


void mouseWheel(MouseEvent event) { //mouse wheel zoom
  if(!cp5.isMouseOver()){
     wheelVal = event.getCount()*10; //scaled x10 cause original too slow
  }
}

void mouseDragged(){
  if(!cp5.isMouseOver()){
    mouX = mouseX;
    mouY = mouseY;
  
    if(mouX <0) //bounding
      mouX = 0;
    else if (mouX >width-1)
      mouX = width-1;
    
    if(mouY <0)
      mouY = 0;
    else if (mouY >height-1)
      mouY = height-1;
  }
}

public void Generate(ControlEvent theEvent) {
    rows = 40;
    cols = 40;
    gridSize = 30;
    snowThresh = 6;
    land.vertices.clear();
    land.indexData.clear();
    rand = int(random(0,5));
    avalanche = false;
      

}

public void Avalanche(ControlEvent theEvent) {
    avalanche = true;
        
}


void draw(){

    perspective(radians(50.0f), width/(float)height, 0.1, 1000);
    colorMode(RGB);
    background(51);
    heightMod  = 8;

    
    float phi = radians( map(mouX,0,width-1,0,360)); //maping to polar vars
    float theta = radians(map(mouY,0,height-1,1,179)); 

  
    //camera positioning
    radius = cam.zoom(radius); //scroll wheel value
    cam.update(radius*cos(phi)*sin(theta),radius*cos(theta),radius*sin(theta)*sin(phi),cam.lookX,cam.lookY,cam.lookZ); //cam updaye
    camera(cam.positionX, cam.positionY, cam.positionZ, cam.lookX, cam.lookY, cam.lookZ, 0, -1, 0); //
    

    
    land.loadTerrain(gridSize,rows,cols);
    land.buildTerrain();
    
    perspective();
    camera();
    
    file = "terrain" + rand;
      if( file.length() == 8){
          land.heightFromImage(file);

       }

    if(snowThresh > 0 && avalanche == true){
      snowThresh -= 0.02;
    }
}


class terrain{
  ArrayList<PVector> vertices = new ArrayList<PVector>();
  ArrayList<Integer> indexData = new ArrayList<Integer>();
  
  
  
  
  void loadTerrain(float terrainSize,int rows, int cols){
    float colSpace = terrainSize/cols;
    float rowSpace = terrainSize/rows;
    int startIndex=0;
    int next=0;
    int last=0;

   float currentRow = -(terrainSize)/2;
   float currentCol = -(terrainSize)/2;
   
   for(int i = 0; i <= rows; i++){ //grid
      for(int j = 0; j <= cols; j++){ //grid

          vertices.add(new PVector(currentRow,0,currentCol));
          currentCol += colSpace;
        }
        currentCol = -(terrainSize)/2;
        currentRow+= rowSpace;
    } 
    
    
    for(int x = 0; x <rows; x++){ //grid
      for(int y = 0; y <cols; y++){
        
        startIndex = (cols+1)*(x)+y;
        next = startIndex+1;
        last = startIndex + cols+1;
          
          indexData.add(startIndex);
          indexData.add(next);
          indexData.add(last);
          startIndex++;
          next+=(cols+1);
          indexData.add(startIndex);
          indexData.add(next);
          indexData.add(last);
      }
      
    }
  }
  
  
  void buildTerrain(){
    
    beginShape(TRIANGLES);
    for(int i = 0; i<indexData.size();i++){
      PVector vert = vertices.get(indexData.get(i));
      float relativeHeight = abs((vert.y*heightMod)/(snowThresh));
        float ratio;
        if(relativeHeight > 0.8*abs(heightMod)){
            ratio = (relativeHeight - 0.8*abs(heightMod))/(0.2*abs(heightMod));
            fill(lerpColor(rock,snow,ratio));

        }
        else if(relativeHeight> 0.4*abs(heightMod)){
            ratio = (relativeHeight - 0.4*abs(heightMod))/(0.4*abs(heightMod));
            fill(lerpColor(grass,rock,ratio));

        }
      
        else if(relativeHeight> 0.2*abs(heightMod)){
            ratio = (relativeHeight - 0.2*abs(heightMod))/(0.2*abs(heightMod));
            fill(lerpColor(dirt,grass,ratio));

        }
        else{
            ratio = (relativeHeight)/(0.2*abs(heightMod));
            fill(lerpColor(water,dirt,ratio));

        }
      
      vertex(vert.x, vert.y, vert.z);
    }
    endShape();
  

    }
    
    void heightFromImage(String filename){
      
      PImage mapImage = loadImage(filename+".png");
      if( mapImage != null){

        for(int i = 0; i <=rows;i++){
          for(int j = 0; j <=cols;j++){
              float xIndex = map(j,0,cols+1,0,mapImage.width);
              float yIndex = map(i,0,rows+1,0,mapImage.height);
              int pixColor = mapImage.get(int(xIndex),int(yIndex));
              float heightFromColor = map(red(pixColor),0,255,0,1.0);
            
            int vertexIndex = i*(cols+1)+j;
            vertices.get(vertexIndex).y = heightFromColor*heightMod;
          }
        
        }
      }
      
    }

  
}


class cameraControl{
  float positionX;
  float positionY;
  float positionZ;
  float lookX = 0;
  float lookY = 0;
  float lookZ = 0;
  
  
  void update(float x, float y, float z,float _lookX, float _lookY, float _lookZ){
        
      positionX = _lookX+x;
      positionY = _lookY+y;
      positionZ = _lookZ+z;
      
  }

 
  float zoom(float input){
      float zoomVal = input + wheelVal;
      wheelVal = 0;    
      if(zoomVal <30)
        zoomVal = 30;
      else if (zoomVal >200)
        zoomVal = 200;
        
      return zoomVal;
  }
  
}
