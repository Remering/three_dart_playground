import 'package:three_dart/three_dart.dart';

enum BackEquipment {
  cape,
  elytra,
}

extension BoxGeometrySkinExtension on BoxGeometry {
  setUvs(double u, double v, double width, double height, double depth,
      double textureWidth, double textureHeight) {
    List<Vector2> toFaceVertices(double x1, double y1, double x2, double y2) {
      return [
        Vector2(x1 / textureWidth, 1.0 - y2 / textureHeight),
        Vector2(x2 / textureWidth, 1.0 - y2 / textureHeight),
        Vector2(x2 / textureWidth, 1.0 - y1 / textureHeight),
        Vector2(x1 / textureWidth, 1.0 - y1 / textureHeight)
      ];
    }

    final top = toFaceVertices(u + depth, v, u + width + depth, v + depth);
    final bottom =
        toFaceVertices(u + width + depth, v, u + width * 2 + depth, v + depth);
    final left = toFaceVertices(u, v + depth, u + depth, v + depth + height);
    final front = toFaceVertices(
        u + depth, v + depth, u + width + depth, v + depth + height);
    final right = toFaceVertices(u + width + depth, v + depth,
        u + width + depth * 2, v + height + depth);
    final back = toFaceVertices(u + width + depth * 2, v + depth,
        u + width * 2 + depth * 2, v + height + depth);
    final uvAttr = attributes['uv'] as BufferAttribute;
    uvAttr.copyVector2sArray([
      right[3],
      right[2],
      right[0],
      right[1],
      left[3],
      left[2],
      left[0],
      left[1],
      top[3],
      top[2],
      top[0],
      top[1],
      bottom[0],
      bottom[1],
      bottom[3],
      bottom[2],
      front[3],
      front[2],
      front[0],
      front[1],
      back[3],
      back[2],
      back[0],
      back[1]
    ]);
    uvAttr.needsUpdate = true;
  }

  void setSkinUvs(
      double u, double v, double width, double height, double depth) {
    setUvs(u, v, width, height, depth, 64, 64);
  }

  void setCapeUvs(
      double u, double v, double width, double height, double depth) {
    setUvs(u, v, width, height, depth, 64, 32);
  }
}

class BodyPart extends Group {
  final Object3D innerLayer;
  final Object3D outerLayer;

  BodyPart(this.innerLayer, this.outerLayer) {
    innerLayer.name = 'inner';
    outerLayer.name = 'outer';
  }
}

class SkinObject extends Group {
  late final BodyPart head;
  late final BodyPart body;
  late final BodyPart rightArm;
  late final BodyPart leftArm;
  late final BodyPart rightLeg;
  late final BodyPart leftLeg;
  final List<Function> _modelListeners =
      []; // called when model(slim property) is changed
  bool _slim = false;
  SkinObject(Texture texture) : super() {
    final layer1Material = MeshStandardMaterial({
      'map': texture,
      'side': FrontSide,
    });

    final layer2Material = MeshStandardMaterial({
      'map': texture,
      'side': DoubleSide,
      'transparent': true,
      'alphaTest': 1e-5
    });

    initHead(layer1Material, layer2Material);
    initBody(layer1Material, layer2Material);

    final layer1MaterialBiased = layer1Material.clone();
    layer1MaterialBiased.polygonOffset = true;
    layer1MaterialBiased.polygonOffsetFactor = 1.0;
    layer1MaterialBiased.polygonOffsetUnits = 1.0;

    final layer2MaterialBiased = layer2Material.clone();
    layer2MaterialBiased.polygonOffset = true;
    layer2MaterialBiased.polygonOffsetFactor = 1.0;
    layer2MaterialBiased.polygonOffsetUnits = 1.0;

    initRightArm(layer1MaterialBiased, layer2MaterialBiased);
    initLeftArm(layer1MaterialBiased, layer2MaterialBiased);
    initRightLeg(layer1MaterialBiased, layer2MaterialBiased);
    initLeftLeg(layer1MaterialBiased, layer2MaterialBiased);
  }

