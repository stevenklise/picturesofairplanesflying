import SimpleOpenNI.*;

SimpleOpenNI kinect;

boolean was_was_airplane = false;
boolean was_airplane = false;
boolean airplane = false;
PImage airplane_image;
String[] airplanes;
int airplane_count;
float slope;

void setup() {
  kinect = new SimpleOpenNI(this);
  kinect.enableDepth();
  kinect.enableRGB();
  kinect.enableUser(SimpleOpenNI.SKEL_PROFILE_ALL);
  kinect.setMirror(true);
  size(1920, 1080);
  
  airplanes = loadStrings("filelist.txt");
  airplane_count = airplanes.length;
}

void draw() {
  kinect.update();

  // write the list of detected users
  int[] userList = kinect.getUsers();

  // if we found any users
  if (userList.length > 0) {
    int userId = userList[0];
    if (kinect.isTrackingSkeleton(userId)) {

      // initialize join position variables
      PVector rightHand = new PVector();
      PVector rightElbow = new PVector();
      PVector leftHand = new PVector();
      PVector leftElbow = new PVector();

      // dump joint info into the PVectors
      kinect.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_LEFT_HAND, leftHand);
      kinect.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_RIGHT_HAND, rightHand);
      kinect.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_LEFT_ELBOW, leftElbow);
      kinect.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_RIGHT_ELBOW, rightElbow);

      kinect.convertRealWorldToProjective(leftHand, leftHand);
      kinect.convertRealWorldToProjective(rightHand, rightHand);
      kinect.convertRealWorldToProjective(leftElbow, leftElbow);
      kinect.convertRealWorldToProjective(rightElbow, rightElbow);

      PVector[] vectors = {
        leftHand, rightHand, leftElbow, rightElbow
      };

      float[] fits = bestFit(vectors);

      float r2 = rsquare(vectors, fits[0], fits[1]);

      stroke(255, 0, 0);
      line(0, fits[1], 700, 700 * fits[0] + fits[1]);

      println("m = " + fits[0]);

      if (r2 > 0.2) {
        airplane = true;
      } else {
        airplane = false;
      }
      
      slope = fits[0];
      
      // debugging
      for (PVector v : vectors) {
        fill(0, 255, 0);
        noStroke();
        ellipse(v.x, v.y, 5, 5);
      }
    }
  }
  
  if (airplane || was_airplane) {
    // Set the airplane image
    if (was_was_airplane == false && was_airplane == false) {
      airplane_image = loadImage("airplanes/" + airplanes[(int)random(airplane_count)]);
    }
    
    if (slope < -0.2) {
      background(255, 0,0);
    } else if (slope > 0.2) {
      background(0, 255, 0);
    } else {
      background(0);
    }
    
    // background(0,0,0);
    image(airplane_image, 100, 100);
  } else {
    background(0);
  }
  // image(kinect.depthImage(), 0, 0);
  
  // Save current state of airplane-ness.
  was_was_airplane = was_airplane;
  was_airplane = airplane;
}

// Significance test for linearity. Overridden when there is an outlier.
float rsquare(PVector[] list, float m, float b) {
  float average = 0.0;

  for (PVector vector : list) {
    average += vector.y;
  }

  average = average / (float)list.length;

  float sumtot = 0;
  float sumerr = 0;
  float sumreg = 0;

  float maxerr = 0;

  for (PVector vector : list) {
    sumtot += pow(vector.y - average, 2);
    float err = pow(vector.y - vector.x * m - b, 2);

    float abserr = abs(err);

    if (abserr > maxerr) { 
      maxerr = abserr;
    }
    sumerr += err;
    sumreg += pow(vector.x * m + b - average, 2);
  }

  if (maxerr > 190) {
    return 0;
  } else {
    return 1 - sumerr / sumtot;
  }
}

// Take a list of PVectors and calculate the slope and y-intercept
float[] bestFit(PVector[] list) {
  float n = (float)list.length;
  float m = 0;
  float b = 0;
  float sumproduct = 0;
  float sumx = 0;
  float sumx2 = 0;
  float sumy = 0;

  for (PVector v : list) {
    sumx += v.x;
    sumx2 += pow(v.x, 2);
    sumy += v.y;
    sumproduct += v.x * v.y;
  }

  m = (sumproduct - (sumx * sumy / n)) / (sumx2 - pow(sumx, 2)/n);

  b = sumy / n - m * sumx / n;

  float[] response = {
    m, b
  };
  return response;
}

