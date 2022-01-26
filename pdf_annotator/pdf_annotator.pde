//import controlP5.*;
import java.util.*;  
//import processing.javafx.*;

import java.util.ArrayList;

import java.awt.Toolkit;
import java.awt.event.KeyAdapter;
import java.awt.event.KeyEvent;

import java.awt.image.BufferedImage;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.rendering.ImageType;
import org.apache.pdfbox.rendering.PDFRenderer;

PDFRenderer pdfRenderer;
//ControlP5 cp5;

PrintWriter annotationFile;
Table annotationFileData;
float pdfDPI = 200;

PFont myFont;

PImage pageImg;
PImage previousPageImg, nextPageImg;
int currentPage = 0;
int totalPageNum;

long scrollOffset = 0;
float aspectRatio;
float scaleFactor;
int canvasWidth;
int canvasHeight;
int dragBoxStartX, dragBoxStartY, dragBoxEndX, dragBoxEndY;
boolean dragActive = false;
boolean inputActive = false;
int inputAnnotationId;
int toolType = 0;
int removeId = 0;
boolean removeOp = false;
int nextId;
String temp = "";
boolean japaneseMode = false;
boolean japaneseBufferConverted = false;
String japaneseBuffer = "";
AnnotationType currentType = AnnotationType.GRAMMAR;
ArrayList<Annotation> annotationArray = new ArrayList<Annotation>();

enum AnnotationType { 
   GRAMMAR, VOCAB, OTHER
}

color[] AnnotationColor = {color(93, 255, 0), color(255, 66, 139), color(33, 115, 255)};

class Annotation { 
  int id;
  float sX;
  float sY;
  float eX;
  float eY;
  AnnotationType type;
  String s = "";
  
  Annotation (int id, float sX, float sY, float eX, float eY, AnnotationType type) {  
    this.id = id;
    this.sX = sX;
    this.sY = sY;
    this.eX = eX;
    this.eY = eY;
    this.type = type;
  }
  
  Annotation (int id, float sX, float sY, float eX, float eY, AnnotationType type, String s) {  
    this.id = id;
    this.sX = sX;
    this.sY = sY;
    this.eX = eX;
    this.eY = eY;
    this.type = type;
    this.s = s;
  }
} 

//void settings() {
//  canvasWidth = displayWidth;
//  canvasHeight = displayHeight-100;
//  size(canvasWidth, canvasHeight, OPENGL);
//}

void setup() {
  //fullScreen(OPENGL);
  //size(1700, 1000, OPENGL);
  //size(displayWidth, canvasHeight-100, OPENGL);
  size(displayWidth, displayHeight, OPENGL);
  background(0);
  pixelDensity(displayDensity());
  
  //cp5 = new ControlP5(this);
  
  surface.setTitle("PDF Annotator");
  surface.setResizable(true);
  surface.setLocation(0, 0);
  
  //Scanner sc= new Scanner(System.in);
  //String b= sc.nextLine();
  //System.out.//println(b);  
  
  myFont = createFont("Helvetica", 15);
  textFont(myFont);
  
  //openImage();
  
  //print(red(AnnotationColor[currentType.ordinal()]));
  
  loadPDFFile();
  loadPDFImage(currentPage);
  loadAnnotationFile(currentPage);
  
  ////println(scaleFactor);
  
  //cp5.addTextfield("input")
  //   .setPosition(20,100)
  //   .setSize(200,40)
  //   .setFont(myFont)
  //   .setFocus(true)
  //   .setColor(color(255,0,0))
  //   ;
}

void draw() {
  background(75);
  
  ////println(scaleFactor);
  renderImage();
  ////println(scaleFactor);
  //loadAnnotationFile(currentPage);
  renderToolSelector();
  if (dragActive) { renderDragBox(); }
  renderAnnotation();
}

void openImage() {
  pageImg = loadImage("0.jpg");
  aspectRatio = float(pageImg.height) / float(pageImg.width);
  print(aspectRatio);
}

void mousePressed() {
  //print("presed");
  if (mouseY >= 20 && toolType == 0) {
    dragBoxStartX = mouseX;
    dragBoxStartY = mouseY;
    dragActive = true;
  }
}

