import 'package:final_flutter/models/email.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

class MockEmailRepository {
  final List<Email> _inbox = [];
  final List<Email> _sent = [];
  final List<Email> _drafts = [];
  final List<Email> _trash = [];

  // Quản lý nhãn toàn cục
  final List<String> _labels = [
    'Work',
    'Personal',
    'Important',
    'Spam',
  ];
  List<String> get labels => List.unmodifiable(_labels);
  void addLabel(String label) {
    if (!_labels.contains(label)) _labels.add(label);
  }
  void removeLabelGlobal(String label) {
    _labels.remove(label);
    // Xóa nhãn này khỏi tất cả email
    for (var e in [..._inbox, ..._sent, ..._drafts, ..._trash]) {
      e.labels.remove(label);
    }
  }
  void renameLabel(String oldLabel, String newLabel) {
    if (_labels.contains(oldLabel) && !_labels.contains(newLabel)) {
      final idx = _labels.indexOf(oldLabel);
      _labels[idx] = newLabel;
      for (var e in [..._inbox, ..._sent, ..._drafts, ..._trash]) {
        for (int i = 0; i < e.labels.length; i++) {
          if (e.labels[i] == oldLabel) e.labels[i] = newLabel;
        }
      }
    }
  }

  // Lấy danh sách
  List<Email> get inbox => List.unmodifiable(_inbox);
  List<Email> get sent => List.unmodifiable(_sent);
  List<Email> get drafts => List.unmodifiable(_drafts);
  List<Email> get trash => List.unmodifiable(_trash);

