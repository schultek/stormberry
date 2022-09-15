import 'package:dart_mappable/dart_mappable.dart';
import 'package:dart_mappable/internals.dart';

import 'models.schema.g.dart';


// === ALL STATICALLY REGISTERED MAPPERS ===

var _mappers = <BaseMapper>{
  // class mappers
  UserInsertRequestMapper._(),
  UserUpdateRequestMapper._(),
  DefaultUserViewMapper._(),
  PublicUserViewMapper._(),
  DefaultCompanyViewMapper._(),
  // enum mappers
  // custom mappers
};


// === GENERATED CLASS MAPPERS AND EXTENSIONS ===

class UserInsertRequestMapper extends BaseMapper<UserInsertRequest> {
  UserInsertRequestMapper._();

  @override Function get decoder => decode;
  UserInsertRequest decode(dynamic v) => checked(v, (Map<String, dynamic> map) => fromMap(map));
  UserInsertRequest fromMap(Map<String, dynamic> map) => UserInsertRequest(id: Mapper.i.$get(map, 'id'), name: Mapper.i.$get(map, 'name'), securityNumber: Mapper.i.$get(map, 'securityNumber'));

  @override Function get encoder => (UserInsertRequest v) => encode(v);
  dynamic encode(UserInsertRequest v) => toMap(v);
  Map<String, dynamic> toMap(UserInsertRequest u) => {'id': Mapper.i.$enc(u.id, 'id'), 'name': Mapper.i.$enc(u.name, 'name'), 'securityNumber': Mapper.i.$enc(u.securityNumber, 'securityNumber')};

  @override String stringify(UserInsertRequest self) => 'UserInsertRequest(id: ${Mapper.asString(self.id)}, name: ${Mapper.asString(self.name)}, securityNumber: ${Mapper.asString(self.securityNumber)})';
  @override int hash(UserInsertRequest self) => Mapper.hash(self.id) ^ Mapper.hash(self.name) ^ Mapper.hash(self.securityNumber);
  @override bool equals(UserInsertRequest self, UserInsertRequest other) => Mapper.isEqual(self.id, other.id) && Mapper.isEqual(self.name, other.name) && Mapper.isEqual(self.securityNumber, other.securityNumber);

  @override Function get typeFactory => (f) => f<UserInsertRequest>();
}

extension UserInsertRequestMapperExtension  on UserInsertRequest {
  String toJson() => Mapper.toJson(this);
  Map<String, dynamic> toMap() => Mapper.toMap(this);
  UserInsertRequestCopyWith<UserInsertRequest> get copyWith => UserInsertRequestCopyWith(this, $identity);
}

abstract class UserInsertRequestCopyWith<$R> {
  factory UserInsertRequestCopyWith(UserInsertRequest value, Then<UserInsertRequest, $R> then) = _UserInsertRequestCopyWithImpl<$R>;
  $R call({String? id, String? name, String? securityNumber});
  $R apply(UserInsertRequest Function(UserInsertRequest) transform);
}

class _UserInsertRequestCopyWithImpl<$R> extends BaseCopyWith<UserInsertRequest, $R> implements UserInsertRequestCopyWith<$R> {
  _UserInsertRequestCopyWithImpl(UserInsertRequest value, Then<UserInsertRequest, $R> then) : super(value, then);

  @override $R call({String? id, String? name, String? securityNumber}) => $then(UserInsertRequest(id: id ?? $value.id, name: name ?? $value.name, securityNumber: securityNumber ?? $value.securityNumber));
}

class UserUpdateRequestMapper extends BaseMapper<UserUpdateRequest> {
  UserUpdateRequestMapper._();

  @override Function get decoder => decode;
  UserUpdateRequest decode(dynamic v) => checked(v, (Map<String, dynamic> map) => fromMap(map));
  UserUpdateRequest fromMap(Map<String, dynamic> map) => UserUpdateRequest(id: Mapper.i.$get(map, 'id'), name: Mapper.i.$getOpt(map, 'name'), securityNumber: Mapper.i.$getOpt(map, 'securityNumber'));