  set modelType(String modelType) {
    final slimBefore = _slim;
    _slim = modelType == 'slim';
    if (slimBefore != _slim) {
      for (var listener in _modelListeners) {
        listener();
      }
    }
  }

  String get modelType => _slim ? 'slim' : 'default';

  Iterable<BodyPart> get _bodyParts => children.whereType<BodyPart>();

  set innerLayerVisible(bool value) {
    for (var bodyPart in _bodyParts) {
      bodyPart.innerLayer.visible = value;
    }
  }

  set outerLayerVisible(bool value) {
    for (var bodyPart in _bodyParts) {
      bodyPart.outerLayer.visible = value;
    }
  }

  void initHead(
    MeshStandardMaterial layer1Material,
    MeshStandardMaterial layer2Material,
  ) {
    final headBox = BoxGeometry(8, 8, 8);
    headBox.setSkinUvs(0, 0, 8, 8, 8);
    final headMesh = Mesh(headBox, layer1Material);

    final head2Box = BoxGeometry(9, 9, 9);
    head2Box.setSkinUvs(32, 0, 8, 8, 8);
    final head2Mesh = Mesh(head2Box, layer2Material);

    head = BodyPart(headMesh, head2Mesh);
    head.name = 'head';
    head.add(headMesh);
    head.add(head2Mesh);
    headMesh.position.y = 4;
    head2Mesh.position.y = 4;
    add(head);
  }

  void initBody(
    MeshStandardMaterial layer1Material,
    MeshStandardMaterial layer2Material,
  ) {
    final bodyBox = BoxGeometry(8, 12, 4);
    bodyBox.setSkinUvs(16, 16, 8, 12, 4);
    final bodyMesh = Mesh(bodyBox, layer1Material);

    final body2Box = BoxGeometry(8.5, 12.5, 4.5);
    body2Box.setSkinUvs(16, 32, 8, 12, 4);
    final body2Mesh = Mesh(body2Box, layer2Material);

    body = BodyPart(bodyMesh, body2Mesh);
    body.name = 'body';
    body.add(bodyMesh);
    body.add(body2Mesh);
    body.position.y = -6;
    add(body);
  }

  void initRightArm(
    MeshStandardMaterial layer1MaterialBiased,
    MeshStandardMaterial layer2MaterialBiased,
  ) {
    final rightArmBox = BoxGeometry();
    final rightArmMesh = Mesh(rightArmBox, layer1MaterialBiased);
    _modelListeners.add(() {
      rightArmMesh.scale.x = _slim ? 3 : 4;
      rightArmMesh.scale.y = 12;
      rightArmMesh.scale.z = 4;
      rightArmBox.setSkinUvs(40, 16, _slim ? 3 : 4, 12, 4);
    });

    final rightArm2Box = BoxGeometry();
    final rightArm2Mesh = Mesh(rightArm2Box, layer2MaterialBiased);
    _modelListeners.add(() {
      rightArm2Mesh.scale.x = _slim ? 3.5 : 4.5;
      rightArm2Mesh.scale.y = 12.5;
      rightArm2Mesh.scale.z = 4.5;
      rightArm2Box.setSkinUvs(40, 32, _slim ? 3 : 4, 12, 4);
    });

    final rightArmPivot = Group();
    rightArmPivot.add(rightArmMesh);
    rightArmPivot.add(rightArm2Mesh);
    _modelListeners.add(() {
      rightArmPivot.position.x = _slim ? -.5 : -1;
    });
    rightArmPivot.position.y = -4;

    rightArm = BodyPart(rightArmMesh, rightArm2Mesh);
    rightArm.name = "rightArm";
    rightArm.add(rightArmPivot);
    rightArm.position.x = -5;
    rightArm.position.y = -2;
    add(rightArm);
  }