void mouseReleased() {
  if (dragActive) {
    dragActive = false;
    ////println(annotationArray);
    //println(dragBoxStartX/scaleFactor/pdfDPI, dragBoxStartY/scaleFactor/pdfDPI, max(mouseX,dragBoxStartX+15)/scaleFactor/pdfDPI, max(mouseY,dragBoxStartY+15)/scaleFactor/pdfDPI);
    annotationArray.add(new Annotation(nextId, dragBoxStartX/scaleFactor/pdfDPI, dragBoxStartY/scaleFactor/pdfDPI, max(mouseX,dragBoxStartX+15)/scaleFactor/pdfDPI, max(mouseY,dragBoxStartY+15)/scaleFactor/pdfDPI, currentType));
    ////println(annotationArray);
    inputAnnotationId = nextId;
    inputActive = true;
    japaneseBuffer = "";
    nextId += 1;
    temp = "";
  }
  else if (mouseY <= 20 && mouseY >= 0 && mouseX >= 0 && mouseX <= 60) {
    toolType = 0;
    if (mouseX <= 20) { currentType = AnnotationType.GRAMMAR; }
    else if (mouseX <= 40) { currentType = AnnotationType.VOCAB; }
    else if (mouseX <= 60) { currentType = AnnotationType.OTHER; }
  }
  else if (mouseY <= 20 && mouseY >= 0 && mouseX >= 60 && mouseX <= 80) {
    toolType = 1;
  }
  else if (mouseY <= 20 && mouseY >= 0 && mouseX >= width - 40 && mouseX <= width) {
    if (mouseX <= width - 20) {
      moveToPreviousPage();
    }
    else {
      moveToNextPage();
    }
  }
  else if (mouseY <= 20 && mouseY >= 0 && mouseX >= width/2 - 25 && mouseX <= width/2 + 25) {
    saveAnnotationFile(currentPage);
    saveBookmark(currentPage);
    exit();
  }
  else if (mouseY <= 20 && mouseY >= 0 && mouseX >= width - 60 && mouseX < width - 40) {
    japaneseMode = !japaneseMode;
    japaneseBuffer = "";
  }
  else if (toolType == 1) {
    for (Annotation i : annotationArray){
      if (mouseX >= i.sX*scaleFactor*pdfDPI && mouseX <= i.eX*scaleFactor*pdfDPI && mouseY >= i.sY*scaleFactor*pdfDPI && mouseY <= i.eY*scaleFactor*pdfDPI) {
        removeOp = true;
        removeId = i.id;
        //println(removeId);
      }
    }
    if (removeOp) { 
      annotationArray.removeIf(t -> t.id == removeId); 
      //print(annotationArray.size());
    }
  }
}

