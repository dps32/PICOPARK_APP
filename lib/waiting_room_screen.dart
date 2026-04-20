import 'dart:math' as math;
import 'dart:ui' as ui;

import 'app_data.dart';
import 'game_app.dart';
import 'libgdx_compat/game_framework.dart';
import 'libgdx_compat/gdx.dart';
import 'libgdx_compat/math_types.dart';
import 'libgdx_compat/viewport.dart';
import 'level_data.dart';
import 'level_loader.dart';
import 'play_screen.dart';
import 'player_list_renderer.dart';

class WaitingRoomScreen extends ScreenAdapter {
  static const double worldWidth = 1280;
  static const double worldHeight = 720;
  static const double panelWidth = 320;
  static const double panelPadding = 14;
  static const double leaderboardStartY = 92;
  static const double playButtonWidth = 250;
  static const double playButtonHeight = 64;

  static final ui.Color background = colorValueOf('070E08');
  static final ui.Color panelFill = colorValueOf('09140CCC');
  static final ui.Color panelStroke = colorValueOf('35FF74');
  static final ui.Color titleColor = colorValueOf('FFFFFF');
  static final ui.Color textColor = colorValueOf('D8FFE3');
  static final ui.Color dimTextColor = colorValueOf('76A784');
  static final ui.Color highlightColor = colorValueOf('35FF74');
  static final ui.Color localPlayerColor = colorValueOf('FFE07A');
  static final ui.Color playButtonFill = colorValueOf('0E1E12');
  static final ui.Color playButtonDisabledFill = colorValueOf('0A130C');
  static final ui.Color playButtonStroke = colorValueOf('35FF74');
  static final ui.Color playButtonDisabledStroke = colorValueOf('315A40');
  static final ui.Color errorColor = colorValueOf('FF7A7A');

  final GameApp game;
  final int levelIndex;
  final Viewport viewport = FitViewport(
    worldWidth,
    worldHeight,
    OrthographicCamera(),
  );
  final GlyphLayout layout = GlyphLayout();
  final Vector3 pointer = Vector3(0, 0, 0);
  final Rectangle playButtonBounds = Rectangle();
  late final LevelData levelData;

  WaitingRoomScreen(this.game, this.levelIndex) {
    levelData = LevelLoader.loadLevel(levelIndex);
  }