  void initLeftArm(
    MeshStandardMaterial layer1MaterialBiased,
    MeshStandardMaterial layer2MaterialBiased,
  ) {
    final leftArmBox = BoxGeometry();
    final leftArmMesh = Mesh(leftArmBox, layer1MaterialBiased);
    _modelListeners.add(() {
      leftArmMesh.scale.x = _slim ? 3 : 4;
      leftArmMesh.scale.y = 12;
      leftArmMesh.scale.z = 4;
      leftArmBox.setSkinUvs(32, 48, _slim ? 3 : 4, 12, 4);
    });

    final leftArm2Box = BoxGeometry();
    final leftArm2Mesh = Mesh(leftArm2Box, layer2MaterialBiased);
    _modelListeners.add(() {
      leftArm2Mesh.scale.x = _slim ? 3.5 : 4.5;
      leftArm2Mesh.scale.y = 12.5;
      leftArm2Mesh.scale.z = 4.5;
      leftArm2Box.setSkinUvs(48, 48, _slim ? 3 : 4, 12, 4);
    });

    final leftArmPivot = Group();
    leftArmPivot.add(leftArmMesh);
    leftArmPivot.add(leftArm2Mesh);
    _modelListeners.add(() {
      leftArmPivot.position.x = _slim ? 0.5 : 1;
    });
    leftArmPivot.position.y = -4;

    leftArm = BodyPart(leftArmMesh, leftArm2Mesh);
    leftArm.name = "leftArm";
    leftArm.add(leftArmPivot);
    leftArm.position.x = 5;
    leftArm.position.y = -2;
    add(leftArm);
  }

  void initRightLeg(
    MeshStandardMaterial layer1MaterialBiased,
    MeshStandardMaterial layer2MaterialBiased,
  ) {
    final rightLegBox = BoxGeometry(4, 12, 4);
    rightLegBox.setSkinUvs(0, 16, 4, 12, 4);
    final rightLegMesh = Mesh(rightLegBox, layer1MaterialBiased);

    final rightLeg2Box = BoxGeometry(4.5, 12.5, 4.5);
    rightLeg2Box.setSkinUvs(0, 32, 4, 12, 4);
    final rightLeg2Mesh = Mesh(rightLeg2Box, layer2MaterialBiased);

    final rightLegPivot = Group();
    rightLegPivot.add(rightLegMesh);
    rightLegPivot.add(rightLeg2Mesh);
    rightLegPivot.position.y = -6;

    rightLeg = BodyPart(rightLegMesh, rightLeg2Mesh);
    rightLeg.name = "rightLeg";
    rightLeg.add(rightLegPivot);
    rightLeg.position.x = -1.9;
    rightLeg.position.y = -12;
    rightLeg.position.z = -.1;
    add(rightLeg);
  }

  void initLeftLeg(
    MeshStandardMaterial layer1MaterialBiased,
    MeshStandardMaterial layer2MaterialBiased,
  ) {
    final leftLegBox = BoxGeometry(4, 12, 4);
    leftLegBox.setSkinUvs(16, 48, 4, 12, 4);
    final leftLegMesh = Mesh(leftLegBox, layer1MaterialBiased);

    final leftLeg2Box = BoxGeometry(4.5, 12.5, 4.5);
    leftLeg2Box.setSkinUvs(0, 48, 4, 12, 4);
    final leftLeg2Mesh = Mesh(leftLeg2Box, layer2MaterialBiased);

    final leftLegPivot = Group();
    leftLegPivot.add(leftLegMesh);
    leftLegPivot.add(leftLeg2Mesh);
    leftLegPivot.position.y = -6;

    leftLeg = BodyPart(leftLegMesh, leftLeg2Mesh);
    leftLeg.name = "leftLeg";
    leftLeg.add(leftLegPivot);
    leftLeg.position.x = 1.9;
    leftLeg.position.y = -12;
    leftLeg.position.z = -.1;
    add(leftLeg);

    modelType = 'default';
  }
}

class CapeObject extends Group {
  late final Mesh cape;

  CapeObject(Texture texture) : super() {
    final capeMaterial = MeshStandardMaterial({
      'map': texture,
      'side': DoubleSide,
      'transparent': true,
      'alphaTest': 1e-5
    });

    // +z (front) - inside of cape
    // -z (back) - outside of cape
    final capeBox = BoxGeometry(10, 16, 1);
    capeBox.setCapeUvs(0, 0, 10, 16, 1);
    cape = Mesh(capeBox, capeMaterial);
    cape.position.y = -8;
    cape.position.z = .5;
    add(cape);
  }
}

