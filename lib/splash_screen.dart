import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shimmer/shimmer.dart';

import 'homeScreen.dart';
import 'package:hexcolor/hexcolor.dart';

class SplashScreen extends StatefulWidget {
  //widget qui change d'etat
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override

  void _navigateToHome() {//fonction qui redirige le navigateur vers la page d'accueil une fois
                          // la duree du splash screen termine
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (BuildContext context) => new HomeScreen()));
  }
//permet d'autres operations a s'executer le temps qu'il se termine
  Future<bool> _nockCheckForSession() async {//fonction d'encochage pour controler la session, qui doit retourner true
                                              //une fois l'animation terminee
    await Future.delayed(const Duration(milliseconds: 3000));//la duree de l'animation

    return true;
  }

  void initState() {//initialisation de chaq etat,, l'implementation doit etre initie avec l'appel
    super.initState();//a la methode heritee

    _nockCheckForSession().then((status) {
      if (status) {
        _navigateToHome();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(//utiliser pour empiler du texte et une image sur du degrade
        fit: StackFit.expand,//pour dimensionner les enfants non positionnes d'une pile
          children: <Widget> [//le corps a 2 enfants un conteneur et une colonne
            Container(
              decoration: BoxDecoration(
                color: HexColor("#ffffff"),
                /*gradient: LinearGradient(
                  colors: [Colors.white, Colors.orangeAccent.shade100],
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                ),*/
              ),
            ),
            Column(
                mainAxisAlignment: MainAxisAlignment.center,//alignement centre sur la colonne de haut en bas
                children: <Widget>[
                  CircleAvatar(//cree un cercle qui contient l'image
                    radius: 75,
                    backgroundImage: AssetImage('images/logoUGB.jpg'),
                    ),
                  Padding(
                    padding: EdgeInsets.only(top: 15.0),
                  ),
                  Shimmer.fromColors(
                    baseColor: HexColor("#b35c35"),
                    highlightColor: HexColor("#ffffff"),
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.all(16.0),
                        child: Text("Université Gaston Berger de Saint-Louis",
                          style: TextStyle(
                            fontSize: 20,
                            fontFamily: 'Pacifico',
                            shadows: <Shadow>[//mettre de l'ombre sur l'ecriture
                              Shadow(
                                blurRadius: 18.0,
                                color: Colors.black87,
                                offset: Offset.fromDirection(120, 12)//decalage
                              )
                            ]
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
            ),
          ],
        ),
      );
  }
}
