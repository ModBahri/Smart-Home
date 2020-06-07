import beads.*;
import org.jaudiolibs.beads.*;
import controlP5.*;
import java.util.Queue;
import java.util.PriorityQueue;
import java.util.List;
import java.util.LinkedList;
import java.util.Arrays;
import java.util.Comparator;

//to use text to speech functionality, copy text_to_speech.pde from this sketch to yours
//example usage below

//IMPORTANT (notice from text_to_speech.pde):
//to use this you must import 'ttslib' into Processing, as this code uses the included FreeTTS library
//e.g. from the Menu Bar select Sketch -> Import Library... -> ttslib

TextToSpeechMaker ttsMaker; 

//<import statements here>

//to use this, copy notification.pde, notification_listener.pde and notification_server.pde from this sketch to yours.
//Example usage below.

//name of a file to load from the data directory

String eventDataJSON1 = "smarthome_dinner_at_home.json";
String eventDataJSON2 = "smarthome_parent_night_out.json";
String eventDataJSON3 = "smarthome_party.json";
String eventDataJSON4 = "smarthome_work_at_home.json";

ControlP5 p5;
SamplePlayer dinnerLoop;
SamplePlayer partyLoop;
SamplePlayer nightLoop;
SamplePlayer workLoop;
NotificationServer server;
Gain masterGain;
Queue<String> soundsToPlay;
ArrayList<Notification> notifications;
PriorityQueue<Notification> queue;
int previousPriorityLevel = 4;
boolean isSoundPlaying = false;
boolean dinner = false;
boolean night = false;
boolean party = false;
boolean work = false;
Envelope env;
WavePlayer saw;
Gain g1;


Example example;

void setup() {
  background(0,0,0);
  size(700, 500);
  ac = new AudioContext(); //ac is defined in helper_functions.pde
  //ac.start();
  dinnerLoop = getSamplePlayer("dinner.wav");
  partyLoop = getSamplePlayer("party.wav");
  workLoop = getSamplePlayer("typing.wav");
  nightLoop = getSamplePlayer("night.wav");
  
  dinnerLoop.pause(true);
  partyLoop.pause(true);
  workLoop.pause(true);
  nightLoop.pause(true);
  soundsToPlay = new LinkedList<String>();
  p5 = new ControlP5(this);
  Comparator<Notification> priorityComp = new Comparator<Notification>() {
    public int compare(Notification n1, Notification n2) {
      if (n2.getTimestamp() < n1.getTimestamp() + 1000 && n1.getPriorityLevel() > n2.getPriorityLevel()) {
        return -1;
      } else {
        return 1;
      }
    }
  };
  
  queue = new PriorityQueue<Notification>(10, priorityComp);

  p5.addButton("DINNER_AT_HOME").setPosition(0, 375).setSize(175, 125);
  p5.addButton("PARENT_NIGHT_OUT").setPosition(175, 375).setSize(175, 125);
  p5.addButton("PARTY").setPosition(350, 375).setSize(175, 125);
  p5.addButton("WORK_AT_HOME").setPosition(525, 375).setSize(175, 125);
  
  List<String> l = Arrays.asList("Null", "Kitchen", "Living Room", "Family Room", "Utility Room", 
    "Garage", "Front Porch", "Back Porch", "Master Bath", "Guest Bath", "Master Bedroom", 
    "Kids Bedroom", "Guest Bedroom");
    
  p5.addScrollableList("SPOUSE_1")
     .setPosition(0, 0)
     .setSize(100, 150)
     .setColorActive(color(0, 255, 255))
     .setBarHeight(20)
     .setItemHeight(20)
     .addItems(l)
     ;
  p5.addScrollableList("SPOUSE_2")
     .setPosition(100, 0)
     .setSize(100, 150)
     .setColorActive(color(0, 255, 255))
     .setBarHeight(20)
     .setItemHeight(20)
     .addItems(l)
     ;
  
  p5.addScrollableList("KID_1")
     .setPosition(200, 0)
     .setSize(100, 150)
     .setColorActive(color(0, 255, 255))
     .setBarHeight(20)
     .setItemHeight(20)
     .addItems(l)
     ;
  
  p5.addScrollableList("KID_2")
     .setPosition(300, 0)
     .setSize(100, 150)
     .setColorActive(color(0, 255, 255))
     .setBarHeight(20)
     .setItemHeight(20)
     .addItems(l)
     ;
  
  p5.addScrollableList("HOUSEKEEPER")
     .setPosition(400, 0)
     .setSize(100, 150)
     .setColorActive(color(0, 255, 255))
     .setBarHeight(20)
     .setItemHeight(20)
     .addItems(l)
     ;
  
  p5.addScrollableList("BABYSITTER")
     .setPosition(500, 0)
     .setSize(100, 150)
     .setColorActive(color(0, 255, 255))
     .setBarHeight(20)
     .setItemHeight(20)
     .addItems(l)
     ;
  
  p5.addScrollableList("GUEST")
     .setPosition(600, 0)
     .setSize(100, 150)
     .setColorActive(color(0, 255, 255))
     .setBarHeight(20)
     .setItemHeight(20)
     .addItems(l)
     ;
  
  p5.addScrollableList("CAR_KEYS")
     .setPosition(0, 200)
     .setSize(100, 150)
     .setColorActive(color(0, 255, 255))
     .setBarHeight(20)
     .setItemHeight(20)
     .addItems(l)
     ;
  
  p5.addScrollableList("MOBILE_PHONE")
     .setPosition(100, 200)
     .setSize(100, 150)
     .setColorActive(color(0, 255, 255))
     .setBarHeight(20)
     .setItemHeight(20)
     .addItems(l)
     ;
  
  p5.addScrollableList("TV_REMOTE")
     .setPosition(200, 200)
     .setSize(100, 150)
     .setColorActive(color(0, 255, 255))
     .setBarHeight(20)
     .setItemHeight(20)
     .addItems(l)
     ;
  
  p5.addScrollableList("CAT")
     .setPosition(300, 200)
     .setSize(100, 150)
     .setColorActive(color(0, 255, 255))
     .setBarHeight(20)
     .setItemHeight(20)
     .addItems(l)
     ;
     
  p5.addScrollableList("DOG")
     .setPosition(400, 200)
     .setSize(100, 150)
     .setColorActive(color(0, 255, 255))
     .setBarHeight(20)
     .setItemHeight(20)
     .addItems(l)
     ;

  p5.addButton("UPDATE").setPosition(550, 225).setSize(100, 100);
  
  //this will create WAV files in your data directory from input speech 
  //which you will then need to hook up to SamplePlayer Beads
  ttsMaker = new TextToSpeechMaker();
  
  //START NotificationServer setup
  server = new NotificationServer();
  
  //instantiating a custom class (seen below) and registering it as a listener to the server
  example = new Example();
  server.addListener(example);
  
  masterGain = new Gain(ac, 1, 0.8);
  ac.out.addInput(masterGain);

  ac.start();
  
}


