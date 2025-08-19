import 'package:flutter/material.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';

void showQuantityInputSheet(
    BuildContext context,
    ItemController itemController,
    int? stock,
    int? quantityLimit,
    ) {
  final countController = TextEditingController(
    text: "${itemController.quantity ?? 1}",
  );

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Enter Quantity",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: countController,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onSubmitted: (_) {
                  _applyQuantityChange(
                    context,
                    countController,
                    itemController,
                    stock,
                    quantityLimit,
                  );
                },
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () {
                  _applyQuantityChange(
                    context,
                    countController,
                    itemController,
                    stock,
                    quantityLimit,
                  );
                },
                child: const Text("Update"),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _applyQuantityChange(
    BuildContext context,
    TextEditingController countController,
    ItemController itemController,
    int? stock,
    int? quantityLimit,
    ) {
  int enteredValue = int.tryParse(countController.text) ?? 1;

  // Apply limits
  if (stock != null && enteredValue > stock) {
    enteredValue = stock;
  }
  if (quantityLimit != null && enteredValue > quantityLimit) {
    enteredValue = quantityLimit;
  }
  if (enteredValue < 1) {
    enteredValue = 1;
  }

  // Directly set quantity
  itemController.quantityy = enteredValue;

  // Refresh UI if using GetX
  itemController.update();

  Navigator.pop(context);
}