class ElytraObject extends Group {
  late final Group leftWing;
  late final Group rightWing;

  ElytraObject(Texture texture) : super() {
    final elytraMaterial = MeshStandardMaterial({
      'map': texture,
      'side': DoubleSide,
      'transparent': true,
      'alphaTest': 1e-5
    });

    final leftWingBox = BoxGeometry(12, 22, 4);
    leftWingBox.setCapeUvs(22, 0, 10, 20, 2);
    final leftWingMesh = Mesh(leftWingBox, elytraMaterial);
    leftWingMesh.position.x = -5;
    leftWingMesh.position.y = -10;
    leftWingMesh.position.z = -1;
    leftWing = Group();
    leftWing.add(leftWingMesh);
    add(leftWing);

    final rightWingBox = BoxGeometry(12, 22, 4);
    rightWingBox.setCapeUvs(22, 0, 10, 20, 2);
    final rightWingMesh = Mesh(rightWingBox, elytraMaterial);
    rightWingMesh.scale.x = -1;
    rightWingMesh.position.x = 5;
    rightWingMesh.position.y = -10;
    rightWingMesh.position.z = -1;
    rightWing = Group();
    rightWing.add(rightWingMesh);
    add(rightWing);

    leftWing.position.x = 5;
    leftWing.rotation.x = .2617994;
    leftWing.rotation.y = .01; // to avoid z-fighting
    leftWing.rotation.z = .2617994;
    updateRightWing();
  }

  ///
  /// Mirrors the position & rotation of left wing,
  /// and apply them to the right wing.
  ///
  void updateRightWing() {
    rightWing.position.x = -leftWing.position.x;
    rightWing.position.y = leftWing.position.y;
    rightWing.rotation.x = leftWing.rotation.x;
    rightWing.rotation.y = -leftWing.rotation.y;
    rightWing.rotation.z = -leftWing.rotation.z;
  }
}

class EarsObject extends Group {
  late final Mesh rightEar;
  late final Mesh leftEar;

  EarsObject(Texture texture) : super() {
    final material = MeshStandardMaterial({
      'map': texture,
      'side': FrontSide,
    });
    final earBox = BoxGeometry(8, 8, 4 / 3);
    earBox.setUvs(0, 0, 6, 6, 1, 14, 7);

    rightEar = Mesh(earBox, material);
    rightEar.name = 'rightEar';
    rightEar.position.x = -6;
    add(rightEar);

    leftEar = Mesh(earBox, material);
    leftEar.name = 'leftEar';
    leftEar.position.x = 6;
    add(leftEar);
  }
}

class PlayerObject extends Group {
  late final SkinObject skin;
  late final CapeObject cape;
  late final ElytraObject elytra;
  late final EarsObject ears;

  PlayerObject({
    required Texture skinTexture,
    required Texture capeTexture,
    required Texture earsTexture,
  }) : super() {
    skin = SkinObject(skinTexture);
    skin.name = "skin";
    skin.position.y = 8;
    add(skin);

    cape = CapeObject(capeTexture);
    cape.name = "cape";
    cape.position.y = 8;
    cape.position.z = -2;
    cape.rotation.x = 10.8 * Math.pi / 180;
    cape.rotation.y = Math.pi;
    add(cape);

    elytra = ElytraObject(capeTexture);
    elytra.name = "elytra";
    elytra.position.y = 8;
    elytra.position.z = -2;
    elytra.visible = false;
    add(elytra);

    ears = EarsObject(earsTexture);
    ears.name = "ears";
    ears.position.y = 10;
    ears.position.z = 2 / 3;
    ears.visible = false;
    skin.head.add(ears);
  }

  BackEquipment? get backEquipment {
    if (cape.visible) return BackEquipment.cape;
    if (elytra.visible) return BackEquipment.elytra;
    return null;
  }

  set backEquipment(BackEquipment? backEquipment) {
    cape.visible = backEquipment == BackEquipment.cape;
    elytra.visible = backEquipment == BackEquipment.elytra;
  }
}