void draw() {
  //this method must be present (even if empty) to process events such as keyPressed()
  while (!queue.isEmpty()) { //<>//
    Notification n = queue.poll();
    sonifyNotification(n);
  }
}

void keyPressed() {
  //example of stopping the current event stream and loading the second one
  if (key == RETURN || key == ENTER) {
    server.stopEventStream(); //always call this before loading a new stream
    server.loadEventStream(eventDataJSON2);
    println("**** New event stream loaded: " + eventDataJSON2 + " ****");
  }
    
}

void UPDATE() {
  workLoop.pause(true);
  dinnerLoop.pause(true);
  partyLoop.pause(true);
  nightLoop.pause(true);
  PlaySounds();
}

void SPOUSE_1(int n) {
  String playback = "Spouse 1 " + p5.get(ScrollableList.class, "SPOUSE_1").getItem(n).get("name");
  String ttsFilePath = ttsMaker.createTTSWavFile(playback);
  soundsToPlay.add(ttsFilePath);
  println(playback);
  
}

void SPOUSE_2(int n) {
  String playback = "Spouse 2 " + p5.get(ScrollableList.class, "SPOUSE_2").getItem(n).get("name");
  String ttsFilePath = ttsMaker.createTTSWavFile(playback);
  soundsToPlay.add(ttsFilePath);
  println(playback);
  
}

void KID_1(int n) {
  String playback = "Kid 1 " + p5.get(ScrollableList.class, "KID_1").getItem(n).get("name");
  String ttsFilePath = ttsMaker.createTTSWavFile(playback);
  soundsToPlay.add(ttsFilePath);
  println(playback);
  
}

void KID_2(int n) {
  String playback = "Kid 2 " + p5.get(ScrollableList.class, "KID_2").getItem(n).get("name");
  String ttsFilePath = ttsMaker.createTTSWavFile(playback);
  soundsToPlay.add(ttsFilePath);
  println(playback);
  
}

