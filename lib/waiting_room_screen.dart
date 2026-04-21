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

class WaitingRoomScreen extends ScreenAdapter {
  static const double worldWidth = 1280;
  static const double worldHeight = 720;
  static const double cardWidth = 760;
  static const double cardHeight = 560;
  static const double listInset = 48;
  static const double listTop = 250;
  static const double listRowHeight = 42;
  static const double playButtonWidth = 280;
  static const double playButtonHeight = 68;

  static final ui.Color background = colorValueOf('F6F8FB');
  static final ui.Color cardFill = colorValueOf('FFFFFF');
  static final ui.Color cardStroke = colorValueOf('D7DEE8');
  static final ui.Color titleColor = colorValueOf('162033');
  static final ui.Color textColor = colorValueOf('314058');
  static final ui.Color dimTextColor = colorValueOf('6D7C93');
  static final ui.Color accentColor = colorValueOf('2D7DFF');
  static final ui.Color localPlayerColor = colorValueOf('0D58D8');
  static final ui.Color listFill = colorValueOf('F9FBFF');
  static final ui.Color listStroke = colorValueOf('DCE6F5');
  static final ui.Color playButtonFill = colorValueOf('2D7DFF');
  static final ui.Color playButtonDisabledFill = colorValueOf('B6C4D8');
  static final ui.Color playButtonStroke = colorValueOf('1F63CF');
  static final ui.Color playButtonDisabledStroke = colorValueOf('AAB8CA');
  static final ui.Color errorColor = colorValueOf('C44545');

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

    final double cardX = (worldWidth - cardWidth) * 0.5;
    final double cardY = (worldHeight - cardHeight) * 0.5;
    final double listX = cardX + listInset;
    final double listY = cardY + listTop;
    final double listWidth = cardWidth - listInset * 2;
    final double listHeight = 190;

    final ShapeRenderer shapes = game.getShapeRenderer();
    shapes.begin(ShapeType.filled);
    shapes.setColor(cardFill);
    shapes.rect(cardX, cardY, cardWidth, cardHeight);
    shapes.setColor(listFill);
    shapes.rect(listX, listY, listWidth, listHeight);
    shapes.end();

    shapes.begin(ShapeType.line);
    shapes.setColor(cardStroke);
    shapes.rect(cardX, cardY, cardWidth, cardHeight);
    shapes.setColor(listStroke);
    shapes.rect(listX, listY, listWidth, listHeight);
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

    _drawCenteredText(batch, font, 'Waiting Room', cardY + 72, 2.6, titleColor);
    _drawCenteredText(
      batch,
      font,
      'Room ${appData.roomLabel}',
      cardY + 110,
      1.2,
      dimTextColor,
    );

    final String playersCounter =
        '${appData.sortedPlayers.length}/${appData.maxPlayers} players';
    _drawCenteredText(
      batch,
      font,
      playersCounter,
      cardY + 156,
      1.7,
      accentColor,
    );

    _drawCenteredText(
      batch,
      font,
      'Players in room',
      listY - 18,
      1.15,
      dimTextColor,
    );

    final List<MultiplayerPlayer> players = appData.sortedPlayers;
    if (players.isEmpty) {
      _drawCenteredText(
        batch,
        font,
        'No players connected yet',
        listY + 108,
        1.2,
        dimTextColor,
      );
    } else {
      double rowY = listY + 44;
      for (int i = 0; i < players.length; i++) {
        final MultiplayerPlayer player = players[i];
        final bool isLocalPlayer = player.id == appData.playerId;
        final String label = '${i + 1}. ${player.name}';
        _drawLeftAlignedText(
          batch,
          font,
          label,
          listX + 20,
          rowY,
          1.2,
          isLocalPlayer ? localPlayerColor : textColor,
        );
        rowY += listRowHeight;
        if (rowY > listY + listHeight - 12) {
          break;
        }
      }
    }

    _drawCenteredText(
      batch,
      font,
      canStart ? 'Play (Enter)' : 'Play',
      playButtonBounds.y + playButtonBounds.height * 0.67,
      1.75,
      colorValueOf('FFFFFF'),
    );

    if (appData.sortedPlayers.length < appData.minPlayers) {
      _drawCenteredText(
        batch,
        font,
        'Need at least ${appData.minPlayers} players',
        playButtonBounds.y - 18,
        1.0,
        dimTextColor,
      );
    }

    final String? roomError = appData.roomErrorMessage;
    if (roomError != null && roomError.isNotEmpty) {
      _drawCenteredText(
        batch,
        font,
        roomError,
        playButtonBounds.y - 42,
        0.95,
        errorColor,
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
    final double x = (worldWidth - layout.width) * 0.5;
    font.draw(batch, layout, x, y);
    font.getData().setScale(1);
  }

  void _updatePlayButtonBounds() {
    final double x = worldWidth * 0.5 - playButtonWidth * 0.5;
    final double y = worldHeight * 0.5 + 180;
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

    viewport.unproject(
      pointer.set(Gdx.input.getX().toDouble(), Gdx.input.getY().toDouble(), 0),
    );

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

  @override
  void resize(int width, int height) {
    viewport.update(width.toDouble(), height.toDouble(), true);
  }
}