void keyPressed() {
  if (keyCode == TAB) {
    japaneseMode = !japaneseMode;
    japaneseBuffer = "";
  }
  else if (inputActive) {
    //if (Toolkit.getDefaultToolkit().getLockingKeyState(KeyEvent.VK_CAPS_LOCK);
    //annotationArray.get(annotationArray.size()-1).s = cp5.get(Textfield.class,"input").getText();
    if (key == ENTER) {
      inputActive = false;
    }
    else if (key == CODED) {
      
    }
    else if (!japaneseMode) {
      if (key == BACKSPACE) {
        if (temp.length()>0) {
          temp = temp.substring(0, temp.length()-1);
        }
      }
      else {
        temp += key;
      }
    }
    else if (japaneseMode){
      if (key == BACKSPACE) {
        if (temp.length()>0) {
          temp = temp.substring(0, temp.length()-1);
        }
        if (japaneseBuffer.length()>0) {
          japaneseBuffer = japaneseBuffer.substring(0, japaneseBuffer.length()-1);
        }
      }
      else {
        japaneseBuffer += key;
        temp += key;
        if (japaneseBuffer.length() == 1) {
          switch (japaneseBuffer){
            case "a": 
              japaneseBuffer = "あ";
              temp = temp.substring(0, temp.length()-1);
              temp += japaneseBuffer;
              japaneseBuffer = "";
              break;
            case "i": 
              japaneseBuffer = "い";
              temp = temp.substring(0, temp.length()-1);
              temp += japaneseBuffer;
              japaneseBuffer = "";
              break;
            case "u": 
              japaneseBuffer = "う";
              temp = temp.substring(0, temp.length()-1);
              temp += japaneseBuffer;
              japaneseBuffer = "";
              break;
            case "e": 
              japaneseBuffer = "え";
              temp = temp.substring(0, temp.length()-1);
              temp += japaneseBuffer;
              japaneseBuffer = "";
              break;
            case "o": 
              japaneseBuffer = "お";
              temp = temp.substring(0, temp.length()-1);
              temp += japaneseBuffer;
              japaneseBuffer = "";
              break;
            case "-": 
              japaneseBuffer = "ー";
              temp = temp.substring(0, temp.length()-1);
              temp += japaneseBuffer;
              japaneseBuffer = "";
              break;
            case ".": 
              japaneseBuffer = "。";
              temp = temp.substring(0, temp.length()-1);
              temp += japaneseBuffer;
              japaneseBuffer = "";
              break;
            case ",": 
              japaneseBuffer = "、";
              temp = temp.substring(0, temp.length()-1);
              temp += japaneseBuffer;
              japaneseBuffer = "";
              break;
            case "!": 
              japaneseBuffer = "！";
              temp = temp.substring(0, temp.length()-1);
              temp += japaneseBuffer;
              japaneseBuffer = "";
              break;
            case "?": 
              japaneseBuffer = "？";
              temp = temp.substring(0, temp.length()-1);
              temp += japaneseBuffer;
              japaneseBuffer = "";
              break;
          }
        }
        else if (japaneseBuffer.length() == 2) {
          // nn
          if (japaneseBuffer.charAt(0) == 'n' && japaneseBuffer.charAt(1) == 'n') {
            japaneseBuffer = "ん";
            temp = temp.substring(0, temp.length()-2);
            temp += japaneseBuffer;
            japaneseBuffer = "";
          }
          // small tsu
          else if (japaneseBuffer.charAt(0) == japaneseBuffer.charAt(1)) {
            char c = japaneseBuffer.charAt(1);
            japaneseBuffer = "っ" + c;
            temp = temp.substring(0, temp.length()-2);
            temp += japaneseBuffer;
            japaneseBuffer = "" + c;
          }
          else {
            switch (japaneseBuffer.charAt(0)){
              case 'k':
                switch (japaneseBuffer.charAt(1)){
                  case 'a':
                    japaneseBuffer = "か";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'i':
                    japaneseBuffer = "き";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'u':
                    japaneseBuffer = "く";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'e':
                    japaneseBuffer = "け";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'o':
                    japaneseBuffer = "こ";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                }
                break;
              case 's':
                switch (japaneseBuffer.charAt(1)){
                  case 'a':
                    japaneseBuffer = "さ";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'i':
                    japaneseBuffer = "し";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'u':
                    japaneseBuffer = "す";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'e':
                    japaneseBuffer = "せ";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'o':
                    japaneseBuffer = "そ";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                }
                break;
              case 't':
                switch (japaneseBuffer.charAt(1)){
                  case 'a':
                    japaneseBuffer = "た";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'i':
                    japaneseBuffer = "ち";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'u':
                    japaneseBuffer = "つ";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'e':
                    japaneseBuffer = "て";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'o':
                    japaneseBuffer = "と";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                }
                break;
              case 'n':
                switch (japaneseBuffer.charAt(1)){
                  case 'a':
                    japaneseBuffer = "な";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'i':
                    japaneseBuffer = "に";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'u':
                    japaneseBuffer = "ぬ";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'e':
                    japaneseBuffer = "ね";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'o':
                    japaneseBuffer = "の";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                }
                break;
              case 'h':
                switch (japaneseBuffer.charAt(1)){
                  case 'a':
                    japaneseBuffer = "は";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'i':
                    japaneseBuffer = "ひ";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'u':
                    japaneseBuffer = "ふ";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'e':
                    japaneseBuffer = "へ";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'o':
                    japaneseBuffer = "ほ";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                }
                break;
              case 'm':
                switch (japaneseBuffer.charAt(1)){
                  case 'a':
                    japaneseBuffer = "ま";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'i':
                    japaneseBuffer = "み";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'u':
                    japaneseBuffer = "む";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'e':
                    japaneseBuffer = "め";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'o':
                    japaneseBuffer = "も";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                }
                break;
              case 'y':
                switch (japaneseBuffer.charAt(1)){
                  case 'a':
                    japaneseBuffer = "や";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  //case 'i':
                  //  japaneseBuffer = "";
                  //  temp = temp.substring(0, temp.length()-2);
                  //  temp += japaneseBuffer;
                  //  japaneseBuffer = "";
                  //  break;
                  case 'u':
                    japaneseBuffer = "ゆ";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  //case 'e':
                  //  japaneseBuffer = "";
                  //  temp = temp.substring(0, temp.length()-2);
                  //  temp += japaneseBuffer;
                  //  japaneseBuffer = "";
                  //  break;
                  case 'o':
                    japaneseBuffer = "よ";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                }
                break;
              case 'r':
                switch (japaneseBuffer.charAt(1)){
                  case 'a':
                    japaneseBuffer = "ら";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'i':
                    japaneseBuffer = "り";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'u':
                    japaneseBuffer = "る";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'e':
                    japaneseBuffer = "れ";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'o':
                    japaneseBuffer = "ろ";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                }
                break;
              case 'w':
                switch (japaneseBuffer.charAt(1)){
                  case 'a':
                    japaneseBuffer = "わ";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  //case 'i':
                  //  japaneseBuffer = "";
                  //  temp = temp.substring(0, temp.length()-2);
                  //  temp += japaneseBuffer;
                  //  japaneseBuffer = "";
                  //  break;
                  //case 'u':
                  //  japaneseBuffer = "";
                  //  temp = temp.substring(0, temp.length()-2);
                  //  temp += japaneseBuffer;
                  //  japaneseBuffer = "";
                  //  break;
                  //case 'e':
                  //  japaneseBuffer = "";
                  //  temp = temp.substring(0, temp.length()-2);
                  //  temp += japaneseBuffer;
                  //  japaneseBuffer = "";
                  //  break;
                  case 'o':
                    japaneseBuffer = "を";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                }
                break;
              case 'g':
                switch (japaneseBuffer.charAt(1)){
                  case 'a':
                    japaneseBuffer = "が";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'i':
                    japaneseBuffer = "ぎ";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'u':
                    japaneseBuffer = "ぐ";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'e':
                    japaneseBuffer = "げ";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'o':
                    japaneseBuffer = "ご";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                }
                break;
              case 'z':
                switch (japaneseBuffer.charAt(1)){
                  case 'a':
                    japaneseBuffer = "ざ";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'i':
                    japaneseBuffer = "じ";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'u':
                    japaneseBuffer = "ず";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'e':
                    japaneseBuffer = "ぜ";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'o':
                    japaneseBuffer = "ぞ";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                }
                break;
              case 'd':
                switch (japaneseBuffer.charAt(1)){
                  case 'a':
                    japaneseBuffer = "だ";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'i':
                    japaneseBuffer = "ぢ";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'u':
                    japaneseBuffer = "づ";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'e':
                    japaneseBuffer = "で";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'o':
                    japaneseBuffer = "ど";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                }
                break;
              case 'b':
                switch (japaneseBuffer.charAt(1)){
                  case 'a':
                    japaneseBuffer = "ば";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'i':
                    japaneseBuffer = "び";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'u':
                    japaneseBuffer = "ぶ";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'e':
                    japaneseBuffer = "べ";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'o':
                    japaneseBuffer = "ぼ";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                }
                break;
              case 'p':
                switch (japaneseBuffer.charAt(1)){
                  case 'a':
                    japaneseBuffer = "ぱ";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'i':
                    japaneseBuffer = "ぴ";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'u':
                    japaneseBuffer = "ぷ";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'e':
                    japaneseBuffer = "ぺ";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'o':
                    japaneseBuffer = "ぽ";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                }
                break;
              case 'f':
                switch (japaneseBuffer.charAt(1)){
                  case 'u':
                    japaneseBuffer = "ふ";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                }
                break;
              case 'j':
                switch (japaneseBuffer.charAt(1)){
                  case 'i':
                    japaneseBuffer = "じ";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'a':
                    japaneseBuffer = "じゃ";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'u':
                    japaneseBuffer = "じゅ";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                  case 'o':
                    japaneseBuffer = "じょ";
                    temp = temp.substring(0, temp.length()-2);
                    temp += japaneseBuffer;
                    japaneseBuffer = "";
                    break;
                }
                break;
            }
          }
        }
        else if (japaneseBuffer.length() == 3) {
          switch (japaneseBuffer.substring(0, 2)) {
            case "ky":
              switch (japaneseBuffer.charAt(2)) {
                case 'a':
                  japaneseBuffer = "きゃ";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
                case 'u':
                  japaneseBuffer = "きゅ";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
                case 'o':
                  japaneseBuffer = "きょ";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
              }
              break;
            case "sh":
              switch (japaneseBuffer.charAt(2)) {
                case 'a':
                  japaneseBuffer = "しゃ";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
                case 'i':
                  japaneseBuffer = "し";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
                case 'u':
                  japaneseBuffer = "しゅ";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
                case 'o':
                  japaneseBuffer = "しょ";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
              }
              break;
            case "ch":
              switch (japaneseBuffer.charAt(2)) {
                case 'a':
                  japaneseBuffer = "ちゃ";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
                case 'i':
                  japaneseBuffer = "ち";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
                case 'u':
                  japaneseBuffer = "ちゅ";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
                case 'o':
                  japaneseBuffer = "ちょ";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
              }
              break;
            case "ny":
              switch (japaneseBuffer.charAt(2)) {
                case 'a':
                  japaneseBuffer = "にゃ";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
                case 'u':
                  japaneseBuffer = "にゅ";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
                case 'o':
                  japaneseBuffer = "にょ";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
              }
              break;
            case "hy":
              switch (japaneseBuffer.charAt(2)) {
                case 'a':
                  japaneseBuffer = "ひゃ";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
                case 'u':
                  japaneseBuffer = "ひゅ";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
                case 'o':
                  japaneseBuffer = "ひょ";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
              }
              break;
            case "my":
              switch (japaneseBuffer.charAt(2)) {
                case 'a':
                  japaneseBuffer = "みゃ";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
                case 'u':
                  japaneseBuffer = "みゅ";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
                case 'o':
                  japaneseBuffer = "みょ";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
              }
              break;
            case "ry":
              switch (japaneseBuffer.charAt(2)) {
                case 'a':
                  japaneseBuffer = "りゃ";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
                case 'u':
                  japaneseBuffer = "りゅ";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
                case 'o':
                  japaneseBuffer = "りょ";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
              }
              break;
            case "gy":
              switch (japaneseBuffer.charAt(2)) {
                case 'a':
                  japaneseBuffer = "ぎゃ";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
                case 'u':
                  japaneseBuffer = "ぎゅ";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
                case 'o':
                  japaneseBuffer = "ぎょ";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
              }
              break;
            case "jy":
              switch (japaneseBuffer.charAt(2)) {
                case 'a':
                  japaneseBuffer = "じゃ";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
                case 'u':
                  japaneseBuffer = "じゅ";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
                case 'o':
                  japaneseBuffer = "じょ";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
              }
              break;
            case "dy":
              switch (japaneseBuffer.charAt(2)) {
                case 'a':
                  japaneseBuffer = "ぢゃ";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
                case 'u':
                  japaneseBuffer = "ぢゅ";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
                case 'o':
                  japaneseBuffer = "ぢょ";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
              }
              break;
            case "by":
              switch (japaneseBuffer.charAt(2)) {
                case 'a':
                  japaneseBuffer = "びゃ";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
                case 'u':
                  japaneseBuffer = "びゅ";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
                case 'o':
                  japaneseBuffer = "びょ";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
              }
              break;
            case "py":
              switch (japaneseBuffer.charAt(2)) {
                case 'a':
                  japaneseBuffer = "ぴゃ";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
                case 'u':
                  japaneseBuffer = "ぴゅ";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
                case 'o':
                  japaneseBuffer = "ぴょ";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
              }
              break;
            case "ts":
              switch (japaneseBuffer.charAt(2)) {
                case 'u':
                  japaneseBuffer = "つ";
                  temp = temp.substring(0, temp.length()-3);
                  temp += japaneseBuffer;
                  japaneseBuffer = "";
                  break;
              }
              break;
          }
          //no conversion happened
          if (japaneseBuffer.length() != 0) {
            temp = temp.substring(0, temp.length()-3);
            japaneseBuffer = "";
          }
        }
      }
    }
    annotationArray.get(annotationArray.size()-1).s = temp;
  }
  else {
    if (key == 'e' || key == 'E') {
      saveAnnotationFile(currentPage);
      saveBookmark(currentPage);
      exit();
    }
    if (key == CODED){
      if (keyCode == UP || keyCode == LEFT) {
        //for (Annotation i : annotationArray){
        //  //println(i.sX,i.sY,i.eX,i.eY);
        //}
        moveToPreviousPage();
      }
      if (keyCode == DOWN || keyCode == RIGHT) {
        moveToNextPage();
      }
    }
  }
}

