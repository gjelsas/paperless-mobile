import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:pdfx/pdfx.dart';

class FileViewer extends StatelessWidget {
  final FutureOr<Uint8List> Function(BuildContext context) fileProvider;
  final Axis scrollDirection;
  const FileViewer({
    super.key,
    required this.fileProvider,
    required this.scrollDirection,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: Future.value(fileProvider(context)),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return _LoadedFileViewer(
          bytes: snapshot.data!,
          scrollDirection: scrollDirection,
        );
      },
    );
  }
}

class _LoadedFileViewer extends StatefulWidget {
  final Uint8List bytes;
  final Axis scrollDirection;

  const _LoadedFileViewer({
    required this.bytes,
    required this.scrollDirection,
  });

  @override
  State<_LoadedFileViewer> createState() => _LoadedFileViewerState();
}

class _LoadedFileViewerState extends State<_LoadedFileViewer> {
  late final PdfControllerPinch _controller;

  int _currentPage = 1;
  int? _totalPages;

  @override
  void initState() {
    super.initState();
    _controller = PdfControllerPinch(
      document: PdfDocument.openData(widget.bytes),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pageTransitionDuration = MediaQuery.disableAnimationsOf(context)
        ? 0.milliseconds
        : 100.milliseconds;
    final canGoToNextPage = _totalPages != null && _currentPage < _totalPages!;
    final canGoToPreviousPage =
        _controller.pagesCount != null && _currentPage > 1;
    final bottomControls = BottomAppBar(
      child: Row(
        children: [
          Flexible(
            child: Row(
              children: [
                IconButton.filled(
                  onPressed: canGoToPreviousPage
                      ? () async {
                          await _controller.previousPage(
                            duration: pageTransitionDuration,
                            curve: Curves.easeOut,
                          );
                        }
                      : null,
                  icon: const Icon(Icons.arrow_left),
                ),
                const SizedBox(width: 16),
                IconButton.filled(
                  onPressed: canGoToNextPage
                      ? () async {
                          await _controller.nextPage(
                            duration: pageTransitionDuration,
                            curve: Curves.easeOut,
                          );
                        }
                      : null,
                  icon: const Icon(Icons.arrow_right),
                ),
              ],
            ),
          ),
          PdfPageNumber(
            controller: _controller,
            builder: (context, loadingState, page, pagesCount) {
              if (loadingState != PdfLoadingState.success) {
                return const Text("-/-");
              }
              return Text(
                "$page/$pagesCount",
                style: Theme.of(context).textTheme.titleMedium,
              ).padded();
            },
          ),
        ],
      ),
    );
    return Scaffold(
      bottomNavigationBar: bottomControls,
      // backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      body: PdfViewPinch(
        controller: _controller,
        padding: 8,
        scrollDirection: Axis.horizontal,
        onDocumentLoaded: (document) {
          if (mounted) {
            setState(() {
              _totalPages = document.pagesCount;
            });
          }
        },
        onPageChanged: (page) {
          if (mounted) {
            setState(() {
              _currentPage = page;
            });
          }
        },
      ),
    );
  }
}
