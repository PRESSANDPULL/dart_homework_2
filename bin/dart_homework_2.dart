import 'dart:io';
import 'dart:math';

// **캐릭터 클래스**
class Character {
  String name;
  int health;
  int attack;
  int defense;
  bool hasUsedItem = false; // 아이템 사용 여부

  Character(this.name, this.health, this.attack, this.defense);

  // **몬스터 공격**
  void attackMonster(Monster monster) {
    int damage = attack - monster.defense;
    if (damage < 0) damage = 0;
    monster.health -= damage;
    print("$name이(가) ${monster.name}에게 $damage 만큼의 데미지를 입혔어요!");
  }

  // **방어 (체력 회복)**
  void defend() {
    health += 5;
    print("$name이 방어했어요! 체력이 5 회복되었습니다. 현재 체력: $health");
  }

  // **아이템 사용 (공격력 2배 증가, 1회만 가능)**
  void useItem() {
    if (!hasUsedItem) {
      attack *= 2;
      hasUsedItem = true;
      print("$name이 아이템을 사용하여 공격력이 2배 증가했습니다! (현재 공격력: $attack)");
    } else {
      print("이미 아이템을 사용했습니다!");
    }
  }

  // **상태 출력**
  void showStatus() {
    print("[$name] 체력: $health, 공격력: $attack, 방어력: $defense");
  }
}

// **몬스터 클래스**
class Monster {
  String name;
  int health;
  int maxAttack;
  int defense = 0;
  int turnCounter = 0; // 턴 수 카운트

  Monster(this.name, this.health, this.maxAttack);

  // **캐릭터 공격**
  void attackCharacter(Character character) {
    int attackPower = Random().nextInt(maxAttack) + 1;
    int damage = attackPower - character.defense;
    if (damage < 0) damage = 0;

    character.health -= damage;
    print("$name이(가) ${character.name}에게 $damage 만큼의 데미지를 입혔어요!");
  }

  // **방어력 증가 (3턴마다)**
  void increaseDefense() {
    turnCounter++;
    if (turnCounter % 3 == 0) {
      defense += 2;
      print("$name의 방어력이 증가했습니다! 현재 방어력: $defense");
    }
  }

  // **상태 출력**
  void showStatus() {
    print("[$name] 체력: $health, 최대 공격력: $maxAttack, 방어력: $defense");
  }
}

// **캐릭터 데이터 로드**
Character? loadCharacterStats(String playerName) {
  try {
    final file = File('data/characters.txt');
    final contents = file.readAsStringSync();
    final stats = contents.split(',');

    if (stats.length != 3) throw FormatException('캐릭터 정보를 정상적으로 읽어오지 못 했어요.');

    int health = int.parse(stats[0]);
    int attack = int.parse(stats[1]);
    int defense = int.parse(stats[2]);

    print("\n캐릭터 데이터를 로드했어요!");

    // 30% 확률로 보너스 체력 +10 추가
    if (Random().nextDouble() < 0.3) {
      health += 10;
      print("🎉 보너스 체력을 얻었습니다! 현재 체력: $health");
    }

    return Character(playerName, health, attack, defense);
  } catch (e) {
    print('캐릭터 데이터를 불러오는 데 실패했어요: $e');
    return null;
  }
}

// **몬스터 데이터 로드**
List<Monster> loadMonsterStats() {
  List<Monster> monsters = [];
  try {
    final file = File('data/monsters.txt');
    final contents = file.readAsLinesSync();

    for (var line in contents) {
      final data = line.split(',');
      if (data.length != 3) throw FormatException('몬스터 정보를 정상적으로 읽어오지 못 했어요.');

      String name = data[0];
      int health = int.parse(data[1]);
      int maxAttack = int.parse(data[2]);

      monsters.add(Monster(name, health, maxAttack));
    }

    print("\n몬스터 데이터를 로드했어요!");
    return monsters;
  } catch (e) {
    print('몬스터 데이터를 불러오는 데 실패했어요: $e');
    return [];
  }
}