//void mouseWheel(MouseEvent event) {
//  float e = event.getCount();
//  if (e > 0) {
//    if (currentPage != 0) {
//      saveAnnotationFile(currentPage);
//      currentPage -= 1;
//      loadPDFImage(currentPage);
//      loadAnnotationFile(currentPage);
//    }
//  }
//  else if (e < 0) {
//    if (currentPage != totalPageNum) {
//      //long start = System.currentTimeMillis();
//      saveAnnotationFile(currentPage);
//      currentPage += 1;
//      loadPDFImage(currentPage);
//      loadAnnotationFile(currentPage);
//      //long end = System.currentTimeMillis();
//      ////println(end-start);
//    }
//  }
//}

void moveToNextPage() {
  if (currentPage != totalPageNum) {
    //long start = System.currentTimeMillis();
    saveAnnotationFile(currentPage);
    currentPage += 1;
    loadPDFImage(currentPage);
    loadAnnotationFile(currentPage);
    //long end = System.currentTimeMillis();
    ////println(end-start);
  }
}

void moveToPreviousPage() {
  if (currentPage != 0) {
    saveAnnotationFile(currentPage);
    currentPage -= 1;
    loadPDFImage(currentPage);
    loadAnnotationFile(currentPage);
  }
}

void renderDragBox() {
  stroke(color(AnnotationColor[currentType.ordinal()], 150));
  strokeWeight(1);
  fill(color(AnnotationColor[currentType.ordinal()], 50));
  rect(dragBoxStartX, dragBoxStartY, mouseX-dragBoxStartX, mouseY-dragBoxStartY);
}