void HOUSEKEEPER(int n) {
  String playback = "Housekeeper " + p5.get(ScrollableList.class, "HOUSEKEEPER").getItem(n).get("name");
  String ttsFilePath = ttsMaker.createTTSWavFile(playback);
  soundsToPlay.add(ttsFilePath);
  println(playback);
  
}

void BABYSITTER(int n) {
  String playback = "Babysitter " + p5.get(ScrollableList.class, "BABYSITTER").getItem(n).get("name");
  String ttsFilePath = ttsMaker.createTTSWavFile(playback);
  soundsToPlay.add(ttsFilePath);
  println(playback);
  
}

void GUEST(int n) {
  String playback = "Guest " + p5.get(ScrollableList.class, "GUEST").getItem(n).get("name");
  String ttsFilePath = ttsMaker.createTTSWavFile(playback);
  soundsToPlay.add(ttsFilePath);
  println(playback);
  
}

void CAR_KEYS(int n) {
  soundsToPlay.add("keys.wav");
  String playback = "" + p5.get(ScrollableList.class, "CAR_KEYS").getItem(n).get("name");
  String ttsFilePath = ttsMaker.createTTSWavFile(playback);
  soundsToPlay.add(ttsFilePath);
  println(playback);
  
}

void MOBILE_PHONE(int n) {
  soundsToPlay.add("mobile phone.wav");
  String playback = "" + p5.get(ScrollableList.class, "MOBILE_PHONE").getItem(n).get("name");
  String ttsFilePath = ttsMaker.createTTSWavFile(playback);
  soundsToPlay.add(ttsFilePath);
  println(playback);
  
}

void TV_REMOTE(int n) {
  soundsToPlay.add("remote.wav");
  String playback = "" + p5.get(ScrollableList.class, "TV_REMOTE").getItem(n).get("name");
  String ttsFilePath = ttsMaker.createTTSWavFile(playback);
  soundsToPlay.add(ttsFilePath);
  println(playback);
  
}

void CAT(int n) {
  soundsToPlay.add("cat.wav");
  String playback = "" + p5.get(ScrollableList.class, "CAT").getItem(n).get("name");
  String ttsFilePath = ttsMaker.createTTSWavFile(playback);
  soundsToPlay.add(ttsFilePath);
  println(playback);
  
}

void DOG(int n) {
  soundsToPlay.add("dog.wav");
  String playback = "" + p5.get(ScrollableList.class, "DOG").getItem(n).get("name");
  String ttsFilePath = ttsMaker.createTTSWavFile(playback);
  soundsToPlay.add(ttsFilePath);
  println(playback);
  
}

void DINNER_AT_HOME(){
  //loading the event stream, which also starts the timer serving events
  dinner = true;
  night = false;
  party = false;
  work = false;
  workLoop.pause(true);
  dinnerLoop.pause(false);
  dinnerLoop.setLoopType(SamplePlayer.LoopType.LOOP_FORWARDS);
  masterGain.addInput(dinnerLoop);
  partyLoop.pause(true);
  nightLoop.pause(true);
  server.stopEventStream();
  server.loadEventStream(eventDataJSON1);
}

void PARENT_NIGHT_OUT(){
  //loading the event stream, which also starts the timer serving events
  dinner = false;
  night = true;
  party = false;
  work = false;
  workLoop.pause(true);
  dinnerLoop.pause(true);
  partyLoop.pause(true);
  nightLoop.pause(false);
  nightLoop.setLoopType(SamplePlayer.LoopType.LOOP_FORWARDS);
  masterGain.addInput(nightLoop);
  server.stopEventStream();
  server.loadEventStream(eventDataJSON2);
}

void PARTY(){
  //loading the event stream, which also starts the timer serving events
  dinner = false;
  night = false;
  party = true;
  work = false;
  workLoop.pause(true);
  dinnerLoop.pause(true);
  partyLoop.pause(false);
  nightLoop.pause(true);
  partyLoop.setLoopType(SamplePlayer.LoopType.LOOP_FORWARDS);
  masterGain.addInput(partyLoop);
  server.stopEventStream();
  server.loadEventStream(eventDataJSON3);
}

