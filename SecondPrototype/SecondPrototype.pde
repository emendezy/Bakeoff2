import java.util.ArrayList;
import java.util.Collections;
import java.awt.Robot;
import java.awt.AWTException;
import java.awt.PointerInfo;
import java.awt.MouseInfo;
import java.awt.Point;
import java.lang.Math;

//these are variables you should probably leave alone
int index = 0; //starts at zero-ith trial
float border = 0; //some padding from the sides of window
int trialCount = 12; //this will be set higher for the bakeoff
int trialIndex = 0; //what trial are we on
int errorCount = 0;  //used to keep track of errors
float errorPenalty = 0.5f; //for every error, add this value to mean time
int startTime = 0; // time starts when the first click is captured
int finishTime = 0; //records the time of the final click
boolean userDone = false; //is the user done
boolean pressedSubmit = false; //is the user done w the current trial

//drag and drop variables
boolean draggingSquare = false;
Robot robby;

final int screenPPI = 72; //what is the DPI of the screen you are using
//you can test this by drawing a 72x72 pixel rectangle in code, and then confirming with a ruler it is 1x1 inch. 

//These variables are for my example design. Your input code should modify/replace these!
float screenTransX = 0;
float screenTransY = 0;
float screenRotation = 0;
float screenZ = 50f;

//rotate resize variables
int lenRotateControlHandle = 50;
boolean rotateResizeSelected = false;
float prevPosX, prevPosY;
int widthOfRotateControlCircle = 40;
int rotateCircleXpos = 0;
int rotateCircleYpos = -lenRotateControlHandle;

private class Target
{
  float x = 0;
  float y = 0;
  float rotation = 0;
  float z = 0;
}

ArrayList<Target> targets = new ArrayList<Target>();

void setup() {
  size(1000, 800); 

  rectMode(CENTER);
  textFont(createFont("Arial", inchToPix(.3f))); //sets the font to Arial that is 0.3" tall
  textAlign(CENTER);

  //setting up mouse movement
  try
  {
    robby = new Robot();
  }
  catch (AWTException e)
  {
    println("Robot class not supported by your system!");
    exit();
  }
  
  //don't change this! 
  border = inchToPix(2f); //padding of 1.0 inches

  for (int i=0; i<trialCount; i++) //don't change this! 
  {
    Target t = new Target();
    t.x = random(-width/2+border, width/2-border); //set a random x with some padding
    t.y = random(-height/2+border, height/2-border); //set a random y with some padding
    t.rotation = random(0, 360); //random rotation between 0 and 360
    int j = (int)random(20);
    t.z = ((j%12)+1)*inchToPix(.25f); //increasing size from .25 up to 3.0" 
    targets.add(t);
    println("created target with " + t.x + "," + t.y + "," + t.rotation + "," + t.z);
  }

  Collections.shuffle(targets); // randomize the order of the button; don't change this.
}



void draw() {
  
  if(checkForSuccess()){
     background(0,255,0);
  } else {
    background(40); //background is dark grey
  }
  fill(200);
  noStroke();

  //shouldn't really modify this printout code unless there is a really good reason to
  if (userDone)
  {
    text("User completed " + trialCount + " trials", width/2, inchToPix(.4f));
    text("User had " + errorCount + " error(s)", width/2, inchToPix(.4f)*2);
    text("User took " + (finishTime-startTime)/1000f/trialCount + " sec per target", width/2, inchToPix(.4f)*3);
    text("User took " + ((finishTime-startTime)/1000f/trialCount+(errorCount*errorPenalty)) + " sec per target inc. penalty", width/2, inchToPix(.4f)*4);
    return;
  }

  //===========DRAW DESTINATION SQUARES=================
  for (int i=0; i<trialCount; i++)
  {
    pushMatrix();
    translate(width/2, height/2); //center the drawing coordinates to the center of the screen
    Target t = targets.get(i);
    translate(t.x, t.y); //center the drawing coordinates to the center of the screen
    rotate(radians(t.rotation));
    if (trialIndex==i){
      fill(255, 0, 0, 192); //set color to semi translucent
      rect(0, 0, t.z, t.z);
      fill(255, 255, 0, 255);
      ellipse(0,0,10,10);
    } else {
      fill(255, 255, 0, 128);
      fill(128, 60, 60, 80); //set color to semi translucent
      rect(0, 0, t.z, t.z);
    }
    popMatrix();
  }
  
  //===========DRAW CONNECTING LINE=================
  fill(255);
  if(trialIndex != trialCount){
    line(targets.get(trialIndex).x, targets.get(trialIndex).y, 0, 0);
  }
  
  //===========DRAW CURSOR SQUARE===================
  pushMatrix();
  translate(width/2, height/2); //center the drawing coordinates to the center of the screen
  translate(screenTransX, screenTransY);
  rotate(radians(screenRotation));
  fill(0,0,0,0);
  strokeWeight(3f);
  stroke(160);
  rect(0, 0, screenZ, screenZ);
  fill(0,190,255, 128);
  ellipse(0,0,screenZ, screenZ);
  line(0, -screenZ/2, 0, -lenRotateControlHandle - (screenZ/2));
  strokeWeight(0f);
  fill(0, 225, 0);
  rotateCircleXpos = (int)screenTransX; 
  ellipse(0, -lenRotateControlHandle - (screenZ/2), widthOfRotateControlCircle + 50, widthOfRotateControlCircle);
  
  fill(0, 198, 255, 200);
  ellipse(0, 0, 10, 10);
  popMatrix();

  //===========DRAW EXAMPLE CONTROLS=================
  fill(255);
  text("Trial " + (trialIndex+1) + " of " +trialCount, width/2, inchToPix(.8f));
  fill(44, 93, 254);
  text("Double click ANYWHERE to submit", width/2, height-inchToPix(.4f));
}