void renderToolSelector() {
  int x = 0;
  int y = 0;
  
  noStroke();
  fill(200);
  
  rect(0, 0, width, 21);
  
  for (int i = 0; i < 3; i++) {
    if (toolType == 0 && currentType.ordinal() == i) { 
      stroke(255);
      strokeWeight(2);
    }
    else { 
      noStroke();
    }
    //stroke(color(AnnotationColor[i], 255));
    //strokeWeight(1);
    fill(color(AnnotationColor[i], 200));
    rect(x, y, 20, 20);
    x += 20;
  }
  
  if (toolType == 1) {
    stroke(255);
    strokeWeight(2);
  }
  else {
    noStroke();
  }
  fill(100);
  rect(60, y, 20, 20);
  stroke(255);
  strokeWeight(1);
  line(60, 0, 80, 20);
  line(80, 0, 60, 20);
  
  stroke(0);
  strokeWeight(2);
  noFill();
  if (toolType == 0) { rect(currentType.ordinal()*20, 0, 20, 20); }
  else if (toolType == 1) { rect(60, 0, 20, 20); }
  
  stroke(0);
  strokeWeight(1);
  fill(250);
  rect(width-40, 0, 20, 20);
  rect(width-20, 0, 20, 20);
  noStroke();
  fill(0);
  triangle(width - 15, 5, width - 15, 15, width - 5, 10);
  triangle(width - 25, 5, width - 25, 15, width - 35, 10);
  
  
  if (!japaneseMode) {
    stroke(0);
    strokeWeight(1);
    fill(100, 100, 100);
    rect(width-60, 0, 20, 20);
    fill(255);
    textSize(12);
    textAlign(CENTER, CENTER);
    text("EN", width-50, 10);
  }
  else if (japaneseMode) {
    stroke(0);
    strokeWeight(1);
    fill(200, 70, 70);
    rect(width-60, 0, 20, 20);
    fill(255);
    textSize(12);
    textAlign(CENTER, CENTER);
    text("JP", width-50, 10);
  }
  
  //stroke(0);
  //strokeWeight(1);
  //fill(200);
  //rect(width/2-25, 0, 50, 20);
  fill(0);
  textSize(10);
  textAlign(CENTER, CENTER);
  text("CLOSE", width/2, 10);

}

