// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_score.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlayerScoreAdapter extends TypeAdapter<PlayerScore> {
  @override
  final int typeId = 0;

  @override
  PlayerScore read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlayerScore(
      name: fields[0] as String,
      wins: fields[1] as int,
      totalGames: fields[2] as int,
      roundsPerGame: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PlayerScore obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.wins)
      ..writeByte(2)
      ..write(obj.totalGames)
      ..writeByte(3)
      ..write(obj.roundsPerGame);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerScoreAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
