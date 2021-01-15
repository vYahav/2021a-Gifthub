import 'dart:ui';
import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'user_repository.dart';
import 'package:circular_profile_avatar/circular_profile_avatar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

///-----------------------------------------------------------------------------
/// User Settings Screen
/// displays user's personal information and enables modifying user's info.
/// including:
/// - Avatar
/// - First and Last name
/// - address
/// - city
/// - Apartment
///-----------------------------------------------------------------------------

class UserSettingsScreen extends StatefulWidget {
  UserSettingsScreen({Key key}) : super(key: key);

  @override
  _UserSettingsScreenState createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKeyUserScreenSet = new GlobalKey<ScaffoldState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _aptController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final FocusNode _firstNameInputFocusNode = FocusNode();
  final FocusNode _lastNameInputFocusNode = FocusNode();
  final FocusNode _addressInputFocusNode = FocusNode();
  final FocusNode _aptInputFocusNode = FocusNode();
  final FocusNode _cityInputFocusNode = FocusNode();
  final FocusNode _googleStreetInputFocusNode = FocusNode();
  final FocusNode _googleCityInputFocusNode = FocusNode();

  /// true if user modified their avatar on edit mode, else false
  bool _avatarChanged = false;

  /// true if screen's current state in edit mode, else false
  bool _editingMode = false;

  ///true if user was on edit mode and presses confirm changes, else false
  bool _confirmEditingPressed = false;

  ///holds new avatar uploaded url if user changed avatar
  String _newAvatarURL = "";

  ///holds new avatar uploaded path if user changed avatar
  String _picPath = "";

  ///true if phone is currently uploading avatar, else false
  bool _uploadingAvatar = false;

  ///true if user chose to delete their avatar, else false
  bool _deletedAvatar = false;

  final Divider _avatarTilesDivider = Divider(
    color: Colors.grey[400],
    indent: 10,
    thickness: 1.0,
    endIndent: 10,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ///fetching current data of user
    var userRep = Provider.of<UserRepository>(context, listen: false);
    _newAvatarURL = userRep.avatarURL ?? defaultAvatar;
    _firstNameController.text = userRep.firstName;
    _lastNameController.text = userRep.lastName;
    _addressController.text = userRep.address;
    _cityController.text = userRep.city;
    _aptController.text = userRep.apt;
  }

  InputDecoration _getInputDecoration(String hint) {
    return InputDecoration(
      enabledBorder: _getOutlineInputBorder(),
      focusedBorder: _getOutlineInputBorder(color: Colors.lightGreen.shade800),
      hintText: hint,
      suffixIcon: hint == 'City'
        ? Icon(Icons.location_city_outlined)
        : Icon(Icons.home_outlined),
      contentPadding: EdgeInsets.fromLTRB(5.0 , 5.0 , 5.0 , 5.0),
    );
  }

