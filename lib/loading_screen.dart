import 'dart:ui' as ui;
import 'dart:math' as math;

import 'game_app.dart';
import 'libgdx_compat/game_framework.dart';
import 'libgdx_compat/math_types.dart';
import 'libgdx_compat/viewport.dart';
import 'level_data.dart';
import 'level_loader.dart';
import 'play_screen.dart';

class LoadingScreen extends ScreenAdapter {
  static const double minSecondsOnScreen = 3.85;
  static const double visualProgressSpeed = 3.2;

  static final ui.Color background = colorValueOf('FFFFFF');
  static final ui.Color textColor = colorValueOf('0038B8');
  static final ui.Color subtextColor = colorValueOf('7A7A7A');

  final GameApp game;
  final int levelIndex;
  final Viewport viewport = ScreenViewport(
    OrthographicCamera(),
  );
  final GlyphLayout layout = GlyphLayout();
  late final LevelData levelData;

  double elapsedSeconds = 0;
  double visualProgress = 0;

  bool _levelReady = false;

  LoadingScreen(this.game, this.levelIndex) {
    levelData = LevelLoader.loadLevel(levelIndex);
  }

  @override
  void show() {
    game.queueReferencedAssetsForLevel(levelIndex);
    elapsedSeconds = 0;
    visualProgress = 0;
    _levelReady = false;
  }

  @override
  void render(double delta) {
    elapsedSeconds += delta;

    final bool done = game.getAssetManager().update(17);
    final double actualProgress = clampDouble(
      game.getAssetManager().getProgress(),
      0,
      1,
    );
    final double maxProgressForTime = clampDouble(
      elapsedSeconds / minSecondsOnScreen,
      0,
      1,
    );
    final double targetProgress = math.min(actualProgress, maxProgressForTime);
    visualProgress = math.min(
      targetProgress,
      visualProgress + math.max(0, delta) * visualProgressSpeed,
    );

    if (done &&
        elapsedSeconds >= minSecondsOnScreen &&
        visualProgress >= 0.999 &&
        !_levelReady) {
      _levelReady = true;
      game.setScreen(PlayScreen(game, levelIndex));
      return;
    }

    ScreenUtils.clear(levelData.backgroundColor);
    viewport.apply();

    _renderText(visualProgress);
  }

  void _renderText(double progress) {
    final double screenWidth = viewport.worldWidth;
    final double screenHeight = viewport.worldHeight;
    final String loadingLabel = _loadingLabel();

    final SpriteBatch batch = game.getBatch();
    final BitmapFont font = game.getFont();
    batch.setProjectionMatrix(viewport.getCamera().combined);
    batch.begin();

    _drawCenteredText(
      batch,
      font,
      loadingLabel,
      screenWidth,
      screenHeight * 0.44,
      _scaleForWidth(screenWidth, 1.9),
      textColor,
    );

    batch.end();
  }

  String _loadingLabel() {
    final int dots = (elapsedSeconds * 3).floor() % 4;
    return 'Cargando${'.' * dots}';
  }

  double _scaleForWidth(double screenWidth, double baseScale) {
    final double factor = (screenWidth / 1280.0).clamp(0.75, 1.35);
    return baseScale * factor;
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

  @override
  void resize(int width, int height) {
    viewport.update(width.toDouble(), height.toDouble(), false);
  }
}