void loadPDFFile() {
  try {
    String sourceDir = dataPath("") + "/ハリー・ポッターと賢者の石.pdf"; // Pdf files are read from this folder
    File sourceFile = new File(sourceDir);
    if (sourceFile.exists()) {
      //println("yes");
      PDDocument document = PDDocument.load(sourceFile);
      pdfRenderer = new PDFRenderer(document);
      totalPageNum = document.getNumberOfPages();
      
      currentPage = int(loadStrings("data/bookmark.csv")[0]);
    }
  } catch (Exception e) {
    e.printStackTrace();
  }
}

void loadPDFImage(int pageNum) {
  try {
    //long start = System.currentTimeMillis();
    BufferedImage bImage = pdfRenderer.renderImageWithDPI(pageNum, pdfDPI, ImageType.RGB);
    ////println(System.currentTimeMillis()-start);
    //BufferedImage bImage = pdfRenderer.renderImage(pageNum);
    //pageImg = PImage(bImage);
    pageImg = new PImage(bImage.getWidth(),bImage.getHeight(),PConstants.ARGB);
    bImage.getRGB(0, 0, pageImg.width, pageImg.height, pageImg.pixels, 0, pageImg.width);
    //pageImg.updatePixels();
    ////println(System.currentTimeMillis()-start);
  //  aspectRatio = float(pageImg.height) / float(pageImg.width);
  //  if (aspectRatio <= height/width){
  //    scaleFactor = width / float(pageImg.width);
  //  }
  //  else {
  //    scaleFactor = height / float(pageImg.height);
  //}
  } catch (Exception e)
  {
    e.printStackTrace();
    exit();
  }
}

