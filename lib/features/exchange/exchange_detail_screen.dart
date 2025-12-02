// ============================================
// FILE: lib/features/exchange/exchange_detail_screen.dart
// ============================================

import 'package:barter/core/resources/colors_manager.dart';
import 'package:barter/core/ui_utils.dart';
import 'package:barter/firebase/firebase_service.dart';
import 'package:barter/model/exchange_model.dart';
import 'package:barter/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ExchangeDetailScreen extends StatefulWidget {
  final String exchangeId;

  const ExchangeDetailScreen({super.key, required this.exchangeId});

  @override
  State<ExchangeDetailScreen> createState() => _ExchangeDetailScreenState();
}

class _ExchangeDetailScreenState extends State<ExchangeDetailScreen> {
  ExchangeModel? _exchange;
  UserModel? _otherUser;
  bool _isLoading = true;
  final _locationController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadExchange();
  }

  Future<void> _loadExchange() async {
    try {
      final exchange = await FirebaseService.getExchangeById(widget.exchangeId);
      if (exchange != null) {
        final userId = FirebaseService.currentUser!.uid;
        final otherUserId = exchange.proposedBy == userId
            ? exchange.proposedTo
            : exchange.proposedBy;

        final otherUser = await FirebaseService.getUserById(otherUserId);

        if (mounted) {
          setState(() {
            _exchange = exchange;
            _otherUser = otherUser;
            _locationController.text = exchange.meetingLocation ?? '';
            _selectedDate = exchange.meetingDate;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading exchange: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Exchange Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_exchange == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Exchange Details')),
        body: const Center(child: Text('Exchange not found')),
      );
    }

    final userId = FirebaseService.currentUser!.uid;
    final isProposer = _exchange!.proposedBy == userId;
    final isPending = _exchange!.status == ExchangeStatus.pending;
    final isAccepted = _exchange!.status == ExchangeStatus.accepted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exchange Details'),
        actions: [
          if (isPending && !isProposer)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: _showActions,
            ),
          if (isAccepted)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: _showActiveExchangeActions,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: REdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            SizedBox(height: 16.h),
            _buildExchangeItems(),
            SizedBox(height: 16.h),
            _buildOtherUserInfo(),
            if (_exchange!.notes != null && _exchange!.notes!.isNotEmpty) ...[
              SizedBox(height: 16.h),
              _buildNotesCard(),
            ],
            if (isAccepted) ...[
              SizedBox(height: 16.h),
              _buildMeetingDetails(),
            ],
            SizedBox(height: 100.h),
          ],
        ),
      ),
      bottomSheet: _buildBottomActions(isProposer, isPending, isAccepted),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      color: _exchange!.status.color.withOpacity(0.1),
      child: Padding(
        padding: REdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: REdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _exchange!.status.color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _exchange!.status.icon,
                color: _exchange!.status.color,
                size: 28.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _exchange!.status.displayName,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: _exchange!.status.color,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _getStatusMessage(),
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExchangeItems() {
    final userId = FirebaseService.currentUser!.uid;
    final isProposer = _exchange!.proposedBy == userId;

    return Card(
      child: Padding(
        padding: REdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exchange Items',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _buildItemCard(
                    isProposer
                        ? _exchange!.itemOffered
                        : _exchange!.itemRequested,
                    'You offer',
                  ),
                ),
                Padding(
                  padding: REdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.swap_horiz,
                    color: ColorsManager.purple,
                    size: 32.sp,
                  ),
                ),
                Expanded(
                  child: _buildItemCard(
                    isProposer
                        ? _exchange!.itemRequested
                        : _exchange!.itemOffered,
                    'You receive',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(ExchangeItem item, String label) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          height: 120.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11.r),
            child: Image.network(
              item.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[200],
                child: Icon(Icons.image, color: Colors.grey),
              ),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          item.title,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildOtherUserInfo() {
    return Card(
      child: ListTile(
        contentPadding: REdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24.r,
          backgroundColor: ColorsManager.purple.withOpacity(0.1),
          backgroundImage: _otherUser?.photoUrl != null && _otherUser!.photoUrl!.isNotEmpty
              ? NetworkImage(_otherUser!.photoUrl!)
              : null,
          child: _otherUser?.photoUrl == null || _otherUser!.photoUrl!.isEmpty
              ? Text(
            _otherUser?.name[0].toUpperCase() ?? 'U',
            style: TextStyle(
              color: ColorsManager.purple,
              fontWeight: FontWeight.bold,
            ),
          )
              : null,
        ),
        title: Text(
          _otherUser?.name ?? 'User',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Exchange partner',
          style: TextStyle(fontSize: 12.sp),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.chat_bubble_outline),
          color: ColorsManager.purple,
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/chat-detail',
              arguments: _exchange!.chatId,
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotesCard() {
    return Card(
      child: Padding(
        padding: REdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.message, color: ColorsManager.purple, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  'Message',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              _exchange!.notes!,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingDetails() {
    return Card(
      child: Padding(
        padding: REdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meeting Details',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Meeting Location',
                prefixIcon: const Icon(Icons.location_on),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _saveMeetingLocation,
                ),
              ),
            ),
            SizedBox(height: 16.h),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(
                _selectedDate != null
                    ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} ${_selectedDate!.hour}:${_selectedDate!.minute.toString().padLeft(2, '0')}'
                    : 'Select meeting date & time',
              ),
              trailing: const Icon(Icons.edit),
              onTap: _selectDateTime,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(bool isProposer, bool isPending, bool isAccepted) {
    return Container(
      padding: REdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: _buildActionButtons(isProposer, isPending, isAccepted),
      ),
    );
  }

  Widget _buildActionButtons(bool isProposer, bool isPending, bool isAccepted) {
    if (isPending && !isProposer) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _rejectExchange,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              child: const Text('Decline'),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _acceptExchange,
              child: const Text('Accept Exchange'),
            ),
          ),
        ],
      );
    }

    if (isAccepted) {
      final hasConfirmed = _exchange!.confirmedBy.contains(
        FirebaseService.currentUser!.uid,
      );

      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: hasConfirmed ? null : _confirmCompletion,
          style: ElevatedButton.styleFrom(
            backgroundColor: hasConfirmed ? Colors.grey : Colors.green,
          ),
          child: Text(
            hasConfirmed
                ? 'Confirmed ✓'
                : 'Confirm Exchange Complete',
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  String _getStatusMessage() {
    switch (_exchange!.status) {
      case ExchangeStatus.pending:
        return 'Waiting for response...';
      case ExchangeStatus.accepted:
        return 'Exchange accepted! Arrange meetup details';
      case ExchangeStatus.completed:
        return 'Exchange completed successfully';
      case ExchangeStatus.cancelled:
        return 'This exchange was cancelled';
    }
  }

  Future<void> _acceptExchange() async {
    try {
      UiUtils.showLoading(context, false);
      await FirebaseService.acceptExchange(widget.exchangeId);
      UiUtils.hideDialog(context);
      await _loadExchange();
      UiUtils.showToastMessage('Exchange accepted!', Colors.green);
    } catch (e) {
      UiUtils.hideDialog(context);
      UiUtils.showToastMessage('Failed to accept exchange', Colors.red);
    }
  }

  Future<void> _rejectExchange() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline Exchange'),
        content: const Text('Are you sure you want to decline this exchange?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        UiUtils.showLoading(context, false);
        await FirebaseService.cancelExchange(widget.exchangeId);
        UiUtils.hideDialog(context);
        Navigator.pop(context);
        UiUtils.showToastMessage('Exchange declined', Colors.grey);
      } catch (e) {
        UiUtils.hideDialog(context);
        UiUtils.showToastMessage('Failed to decline exchange', Colors.red);
      }
    }
  }

  Future<void> _cancelActiveExchange() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Exchange'),
        content: const Text(
          'Are you sure you want to cancel this exchange?\n\n'
              'Both items will become available again and can be exchanged with others.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No, Keep It'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        UiUtils.showLoading(context, false);
        await FirebaseService.cancelExchange(widget.exchangeId);
        UiUtils.hideDialog(context);
        Navigator.pop(context);
        UiUtils.showToastMessage(
          'Exchange cancelled. Items are now available.',
          Colors.orange,
        );
      } catch (e) {
        UiUtils.hideDialog(context);
        UiUtils.showToastMessage('Failed to cancel exchange', Colors.red);
      }
    }
  }

  Future<void> _confirmCompletion() async {
    try {
      UiUtils.showLoading(context, false);
      await FirebaseService.confirmExchangeCompletion(widget.exchangeId);
      UiUtils.hideDialog(context);
      await _loadExchange();
      UiUtils.showToastMessage('Confirmed!', Colors.green);
    } catch (e) {
      UiUtils.hideDialog(context);
      UiUtils.showToastMessage('Failed to confirm', Colors.red);
    }
  }

  Future<void> _saveMeetingLocation() async {
    if (_locationController.text.trim().isEmpty) return;

    try {
      await FirebaseService.updateMeetingDetails(
        widget.exchangeId,
        _locationController.text.trim(),
        _selectedDate,
      );
      UiUtils.showToastMessage('Location saved', Colors.green);
    } catch (e) {
      UiUtils.showToastMessage('Failed to save location', Colors.red);
    }
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        final dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        setState(() => _selectedDate = dateTime);

        try {
          await FirebaseService.updateMeetingDetails(
            widget.exchangeId,
            _locationController.text.trim().isEmpty
                ? null
                : _locationController.text.trim(),
            dateTime,
          );
          UiUtils.showToastMessage('Meeting time saved', Colors.green);
        } catch (e) {
          UiUtils.showToastMessage('Failed to save time', Colors.red);
        }
      }
    }
  }

  void _showActions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Accept Exchange'),
              onTap: () {
                Navigator.pop(ctx);
                _acceptExchange();
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('Decline Exchange'),
              onTap: () {
                Navigator.pop(ctx);
                _rejectExchange();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showActiveExchangeActions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
              title: const Text('Open Chat'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/chat-detail', arguments: _exchange!.chatId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('Cancel Exchange'),
              subtitle: const Text('Items will become available again'),
              onTap: () {
                Navigator.pop(ctx);
                _cancelActiveExchange();
              },
            ),
          ],
        ),
      ),
    );
  }
}