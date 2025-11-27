import 'dart:io';
import 'package:intl/intl.dart';

void main(List<String> arguments) async {
  // 1. 제목 체크
  if (arguments.isEmpty) {
    print('❌ 사용법: dart run auto_post.dart "포스팅 제목"');
    return;
  }

  final title = arguments[0];
  print('✨ 포스팅 시작: "$title"');

  // 2. 클립보드 내용 가져오기
  final content = await getClipboardContent();
  if (content.trim().isEmpty) {
    print('❌ 클립보드가 비어있거나 읽을 수 없습니다.');
    return;
  }

  // 3. 파일 메타데이터 생성
  final now = DateTime.now();
  final dateStr = DateFormat('yyyy-MM-dd').format(now);
  final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

  // 파일명 슬러그 처리 (특수문자 제거, 공백 -> 하이픈)
  final slug = title
      .trim()
      .replaceAll(RegExp(r'[^\w\uAC00-\uD7A3\s-]'), '')
      .replaceAll(RegExp(r'\s+'), '-');
  final fileName = '$dateStr-$slug.md';
  final filePath = '_posts/$fileName';

  // 4. 마크다운 내용 조합 (Frontmatter 포함)
  final fileContent = '''
---
layout: post
title:  "$title"
date:   $timeStr +0900
categories: [DevLog]
---

$content
''';

  // 5. 파일 쓰기
  try {
    await File(filePath).writeAsString(fileContent);
    print('✅ 파일 생성됨: $filePath');
  } catch (e) {
    print('❌ 파일 쓰기 실패: $e');
    return;
  }

  // 6. Git Push 자동화
  await runGit(['add', '.']);
  await runGit(['commit', '-m', 'Add post: $title']);
  print('🚀 GitHub으로 푸시 중...');
  await runGit(['push']);
  print('🎉 배포 완료! (https://sanghyun8039.github.io)');
}

Future<String> getClipboardContent() async {
  try {
    ProcessResult result;
    if (Platform.isMacOS) {
      result = await Process.run('pbpaste', []);
    } else if (Platform.isWindows) {
      // PowerShell을 통해 텍스트 가져오기 (인코딩 문제 방지)
      result = await Process.run('powershell', ['-command', 'Get-Clipboard']);
    } else {
      result = await Process.run('xclip', ['-selection', 'clipboard', '-o']);
    }
    return result.stdout.toString();
  } catch (e) {
    return '';
  }
}

Future<void> runGit(List<String> args) async {
  final result = await Process.run('git', args);
  if (result.exitCode != 0) print('Git Error: ${result.stderr}');
}