void renderImage() {
  aspectRatio = float(pageImg.height) / float(pageImg.width);
    if (aspectRatio <= float(height)/float(width)){
      scaleFactor = width / float(pageImg.width);
    }
    else {
      scaleFactor = height / float(pageImg.height);
  }
  image(pageImg, 0, 0, pageImg.width*scaleFactor, pageImg.height*scaleFactor);
  //image(pageImg, 0, 0, width, height);
}

void loadAnnotationFile(int pageNum) {
  annotationArray = new ArrayList<Annotation>();
  annotationFileData = loadTable("data/annotation/"+str(pageNum)+".csv", "header");
  if (annotationFileData != null) {
    nextId = 0;
    for (TableRow row : annotationFileData.rows()) {
      annotationArray.add(new Annotation(nextId,row.getFloat("sX"),
                          row.getFloat("sY"),row.getFloat("eX"), 
                          row.getFloat("eY"), AnnotationType.values()[row.getInt("type")], row.getString("s")));
      ////println(scaleFactor);
      ////println(int(row.getInt("sX")*scaleFactor));
      nextId++;
    }
  }
  else {
    //annotationFile = createWriter("data/annotation/"+str(pageNum)+".csv");
    //annotationFile.//println("id,sX,sY,eX,eY,type,s");
    //annotationFile.flush();
    //annotationFile.close();
  }
}