void WORK_AT_HOME(){
  //loading the event stream, which also starts the timer serving events
  dinner = false;
  night = false;
  party = false;
  work = true;
  workLoop.pause(false);
  dinnerLoop.pause(true);
  partyLoop.pause(true);
  nightLoop.pause(true);
  workLoop.setLoopType(SamplePlayer.LoopType.LOOP_FORWARDS);
  masterGain.addInput(workLoop);
  server.stopEventStream();
  server.loadEventStream(eventDataJSON4);
}

public void sonifyNotification(Notification n) {
  String debugOutput = ">>> ";
  String note = "";
  String written = "";
  if (n.getPriorityLevel() > 0) {
      switch (n.getType()) {
        case Door:
          if (n.getPriorityLevel() < 3 && !party) {
            if (n.getFlag().equals("on")) {
              soundsToPlay.add("door open.wav");
              written += n.getLocation() + " door open";
            } else if (n.getFlag().equals("off")) {
              soundsToPlay.add("door close.wav");
              written += n.getLocation() + " door closed";
            }
          }
          debugOutput += "Door notification dequeued at " + n.getTimestamp() + " ms, Priority:" + n.getPriorityLevel();
          break;
        case PersonMove:
          if (n.getPriorityLevel() == 1) {
            env = new Envelope(ac, 250);
            saw = new WavePlayer(ac, env, Buffer.SAW);
            g1 = new Gain(ac, 1, 0.1);
            g1.addInput(saw);
            masterGain.addInput(g1);
            env.addSegment(500, 250, new KillTrigger(g1));
            written += n.getTag() + " in " + n.getLocation();
          }
          if (n.getPriorityLevel() < 3 && !isSoundPlaying && !party) {
            note += n.getTag() + " in " + n.getLocation(); 
          } else if ((n.getTag().equals("kid_1") || n.getTag().equals("kid_2")) && (work || night) && n.getFlag().equals("on")) {
            note += n.getTag() + " in " + n.getLocation();
          } else if (n.getFlag().equals("on")) {
            written += n.getTag() + " in " + n.getLocation();
          }
          debugOutput += "PersonMove notification dequeued at " + n.getTimestamp() + " ms, Priority:" + n.getPriorityLevel();
          break;
        case ObjectMove:
          if (n.getPriorityLevel() == 1 && (n.getTag().equals("dog") || n.getTag().equals("cat"))) {
            if (!night) {
              env = new Envelope(ac, 250);
              saw = new WavePlayer(ac, env, Buffer.SAW);
              g1 = new Gain(ac, 1, 0.1);
              g1.addInput(saw);
              masterGain.addInput(g1);
              env.addSegment(500, 250, new KillTrigger(g1));
            }
            if (n.getTag().equals("dog")) {
              soundsToPlay.add("dog.wav");
            } else if (n.getTag().equals("cat")) {
              soundsToPlay.add("cat.wav");
            }
            note += " in " + n.getLocation();
          }
          if (n.getPriorityLevel() == 2 && !work) {
            if (n.getTag().equals("dog")) {
              soundsToPlay.add("dog.wav");
            } else if (n.getTag().equals("cat")) {
              soundsToPlay.add("cat.wav");
            } else if (n.getTag().equals("car_keys")) {
              soundsToPlay.add("keys.wav");
            } else {
              note += n.getTag();
            }
            note += " in " + n.getLocation();
          }
          if (n.getFlag().equals("on")) {
            written += n.getTag() + " in " + n.getLocation();
          }
          debugOutput += "ObjectMove notification dequeued at " + n.getTimestamp() + " ms, Priority:" + n.getPriorityLevel();
          break;
        case ApplianceStateChange:
          if (n.getPriorityLevel() == 1) {
            note += n.getTag() + " " + n.getFlag() + ",";
            if (!n.getTag().equals("stove")){
              note += n.getLocation() + " ";
            }
            if (!party) {
              note += n.getNote().replace(":",",");
            }
          } else {
            written += n.getTag() + " " + n.getFlag() + " " + n.getLocation();
          }
          if (n.getTag().equals("stove")) {
            if (n.getFlag().equals("on")) {
              soundsToPlay.add("stove on.wav");
              //written+="stove on";
            } else if (n.getFlag().equals("off")) {
              soundsToPlay.add("stove off.wav");
             //written+="stove off";
            }
          }
          debugOutput += "ApplianceStateChange notification dequeued at " + n.getTimestamp() + " ms, Priority:" + n.getPriorityLevel();
          break;
        case PackageDelivery:
          if (!party && !night) {
            note += n.getNote().replace(":",",").replace("."," dot ") + " " + n.getLocation();
          } else {
            note += n.getType() + n.getLocation();
          }
          debugOutput += "PackageDelivery notification dequeued at " + n.getTimestamp() + " ms, Priority:" + n.getPriorityLevel();
          break;
        case Message:
          soundsToPlay.add("mobile phone.wav");
          if (n.getPriorityLevel() == 1) {
            note += "message for " + n.getTag();
            note += n.getNote().replace(":",",");
          }
          debugOutput += "Message notification dequeued at " + n.getTimestamp() + " ms, Priority:" + n.getPriorityLevel();
          break;
    }
    if (note != "") {
      String ttsFilePath = ttsMaker.createTTSWavFile(note);
      soundsToPlay.add(ttsFilePath);
      println("TTS: " + note);
    }
    if (!isSoundPlaying) {
      PlaySounds();
    }
  }
  println(debugOutput);
  println(written);
}
// load filenames for sounds into the global soundsToPlay Queue before calling PlaySounds()
// Note: You should have a way to prent PlaySounds() from being called again while the current
// list of sounds is still playing. For example, you could use the global isSoundPlaying, or another
// global flag, to prevent PlaySounds from being called while the current list of sounds is still playing.
public void PlaySounds() {
  String soundFile = soundsToPlay.poll();
  
  if (soundFile != null) {
    // These SamplePlayers are set to killOnEnd
    SamplePlayer sound = getSamplePlayer(soundFile, true);
    sound.pause(true);
    masterGain.addInput(sound);
    
    // create endListener for first sound
    Bead endListener = new Bead() {
      public void messageReceived(Bead message) {
        // the message parameter is the SamplePlayer that triggered the
        // endListener handler, so cast it to SamplePlayer to use
        // use it's member functions
        SamplePlayer sp = (SamplePlayer) message;
        // necessary to remove this endListener or it could fire again - bug in Beads?
        sp.setEndListener(null);
        
        println("Done playing " + sp.getSample().getFileName());
        // Try to play next sound in the queue
        PlaySounds();
      }
    };
    
    // start playing first sound
    if (!isSoundPlaying) {
      println("isSoundPlaying = true");
    }
    isSoundPlaying = true;
    sound.setEndListener(endListener);
    sound.start();
  }
  else {
    isSoundPlaying = false;
    println("isSoundPlaying = false");
  }  
}