  OutlineInputBorder _getOutlineInputBorder({Color color = Colors.grey}) {
    return OutlineInputBorder(
      borderSide: BorderSide(
        color: color,
        width: 1.3,
      ),
      borderRadius: BorderRadius.all(Radius.circular(30)),
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_){
      setState(() {});
    });
    return Material(
      child: Consumer<UserRepository>(
        builder:(context, userRep, _) {
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.width * 0.35,
                  color: Colors.lightGreen[800],
                ),
              ),
              Scaffold(
                resizeToAvoidBottomInset: true,
                resizeToAvoidBottomPadding: false,
                backgroundColor: Colors.transparent,
                key: _scaffoldKeyUserScreenSet,
                body: GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.0),
                      topRight: Radius.circular(20.0),
                    ),
                    child: Container(
                      height: MediaQuery.of(context).size.height,
                      color: Colors.white,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            SizedBox(height: 15),
                            ///user's Avatar
                            Stack(
                              alignment: Alignment.center,
                              children: <Widget> [
                                ///circular progress indicator if user's picture yet to be set
                                _uploadingAvatar ?
                                Container(
                                  width: MediaQuery.of(context).size.height * 0.1 * 2,
                                  height: MediaQuery.of(context).size.height * 0.1 * 2,
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      valueColor: new AlwaysStoppedAnimation<Color>(Colors.lightGreen[800]),
                                    )
                                  )
                                )
                                : CircularProfileAvatar(
                                  ///showing currently uploaded avatar if we're on edit mode
                                  _editingMode ? _newAvatarURL : userRep.avatarURL ?? defaultAvatar,
                                  borderColor: Colors.black,
                                  borderWidth: 1.3,
                                  radius: MediaQuery.of(context).size.height * 0.1,
                                  onTap: _editingMode
                                  ? _showAvatarChangeOptions
                                  : userRep?.avatarURL != defaultAvatar
                                    ? () => Navigator.of(context).push(
                                    new MaterialPageRoute<void>(
                                      builder: (_) => Dismissible(
                                        key: const Key('key2'),
                                        direction: DismissDirection.horizontal,
                                        onDismissed: (direction) => Navigator.pop(context),
                                        child: Dismissible(
                                          key: const Key('key'),
                                          direction: DismissDirection.vertical,
                                          onDismissed: (direction) => Navigator.pop(context),
                                          child: InteractiveViewer(
                                            minScale: 1.0,
                                            maxScale: 1.0,
                                            panEnabled: false,
                                            scaleEnabled: false,
                                            boundaryMargin: EdgeInsets.all(100.0),
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                image: DecorationImage(
                                                  image: NetworkImage(userRep.avatarURL ?? defaultAvatar),
                                                  fit: BoxFit.fitWidth,
                                                )
                                              ),
                                            )
                                          ),
                                        ),
                                      ),
                                    )
                                  ) : null
                                ),
                                _editingMode && !_uploadingAvatar
                                ? Column(
                                  ///'Press to change' text if we're on edit mode and not uploading
                                  ///new avatar
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    SizedBox(height: 50,),
                                    InkWell(
                                      onTap: _showAvatarChangeOptions,
                                      child: Container(
                                        width: MediaQuery.of(context).size.height * 0.18,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.all(Radius.circular(20)),
                                          color: Colors.white54,
                                        ),
                                        child: Text(
                                          "Press to change",
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.lato(
                                            fontSize: MediaQuery.of(context).size.height * 0.0256 * (15/18),
                                            color: Colors.black
                                          ),
                                        ),
                                      ),
                                    ),
                                  ]
                                ) : Container(),
                              ],
                            ),
                            SizedBox(height: 15,),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                ///user's first name
                                Padding(
                                  padding: EdgeInsets.only(left: 10, right: 5),
                                  child: Container(
                                    width: MediaQuery.of(context).size.width * 0.5 - 15,
                                    height: MediaQuery.of(context).size.height * 0.11,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: <Widget>[
                                        Flexible(
                                          child: Text('First name',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Flexible(
                                          flex: 2,
                                          child: Container(
                                            height: MediaQuery.of(context).size.height * 0.075 - 2,
                                            width: MediaQuery.of(context).size.width * 0.5 - 10,
                                            child: TextField(
                                              readOnly: !_editingMode,
                                              enableInteractiveSelection: true,
                                              autofocus: false,
                                              decoration: InputDecoration(
                                                isDense: true,
                                                enabledBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(color: Colors.grey),
                                                  borderRadius: BorderRadius.all(Radius.circular(30))
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(color: Colors.grey),
                                                  borderRadius: BorderRadius.all(Radius.circular(30))
                                                ),
                                              ),
                                              onChanged: (text) => {},
                                              textAlignVertical: TextAlignVertical.top,
                                              textAlign: TextAlign.center,
                                              controller: _firstNameController,
                                              inputFormatters: [
                                                FilteringTextInputFormatter.allow(RegExp('[a-z A-Z -]'))
                                              ],
                                              focusNode: _firstNameInputFocusNode,
                                              style: GoogleFonts.lato(
                                                fontSize: 16.0,
                                                color: Colors.black,
                                              )
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                ///user's last name
                                Padding(
                                  padding: EdgeInsets.only(right: 10, left: 5),
                                  child: Container(
                                    width: MediaQuery.of(context).size.width * 0.5 - 15,
                                    height: MediaQuery.of(context).size.height * 0.11,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: <Widget>[
                                        Flexible(
                                          child: Text('Last name',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.montserrat(
                                                fontSize: 16.0,
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                              )
                                          ),
                                        ),
                                        Flexible(
                                          flex: 2,
                                          child: Container(
                                            height: MediaQuery.of(context).size.height * 0.075 - 2,
                                            width: MediaQuery.of(context).size.width * 0.5 - 10,
                                            child: TextField(
                                              readOnly: !_editingMode,
                                              autofocus: false,
                                              focusNode: _lastNameInputFocusNode,
                                              keyboardType: TextInputType.name,
                                              decoration: InputDecoration(
                                                isDense: true,
                                                enabledBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(color: Colors.grey),
                                                  borderRadius: BorderRadius.all(Radius.circular(30))
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(color: Colors.grey),
                                                  borderRadius: BorderRadius.all(Radius.circular(30))
                                                ),
                                              ),
                                              inputFormatters: [
                                                FilteringTextInputFormatter.allow(RegExp('[a-z A-Z -]'))
                                              ],
                                              textAlignVertical: TextAlignVertical.top,
                                              textAlign: TextAlign.center,
                                              controller: _lastNameController,
                                              onChanged: (text) => {},
                                              style: GoogleFonts.lato(
                                                fontSize: 16.0,
                                                color: Colors.black,
                                              )
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                            SizedBox(height: 15,),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Text('Street address',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    )
                                ),
                                ///user's address
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                                  child: Container(
                                    height: MediaQuery.of(context).size.height * 0.075 - 2,
                                    child: TextField(
                                      readOnly: !_editingMode,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        prefix: Transform.translate(
                                          offset: Offset(0.0, 5.0),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                            child: InkWell(
                                              focusColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              highlightColor: Colors.transparent,
                                              onTap: () {
                                                print('maps Pressed!');
                                                _unfocusAll();
                                                if(!_editingMode || _confirmEditingPressed){
                                                  return;
                                                }
                                                showDialog(
                                                  context: context,
                                                  barrierDismissible: true,
                                                  builder: (context){
                                                    return Center(
                                                      child: Padding(
                                                        padding: const EdgeInsets.all(20.0),
                                                        child: GestureDetector(
                                                          onTap: () {
                                                            FocusScope.of(context).unfocus();
                                                          },
                                                          child: ClipRRect(
                                                            borderRadius: BorderRadius.all(Radius.circular(20.0)),
                                                            child: Material(
                                                              child: Container(
                                                                color: Colors.transparent,
                                                                height: MediaQuery.of(context).size.height * 0.75,
                                                                width: MediaQuery.of(context).size.width,
                                                                child: Column(
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                                  children: <Widget>[
                                                                    Flexible(
                                                                      flex: 1,
                                                                      child: Row(
                                                                        mainAxisSize: MainAxisSize.min,
                                                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                                        crossAxisAlignment: CrossAxisAlignment.center,
                                                                        children: <Widget>[
                                                                          Flexible(
                                                                            flex: 4,
                                                                            child: Padding(
                                                                              padding: const EdgeInsets.only(
                                                                                left: 8.0,
                                                                                right: 4.0,
                                                                                top: 12.0,
                                                                                bottom: 12.0,
                                                                              ),
                                                                              child: TextField(
                                                                                decoration: _getInputDecoration('Street'),
                                                                                style: GoogleFonts.lato(
                                                                                  fontWeight: FontWeight.w600,
                                                                                  fontSize: 16.0,
                                                                                ),
                                                                                focusNode: _googleStreetInputFocusNode,
                                                                                autofocus: false,
                                                                                textAlign: TextAlign.start,
                                                                                textAlignVertical: TextAlignVertical.center,
                                                                                keyboardType: TextInputType.streetAddress,
                                                                                inputFormatters: [
                                                                                  FilteringTextInputFormatter.allow(RegExp('[a-z A-Z 0-9 .]'))
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Flexible(
                                                                            flex: 3,
                                                                            child: Padding(
                                                                              padding: const EdgeInsets.only(
                                                                                left: 8.0,
                                                                                right: 4.0,
                                                                                top: 12.0,
                                                                                bottom: 12.0,
                                                                              ),
                                                                              child: TextField(
                                                                                decoration: _getInputDecoration('City'),
                                                                                style: GoogleFonts.lato(
                                                                                  fontWeight: FontWeight.w600,
                                                                                  fontSize: 16.0,
                                                                                ),
                                                                                keyboardType: TextInputType.streetAddress,
                                                                                inputFormatters: [
                                                                                  FilteringTextInputFormatter.allow(RegExp('[a-z A-Z .]'))
                                                                                ],
                                                                                focusNode: _googleCityInputFocusNode,
                                                                                autofocus: false,
                                                                                textAlign: TextAlign.start,
                                                                                textAlignVertical: TextAlignVertical.center,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Flexible(
                                                                            flex: 1,
                                                                            child: Column(
                                                                              mainAxisSize: MainAxisSize.min,
                                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                                              children: <Widget>[
                                                                                IconButton(
                                                                                  icon: Icon(
                                                                                    Icons.add_location_alt,
                                                                                    color: Colors.deepOrange,
                                                                                    size: 27.0,
                                                                                  ),
                                                                                  onPressed: () {
                                                                                    print('search pressed!');
                                                                                  }
                                                                                ),
                                                                                Transform.translate(
                                                                                  offset: Offset(0.0, -9.0),
                                                                                  child: Text('Add')
                                                                                ),
                                                                              ],
                                                                            )
                                                                          ),
                                                                        ],
                                                                      )
                                                                    ),
                                                                    Flexible(
                                                                      flex: 7,
                                                                      child: Container(color: Colors.red,)
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                );
                                              },
                                              child: Image.asset(
                                                _editingMode && !_confirmEditingPressed
                                                  ? 'Assets/GoogleMaps.png'
                                                  : 'Assets/GoogleMapsGrey.jpeg',
                                                width: MediaQuery.of(context).size.width * 0.075,
                                                height: MediaQuery.of(context).size.height * 0.04,
                                              ),
                                            ),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: Colors.grey),
                                          borderRadius: BorderRadius.all(Radius.circular(30))
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: Colors.grey),
                                          borderRadius: BorderRadius.all(Radius.circular(30))
                                        ),
                                      ),
                                      focusNode: _addressInputFocusNode,
                                      controller: _addressController,
                                      autofocus: false,
                                      keyboardType: TextInputType.streetAddress,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp('[a-z A-Z 0-9 .]'))
                                      ],
                                      onChanged: (text) => {},
                                      textAlignVertical: TextAlignVertical.top,
                                      textAlign: TextAlign.start,
                                      style: GoogleFonts.lato(
                                        fontSize: 16.0,
                                        color: Colors.black
                                      )
                                    ),
                                  ),
                                ),
                                SizedBox(height: 15,),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    ///user's apartment
                                    Padding(
                                      padding: const EdgeInsets.only(left: 10.0, right: 5.0),
                                      child: Container(
                                        width: MediaQuery.of(context).size.width * 0.3 - 15,
                                        height: MediaQuery.of(context).size.height * 0.11,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: <Widget>[
                                            Flexible(
                                              child: Text('Apt.',
                                                style: GoogleFonts.montserrat(
                                                  fontSize: 16.0,
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Flexible(
                                              flex: 2,
                                              child: Container(
                                                height: MediaQuery.of(context).size.height * 0.075 - 2,
                                                width: MediaQuery.of(context).size.width * 0.3,
                                                child: TextField(
                                                  autofocus: false,
                                                  readOnly: !_editingMode,
                                                  keyboardType: TextInputType.number,
                                                  decoration: InputDecoration(
                                                    counterText: "",
                                                    isDense: true,
                                                    enabledBorder: OutlineInputBorder(
                                                        borderSide: BorderSide(color: Colors.grey),
                                                        borderRadius: BorderRadius.all(Radius.circular(30))
                                                    ),
                                                    focusedBorder: OutlineInputBorder(
                                                        borderSide: BorderSide(color: Colors.grey),
                                                        borderRadius: BorderRadius.all(Radius.circular(30))
                                                    ),
                                                  ),
                                                  onChanged: (text) => {},
                                                  textAlignVertical: TextAlignVertical.top,
                                                  textAlign: TextAlign.center,
                                                  controller: _aptController,
                                                  maxLength: 6,
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter.allow(RegExp('[0-9]'))
                                                  ],
                                                  focusNode: _aptInputFocusNode,
                                                  style: GoogleFonts.lato(
                                                    fontSize: 16.0,
                                                    color: Colors.black,
                                                  )
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    ///user's city
                                    Padding(
                                      padding: const EdgeInsets.only(right: 10.0, left: 5.0),
                                      child: Container(
                                        width: MediaQuery.of(context).size.width * 0.7 - 15,
                                        height: MediaQuery.of(context).size.height * 0.11,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: <Widget>[
                                            Flexible(
                                              child: Text('City',
                                                style: GoogleFonts.montserrat(
                                                  fontSize: 16.0,
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Flexible(
                                              flex: 2,
                                              child: Container(
                                                height: MediaQuery.of(context).size.height * 0.075 - 2,
                                                width: MediaQuery.of(context).size.width * 0.7 - 10,
                                                child: TextField(
                                                  autofocus: false,
                                                  readOnly: !_editingMode,
                                                  decoration: InputDecoration(
                                                    isDense: true,
                                                    enabledBorder: OutlineInputBorder(
                                                        borderSide: BorderSide(color: Colors.grey),
                                                        borderRadius: BorderRadius.all(Radius.circular(30))
                                                    ),
                                                    focusedBorder: OutlineInputBorder(
                                                        borderSide: BorderSide(color: Colors.grey),
                                                        borderRadius: BorderRadius.all(Radius.circular(30))
                                                    ),
                                                  ),
                                                  onChanged: (text) => {},
                                                  textAlign: TextAlign.center,
                                                  textAlignVertical: TextAlignVertical.top,
                                                  controller: _cityController,
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter.allow(RegExp('[a-zA-Z .]'))
                                                  ],
                                                  focusNode: _cityInputFocusNode,
                                                  style: GoogleFonts.lato(
                                                    fontSize: 16.0,
                                                    color: Colors.black,
                                                  )
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 60,),
                            /// edit/submit changes button
                            Align(
                              alignment: FractionalOffset.bottomCenter,
                              child: Container(
                                height: 40,
                                width: 200,
                                child: InkWell(
                                  focusColor: Colors.transparent,
                                  hoverColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  child: RaisedButton(
                                    elevation: 20.0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18.0),
                                      side: BorderSide(color: Colors.transparent),
                                    ),
                                    visualDensity: VisualDensity.adaptivePlatformDensity,
                                    color: _editingMode && !_confirmEditingPressed ? Colors.green[900] : Colors.grey[900],
                                    textColor: Colors.white,
                                    onPressed:
                                    ///disabling button if we're uploading new avatar
                                    _uploadingAvatar ? null
                                      : _editingMode
                                    ///if we're in edit mode then we submit our changes
                                      ? () async {
                                      setState(() {
                                        _confirmEditingPressed = true;
                                      });
                                      if(_avatarChanged) {
                                        setState(() {
                                          _uploadingAvatar = true;
                                        });
                                        if(_deletedAvatar){
                                          await userRep.deleteAvatar();
                                          userRep.avatarURL = defaultAvatar;
                                        } else {
                                          await userRep.setAvatar(_picPath);
                                        }
                                        _avatarChanged = false;
                                        _deletedAvatar = false;
                                      }
                                      setState(() {
                                        if(_firstNameController.text.isNotEmpty) {
                                          userRep.firstName = _firstNameController.text;
                                        }
                                        if(_lastNameController.text.isNotEmpty) {
                                          userRep.lastName = _lastNameController.text;
                                        }
                                        if(_addressController.text.isNotEmpty) {
                                          userRep.address = _addressController.text;
                                        }
                                        if(_aptController.text.isNotEmpty) {
                                          userRep.apt = _aptController.text;
                                        }
                                        if(_cityController.text.isNotEmpty){
                                          userRep.city = _cityController.text;
                                        }
                                        _editingMode = false;
                                      });
                                      await userRep.updateFirebaseUserList();
                                      setState(() {
                                        _uploadingAvatar = false;
                                      });
                                    }
                                    ///setting edit mode:
                                    : () {
                                      _unfocusAll();
                                      setState(() {
                                        _editingMode = true;
                                        _confirmEditingPressed = false;
                                      });
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment:CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          _editingMode && !_confirmEditingPressed ? "Update   " : "Edit   ",
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.openSans(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.bold
                                          ),
                                        ),
                                        Icon(_editingMode && !_confirmEditingPressed ? Icons.check_outlined : Icons.edit_outlined,
                                          color: Colors.white,
                                          size: 17.0,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ]
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ]
          );
        }
      )
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lastNameInputFocusNode.dispose();
    _firstNameInputFocusNode.dispose();
    _addressInputFocusNode.dispose();
    _aptInputFocusNode.dispose();
    _cityInputFocusNode.dispose();
    _lastNameController.dispose();
    _firstNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _aptController.dispose();
    super.dispose();
  }

  ///showing bottom sheet of avatar changing options, including
  ///choose from gallery, camera and if user's avatar isn;t the defaulted one
  ///then also deletion option
  void _showAvatarChangeOptions() {
    _unfocusAll();
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: _newAvatarURL == defaultAvatar ? 67.0 * 2.0 : 67.0 * 3.0,
          child: Column(
            textDirection: TextDirection.ltr,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ListTile(
                tileColor: Colors.white,
                leading: Icon(
                  Icons.photo_camera_outlined,
                  color: Colors.lightGreen[800],
                ),
                title: Text("Take a new photo",
                  style: GoogleFonts.lato(),
                ),
                onTap: () async {
                  PickedFile photo = await ImagePicker().getImage(source: ImageSource.camera);
                  Navigator.pop(_scaffoldKeyUserScreenSet.currentContext);
                  if (null == photo) {
                    _scaffoldKeyUserScreenSet.currentState.showSnackBar(
                      SnackBar(
                        content: Text("No image selected",
                          style: GoogleFonts.notoSans(fontSize: 14.0),
                        ),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(milliseconds: 2500),
                      )
                    );
                  } else {
                    setState(() {
                      _uploadingAvatar = true;
                    });
                    _picPath = photo.path;
                    var userRep = Provider.of<UserRepository>(context, listen: false);
                    await userRep.storage.ref("tempAvatarImages").child(userRep.auth.currentUser.uid).putFile(File(photo.path));
                    var pic = await userRep.storage.ref("tempAvatarImages").child(userRep.auth.currentUser.uid).getDownloadURL();
                    setState(() {
                      _newAvatarURL = pic;
                      _avatarChanged = true;
                    });
                    setState(() {
                      _uploadingAvatar = false;
                    });
                  }
                },
              ),
              _avatarTilesDivider,
              ListTile(
                tileColor: Colors.white,
                leading: Icon(
                  Icons.photo_library_outlined,
                  color: Colors.lightGreen[800],
                ),
                title: Text("Select from gallery",
                  style: GoogleFonts.lato(),
                ),
                onTap: () async {
                  PickedFile photo = await ImagePicker().getImage(source: ImageSource.gallery);
                  Navigator.pop(context);
                  if (null == photo) {
                    _scaffoldKeyUserScreenSet.currentState.showSnackBar(
                      SnackBar(
                        content: Text("No image selected",
                          style: GoogleFonts.notoSans(fontSize: 14.0),
                        ),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(milliseconds: 2500),
                      )
                    );
                  } else {
                    setState(() {
                      _uploadingAvatar = true;
                    });
                    _picPath = photo.path;
                    var userRep = Provider.of<UserRepository>(context, listen: false);
                    await userRep.storage.ref("tempAvatarImages").child(userRep.auth.currentUser.uid).putFile(File(photo.path));
                    var pic = await userRep.storage.ref("tempAvatarImages").child(userRep.auth.currentUser.uid).getDownloadURL();
                    setState(() {
                      _newAvatarURL = pic;
                      _avatarChanged = true;
                    });
                    setState(() {
                      _uploadingAvatar = false;
                    });
                  }
                },
              ),
              _newAvatarURL != defaultAvatar
                ? _avatarTilesDivider
                : Container(),
              _newAvatarURL != defaultAvatar
                  ? ListTile(
                tileColor: Colors.white,
                leading: Icon(
                  Icons.delete_outline_outlined,
                  color: Colors.red,
                ),
                title: Text("Delete avatar",
                  style: GoogleFonts.lato(
                    color: Colors.black,
                  ),
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (_) => AlertDialog(
                      title: Text("Delete avatar?",
                        style: GoogleFonts.lato(
                          fontSize: 18.0,
                          color: Colors.black,
                        ),
                      ),
                      content: Text("Are you sure you want to delete your avatar?",
                        style: GoogleFonts.lato(
                          fontSize: 16.0,
                          color: Colors.grey,
                        ),
                      ),
                      backgroundColor: Colors.white,
                      elevation: 24.0,
                      actions: [
                        FlatButton(
                          child: Text("Yes",
                            style: GoogleFonts.lato(
                              fontSize: 14.0,
                              color: Colors.green,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _newAvatarURL = defaultAvatar;
                              _avatarChanged = true;
                              _deletedAvatar = true;
                            });
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                        ),
                        FlatButton(
                          child: Text("No",
                            style: GoogleFonts.lato(
                              fontSize: 14.0,
                              color: Colors.red,
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        )
                      ],
                    )
                  );
                },
              )
                  : Container(),
            ],
          ),
        );
      }
    );
  }

  ///removing focus from all text field's
  void _unfocusAll(){
    _addressInputFocusNode.unfocus();
    _firstNameInputFocusNode.unfocus();
    _lastNameInputFocusNode.unfocus();
    _aptInputFocusNode.unfocus();
    _cityInputFocusNode.unfocus();
  }


  ///hiding keyboard and un-focusing text field on user tap outside text field
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final value = WidgetsBinding.instance.window.viewInsets.bottom;
    if(0 == value) {
      _unfocusAll();
    }
  }
}