  @override
  void render(double delta) {
    final AppData appData = game.getAppData();

    _updatePlayButtonBounds();
    _handleStartInput(appData);

    if (appData.phase == MatchPhase.playing ||
        appData.phase == MatchPhase.finished) {
      game.setScreen(PlayScreen(game, levelIndex));
      return;
    }

    ScreenUtils.clear(background);
    viewport.apply();

    final ShapeRenderer shapes = game.getShapeRenderer();
    shapes.begin(ShapeType.filled);
    shapes.setColor(panelFill);
    shapes.rect(worldWidth - panelWidth, 0, panelWidth, worldHeight);
    shapes.end();

    shapes.begin(ShapeType.line);
    shapes.setColor(panelStroke);
    shapes.rect(worldWidth - panelWidth, 0, panelWidth, worldHeight);
    shapes.end();

    final bool canStart = appData.canRequestMatchStart;
    shapes.begin(ShapeType.filled);
    shapes.setColor(canStart ? playButtonFill : playButtonDisabledFill);
    shapes.rect(
      playButtonBounds.x,
      playButtonBounds.y,
      playButtonBounds.width,
      playButtonBounds.height,
    );
    shapes.end();

    shapes.begin(ShapeType.line);
    shapes.setColor(canStart ? playButtonStroke : playButtonDisabledStroke);
    shapes.rect(
      playButtonBounds.x,
      playButtonBounds.y,
      playButtonBounds.width,
      playButtonBounds.height,
    );
    shapes.end();

    final SpriteBatch batch = game.getBatch();
    final BitmapFont font = game.getFont();
    batch.begin();

    _drawCenteredText(
      batch,
      font,
      'Waiting Room',
      worldHeight * 0.18,
      2.8,
      titleColor,
    );
    _drawCenteredText(
      batch,
      font,
      'Room ${appData.roomLabel}  ${appData.sortedPlayers.length}/${appData.maxPlayers}',
      worldHeight * 0.32,
      1.35,
      dimTextColor,
    );

    final bool usingCountdown = appData.countdownSeconds > 0;
    _drawCenteredText(
      batch,
      font,
      usingCountdown
          ? '${math.max(0, appData.countdownSeconds)}'
          : (appData.isRoomHost ? 'Press PLAY' : 'Waiting host'),
      worldHeight * 0.48,
      usingCountdown ? 5.5 : 2.5,
      highlightColor,
    );

    _drawCenteredText(
      batch,
      font,
      'Work together to complete the puzzle.',
      worldHeight * 0.62,
      1.55,
      textColor,
    );

    _drawCenteredText(
      batch,
      font,
      canStart ? 'PLAY (ENTER)' : 'PLAY',
      playButtonBounds.y + playButtonBounds.height * 0.68,
      1.8,
      canStart ? highlightColor : dimTextColor,
    );

    if (appData.sortedPlayers.length < appData.minPlayers) {
      _drawCenteredText(
        batch,
        font,
        'Need at least ${appData.minPlayers} players to start',
        playButtonBounds.y + playButtonBounds.height + 34,
        1.05,
        dimTextColor,
      );
    }

    final String? roomError = appData.roomErrorMessage;
    if (roomError != null && roomError.isNotEmpty) {
      _drawCenteredText(
        batch,
        font,
        roomError,
        playButtonBounds.y + playButtonBounds.height + 62,
        0.95,
        errorColor,
      );
    }

    _drawLeftAlignedText(
      batch,
      font,
      'Players',
      worldWidth - panelWidth + panelPadding,
      34,
      1.45,
      titleColor,
    );
    _drawLeftAlignedText(
      batch,
      font,
      'Ready to start',
      worldWidth - panelWidth + panelPadding,
      64,
      1.0,
      dimTextColor,
    );

    PlayerListRenderer.render(
      batch: batch,
      font: font,
      layout: layout,
      players: appData.sortedPlayers,
      localPlayerId: appData.playerId,
      left: worldWidth - panelWidth + panelPadding,
      right: worldWidth - panelPadding,
      startY: leaderboardStartY,
      textColor: textColor,
      localPlayerColor: localPlayerColor,
      drawLeftAlignedText: _drawLeftAlignedText,
      drawRightAlignedText: _drawRightAlignedText,
      style: PlayerListRenderer.gameplayStyle,
    );

    if (appData.sortedPlayers.isEmpty) {
      _drawLeftAlignedText(
        batch,
        font,
        'Waiting for players...',
        worldWidth - panelWidth + panelPadding,
        leaderboardStartY,
        1.0,
        dimTextColor,
      );
    }

    batch.end();
  }

  void _drawCenteredText(
    SpriteBatch batch,
    BitmapFont font,
    String text,
    double y,
    double scale,
    ui.Color color,
  ) {
    font.getData().setScale(scale);
    font.setColor(color);
    layout.setText(font, text);
    final double x = (worldWidth - panelWidth - layout.width) * 0.5;
    font.draw(batch, layout, x, y);
    font.getData().setScale(1);
  }

  void _updatePlayButtonBounds() {
    final double x = (worldWidth - panelWidth) * 0.5 - playButtonWidth * 0.5;
    final double y = worldHeight * 0.78;
    playButtonBounds.set(x, y, playButtonWidth, playButtonHeight);
  }

  void _handleStartInput(AppData appData) {
    if (!appData.canRequestMatchStart) {
      return;
    }

    if (Gdx.input.isKeyJustPressed(Input.keys.enter) ||
        Gdx.input.isKeyJustPressed(Input.keys.space)) {
      appData.requestMatchStart();
      return;
    }

    if (!Gdx.input.justTouched()) {
      return;
    }

    viewport.unproject(pointer.set(
      Gdx.input.getX().toDouble(),
      Gdx.input.getY().toDouble(),
      0,
    ));

    if (playButtonBounds.contains(pointer.x, pointer.y)) {
      appData.requestMatchStart();
    }
  }

  void _drawLeftAlignedText(
    SpriteBatch batch,
    BitmapFont font,
    String text,
    double x,
    double y,
    double scale,
    ui.Color color,
  ) {
    font.getData().setScale(scale);
    font.setColor(color);
    font.drawText(text, x, y);
    font.getData().setScale(1);
  }

  void _drawRightAlignedText(
    SpriteBatch batch,
    BitmapFont font,
    String text,
    double right,
    double y,
    double scale,
    ui.Color color,
  ) {
    font.getData().setScale(scale);
    font.setColor(color);
    layout.setText(font, text);
    font.draw(batch, layout, right - layout.width, y);
    font.getData().setScale(1);
  }

  @override
  void resize(int width, int height) {
    viewport.update(width.toDouble(), height.toDouble(), true);
  }
}
