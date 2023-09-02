import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_dart/three_dart.dart' as three;
import 'package:three_dart_playground/model.dart';
import 'package:image/image.dart' as image;
import 'process.dart' show SkinImageExtension;

@immutable
abstract class LoadOptions {
  bool? get makeVisible;
}

class SkinLoadOptions extends LoadOptions {
  @override
  final bool? makeVisible;
  final String? model;
  final bool? ears;
  final bool? earsLoadOnly;

  SkinLoadOptions({
    this.makeVisible,
    this.model,
    this.ears,
    this.earsLoadOnly,
  }) : super();
}

class CapeLoadOptions extends LoadOptions {
  @override
  final bool? makeVisible;
  final BackEquipment? backEquipment;

  CapeLoadOptions({this.makeVisible, this.backEquipment});
}

enum EarsTextureType {
  standalone,
  skin,
}

class EarsLoadOptions extends LoadOptions {
  @override
  final bool? makeVisible;
  final EarsTextureType textureType;

  EarsLoadOptions({this.makeVisible, required this.textureType});
}

abstract class SkinViewerEarsOptions {
  EarsTextureType textureType;
  ByteData source;
  SkinViewerEarsOptions({required this.textureType, required this.source});
}

class SkinViewerOptions {
  int width;
  int height;
  double? devicePixelRatio;
  ByteData? skin;
  String? model;
  ByteData? cape;
  SkinViewerEarsOptions? ears;
  bool? earsUseCurrentSkin;
  bool? alpha = true;
  bool? preserveDrawingBuffer = false;
  bool? renderPaused;
  Texture? background;
  Texture? panorama;
  double? fov = 50;
  double? zoom = 0.9;

  SkinViewerOptions({
    required this.width,
    required this.height,
    this.devicePixelRatio,
    this.skin,
    this.model,
    this.cape,
    this.ears,
    this.earsUseCurrentSkin,
    this.alpha,
    this.preserveDrawingBuffer,
    this.renderPaused,
    this.background,
    this.panorama,
    this.fov,
    this.zoom,
  });
}

class SkinViewer extends StatefulWidget {
  final SkinViewerOptions options;
  const SkinViewer({Key? key, required this.options}) : super(key: key);

  @override
  SkinViewerState createState() => SkinViewerState();
}

class SkinViewerState extends State<SkinViewer> {
  late final FlutterGlPlugin glPlugin;
  late final three.Scene scene;
  late final three.PerspectiveCamera camera;
  late final three.WebGLRenderer renderer;
  late final PlayerObject playerObject;
  late final three.Group playerWrapper;
  final three.AmbientLight globalLight = three.AmbientLight(0xFFFFFF, 0.4);
  final three.PointLight cameraLight = three.PointLight(0xFFFFF, 0.6);

  late final three.Texture _skinTexture;
  late final three.Texture _capeTexture;
  late final three.Texture _earsTexture;
  late final Texture? _backgroundTexture;
  late final dynamic _sourceTexture;
  bool _disposed = false;
  bool _renderPaused = false;
  late double _zoom;
  int? _animationId;

  Future<void> init() async {
    // initTexture();
    await initRenderer();
    // scene = three.Scene();
    // camera = three.PerspectiveCamera();
    // camera.add(cameraLight);
    // scene.add(camera);
    // scene.add(globalLight);
    // initPlayer();
    camera = three.PerspectiveCamera(40, 1, 0.1, 10);
    scene = three.Scene();
    scene.add(camera);
    camera.lookAt(scene.position);
    scene.background = three.Color(1.0, 1.0, 1.0);
    scene.add(three.AmbientLight(0x222244, null));
    final geometryCylinder = three.CylinderGeometry(0.5, 0.5, 1, 32);
    final materialCylinder = three.MeshPhongMaterial({"color": 0xff0000});
    final mesh = three.Mesh(geometryCylinder, materialCylinder);
    scene.add(mesh);
  }

  void initTexture() {
    _skinTexture = newNearestFilterTexture();
    _capeTexture = newNearestFilterTexture();
    _earsTexture = newNearestFilterTexture();
  }

