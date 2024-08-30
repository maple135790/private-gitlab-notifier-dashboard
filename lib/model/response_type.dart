import 'package:private_gitlab_notifier_dashboard/model/merge_request.dart';
import 'package:private_gitlab_notifier_dashboard/model/note.dart';

typedef MergeRequestDiff = ({
  List<MergeRequest> mrChanges,
  Map<MergeRequest, List<Note>> commentChanges,
});

enum MRResponseType {
  nothingToNotify(0, ''),
  mergeRequest(2, 'New Merge Request'),
  multipleMergeRequests(3, 'New Merge Requests'),
  comment(4, 'New Comment'),
  multipleComments(5, 'New Comments'),
  mixed(6, 'Mixed'),
  ;

  final int value;
  final String title;
  const MRResponseType(this.value, this.title);

  static MRResponseType fromRawJson(Map<String, dynamic> json) {
    return fromRawValue(json['type'] as int);
  }

  static MRResponseType fromRawValue(int rawValue) {
    return switch (rawValue) {
      0 => nothingToNotify,
      2 => mergeRequest,
      3 => multipleMergeRequests,
      4 => comment,
      5 => multipleComments,
      6 => mixed,
      _ => throw Exception('Unknown ResponseType: $rawValue'),
    };
  }

  static MRResponseType fromChanges(MergeRequestDiff changes) {
    final mrChanges = changes.mrChanges;
    final commentChanges = changes.commentChanges;

    if (mrChanges.isEmpty && commentChanges.isEmpty) {
      return nothingToNotify;
    }

    if (mrChanges.isNotEmpty && commentChanges.isNotEmpty) {
      return mixed;
    }

    if (mrChanges.length == 1) {
      return mergeRequest;
    } else if (mrChanges.length > 1) {
      return multipleMergeRequests;
    } else if (commentChanges.length == 1 &&
        commentChanges.entries.first.value.length == 1) {
      return comment;
    } else {
      return multipleComments;
    }
  }
}
