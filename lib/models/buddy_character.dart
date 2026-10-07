enum BuddyCharacter {
  boy('boy', '元气男生', 'lib/static/water_buddy.png'),
  girl('girl', '活力女生', 'lib/static/water_buddy_girl.png'),
  yellow('yellow', '黄色小伙伴', 'lib/static/water_buddy_yellow.png');

  const BuddyCharacter(this.id, this.label, this.asset);
  final String id, label, asset;
  double get heightFactor => this == boy ? 1.3 : 1.5;
  double get seatOffset => switch (this) {
    boy => 80,
    girl => 90,
    yellow => 114,
  };

  static BuddyCharacter fromId(String? id) =>
      values.firstWhere((value) => value.id == id, orElse: () => boy);
}