//in your own custom class, you will implement the NotificationListener interface 
//(with the notificationReceived() method) to receive Notification events as they come in
class Example implements NotificationListener {
  
  public Example() {
    //setup here
  }
  
  //this method must be implemented to receive notifications
  public void notificationReceived(Notification notification) { 
    /*println("<Example> " + notification.getType().toString() + " notification received at " 
    + Integer.toString(notification.getTimestamp()) + " ms");
    
    String debugOutput = ">>> ";
    switch (notification.getType()) {
      case Door:
        debugOutput += "Door moved: ";
        break;
      case PersonMove:
        debugOutput += "Person moved: ";
        break;
      case ObjectMove:
        debugOutput += "Object moved: ";
        break;
      case ApplianceStateChange:
        debugOutput += "Appliance changed state: ";
        break;
      case PackageDelivery:
        debugOutput += "Package delivered: ";
        break;
      case Message:
        debugOutput += "New message: ";
        break;
    }
    debugOutput += notification.toString();
    //debugOutput += notification.getLocation() + ", " + notification.getTag();
    
    println(debugOutput);*/
    
    queue.add(notification);
    
   //You can experiment with the timing by altering the timestamp values (in ms) in the exampleData.json file
    //(located in the data directory)
  }
}

void ttsExamplePlayback(String inputSpeech) {
  //create TTS file and play it back immediately
  //the SamplePlayer will remove itself when it is finished in this case
  
  String ttsFilePath = ttsMaker.createTTSWavFile(inputSpeech);
  println("File created at " + ttsFilePath);
  
  //createTTSWavFile makes a new WAV file of name ttsX.wav, where X is a unique integer
  //it returns the path relative to the sketch's data directory to the wav file
  
  //see helper_functions.pde for actual loading of the WAV file into a SamplePlayer
  
  SamplePlayer sp = getSamplePlayer(ttsFilePath, true); 
  //true means it will delete itself when it is finished playing
  //you may or may not want this behavior!
  
  ac.out.addInput(sp);
  sp.setToLoopStart();
  sp.start();
  println("TTS: " + inputSpeech);
}
