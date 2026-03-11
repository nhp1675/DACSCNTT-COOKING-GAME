import 'package:flutter/material.dart';

class PetClient {
  String itemWanted; 
  String avatarAssetPath; 
  double patience = 1.0; 
  bool isVip; 
  PetClient(this.itemWanted, this.avatarAssetPath, {this.isVip = false});
}

class PetItem {
  String name; 
  double progress = 0; 
  bool isRuined = false; 
  int ruinedTicks = 0; 
  bool isOnFire = false; 
  PetItem(this.name);
}

class FloatingScore {
  int petIndex; 
  double yOffset; 
  double opacity; 
  String text; 
  Color color;
  FloatingScore(this.petIndex, this.yOffset, this.opacity, this.text, this.color);
}