  @override Function get encoder => (UserUpdateRequest v) => encode(v);
  dynamic encode(UserUpdateRequest v) => toMap(v);
  Map<String, dynamic> toMap(UserUpdateRequest u) => {'id': Mapper.i.$enc(u.id, 'id'), 'name': Mapper.i.$enc(u.name, 'name'), 'securityNumber': Mapper.i.$enc(u.securityNumber, 'securityNumber')};

  @override String stringify(UserUpdateRequest self) => 'UserUpdateRequest(id: ${Mapper.asString(self.id)}, name: ${Mapper.asString(self.name)}, securityNumber: ${Mapper.asString(self.securityNumber)})';
  @override int hash(UserUpdateRequest self) => Mapper.hash(self.id) ^ Mapper.hash(self.name) ^ Mapper.hash(self.securityNumber);
  @override bool equals(UserUpdateRequest self, UserUpdateRequest other) => Mapper.isEqual(self.id, other.id) && Mapper.isEqual(self.name, other.name) && Mapper.isEqual(self.securityNumber, other.securityNumber);

  @override Function get typeFactory => (f) => f<UserUpdateRequest>();
}

extension UserUpdateRequestMapperExtension  on UserUpdateRequest {
  String toJson() => Mapper.toJson(this);
  Map<String, dynamic> toMap() => Mapper.toMap(this);
  UserUpdateRequestCopyWith<UserUpdateRequest> get copyWith => UserUpdateRequestCopyWith(this, $identity);
}

abstract class UserUpdateRequestCopyWith<$R> {
  factory UserUpdateRequestCopyWith(UserUpdateRequest value, Then<UserUpdateRequest, $R> then) = _UserUpdateRequestCopyWithImpl<$R>;
  $R call({String? id, String? name, String? securityNumber});
  $R apply(UserUpdateRequest Function(UserUpdateRequest) transform);
}

class _UserUpdateRequestCopyWithImpl<$R> extends BaseCopyWith<UserUpdateRequest, $R> implements UserUpdateRequestCopyWith<$R> {
  _UserUpdateRequestCopyWithImpl(UserUpdateRequest value, Then<UserUpdateRequest, $R> then) : super(value, then);

  @override $R call({String? id, Object? name = $none, Object? securityNumber = $none}) => $then(UserUpdateRequest(id: id ?? $value.id, name: or(name, $value.name), securityNumber: or(securityNumber, $value.securityNumber)));
}

class DefaultUserViewMapper extends BaseMapper<DefaultUserView> {
  DefaultUserViewMapper._();

  @override Function get decoder => decode;
  DefaultUserView decode(dynamic v) => checked(v, (Map<String, dynamic> map) => fromMap(map));
  DefaultUserView fromMap(Map<String, dynamic> map) => DefaultUserView(id: Mapper.i.$get(map, 'id'), name: Mapper.i.$get(map, 'name'), securityNumber: Mapper.i.$get(map, 'securityNumber'));

  @override Function get encoder => (DefaultUserView v) => encode(v);
  dynamic encode(DefaultUserView v) => toMap(v);
  Map<String, dynamic> toMap(DefaultUserView d) => {'id': Mapper.i.$enc(d.id, 'id'), 'name': Mapper.i.$enc(d.name, 'name'), 'securityNumber': Mapper.i.$enc(d.securityNumber, 'securityNumber')};

  @override String stringify(DefaultUserView self) => 'DefaultUserView(id: ${Mapper.asString(self.id)}, name: ${Mapper.asString(self.name)}, securityNumber: ${Mapper.asString(self.securityNumber)})';
  @override int hash(DefaultUserView self) => Mapper.hash(self.id) ^ Mapper.hash(self.name) ^ Mapper.hash(self.securityNumber);
  @override bool equals(DefaultUserView self, DefaultUserView other) => Mapper.isEqual(self.id, other.id) && Mapper.isEqual(self.name, other.name) && Mapper.isEqual(self.securityNumber, other.securityNumber);

  @override Function get typeFactory => (f) => f<DefaultUserView>();
}