// **전투 시스템**
void battle(Character character, List<Monster> monsters) {
  while (character.health > 0 && monsters.isNotEmpty) {
    Monster monster = monsters[Random().nextInt(monsters.length)];
    print("\n⚔️ ${monster.name}이(가) 나타났다!");
    monster.showStatus();

    while (character.health > 0 && monster.health > 0) {
      character.showStatus();
      print("\n행동을 선택하세요: [1] 공격 / [2] 방어 / [3] 아이템 사용 / [exit] 게임 종료");
      String? input = stdin.readLineSync();

      if (input == "1") {
        character.attackMonster(monster);
      } else if (input == "2") {
        character.defend();
      } else if (input == "3") {
        character.useItem();
      } else if (input == "exit") {
        print("\n게임을 종료합니다. 처음부터 다시 시작합니다.");
        restartGame();
        return;
      } else {
        print("올바른 입력이 아닙니다. 다시 입력해주세요.");
        continue;
      }

      // 몬스터가 살아있다면 반격
      if (monster.health > 0) {
        monster.increaseDefense();
        monster.attackCharacter(character);
      }

      // 몬스터 사망 확인
      if (monster.health <= 0) {
        print("\n🎉 ${monster.name}을(를) 처치했습니다!");
        monsters.remove(monster);
        break;
      }

      // 플레이어 사망 확인
      if (character.health <= 0) {
        print("\n💀 ${character.name}이(가) 쓰러졌습니다. 게임 오버!");
        saveGameResult(character.name, character.health, "패배");
        print("\n게임을 종료합니다. 다시 시작하시겠습니까? (y/n)");
        String? restartChoice = stdin.readLineSync();
        if (restartChoice == "y") {
          restartGame();
        } else {
          print("\n게임을 완전히 종료합니다.");
          return;
        }
      }
    }

    // 모든 몬스터 처치 시 게임 종료
    if (monsters.isEmpty) {
      print("\n🎉 모든 몬스터를 물리쳤습니다! 승리!");
      saveGameResult(character.name, character.health, "승리");
      print("\n게임을 다시 시작하시겠습니까? (y/n)");
      String? restartChoice = stdin.readLineSync();
      if (restartChoice == "y") {
        restartGame();
      } else {
        print("\n게임을 완전히 종료합니다.");
        return;
      }
    }

    // 플레이어가 계속할지 선택
    print("\n다음 몬스터와 싸우시겠습니까? (y/n)");
    String? choice = stdin.readLineSync();
    if (choice == "n") {
      print("\n게임을 종료합니다. 처음부터 다시 시작하시겠습니까? (y/n)");
      String? restartChoice = stdin.readLineSync();
      if (restartChoice == "y") {
        restartGame();
      } else {
        print("\n게임을 완전히 종료합니다.");
        return;
      }
    }
  }
}

// **플레이어 이름 입력 함수**
String getPlayerName() {
  while (true) {
    print("\n플레이어의 이름을 입력하세요 (한글 또는 영문만 가능):");
    String? input = stdin.readLineSync();

    // 정규식: 한글 or 영문 대소문자만 허용
    if (input != null && RegExp(r'^[a-zA-Z가-힣]+$').hasMatch(input)) {
      return input;
    } else {
      print("올바르지 않은 이름입니다! 한글 또는 영문만 입력하세요.");
    }
  }
}

// **게임 결과 저장**
void saveGameResult(String name, int health, String result) {
  final file = File('data/result.txt');
  file.writeAsStringSync("$name, 남은 체력: $health, 결과: $result");
  print("\n게임 결과를 result.txt에 저장했습니다.");
}

// **게임을 다시 시작하는 함수**
void restartGame() {
  print("\n게임을 다시 시작합니다!\n");
  main(); // `main()`을 다시 호출하여 처음부터 시작
}

// **메인 함수**
void main() {
  // **플레이어 이름 입력**
  String playerName = getPlayerName();

  // **캐릭터 & 몬스터 데이터 로드**
  Character? character = loadCharacterStats(playerName);
  List<Monster> monsters = loadMonsterStats();

  if (character == null || monsters.isEmpty) {
    print("게임 데이터를 불러오는 데 실패했습니다. 프로그램을 종료합니다.");
    return;
  }

  battle(character, monsters);
}
