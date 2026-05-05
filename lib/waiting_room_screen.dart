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

class WaitingRoomScreen extends ScreenAdapter {
  static const double _baseCardWidth = 760;
  static const double _baseCardHeight = 560;
  static const double _baseListInset = 48;
  static const double _baseListTop = 250;
  static const double _baseListRowHeight = 42;
  static const double _basePlayButtonWidth = 280;
  static const double _basePlayButtonHeight = 68;
  static const double _baseTitleScale = 2.6;
  static const double _baseRoomScale = 1.2;
  static const double _basePlayersScale = 1.7;
  static const double _baseSectionScale = 1.15;
  static const double _baseEmptyScale = 1.2;
  static const double _baseButtonScale = 1.75;
  static const double _baseNoteScale = 1.0;

  static final ui.Color background = colorValueOf('FFFFFF');
  static final ui.Color cardFill = colorValueOf('FFFFFF');
  static final ui.Color cardStroke = colorValueOf('9FA4AD');
  static final ui.Color titleColor = colorValueOf('0038B8');
  static final ui.Color textColor = colorValueOf('6F7682');
  static final ui.Color dimTextColor = colorValueOf('9FA4AD');
  static final ui.Color accentColor = colorValueOf('0038B8');
  static final ui.Color localPlayerColor = colorValueOf('0038B8');
  static final ui.Color listFill = colorValueOf('FFFFFF');
  static final ui.Color listStroke = colorValueOf('9FA4AD');
  static final ui.Color playButtonFill = colorValueOf('0038B8');
  static final ui.Color playButtonDisabledFill = colorValueOf('B7BDC7');
  static final ui.Color playButtonStroke = colorValueOf('002A8A');
  static final ui.Color playButtonDisabledStroke = colorValueOf('9FA4AD');
  static final ui.Color errorColor = colorValueOf('6F7682');

  final GameApp game;
  final int levelIndex;
  final Viewport viewport = ScreenViewport(OrthographicCamera());
  final GlyphLayout layout = GlyphLayout();
  final Vector3 pointer = Vector3(0, 0, 0);
  final Rectangle playButtonBounds = Rectangle();
  late final LevelData levelData;
  bool _touchStartHandled = false;

  WaitingRoomScreen(this.game, this.levelIndex) {
    levelData = LevelLoader.loadLevel(levelIndex);
  }

  @override
  void show() {
    game.queueReferencedAssetsForLevel(levelIndex);
    // Keep trying to connect while the player is on this screen.
    game.getAppData().startConnectionRetryTimer();
  }

  @override
  void dispose() {
    game.getAppData().stopRetryTimer();
  }

