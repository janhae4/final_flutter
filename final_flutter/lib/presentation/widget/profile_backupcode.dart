// File: presentation/widgets/backup_code_item.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BackupCodeItem extends StatefulWidget {
  final String code;
  final int index;

  const BackupCodeItem({super.key, required this.code, required this.index});

  @override
  State<BackupCodeItem> createState() => _BackupCodeItemState();
}

class _BackupCodeItemState extends State<BackupCodeItem>
    with SingleTickerProviderStateMixin {
  bool _isCopied = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Color constants
  static const primaryColor = Color(0xFF6C63FF);
  static const secondaryColor = Color(0xFF4CAF50);
  static const cardColor = Colors.white;
  static const textPrimary = Color(0xFF2D3748);
  static const textSecondary = Color(0xFF718096);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _copyCode() async {
    await Clipboard.setData(ClipboardData(text: widget.code));

    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    setState(() {
      _isCopied = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isCopied = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: _copyCode,
            child: Container(
              decoration: BoxDecoration(
                color: _isCopied 
                    ? secondaryColor.withAlpha((255*0.1).toInt()) 
                    : cardColor,
                border: Border.all(
                  color: _isCopied 
                      ? secondaryColor.withAlpha((255*0.5).toInt()) 
                      : primaryColor.withAlpha((255*0.2).toInt()),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _isCopied 
                        ? secondaryColor.withAlpha((255*0.1).toInt())
                        : primaryColor.withAlpha((255*0.08).toInt()),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: _isCopied ? secondaryColor : primaryColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _isCopied
                                  ? secondaryColor.withAlpha((255*0.2).toInt())
                                  : primaryColor.withAlpha((255*0.2).toInt()),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${widget.index}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _isCopied 
                                      ? secondaryColor 
                                      : primaryColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.code,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'monospace',
                                color: _isCopied 
                                    ? textPrimary 
                                    : textPrimary,
                              ),
                            ),
                          ),
                          Icon(
                            _isCopied ? Icons.check_circle : Icons.copy,
                            size: 16,
                            color: _isCopied 
                                ? secondaryColor 
                                : textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}