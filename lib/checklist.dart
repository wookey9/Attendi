

class CheckListItem{
  CheckListItem({required this.name, required this.writetime, required this.checked});

  String name;
  DateTime writetime;
  Map<DateTime, bool> checked;
}