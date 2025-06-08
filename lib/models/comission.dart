class Commission {
  final dynamic commissionId;
  final String productName;
  final String penitipName;
  final int amount;
  final String date;
  final String status;
  final String imagePath;

  Commission({
    required this.commissionId,
    required this.productName,
    required this.penitipName,
    required this.amount,
    required this.date,
    required this.status,
    required this.imagePath,
  });
}
