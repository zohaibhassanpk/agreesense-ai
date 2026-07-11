import '../../domain/entities/alert_section.dart';
import 'alert_item_model.dart';

class AlertSectionModel extends AlertSection {
  const AlertSectionModel({
    required super.label,
    required List<AlertItemModel> super.items,
    super.isHistorical,
  });
}