extension DefaultUserViewMapperExtension  on DefaultUserView {
  String toJson() => Mapper.toJson(this);
  Map<String, dynamic> toMap() => Mapper.toMap(this);
  DefaultUserViewCopyWith<DefaultUserView> get copyWith => DefaultUserViewCopyWith(this, $identity);
}

abstract class DefaultUserViewCopyWith<$R> {
  factory DefaultUserViewCopyWith(DefaultUserView value, Then<DefaultUserView, $R> then) = _DefaultUserViewCopyWithImpl<$R>;
  $R call({String? id, String? name, String? securityNumber});
  $R apply(DefaultUserView Function(DefaultUserView) transform);
}

class _DefaultUserViewCopyWithImpl<$R> extends BaseCopyWith<DefaultUserView, $R> implements DefaultUserViewCopyWith<$R> {
  _DefaultUserViewCopyWithImpl(DefaultUserView value, Then<DefaultUserView, $R> then) : super(value, then);

  @override $R call({String? id, String? name, String? securityNumber}) => $then(DefaultUserView(id: id ?? $value.id, name: name ?? $value.name, securityNumber: securityNumber ?? $value.securityNumber));
}

class PublicUserViewMapper extends BaseMapper<PublicUserView> {
  PublicUserViewMapper._();

  @override Function get decoder => decode;
  PublicUserView decode(dynamic v) => checked(v, (Map<String, dynamic> map) => fromMap(map));
  PublicUserView fromMap(Map<String, dynamic> map) => PublicUserView(id: Mapper.i.$get(map, 'id'), name: Mapper.i.$get(map, 'name'));

  @override Function get encoder => (PublicUserView v) => encode(v);
  dynamic encode(PublicUserView v) => toMap(v);
  Map<String, dynamic> toMap(PublicUserView p) => {'id': Mapper.i.$enc(p.id, 'id'), 'name': Mapper.i.$enc(p.name, 'name')};

  @override String stringify(PublicUserView self) => 'PublicUserView(id: ${Mapper.asString(self.id)}, name: ${Mapper.asString(self.name)})';
  @override int hash(PublicUserView self) => Mapper.hash(self.id) ^ Mapper.hash(self.name);
  @override bool equals(PublicUserView self, PublicUserView other) => Mapper.isEqual(self.id, other.id) && Mapper.isEqual(self.name, other.name);

  @override Function get typeFactory => (f) => f<PublicUserView>();
}

extension PublicUserViewMapperExtension  on PublicUserView {
  String toJson() => Mapper.toJson(this);
  Map<String, dynamic> toMap() => Mapper.toMap(this);
  PublicUserViewCopyWith<PublicUserView> get copyWith => PublicUserViewCopyWith(this, $identity);
}

abstract class PublicUserViewCopyWith<$R> {
  factory PublicUserViewCopyWith(PublicUserView value, Then<PublicUserView, $R> then) = _PublicUserViewCopyWithImpl<$R>;
  $R call({String? id, String? name});
  $R apply(PublicUserView Function(PublicUserView) transform);
}

class _PublicUserViewCopyWithImpl<$R> extends BaseCopyWith<PublicUserView, $R> implements PublicUserViewCopyWith<$R> {
  _PublicUserViewCopyWithImpl(PublicUserView value, Then<PublicUserView, $R> then) : super(value, then);

  @override $R call({String? id, String? name}) => $then(PublicUserView(id: id ?? $value.id, name: name ?? $value.name));
}

class DefaultCompanyViewMapper extends BaseMapper<DefaultCompanyView> {
  DefaultCompanyViewMapper._();

  @override Function get decoder => decode;
  DefaultCompanyView decode(dynamic v) => checked(v, (Map<String, dynamic> map) => fromMap(map));
  DefaultCompanyView fromMap(Map<String, dynamic> map) => DefaultCompanyView(id: Mapper.i.$get(map, 'id'), member: Mapper.i.$get(map, 'member'));

  @override Function get encoder => (DefaultCompanyView v) => encode(v);
  dynamic encode(DefaultCompanyView v) => toMap(v);
  Map<String, dynamic> toMap(DefaultCompanyView d) => {'id': Mapper.i.$enc(d.id, 'id'), 'member': Mapper.i.$enc(d.member, 'member')};

