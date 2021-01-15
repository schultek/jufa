import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../supply_models.dart';
import '../../supply_repository.dart';
import '../edit_shopping_list_screen.dart';

class ShoppingListDialog extends StatefulWidget {
  final String id;
  const ShoppingListDialog(this.id);

  @override
  _ShoppingListDialogState createState() => _ShoppingListDialogState();

  static Future<void> open(BuildContext context, String id) async {
    await showDialog(
      context: context,
      builder: (_context) => SupplyProvider.of(context, child: ShoppingListDialog(id)),
    );
  }
}

class _ShoppingListDialogState extends State<ShoppingListDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Selector<SupplyRepository, ArticleList>(
        builder: (BuildContext context, ArticleList list, _) {
          return Text(list.name);
        },
        selector: (BuildContext context, SupplyRepository repo) {
          return repo.getArticleListById(widget.id);
        },
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        child: Selector<SupplyRepository, ArticleList>(
          builder: (BuildContext context, ArticleList list, _) {
            return ListView.builder(
              itemCount: list.entries.length,
              itemBuilder: (BuildContext context, int index) {
                return Selector<SupplyRepository, Article>(
                  builder: (BuildContext context, Article article, _) {
                    var child = CheckboxListTile(
                      title: Text(article.name),
                      value: list.entries[index].checked,
                      onChanged: (value) {
                        list.entries[index].checked = value ?? false;
                        Provider.of<SupplyRepository>(context, listen: false).updateShoppingList(list);
                      },
                      subtitle: Text("${list.entries[index].amount} ${list.entries[index].unit}"),
                    );

                    if (index == 0 ||
                        Provider.of<SupplyRepository>(context, listen: false)
                                .getArticleById(list.entries[index - 1].articleId)
                                .category !=
                            article.category) {
                      return Column(
                        children: [
                          Text(article.category, style: const TextStyle(fontWeight: FontWeight.bold)),
                          child,
                        ],
                      );
                    } else {
                      return child;
                    }
                  },
                  selector: (BuildContext context, SupplyRepository repo) {
                    return repo.getArticleById(list.entries[index].articleId);
                  },
                );
              },
            );
          },
          selector: (BuildContext context, SupplyRepository repo) {
            var list = repo.getArticleListById(widget.id);
            list.entries.sort((a, b) {
              var articleA = repo.getArticleById(a.articleId);
              var articleB = repo.getArticleById(b.articleId);
              return articleA.category.compareTo(articleB.category);
            });
            return list;
          },
        ),
      ),
      actions: <Widget>[
        FloatingActionButton(
          onPressed: () {
            var list = Provider.of<SupplyRepository>(context, listen: false).getArticleListById(widget.id);
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => SupplyProvider.of(context, child: EditShoppingListPage(list))),
            );
          },
          child: const Icon(Icons.edit),
        ),
      ],
    );
  }
}
