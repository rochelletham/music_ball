import processing.sound.*;
import java.lang.Math; 
// This sketch takes an uploaded file and the user can manipulate the sound's speed and panning. 

/****** VARIABLES *******/
// music ball variables
boolean locked = false;
int x_pos, y_pos;
int radius = 15;
// for mouse precison
int x_offset, y_offset = 0;
// sound variables
SoundFile audio;
String filename;
float pan = 0.0;
float rate = 1.0;
// used for draw pan display ex: 0.5L or 0.6R
String read_pan;
// for background waveform of audio
int samples = 1000;
Waveform waveform;
// true if selected a mono sound file
boolean selected_file;
// true if uploading selected file
boolean uploading;
// image variables
PImage img;
int img_width = 25;
int img_height = 26;
// for handling errors and corresponding msgs
boolean error;
String error_msg = "Please select a mono soundfile for the panning to work.\n";
/************************/

void setup() {
  size(640, 360);
  strokeWeight(0.5);
  selected_file = false;
  frameRate(1000);
  ellipseMode(RADIUS);
  x_pos = width/2;
  y_pos = radius;
  //upload file
  img = loadImage("upload_pic_button.png");
  textAlign(CENTER);
  textSize(16);
}
// callback which handles selecting soundfile for upload
void folderSelected(File selection) {
  if (selection != null) {
    uploading = true;
    try {
      audio = new SoundFile(this, selection.getAbsolutePath());
      filename = selection.getAbsolutePath().substring(
                  selection.getAbsolutePath().lastIndexOf("/")+1);
      // received a soundfile but not mono
      if (audio.channels() > 1) {
        uploading = false;
        selected_file = false;
        error = true;
      } else {
        // mono soundfile upload was successful
        uploading = false;
        error = false;
        selected_file = true;
        audio.loop();
        // set up for the background!
        waveform = new Waveform(this, samples);
        waveform.input(audio);
      }
      // did not receive a soundfile
    } catch (Exception e) {
      error = true;
      selected_file = false;
    }
  }
}

void draw() {
  background(0,0,0);
  textSize(16);
  if (waveform != null) {
    // from https://processing.org/reference/libraries/sound/Waveform.html
    // draws the background for the window
    waveform.analyze();
    beginShape();
    for(int i = 0; i < samples; i++) {
      vertex(
        // map each i to horizontal location according to window width
        map(i, 0, samples, 0, width),
        // map each waveform data sample val according to window height
        map(waveform.data[i], -1, 1, 0, height)
      );
      fill(100,2,20);
    }
    endShape();
  }
  // upload button
  image(img, width - (img_width + 10), height - (img_height + 10), img_width, img_height);
  if (error) {
    fill(255,0,0);
    text(error_msg, width-260, height - 16);
  } else if (uploading) {
     text("Uploading...", width/2, height-16);
   } else if (!uploading && !selected_file) {
      text("Please first upload a mono sound file here", 5*width/7, height-16);
   }
   
  // see if mouse hovering over ball
  if (is_ball_hover()) { 
    stroke(255);      // highlight white
  } else {
    stroke(153);
  }
  // Draw the shape
  fill(255,255,255);
  ellipse(x_pos, y_pos, radius, radius);
  // for readabilitiy
  if (selected_file) {
    fill(0,0,0);
    if (pan < 0) {
      read_pan = String.format("%.2f", abs(pan)) + "L";
    } else if (pan > 0) {
      read_pan = String.format("%.2f", abs(pan)) + "R";
    } else {
      read_pan = String.format("%.2f", pan);
    }
    fill(255,255,255);
    textSize(14);
    text("(pan: " + read_pan + ", rate: " + String.format("%.2f", abs(rate))+")",
          x_pos, y_pos-radius-4);  
    text("Tab for default", 60, height-14);
    text(filename, width - (img_width + 10 + textWidth(filename)), height-16);
  }
  
}

void mousePressed() {
  // only able to move the circle if we have a valid mono file
  if (selected_file) {
    if (is_ball_hover()) { 
      locked = true; 
      fill(255);
    } else {
      locked = false;
    }
    x_offset = mouseX - x_pos;
    y_offset = mouseY - y_pos;
  }
  // clicked the soundfile upload button
  if (is_upload_hover()) {
    // already have uploaded sound, but we want to reset 
    if (selected_file) {
      audio.stop();
      setup();
      update_sound();
    }
    selectInput("Select a folder to process:", "folderSelected");
  }
}
// only allow visual&sound updates when dragging circle
void mouseDragged() {
  if (is_ball_hover() && locked) {
    x_pos = mouseX - x_offset; 
    y_pos = mouseY - y_offset; 
    update_sound();
  }
}
/* used for detecting tab --> go to default settings */
void keyPressed() {
  // go back to default circle position, pan, rate
  if (key == TAB && audio != null) {
    audio.stop();
    setup();
    selected_file = true;
    locked = false;
    update_sound();
    audio.loop(rate, pan, 1.0);
    print("rate: " + rate + " pan: " + pan);
    draw();
  }
}

/* Checks if the mouse is hovering over the ball. 
 Use distance formula to check if distance btwn mouse location
 and ball's center <= the radius
*/
boolean is_ball_hover()  {
  float x = pow(mouseX - x_pos, 2);
  float y = pow(mouseY - y_pos, 2);
  return (Math.sqrt(x+y) <= radius);
}
/* Checks if mouse is hovering over upload button */
boolean is_upload_hover() {
  return (mouseX >= width -  (img_width + 10) && mouseX <= width 
      && mouseY <= height && mouseY >= height - (img_height + 10));
}

/* Changes the rate and pan of the audio file */
void update_sound() {
  // reset back to default settings
  if (!locked) {
    rate = 1.0;
    pan = 0.0;
  } else {
    // rate: 0.5 = half speed, octave down. 2 = double speed, octave up
    rate = map(mouseY, radius, height, 1, 5);
    audio.rate(rate);
    print("rate: " + rate + "\n");
    
    pan = map(mouseX, 0, width, -1, 1);
    audio.pan(pan);
    print("pan: " + pan + "\n");
  }  
}
