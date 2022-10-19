import 'package:flutter/material.dart';
import 'package:notes/Screens/Actions/CreateNote.dart';
import 'package:notes/Screens/HomeScreen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:intl/intl.dart';

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

final TextEditingController titleC = TextEditingController();
final TextEditingController contentC = TextEditingController();
late int Index;
int chosenIndex = 0;

class EditNote extends StatefulWidget {
  String Title = "";
  String Content = "";
  int index = 0;

  EditNote(
      {Key? key,
      required this.Title,
      required this.Content,
      required this.index})
      : super(key: key);

  @override
  State<EditNote> createState() => _EditNoteState();
}

class _EditNoteState extends State<EditNote> {
  Future<void> share() async {
    await FlutterShare.share(
      title: titleC.text,
      text: "Title: " + titleC.text + "\n" + "Content: " + contentC.text,
    );
  }

  @override
  void initState() {
    super.initState();
    titleC.text = widget.Title;
    contentC.text = widget.Content;
    Index = widget.index;
    chosenIndex = Index;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: share,
        backgroundColor: colors[chosenIndex],
        child: const Icon(
          Icons.share_outlined,
          color: Colors.white,
        ),
        tooltip: "Share",
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      backgroundColor: colors[chosenIndex],
      body: SafeArea(
          child: ListView(children: [
        // SizedBox(
        //   height: 10,
        // ),
        Row(
          children: [
            SizedBox(
              width: 15,
            ),
            FloatingActionButton(
              onPressed: _createPdfWithTable,
              backgroundColor: colors[chosenIndex],
              child: const Icon(
                Icons.sim_card_download,
                color: Colors.white,
              ),
              tooltip: "PDF",
            ),
          ],
        ),

        SizedBox(
          height: 30,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: TextFormField(
              maxLines: 2,
              cursorColor: Colors.white,
              textInputAction: TextInputAction.done,
              controller: titleC,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 60 : 36,
                  fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                  border: InputBorder.none, hintText: "No Title")),
        ),
        SizedBox(
          height: 10,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: TextFormField(
              cursorColor: Colors.white,
              textInputAction: TextInputAction.newline,
              controller: contentC,
              maxLines: isTablet ? 20 : 15,
              showCursor: true,
              style:
                  TextStyle(color: Colors.white, fontSize: isTablet ? 40 : 24),
              decoration: InputDecoration(
                  border: InputBorder.none,
                  constraints: BoxConstraints.expand(
                      height: isTablet ? 800 : 460, width: 200),
                  hintText: "Write Your Note Here")),
        ),
        FittedBox(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 100 : 20.0),
            child: Container(
              height: 60,
              child: Center(
                child: ListView.builder(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  itemCount: colors.length,
                  itemBuilder: (BuildContext context, Index) => GestureDetector(
                    onTap: () {
                      chosenIndex = Index;
                      setState(() {});
                    },
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: colors[Index],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
          child: TextButton(
            onPressed: () async {
              var time = DateTime.now().toString();
              titleC.text != widget.Title ||
                      contentC.text != widget.Content ||
                      chosenIndex != widget.index
                  ? {
                      await editDatabaseItem(
                          time: "$time",
                          content: contentC.text,
                          title: widget.Title,
                          title2: titleC.text,
                          index: chosenIndex),
                      Navigator.of(context).pop(),
                    }
                  : Navigator.of(context).pop();
            },
            child: Text(
              "Done",
              style: TextStyle(fontSize: 30, color: Colors.white),
            ),
          ),
        )
      ])),
    );
  }

  Future<void> _createPdfWithTable() async {
    PdfDocument document = PdfDocument();
    PdfGrid grid = PdfGrid();
    final page = document.pages.add();

    PdfPageTemplateElement header = PdfPageTemplateElement(
      Rect.fromLTWH(0, 0, document.pageSettings.size.width, 100),
    );

    page.graphics.drawImage(
        PdfBitmap(await _readImageData()), Rect.fromLTWH(10, 10, 40, 50));

    page.graphics.drawString(
        'Title: ${titleC.text}', PdfStandardFont(PdfFontFamily.helvetica, 30),
        bounds: Rect.fromLTWH(60, 20, document.pageSettings.size.width,
            document.pageSettings.size.height));

    DateTime now = DateTime.now();
    String formatedDate = DateFormat('MMM d, h:mm a').format(now);
    page.graphics.drawString(
        'Date: ${formatedDate}', PdfStandardFont(PdfFontFamily.helvetica, 20),
        bounds: Rect.fromLTWH(320, 30, document.pageSettings.size.width,
            document.pageSettings.size.height));

    page.graphics.drawLine(PdfPen(PdfColor(165, 42, 42), width: 5),
        Offset(0, 80), Offset(document.pageSettings.size.width, 80));

    page.graphics.drawString('Descreption:\n\n ${contentC.text}',
        PdfStandardFont(PdfFontFamily.helvetica, 22),
        bounds: Rect.fromLTWH(10, 100, page.getClientSize().width,
            page.getClientSize().height),);

    final directory = await getExternalStorageDirectory();

    final path = directory!.path;
    print(path);

    File('$path/${titleC.text}.pdf').writeAsBytes(document.saveSync());
    document.dispose();

    OpenFile.open('$path/${titleC.text}.pdf');
  }
}

Future<Uint8List> _readImageData() async {
  final data = await rootBundle.load("assets/icon/Icon.png");
  return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}