void mousePressed()
{  
  if (startTime == 0) //start time on the instant of the first user click
  {
    startTime = millis();
    println("time started!");
  }
  float adjustedX = mouseX - (width/2);
  float adjustedY = mouseY - (height/2);
  float length = (screenZ/2) + 2;
  //clicked inside of square
  if (abs(screenTransX - adjustedX) < length && abs(screenTransY - adjustedY) < length)
  {
    //jump the cursor to be in the center of the square
    PointerInfo a = MouseInfo.getPointerInfo();
    Point b = a.getLocation();
    int x = (int) b.getX();
    int y = (int) b.getY();
    float xdiff =  screenTransX - adjustedX;
    float ydiff = screenTransY - adjustedY;
    robby.mouseMove(x+(int)xdiff, y+(int)ydiff);
    
    //start dragging the square to follow the cursor for as long as it is still pressed
    draggingSquare = true;
  } 
  
  if (!rotateResizeSelected && overCircle())
  {
    prevPosX = mouseX;
    prevPosY = mouseY;
    rotateResizeSelected = true;
  }
}

void mouseDragged() 
{  
  
  if (draggingSquare){
    float adjustedX = mouseX - (width/2);
    float adjustedY = mouseY - (height/2);
    screenTransX = adjustedX;
    screenTransY = adjustedY;
  }
  // rotation logic
  if(rotateResizeSelected)
  {
    if(mouseX > prevPosX)
    {
      screenRotation += 2;
    }
    else if (mouseX < prevPosX)
    {
      screenRotation -= 2;
    }
    prevPosX = mouseX;
    
    // resizing logic
    if(rotateResizeSelected)
    {
      if(mouseY > prevPosY)
      {
        screenZ = constrain(screenZ-inchToPix(.02f), .01, inchToPix(4f)); //leave min and max alone!
      }
      else if (mouseY < prevPosY)
      {
        screenZ = constrain(screenZ+inchToPix(.02f), .01, inchToPix(4f)); //leave min and max alone!
      }
      prevPosY = mouseY;
    }
  }
}

public void mouseClicked(MouseEvent evt) {
  if (evt.getCount() == 2){
    if (userDone==false && !checkForSuccess())
      errorCount++;

    trialIndex++; //and move on to next trial

    if (trialIndex==trialCount && userDone==false)
    {
      userDone = true;
      finishTime = millis();
    }
    
  }
}

void mouseReleased()
{

  if (draggingSquare){
    draggingSquare = false;
  }
  if (rotateResizeSelected){
    rotateResizeSelected = false;
  }
}

boolean overCircle() {
  double radians = radians(screenRotation);  
  double hyp = (screenZ/2) + lenRotateControlHandle + (widthOfRotateControlCircle/2); 
  double adj = hyp * Math.sin(radians);
  double opp = hyp * Math.cos(radians);
  double centerCircleX = screenTransX + adj;
  double centerCircleY = screenTransY - opp;
  float adjustedX = mouseX - (width/2);
  float adjustedY = mouseY - (height/2);
      
  if (dist((float)centerCircleX, (float)centerCircleY, adjustedX, adjustedY) < (widthOfRotateControlCircle)){
    return true;
  }
  else {
    return false;
  }
}


//probably shouldn't modify this, but email me if you want to for some good reason.
public boolean checkForSuccess()
{
  if (trialIndex < trialCount) { 
    Target t = targets.get(trialIndex);	
    boolean closeDist = dist(t.x, t.y, screenTransX, screenTransY)<inchToPix(.05f); //has to be within +-0.05"
    boolean closeRotation = calculateDifferenceBetweenAngles(t.rotation, screenRotation)<=5;
    boolean closeZ = abs(t.z - screenZ)<inchToPix(.05f); //has to be within +-0.05"	
  
    println("Close Enough Distance: " + closeDist + " (cursor X/Y = " + t.x + "/" + t.y + ", target X/Y = " + screenTransX + "/" + screenTransY +")");
    println("Close Enough Rotation: " + closeRotation + " (rot dist="+calculateDifferenceBetweenAngles(t.rotation, screenRotation)+")");
    println("Close Enough Z: " +  closeZ + " (cursor Z = " + t.z + ", target Z = " + screenZ +")");
    println("Close enough all: " + (closeDist && closeRotation && closeZ));
  
    return closeDist && closeRotation && closeZ;
  }
  else {return false;}
}

//utility function I include to calc diference between two angles
double calculateDifferenceBetweenAngles(float a1, float a2)
{
  double diff=abs(a1-a2);
  diff%=90;
  if (diff>45)
    return 90-diff;
  else
    return diff;
}

//utility function to convert inches into pixels based on screen PPI
float inchToPix(float inch)
{
  return inch*screenPPI;
}
