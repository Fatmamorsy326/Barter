import 'package:barter/core/resources/colors_manager.dart';
import 'package:barter/core/routes_manager/routes.dart';
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
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ColorsManager.purpleFor(context)),
          ),
        ),
      );
    }

    if (_exchange == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Exchange Details')),
        body: Center(
          child: Text(
            'Exchange not found',
            style: TextStyle(color: ColorsManager.textFor(context)),
          ),
        ),
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
              icon: const Icon(Icons.more_vert_rounded),
              onPressed: _showActions,
            ),
          if (isAccepted)
            IconButton(
              icon: const Icon(Icons.more_vert_rounded),
              onPressed: _showActiveExchangeActions,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: REdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            SizedBox(height: 24.h),
            _buildExchangeItems(),
            SizedBox(height: 24.h),
            _buildOtherUserInfo(),
            if (_exchange!.notes != null && _exchange!.notes!.isNotEmpty) ...[
              SizedBox(height: 24.h),
              _buildNotesCard(),
            ],
            if (isAccepted) ...[
              SizedBox(height: 24.h),
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
    return Container(
      padding: REdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _exchange!.status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: _exchange!.status.color.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: REdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorsManager.cardFor(context),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _exchange!.status.color.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
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
                    fontSize: 14.sp,
                    color: ColorsManager.textSecondaryFor(context),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeItems() {
    final userId = FirebaseService.currentUser!.uid;
    final isProposer = _exchange!.proposedBy == userId;

    final myItems = isProposer ? _exchange!.itemsOffered : _exchange!.itemsRequested;
    final theirItems = isProposer ? _exchange!.itemsRequested : _exchange!.itemsOffered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: REdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'The Deal',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: ColorsManager.textFor(context),
            ),
          ),
        ),
        Container(
          padding: REdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ColorsManager.cardFor(context),
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: ColorsManager.shadowFor(context),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildItemsList(myItems, 'You Offer'),
              Padding(
                padding: REdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: ColorsManager.dividerFor(context))),
                    Padding(
                      padding: REdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: REdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ColorsManager.purpleFor(context).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.swap_vert_rounded,
                          color: ColorsManager.purpleFor(context),
                          size: 24.sp,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: ColorsManager.dividerFor(context))),
                  ],
                ),
              ),
              _buildItemsList(theirItems, 'You Receive'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemsList(List<ExchangeItem> items, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: ColorsManager.textSecondaryFor(context),
          ),
        ),
        SizedBox(height: 12.h),
        if (items.isEmpty)
          Text(
            'No items selected',
            style: TextStyle(
              color: ColorsManager.textSecondaryFor(context),
              fontStyle: FontStyle.italic,
            ),
          )
        else if (items.length == 1)
          _buildSingleItem(items.first)
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 16.h,
              childAspectRatio: 0.8,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _buildSingleItem(items[index]);
            },
          ),
      ],
    );
  }

  Widget _buildSingleItem(ExchangeItem item) {
    return Column(
      children: [
        Container(
          height: 120.h,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: ColorsManager.shadowFor(context),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: Image.network(
              item.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: ColorsManager.shimmerBaseFor(context),
                child: Icon(
                  Icons.image_not_supported_rounded,
                  color: ColorsManager.textSecondaryFor(context),
                ),
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
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: ColorsManager.textFor(context),
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildOtherUserInfo() {
    return Container(
      padding: REdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorsManager.cardFor(context),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.shadowFor(context),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: REdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: ColorsManager.purpleFor(context),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 26.r,
              backgroundColor: ColorsManager.purpleFor(context).withOpacity(0.1),
              backgroundImage: _otherUser?.photoUrl != null && _otherUser!.photoUrl!.isNotEmpty
                  ? NetworkImage(_otherUser!.photoUrl!)
                  : null,
              child: _otherUser?.photoUrl == null || _otherUser!.photoUrl!.isEmpty
                  ? Text(
                      _otherUser?.name[0].toUpperCase() ?? 'U',
                      style: TextStyle(
                        color: ColorsManager.purpleFor(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 20.sp,
                      ),
                    )
                  : null,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _otherUser?.name ?? 'User',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                    color: ColorsManager.textFor(context),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Exchange Partner',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: ColorsManager.textSecondaryFor(context),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                Routes.chatDetail,
                arguments: _exchange!.chatId,
              );
            },
            style: IconButton.styleFrom(
              backgroundColor: ColorsManager.purpleFor(context).withOpacity(0.1),
              padding: REdgeInsets.all(12),
            ),
            icon: Icon(
              Icons.chat_bubble_rounded,
              color: ColorsManager.purpleFor(context),
              size: 22.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      padding: REdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorsManager.cardFor(context),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.shadowFor(context),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote_rounded, color: ColorsManager.purpleFor(context), size: 24.sp),
              SizedBox(width: 8.w),
              Text(
                'Message',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: ColorsManager.textFor(context),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            _exchange!.notes!,
            style: TextStyle(
              fontSize: 15.sp,
              color: ColorsManager.textSecondaryFor(context),
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: REdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Meeting Details',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: ColorsManager.textFor(context),
            ),
          ),
        ),
        Container(
          padding: REdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ColorsManager.cardFor(context),
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: ColorsManager.shadowFor(context),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              TextFormField(
                controller: _locationController,
                style: TextStyle(color: ColorsManager.textFor(context)),
                decoration: InputDecoration(
                  labelText: 'Meeting Location',
                  labelStyle: TextStyle(color: ColorsManager.textSecondaryFor(context)),
                  prefixIcon: Icon(Icons.location_on_rounded, color: ColorsManager.purpleFor(context)),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.check_circle_rounded, color: ColorsManager.purpleFor(context)),
                    onPressed: _saveMeetingLocation,
                  ),
                  filled: true,
                  fillColor: ColorsManager.backgroundFor(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: BorderSide(color: ColorsManager.purpleFor(context), width: 1.5),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              InkWell(
                onTap: _selectDateTime,
                borderRadius: BorderRadius.circular(16.r),
                child: Container(
                  padding: REdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ColorsManager.backgroundFor(context),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, color: ColorsManager.purpleFor(context)),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date & Time',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: ColorsManager.textSecondaryFor(context),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              _selectedDate != null
                                  ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} at ${_selectedDate!.hour}:${_selectedDate!.minute.toString().padLeft(2, '0')}'
                                  : 'Select meeting time',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: ColorsManager.textFor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.edit_rounded, color: ColorsManager.textSecondaryFor(context), size: 20.sp),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(bool isProposer, bool isPending, bool isAccepted) {
    if (!isPending && !isAccepted) return const SizedBox.shrink();
    if (isPending && isProposer) {
      return Container(
        padding: REdgeInsets.fromLTRB(20, 20, 20, 34),
        decoration: BoxDecoration(
          color: ColorsManager.cardFor(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
          boxShadow: [
            BoxShadow(
              color: ColorsManager.shadowFor(context),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _cancelPendingRequest,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: BorderSide(color: Colors.red.withOpacity(0.5), width: 1.5),
              padding: REdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            ),
            child: const Text('Cancel Request'),
          ),
        ),
      );
    }

    return Container(
      padding: REdgeInsets.fromLTRB(20, 20, 20, 34),
      decoration: BoxDecoration(
        color: ColorsManager.cardFor(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.shadowFor(context),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: _buildActionButtons(isProposer, isPending, isAccepted),
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
                side: BorderSide(color: Colors.red.withOpacity(0.5), width: 1.5),
                padding: REdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              ),
              child: const Text('Decline'),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _acceptExchange,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.purpleFor(context),
                foregroundColor: Colors.white,
                padding: REdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              ),
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
            backgroundColor: hasConfirmed ? ColorsManager.grey : Colors.green,
            foregroundColor: Colors.white,
            padding: REdgeInsets.symmetric(vertical: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hasConfirmed) ...[
                const Icon(Icons.check_circle_rounded, size: 20),
                SizedBox(width: 8.w),
              ],
              Text(
                hasConfirmed ? 'Confirmed' : 'Confirm Exchange Complete',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
        return 'Exchange accepted! Arrange meetup details below.';
      case ExchangeStatus.completed:
        return 'Exchange completed successfully!';
      case ExchangeStatus.cancelled:
        return 'This exchange was cancelled.';
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
        backgroundColor: ColorsManager.cardFor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text('Decline Exchange', style: TextStyle(color: ColorsManager.textFor(context))),
        content: Text(
          'Are you sure you want to decline this exchange?',
          style: TextStyle(color: ColorsManager.textSecondaryFor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: ColorsManager.textSecondaryFor(context))),
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
        UiUtils.showToastMessage('Exchange declined', ColorsManager.grey);
      } catch (e) {
        UiUtils.hideDialog(context);
        UiUtils.showToastMessage('Failed to decline exchange', Colors.red);
      }
    }
  }

  Future<void> _cancelPendingRequest() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ColorsManager.cardFor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text('Cancel Request', style: TextStyle(color: ColorsManager.textFor(context))),
        content: Text(
          'Are you sure you want to cancel this exchange request?',
          style: TextStyle(color: ColorsManager.textSecondaryFor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('No, Keep It', style: TextStyle(color: ColorsManager.textSecondaryFor(context))),
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
        UiUtils.showToastMessage('Request cancelled', Colors.orange);
      } catch (e) {
        UiUtils.hideDialog(context);
        UiUtils.showToastMessage('Failed to cancel request', Colors.red);
      }
    }
  }

  Future<void> _cancelActiveExchange() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ColorsManager.cardFor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text('Cancel Exchange', style: TextStyle(color: ColorsManager.textFor(context))),
        content: Text(
          'Are you sure you want to cancel this exchange?\n\n'
              'Both items will become available again and can be exchanged with others.',
          style: TextStyle(color: ColorsManager.textSecondaryFor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('No, Keep It', style: TextStyle(color: ColorsManager.textSecondaryFor(context))),
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).brightness == Brightness.dark
                ? ColorScheme.dark(
              primary: ColorsManager.purpleFor(context),
              onPrimary: Colors.white,
              surface: ColorsManager.cardFor(context),
              onSurface: ColorsManager.textFor(context),
            )
                : ColorScheme.light(
              primary: ColorsManager.purpleFor(context),
              onPrimary: Colors.white,
              surface: ColorsManager.white,
              onSurface: ColorsManager.black,
            ),
            dialogBackgroundColor: ColorsManager.cardFor(context),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).brightness == Brightness.dark
                  ? ColorScheme.dark(
                primary: ColorsManager.purpleFor(context),
                onPrimary: Colors.white,
                surface: ColorsManager.cardFor(context),
                onSurface: ColorsManager.textFor(context),
              )
                  : ColorScheme.light(
                primary: ColorsManager.purpleFor(context),
                onPrimary: Colors.white,
                surface: ColorsManager.white,
                onSurface: ColorsManager.black,
              ),
              dialogBackgroundColor: ColorsManager.cardFor(context),
            ),
            child: child!,
          );
        },
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
      backgroundColor: ColorsManager.cardFor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: REdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: ColorsManager.dividerFor(context),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 24.h),
              ListTile(
                leading: Container(
                  padding: REdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Colors.green),
                ),
                title: Text('Accept Exchange', style: TextStyle(fontWeight: FontWeight.w600, color: ColorsManager.textFor(context))),
                onTap: () {
                  Navigator.pop(ctx);
                  _acceptExchange();
                },
              ),
              SizedBox(height: 8.h),
              ListTile(
                leading: Container(
                  padding: REdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cancel_rounded, color: Colors.red),
                ),
                title: Text('Decline Exchange', style: TextStyle(fontWeight: FontWeight.w600, color: ColorsManager.textFor(context))),
                onTap: () {
                  Navigator.pop(ctx);
                  _rejectExchange();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActiveExchangeActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ColorsManager.cardFor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: REdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: ColorsManager.dividerFor(context),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 24.h),
              ListTile(
                leading: Container(
                  padding: REdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat_bubble_rounded, color: Colors.blue),
                ),
                title: Text('Open Chat', style: TextStyle(fontWeight: FontWeight.w600, color: ColorsManager.textFor(context))),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, Routes.chatDetail, arguments: _exchange!.chatId);
                },
              ),
              SizedBox(height: 8.h),
              ListTile(
                leading: Container(
                  padding: REdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cancel_rounded, color: Colors.red),
                ),
                title: Text('Cancel Exchange', style: TextStyle(fontWeight: FontWeight.w600, color: ColorsManager.textFor(context))),
                subtitle: Text('Items will become available again', style: TextStyle(color: ColorsManager.textSecondaryFor(context))),
                onTap: () {
                  Navigator.pop(ctx);
                  _cancelActiveExchange();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}