  @override String stringify(DefaultCompanyView self) => 'DefaultCompanyView(id: ${Mapper.asString(self.id)}, member: ${Mapper.asString(self.member)})';
  @override int hash(DefaultCompanyView self) => Mapper.hash(self.id) ^ Mapper.hash(self.member);
  @override bool equals(DefaultCompanyView self, DefaultCompanyView other) => Mapper.isEqual(self.id, other.id) && Mapper.isEqual(self.member, other.member);

  @override Function get typeFactory => (f) => f<DefaultCompanyView>();
}

extension DefaultCompanyViewMapperExtension  on DefaultCompanyView {
  String toJson() => Mapper.toJson(this);
  Map<String, dynamic> toMap() => Mapper.toMap(this);
  DefaultCompanyViewCopyWith<DefaultCompanyView> get copyWith => DefaultCompanyViewCopyWith(this, $identity);
}

abstract class DefaultCompanyViewCopyWith<$R> {
  factory DefaultCompanyViewCopyWith(DefaultCompanyView value, Then<DefaultCompanyView, $R> then) = _DefaultCompanyViewCopyWithImpl<$R>;
  PublicUserViewCopyWith<$R> get member;
  $R call({String? id, PublicUserView? member});
  $R apply(DefaultCompanyView Function(DefaultCompanyView) transform);
}

class _DefaultCompanyViewCopyWithImpl<$R> extends BaseCopyWith<DefaultCompanyView, $R> implements DefaultCompanyViewCopyWith<$R> {
  _DefaultCompanyViewCopyWithImpl(DefaultCompanyView value, Then<DefaultCompanyView, $R> then) : super(value, then);

  @override PublicUserViewCopyWith<$R> get member => PublicUserViewCopyWith($value.member, (v) => call(member: v));
  @override $R call({String? id, PublicUserView? member}) => $then(DefaultCompanyView(id: id ?? $value.id, member: member ?? $value.member));
}


// === GENERATED ENUM MAPPERS AND EXTENSIONS ===




// === GENERATED UTILITY CODE ===

class Mapper {
  Mapper._();

  static MapperContainer i = MapperContainer(_mappers);

  static T fromValue<T>(dynamic value) => i.fromValue<T>(value);
  static T fromMap<T>(Map<String, dynamic> map) => i.fromMap<T>(map);
  static T fromIterable<T>(Iterable<dynamic> iterable) => i.fromIterable<T>(iterable);
  static T fromJson<T>(String json) => i.fromJson<T>(json);

  static dynamic toValue(dynamic value) => i.toValue(value);
  static Map<String, dynamic> toMap(dynamic object) => i.toMap(object);
  static Iterable<dynamic> toIterable(dynamic object) => i.toIterable(object);
  static String toJson(dynamic object) => i.toJson(object);

  static bool isEqual(dynamic value, Object? other) => i.isEqual(value, other);
  static int hash(dynamic value) => i.hash(value);
  static String asString(dynamic value) => i.asString(value);

  static void use<T>(BaseMapper<T> mapper) => i.use<T>(mapper);
  static BaseMapper<T>? unuse<T>() => i.unuse<T>();
  static void useAll(List<BaseMapper> mappers) => i.useAll(mappers);

  static BaseMapper<T>? get<T>([Type? type]) => i.get<T>(type);
  static List<BaseMapper> getAll() => i.getAll();
}

mixin Mappable implements MappableMixin {
  String toJson() => Mapper.toJson(this);
  Map<String, dynamic> toMap() => Mapper.toMap(this);

  @override
  String toString() {
    return _guard(() => Mapper.asString(this), super.toString);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (runtimeType == other.runtimeType &&
            _guard(() => Mapper.isEqual(this, other), () => super == other));
  }

  @override
  int get hashCode {
    return _guard(() => Mapper.hash(this), () => super.hashCode);
  }

  T _guard<T>(T Function() fn, T Function() fallback) {
    try {
      return fn();
    } on MapperException catch (e) {
      if (e.isUnsupportedOrUnallowed()) {
        return fallback();
      } else {
        rethrow;
      }
    }
  }
}
