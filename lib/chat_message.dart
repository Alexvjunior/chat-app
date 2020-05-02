import 'package:flutter/material.dart';

class ChatMessage extends StatelessWidget {
  ChatMessage(this.data, this._mine);

  final Map<String, dynamic> data;
  final bool _mine;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Row(
        children: <Widget>[
          _paddingMessage(!_mine),
          Expanded(
              child: Column(
            crossAxisAlignment: _crossAlignmentMine(),
            children: <Widget>[
              _message(data),
              Text(
                data["senderName"],
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              )
            ],
          )),
          _paddingMessage(_mine)
        ],
      ),
    );
  }

  Widget _paddingMessage(bool mine) {
    if (mine)
      return Padding(
          padding: EdgeInsets.only(left: 16, right: 16),
          child: CircleAvatar(
              backgroundImage: NetworkImage(data['senderPhotoUrl'])));
    return Container();
  }

  CrossAxisAlignment _crossAlignmentMine() {
    if (this._mine) return CrossAxisAlignment.end;
    return CrossAxisAlignment.start;
  }

  Widget _message(Map<String, dynamic> data) {
    if (data['imageUrl'] == null) {
      return Text(data['text'],
          textAlign: _mine ? TextAlign.end : TextAlign.start,
          style: TextStyle(fontSize: 16));
    }
    return Image.network(
      data["imageUrl"],
      width: 150,
    );
  }
}