  three.Texture newNearestFilterTexture() => three.Texture()
    ..magFilter = three.NearestFilter
    ..minFilter = three.NearestFilter;

  Future<void> initRenderer() async {
    glPlugin = FlutterGlPlugin();
    final devicePixelRatio =
        widget.options.devicePixelRatio ?? window.devicePixelRatio;
    Map<String, dynamic> options = {
      'antialias': true,
      // 'alpha': widget.options.alpha ?? true,
      'alpha': widget.options.alpha ?? false,
      // 'width': widget.options.width,
      'width': 200,
      // 'height': widget.options.height,
      'height': 200,
      'dpr': devicePixelRatio,
    };

    await glPlugin.initialize(options: options);
    if (kIsWeb) {
      await glPlugin.prepareContext();
    }

    renderer = three.WebGLRenderer({
      'gl': glPlugin.gl,
      'canvas': glPlugin.element,
      'width': widget.options.width.toDouble(),
      'height': widget.options.height.toDouble(),
      'alpha': widget.options.alpha ?? true,
      "antialias": true,
      'preserveDrawingBuffer': widget.options.preserveDrawingBuffer ?? false
    });
    renderer.setPixelRatio(devicePixelRatio);
    renderer.setSize(widget.options.width.toDouble(),
        widget.options.height.toDouble(), false);
    renderer.shadowMap.enabled = false;

    if (!kIsWeb) {
      final three.WebGLRenderTargetOptions options =
          three.WebGLRenderTargetOptions({'format': three.RGBAFormat});
      final three.RenderTarget renderTarget =
          three.WebGLMultisampleRenderTarget(
        (widget.options.width * devicePixelRatio).toInt(),
        (widget.options.width * devicePixelRatio).toInt(),
        options,
      );
      renderTarget.samples = 4;
      renderer.setRenderTarget(renderTarget);
      _sourceTexture = renderer.getRenderTargetGLTexture(renderTarget);
    }
  }

  void initPlayer() async {
    playerObject = PlayerObject(
      skinTexture: _skinTexture,
      capeTexture: _capeTexture,
      earsTexture: _earsTexture,
    );
    playerObject.name = 'player';
    playerObject.skin.visible = false;
    playerObject.cape.visible = false;
    playerWrapper = three.Group();
    playerWrapper.add(playerObject);
    scene.add(playerWrapper);
    if (widget.options.skin != null) {
      final skinImageData =
          image.decodeImage(widget.options.skin!.buffer.asUint8List());
      assert(skinImageData != null);
      loadSkin(
        skinImageData!,
        SkinLoadOptions(
          model: widget.options.model,
          earsLoadOnly: widget.options.earsUseCurrentSkin,
        ),
      );
    }
  }

  void loadSkin(image.Image source, SkinLoadOptions options) {
    image.Image skinImage = source.loadSkinToImage();
    _skinTexture.source = three.Source(skinImage.data);
    _skinTexture.needsUpdate = true;
    String model = widget.options.model ?? 'auto-detect';
    if (model == 'auto-detect') {
      model = skinImage.inferModelType();
    }
    if (options.makeVisible ?? true) {
      playerObject.skin.visible = true;
    }
    if (options.ears == true || (options.earsLoadOnly ?? false)) {
      final image.Image earsImage = skinImage.loadEarsToImageFromSkin();
      _earsTexture.source = three.Source(earsImage.data);
      _earsTexture.needsUpdate = true;
      if (options.ears == true) {
        playerObject.ears.visible = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    renderer.render(scene, camera);
    return FutureBuilder(
      future: init(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        return Container(
            color: Colors.black,
            child: Builder(builder: (BuildContext context) {
              if (kIsWeb) {
                return glPlugin.isInitialized
                    ? HtmlElementView(viewType: glPlugin.textureId!.toString())
                    : Container();
              } else {
                return glPlugin.isInitialized
                    ? Texture(textureId: glPlugin.textureId!)
                    : Container();
              }
            }));
      },
    );
  }

  @override
  void dispose() {
    renderer.dispose();
    glPlugin.dispose();
    super.dispose();
  }
}