  @override
  void render(double delta) {
    final AppData appData = game.getAppData();

    _updatePlayButtonBounds();
    _handleStartInput(appData);

    if (appData.phase == MatchPhase.playing ||
        appData.phase == MatchPhase.finished) {
      game.queueReferencedAssetsForLevel(levelIndex);
      game.getAssetManager().update(17);
      if (!game.hasRenderableAssetsForLevel(levelData)) {
        _renderMatchLoading();
        return;
      }
      game.setScreen(PlayScreen(game, levelIndex));
      return;
    }

    ScreenUtils.clear(levelData.backgroundColor);
    viewport.apply();

    final double screenWidth = viewport.worldWidth;
    final double screenHeight = viewport.worldHeight;
    final double scale = math
        .min(screenWidth / 1280.0, screenHeight / 720.0)
        .clamp(0.78, 1.35);
    final double cardWidth = _baseCardWidth * scale;
    final double cardHeight = _baseCardHeight * scale;
    final double listInset = _baseListInset * scale;
    final double listTop = _baseListTop * scale;
    final double listRowHeight = _baseListRowHeight * scale;

    final double cardX = (screenWidth - cardWidth) * 0.5;
    final double cardY = (screenHeight - cardHeight) * 0.5;
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
    _renderPlayButton(shapes, canStart);

    final SpriteBatch batch = game.getBatch();
    final BitmapFont font = game.getFont();
    batch.begin();

    _drawCenteredText(
      batch,
      font,
      'Sala de espera',
      screenWidth,
      cardY + 72,
      _baseTitleScale * scale,
      titleColor,
    );
    _drawCenteredText(
      batch,
      font,
      'Sala ${appData.roomLabel}',
      screenWidth,
      cardY + 110,
      _baseRoomScale * scale,
      dimTextColor,
    );

    final String playersCounter =
        '${appData.sortedPlayers.length}/${appData.maxPlayers} jugadores';
    _drawCenteredText(
      batch,
      font,
      playersCounter,
      screenWidth,
      cardY + 156,
      _basePlayersScale * scale,
      accentColor,
    );

    _drawCenteredText(
      batch,
      font,
      'Jugadores en la sala',
      screenWidth,
      listY - 18,
      _baseSectionScale * scale,
      dimTextColor,
    );

    final List<MultiplayerPlayer> players = appData.sortedPlayers;
    if (players.isEmpty) {
      _drawCenteredText(
        batch,
        font,
        'Aun no hay jugadores conectados',
        screenWidth,
        listY + 108,
        _baseEmptyScale * scale,
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
          _baseEmptyScale * scale,
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
      canStart ? 'Jugar (Enter)' : 'Jugar',
      screenWidth,
      playButtonBounds.y + playButtonBounds.height * 0.67,
      _baseButtonScale * scale,
      colorValueOf('FFFFFF'),
    );

    if (appData.sortedPlayers.length < appData.minPlayers) {
      _drawCenteredText(
        batch,
        font,
        'Se necesitan al menos ${appData.minPlayers} jugadores',
        screenWidth,
        playButtonBounds.y - 18,
        _baseNoteScale * scale,
        dimTextColor,
      );
    }

    final String? roomError = appData.roomErrorMessage;
    if (roomError != null && roomError.isNotEmpty) {
      _drawCenteredText(
        batch,
        font,
        roomError,
        screenWidth,
        playButtonBounds.y - 42,
        0.95 * scale,
        errorColor,
      );
    }

    batch.end();
  }

  // pintamos el boton de jugar con sombra, pseudo gradiente y highlight para
  // que se vea mas pulido sin necesidad de assets
  void _renderPlayButton(ShapeRenderer shapes, bool canStart) {
    final double bx = playButtonBounds.x;
    final double by = playButtonBounds.y;
    final double bw = playButtonBounds.width;
    final double bh = playButtonBounds.height;

    shapes.begin(ShapeType.filled);
    shapes.setColor(canStart ? playButtonFill : playButtonDisabledFill);
    shapes.rect(bx, by, bw, bh);
    shapes.end();

    shapes.begin(ShapeType.line);
    shapes.setColor(canStart ? playButtonStroke : playButtonDisabledStroke);
    shapes.rect(bx, by, bw, bh);
    shapes.end();
  }

  void _drawCenteredText(
    SpriteBatch batch,
    BitmapFont font,
    String text,
    double worldWidth,
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

  void _renderMatchLoading() {
    ScreenUtils.clear(background);
    viewport.apply();

    final String? assetError = game.firstRenderableAssetError(levelData);
    final SpriteBatch batch = game.getBatch();
    final BitmapFont font = game.getFont();
    batch.begin();
    _drawCenteredText(
      batch,
      font,
      assetError == null
          ? 'Cargando escenario...'
          : 'No se pudo cargar el escenario',
      viewport.worldWidth,
      viewport.worldHeight * 0.5,
      1.4,
      titleColor,
    );
    if (assetError != null) {
      _drawCenteredText(
        batch,
        font,
        assetError,
        viewport.worldWidth,
        viewport.worldHeight * 0.5 + 32,
        0.75,
        dimTextColor,
      );
    }
    batch.end();
  }

  void _updatePlayButtonBounds() {
    final double screenWidth = viewport.worldWidth;
    final double screenHeight = viewport.worldHeight;
    final double scale = math
        .min(screenWidth / 1280.0, screenHeight / 720.0)
        .clamp(0.78, 1.35);
    final double playButtonWidth = _basePlayButtonWidth * scale;
    final double playButtonHeight = _basePlayButtonHeight * scale;
    final double x = screenWidth * 0.5 - playButtonWidth * 0.5;
    final double y = screenHeight * 0.5 + 180 * scale;
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

    final bool touchActive = Gdx.input.justTouched() || Gdx.input.isTouchDown();
    if (!touchActive) {
      _touchStartHandled = false;
      return;
    }

    viewport.unproject(
      pointer.set(Gdx.input.getX().toDouble(), Gdx.input.getY().toDouble(), 0),
    );

    final bool insideButton = playButtonBounds.contains(pointer.x, pointer.y);
    if (insideButton && !_touchStartHandled) {
      _touchStartHandled = true;
      appData.requestMatchStart();
      return;
    }

    if (!insideButton) {
      _touchStartHandled = false;
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
    viewport.update(width.toDouble(), height.toDouble(), false);
  }
}