void renderAnnotation() {
  //for (Annotation i : annotationArray){
  //  float sX_screen = i.sX*scaleFactor*pdfDPI;
  //  float eX_screen = i.eX*scaleFactor*pdfDPI;
  //  float sY_screen = i.sY*scaleFactor*pdfDPI;
  //  float eY_screen = i.eY*scaleFactor*pdfDPI;
  //  if (mouseX >= sX_screen && mouseX <= eX_screen && mouseY >= sY_screen && mouseY <= eY_screen) {
  //    //stroke(color(AnnotationColor[i.type.ordinal()], 255));
  //    //strokeWeight(2);
  //    //fill(color(AnnotationColor[i.type.ordinal()], 100));
  //    //rect(i.sX, i.sY, i.eX-i.sX, i.eY-i.sY);
      
  //    //stroke(color(AnnotationColor[i.type.ordinal()], 255));
  //    //strokeWeight(1);
  //    //fill(color(AnnotationColor[i.type.ordinal()], 255));
  //    //rect(mouseX + 20, mouseY + 20, 150, 100);
  //  }
  //  else {
  //    stroke(color(AnnotationColor[i.type.ordinal()], 150));
  //    strokeWeight(1);
  //    noStroke();
  //    fill(color(AnnotationColor[i.type.ordinal()], 50));
  //    rect(sX_screen, sY_screen, eX_screen-sX_screen, eY_screen-sY_screen);
  //  }
  //}
  
  if (inputActive) {
    for (Annotation i : annotationArray){
      float sX_screen = i.sX*scaleFactor*pdfDPI;
      float eX_screen = i.eX*scaleFactor*pdfDPI;
      float sY_screen = i.sY*scaleFactor*pdfDPI;
      float eY_screen = i.eY*scaleFactor*pdfDPI;
      if (inputAnnotationId != i.id) {
        stroke(color(AnnotationColor[i.type.ordinal()], 150));
        strokeWeight(1);
        noStroke();
        fill(color(AnnotationColor[i.type.ordinal()], 50));
        rect(sX_screen, sY_screen, eX_screen-sX_screen, eY_screen-sY_screen);
      }
      else {
        stroke(color(AnnotationColor[i.type.ordinal()], 255));
        strokeWeight(2);
        noStroke();
        fill(color(AnnotationColor[i.type.ordinal()], 100));
        rect(sX_screen, sY_screen, eX_screen-sX_screen, eY_screen-sY_screen);
        
        String s;
        s = i.s;
        float sw = textWidth(s);
        
        float boxX = eX_screen, boxY = eY_screen, textX = eX_screen + 10, textY = eY_screen + 10;
        
        if (boxX + 150 >= width) {
          boxX = sX_screen - 150;
          textX = boxX + 10;
        }
        
        if (boxY + int(5+sw/130)*17 >= height) {
          boxY = sY_screen -(int(5+sw/130)*17);
          textY = boxY + 10;
        }
        
        stroke(100, 100, 100, 255);
        strokeWeight(0.5);
        fill(color(AnnotationColor[i.type.ordinal()], 255));
        fill(color(red(AnnotationColor[i.type.ordinal()])+120, green(AnnotationColor[i.type.ordinal()])+120, blue(AnnotationColor[i.type.ordinal()])+120));
        //rect(mouseX + 20, mouseY + 20, 150, int(3+sw/130)*17);
        rect(boxX, boxY, 150, int(5+sw/130)*17);
        
        textSize(15);
        textLeading(15);
        textAlign(LEFT);
        fill(0);
        //text(s, mouseX + 30, mouseY + 30, 150 - 20, int(3+sw/130)*20);
        text(s, textX, textY, 150 - 20, int(5+sw/130)*20);
      }
    }
  }
  else {
    for (Annotation i : annotationArray){
      float sX_screen = i.sX*scaleFactor*pdfDPI;
      float eX_screen = i.eX*scaleFactor*pdfDPI;
      float sY_screen = i.sY*scaleFactor*pdfDPI;
      float eY_screen = i.eY*scaleFactor*pdfDPI;
      
      stroke(color(AnnotationColor[i.type.ordinal()], 150));
      strokeWeight(1);
      noStroke();
      fill(color(AnnotationColor[i.type.ordinal()], 50));
      rect(sX_screen, sY_screen, eX_screen-sX_screen, eY_screen-sY_screen);
    }
    for (Annotation i : annotationArray){
      float sX_screen = i.sX*scaleFactor*pdfDPI;
      float eX_screen = i.eX*scaleFactor*pdfDPI;
      float sY_screen = i.sY*scaleFactor*pdfDPI;
      float eY_screen = i.eY*scaleFactor*pdfDPI;
      if (mouseX >= sX_screen && mouseX <= eX_screen && mouseY >= sY_screen && mouseY <= eY_screen) {
        stroke(color(AnnotationColor[i.type.ordinal()], 100));
        strokeWeight(2);
        noStroke();
        fill(color(AnnotationColor[i.type.ordinal()], 50));
        rect(sX_screen, sY_screen, eX_screen-sX_screen, eY_screen-sY_screen);
        
        String s;
        s = i.s;
        float sw = textWidth(s);
        
        int boxX = mouseX + 20, boxY = mouseY + 20, textX = mouseX + 30, textY = mouseY + 30;
        
        if (boxX + 150 >= width) {
          boxX = mouseX - 20 - 150;
          textX = boxX + 10;
        }
        
        if (boxY + int(5+sw/130)*17 >= height) {
          boxY = mouseY - 30 -(int(5+sw/130)*17);
          textY = boxY + 10;
        }
        
        stroke(100, 100, 100, 255);
        strokeWeight(0.5);
        fill(color(AnnotationColor[i.type.ordinal()], 255));
        fill(color(red(AnnotationColor[i.type.ordinal()])+120, green(AnnotationColor[i.type.ordinal()])+120, blue(AnnotationColor[i.type.ordinal()])+120));
        //rect(mouseX + 20, mouseY + 20, 150, int(3+sw/130)*17);
        rect(boxX, boxY, 150, int(5+sw/130)*17);
        
        textSize(15);
        textLeading(15);
        textAlign(LEFT);
        fill(0);
        //text(s, mouseX + 30, mouseY + 30, 150 - 20, int(3+sw/130)*20);
        text(s, textX, textY, 150 - 20, int(5+sw/130)*20);
      }
    }
  }
}


void saveAnnotationFile(int pageNum) {
  if (annotationArray.size() != 0) {
    annotationFile = createWriter("data/annotation/"+str(pageNum)+".csv");
    annotationFile.println("id,sX,sY,eX,eY,type,s");
    int rowCount = 0;
    for (Annotation i : annotationArray){
      //println(i.sX,i.sY,i.eX,i.eY);
      annotationFile.println(String.format("%d,%f,%f,%f,%f,%d,%s",
                       rowCount,i.sX,i.sY,i.eX,
                       i.eY,i.type.ordinal(),i.s));
      rowCount += 1;
    }
    annotationFile.flush();
    annotationFile.close();
  }
}

void saveBookmark(int pageNum) {
  annotationFile = createWriter("data/bookmark.csv");
  annotationFile.println(pageNum);
  annotationFile.flush();
  annotationFile.close();
}
