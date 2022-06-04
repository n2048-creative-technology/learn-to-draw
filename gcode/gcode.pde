import processing.serial.*;

Serial myPort = new Serial(this, "COM6", 115200);
int counter =0;
boolean grblInit = false;

void senderInit(String initCommand) {
  println("In init");
  String val = "";
  while (myPort.available()==0){println("waiting for serial port");}
  while (myPort.available()>0) {
    println("Waiting for init...");
    val = myPort.readString();
    if (val.contains("Grbl 1.1f")) {
      delay(2000);
      myPort.clear();
      println("Grbl initalized");
      grblInit = true;
      print("Sending init command: ");
      println(initCommand);
      myPort.write(initCommand);
      myPort.write("\n");
      while(myPort.available()==0){println("waiting for response");}
      print("Got response ");
      val = myPort.readString();
      myPort.clear();
      println(val);
      
      delay(1000);
      
    }
  }
  println("Exiting init");
}

void sender(String gcode) {
  println("In sender function");
  String val = "";
  if (grblInit) {
    println("grbl has been initalized so sending some gcode");
    println(gcode);
    myPort.clear();
    //delay(1000);
    myPort.write(gcode);
    myPort.write("\n");
    println("Waiting for 4 bytes e.g. 'ok'");
    counter++;
    println(counter);
    while(myPort.available()==4){;}
    if(myPort.available()>1){
      print("Number of bytes in serial buffer: ");
      println(myPort.available());
      val = myPort.readString();
      myPort.clear();
    }

    println(val);
  }




  println(val);
}
