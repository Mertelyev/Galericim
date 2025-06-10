import 'package:flutter/material.dart';

class PaginatedListView extends StatefulWidget {
  final List<dynamic> items;
  final Widget Function(BuildContext context, int index, dynamic item)
      itemBuilder;
  final int itemsPerPage;
  final Widget? loadingWidget;
  final Widget? emptyWidget;

  const PaginatedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.itemsPerPage = 20,
    this.loadingWidget,
    this.emptyWidget,
  });

  @override
  State<PaginatedListView> createState() => _PaginatedListViewState();
}

class _PaginatedListViewState extends State<PaginatedListView> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (_isLoadingMore) return;

    final totalItems = widget.items.length;
    final maxPages = (totalItems / widget.itemsPerPage).ceil();

    if (_currentPage >= maxPages) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    // Simulate loading delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    });
  }

  List<dynamic> get _visibleItems {
    final endIndex = _currentPage * widget.itemsPerPage;
    return widget.items.take(endIndex).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return widget.emptyWidget ?? const SizedBox.shrink();
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _visibleItems.length,
            itemBuilder: (context, index) {
              return widget.itemBuilder(context, index, _visibleItems[index]);
            },
          ),
        ),
        if (_isLoadingMore)
          Padding(
            padding: const EdgeInsets.all(16),
            child: widget.loadingWidget ?? const CircularProgressIndicator(),
          ),
      ],
    );
  }
}
