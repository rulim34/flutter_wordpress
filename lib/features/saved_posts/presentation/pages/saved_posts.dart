/* 
 * Copyright (C) 2021  Ahmad Rulim
 * 
 * This file is part of Flutter WordPress.
 * 
 * Flutter WordPress is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * Flutter WordPress is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with Flutter WordPress.  If not, see <https://www.gnu.org/licenses/>.
 * 
 * @license GPL-3.0-or-later <https://spdx.org/licenses/GPL-3.0-or-later.html>
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../../core/entities/post.dart';
import '../../../../core/widgets/error_indicator.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/post_box.dart';
import '../../../../providers.dart';
import '../../../single_post/presentation/pages/single_post.dart';
import '../notifier/notifier.dart';

class SavedPosts extends StatefulWidget {
  const SavedPosts({
    Key? key,
  }) : super(
          key: key,
        );

  @override
  _SavedPosts createState() => _SavedPosts();
}

class _SavedPosts extends State<SavedPosts> {
  final PagingController<int, Post> _pagingController = PagingController(
    firstPageKey: 0,
  );

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      context.read(savedPostsProvider.notifier).fetchPage(
            pageKey,
            _pagingController.itemList?.length ?? 0,
          );
    });
  }

  @override
  void dispose() {
    super.dispose();
    _pagingController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProviderListener(
      provider: savedPostsProvider,
      onChange: (context, state) {
        if (state is SavedPostsAppend) {
          _pagingController.appendPage(state.posts, state.nextPageKey);
        } else if (state is SavedPostsAppendLast) {
          _pagingController.appendLastPage(state.posts);
        } else if (state is SavedPostsError) {
          _pagingController.error = state.message;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          title: Text(
            'Kiriman Tersimpan',
            style: Theme.of(context).primaryTextTheme.headline1,
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
          ),
          child: RefreshIndicator(
            onRefresh: () => Future.sync(
              () {
                context.read(savedPostsProvider.notifier).forceRefresh = true;

                _pagingController.refresh();
              },
            ),
            child: PagedListView<int, Post>(
              pagingController: _pagingController,
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
              builderDelegate: PagedChildBuilderDelegate(
                noItemsFoundIndicatorBuilder: (context) {
                  return const ErrorIndicator(
                    message:
                        'Belum ada kiriman tersimpan.\nMulailah menyimpan!',
                    image: 'assets/no_data.png',
                  );
                },
                firstPageProgressIndicatorBuilder: (context) {
                  return const LoadingIndicator(
                    count: 5,
                    type: LoadingType.post,
                  );
                },
                itemBuilder: (context, post, index) {
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SinglePost(
                            post: post,
                          ),
                        ),
                      );
                    },
                    child: PostBox(
                      post: post,
                    ),
                  );
                },
                firstPageErrorIndicatorBuilder: (context) {
                  return ErrorIndicator(
                    message: 'Gagal memuat data.',
                    image: 'assets/error.png',
                    onTryAgain: () {
                      _pagingController.refresh();
                    },
                  );
                },
                newPageProgressIndicatorBuilder: (context) {
                  return const LoadingIndicator(
                    count: 3,
                    type: LoadingType.post,
                  );
                },
                newPageErrorIndicatorBuilder: (context) {
                  return ErrorIndicator(
                    message: 'Gagal memuat data.',
                    image: 'assets/error.png',
                    onTryAgain: () {
                      _pagingController.retryLastFailedRequest();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}