  // Lắng nghe sự kiện nhận email mới
  final List<VoidCallback> _listeners = [];
  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);
  void _notifyListeners() {
    for (final l in _listeners) {
      l();
    }
  }

  // Auto answer mode
  bool _autoAnswerEnabled = false;
  String _autoAnswerContent = 'Cảm ơn bạn đã gửi email. Tôi sẽ phản hồi sớm nhất.';
  bool get autoAnswerEnabled => _autoAnswerEnabled;
  set autoAnswerEnabled(bool v) => _autoAnswerEnabled = v;
  String get autoAnswerContent => _autoAnswerContent;
  set autoAnswerContent(String v) => _autoAnswerContent = v;

  MockEmailRepository() {
    _inbox.addAll([
      Email(
        id: '1',
        sender: 'alice@example.com',
        to: ['me@example.com'],
        cc: [],
        bcc: [],
        subject: 'Chào mừng đến với Flutter Mail!',
        content: 'Cảm ơn bạn đã đăng ký sử dụng dịch vụ của chúng tôi.',
        time: DateTime.now().subtract(Duration(minutes: 10)),
        starred: true,
        isRead: false,
      ),
      Email(
        id: '2',
        sender: 'bob@company.com',
        to: ['me@example.com'],
        cc: [],
        bcc: [],
        subject: 'Thông báo lịch họp',
        content: 'Cuộc họp sẽ diễn ra vào lúc 9h sáng mai tại phòng họp lớn.',
        time: DateTime.now().subtract(Duration(hours: 2)),
        starred: false,
        isRead: true,
      ),
      Email(
        id: '3',
        sender: 'support@flutter.dev',
        to: ['me@example.com'],
        cc: [],
        bcc: [],
        subject: 'Hỗ trợ Flutter',
        content: 'Bạn cần hỗ trợ gì về Flutter? Hãy liên hệ lại với chúng tôi.',
        time: DateTime.now().subtract(Duration(days: 1)),
        starred: false,
        isRead: false,
      ),
      Email(
        id: '7',
        sender: 'marketing@shop.com',
        to: ['me@example.com'],
        cc: [],
        bcc: [],
        subject: 'Khuyến mãi tháng 7',
        content: 'Nhận ngay ưu đãi 50% cho đơn hàng đầu tiên!',
        time: DateTime.now().subtract(Duration(hours: 5)),
        starred: false,
        isRead: false,
      ),
      Email(
        id: '8',
        sender: 'friend@zalo.com',
        to: ['me@example.com'],
        cc: [],
        bcc: [],
        subject: 'Hẹn cafe cuối tuần',
        content: 'Cuối tuần này bạn có rảnh không? Mình mời bạn cafe nhé!',
        time: DateTime.now().subtract(Duration(days: 1, hours: 3)),
        starred: true,
        isRead: false,
      ),
      Email(
        id: '9',
        sender: 'newsletter@flutter.dev',
        to: ['me@example.com'],
        cc: [],
        bcc: [],
        subject: 'Bản tin Flutter tháng 7',
        content: 'Cập nhật mới nhất về Flutter và các sự kiện sắp tới.',
        time: DateTime.now().subtract(Duration(days: 2)),
        starred: false,
        isRead: false,
      ),
      Email(
        id: '10',
        sender: 'colleague@work.com',
        to: ['me@example.com'],
        cc: [],
        bcc: [],
        subject: 'Tài liệu dự án',
        content: 'Mình gửi bạn file tài liệu dự án mới nhất.',
        time: DateTime.now().subtract(Duration(hours: 7)),
        starred: false,
        isRead: true,
      ),
    ]);
    _sent.addAll([
      Email(
        id: '4',
        sender: 'me@example.com',
        to: ['alice@example.com'],
        cc: [],
        bcc: [],
        subject: 'Gửi tài liệu',
        content: 'Mình gửi bạn file tài liệu như đã trao đổi.',
        time: DateTime.now().subtract(Duration(hours: 3)),
        starred: false,
        isRead: true,
      ),
      Email(
        id: '11',
        sender: 'me@example.com',
        to: ['bob@company.com'],
        cc: [],
        bcc: [],
        subject: 'Báo cáo tuần',
        content: 'Đây là báo cáo công việc tuần này.',
        time: DateTime.now().subtract(Duration(hours: 8)),
        starred: false,
        isRead: true,
      ),
    ]);
    _drafts.addAll([
      Email(
        id: '5',
        sender: 'me@example.com',
        to: ['bob@company.com'],
        cc: [],
        bcc: [],
        subject: 'Nháp: Báo cáo tuần',
        content: 'Đây là nội dung báo cáo tuần, sẽ hoàn thiện sau.',
        time: DateTime.now().subtract(Duration(hours: 1)),
        starred: false,
        isRead: false,
        isDraft: true,
      ),
      Email(
        id: '12',
        sender: 'me@example.com',
        to: ['alice@example.com'],
        cc: [],
        bcc: [],
        subject: 'Nháp: Kế hoạch tháng 8',
        content: 'Kế hoạch tháng 8 sẽ được cập nhật sau.',
        time: DateTime.now().subtract(Duration(hours: 2)),
        starred: false,
        isRead: false,
        isDraft: true,
      ),
    ]);
    _trash.addAll([
      Email(
        id: '6',
        sender: 'spam@unknown.com',
        to: ['me@example.com'],
        cc: [],
        bcc: [],
        subject: 'Bạn đã trúng thưởng!',
        content: 'Chúc mừng bạn đã trúng thưởng 1 tỷ đồng!',
        time: DateTime.now().subtract(Duration(days: 2)),
        starred: false,
        isRead: true,
      ),
      Email(
        id: '13',
        sender: 'ads@shop.com',
        to: ['me@example.com'],
        cc: [],
        bcc: [],
        subject: 'Quảng cáo sản phẩm mới',
        content: 'Khám phá sản phẩm mới với giá ưu đãi!',
        time: DateTime.now().subtract(Duration(days: 3)),
        starred: false,
        isRead: true,
      ),
    ]);
  }

  // Thêm email vào inbox (giả lập nhận email)
  void receiveEmail(Email email) {
    _inbox.insert(0, email);
    _notifyListeners();
    // Auto answer nếu bật
    if (_autoAnswerEnabled) {
      final reply = Email(
        id: const Uuid().v4(),
        sender: 'me@example.com',
        to: [email.sender],
        cc: [],
        bcc: [],
        subject: 'Re: ${email.subject}',
        content: _autoAnswerContent,
        time: DateTime.now(),
        isRead: true,
      );
      _sent.insert(0, reply);
      // Có thể notifyListeners hoặc callback nếu muốn
    }
  }

  // Gửi email
  void sendEmail({
    required String sender,
    required List<String> to,
    List<String>? cc,
    List<String>? bcc,
    required String subject,
    required String content,
    List<String>? attachments,
    List<String>? labels,
  }) {
    final email = Email(
      id: const Uuid().v4(),
      sender: sender,
      to: to,
      cc: cc ?? [],
      bcc: bcc ?? [],
      subject: subject,
      content: content,
      time: DateTime.now(),
      attachments: attachments ?? [],
      labels: labels ?? [],
      isRead: true,
    );
    _sent.insert(0, email);
  }

  // Lưu nháp
  void saveDraft(Email email) {
    final index = _drafts.indexWhere((e) => e.id == email.id);
    if (index >= 0) {
      _drafts[index] = email;
    } else {
      _drafts.insert(0, email);
    }
  }

  // Xóa email (chuyển vào trash)
  void moveToTrash(Email email) {
    _inbox.removeWhere((e) => e.id == email.id);
    _sent.removeWhere((e) => e.id == email.id);
    _drafts.removeWhere((e) => e.id == email.id);
    _trash.insert(0, email);
  }

  // Gắn/bỏ sao
  void toggleStar(Email email) {
    email.starred = !email.starred;
  }

  // Đánh dấu đã đọc/chưa đọc
  void markRead(Email email, bool read) {
    email.isRead = read;
  }

  // Trả lời email
  Email replyTo(Email original, String sender, String content) {
    return Email(
      id: const Uuid().v4(),
      sender: sender,
      to: [original.sender],
      cc: [],
      bcc: [],
      subject: 'Re: ${original.subject}',
      content: content,
      time: DateTime.now(),
      isRead: true,
    );
  }

  // Chuyển tiếp email
  Email forward(Email original, String sender, List<String> to, String content) {
    return Email(
      id: const Uuid().v4(),
      sender: sender,
      to: to,
      cc: [],
      bcc: [],
      subject: 'Fwd: ${original.subject}',
      content: '$content\n\n--- Forwarded message ---\n${original.content}',
      time: DateTime.now(),
      isRead: true,
    );
  }

  // Gán nhãn
  void assignLabel(Email email, String label) {
    if (!email.labels.contains(label)) {
      email.labels.add(label);
    }
  }

  // Xóa nhãn
  void removeLabel(Email email, String label) {
    email.labels.remove(label);
  }

  // Đính kèm file (mock)
  void addAttachment(Email email, String fileName) {
    email.attachments.add(fileName);
  }

  void deleteEmailPermanently(Email email) {
    _trash.removeWhere((e) => e.id == email.id);
    _notifyListeners();
  }

  void notifyListeners() => _notifyListeners();
} 