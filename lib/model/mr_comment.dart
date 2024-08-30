import 'package:private_gitlab_notifier_dashboard/model/merge_request.dart';
import 'package:private_gitlab_notifier_dashboard/model/note.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mr_comment.g.dart';

@JsonSerializable()
class MRComment {
  final String title;
  final Note note;
  final String webUrl;

  const MRComment(this.title, this.note, this.webUrl);

  factory MRComment.fromChanges(Map<MergeRequest, List<Note>> changes) {
    final title = changes.entries.first.key.title;
    final note = changes.entries.first.value.first;
    final webUrl = changes.entries.first.key.webUrl;

    return MRComment(title, note, webUrl);
  }

  factory MRComment.fromJson(Map<String, dynamic> json) =>
      _$MRCommentFromJson(json);

  Map<String, dynamic> toJson() => _$MRCommentToJson(this);
}
