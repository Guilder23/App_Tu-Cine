import 'package:flutter/material.dart';
import 'package:peliculas/src/services/role_service.dart';

/// Widget que renderiza contenido basado en el rol del usuario
class RoleBasedWidget extends StatefulWidget {
  final Widget child;
  final UserRole requiredRole;
  final Widget? fallbackWidget;
  final Map<String, dynamic>? userData;

  const RoleBasedWidget({
    Key? key,
    required this.child,
    required this.requiredRole,
    this.fallbackWidget,
    this.userData,
  }) : super(key: key);

  @override
  State<RoleBasedWidget> createState() => _RoleBasedWidgetState();
}

class _RoleBasedWidgetState extends State<RoleBasedWidget> {
  bool _hasRequiredRole = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    try {
      // Si tenemos userData, usar el rol de ahí primero
      if (widget.userData != null) {
        final String? role =
            widget.userData!['role'] ?? widget.userData!['rol'];
        final userRole = UserRole.fromString(role);
        setState(() {
          _hasRequiredRole =
              _checkRolePermission(userRole, widget.requiredRole);
          _isLoading = false;
        });
        return;
      }

      // Si no tenemos userData, obtener el rol del servicio
      final currentRole = await RoleService.getCurrentUserRole();
      setState(() {
        _hasRequiredRole =
            _checkRolePermission(currentRole, widget.requiredRole);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasRequiredRole = false;
        _isLoading = false;
      });
    }
  }

  bool _checkRolePermission(UserRole userRole, UserRole requiredRole) {
    switch (requiredRole) {
      case UserRole.admin:
        return userRole == UserRole.admin;
      case UserRole.manager:
        return userRole == UserRole.admin || userRole == UserRole.manager;
      case UserRole.user:
        return true; // Todos los roles pueden ver contenido de usuario
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink(); // O un loading indicator si prefieres
    }

    if (_hasRequiredRole) {
      return widget.child;
    }

    return widget.fallbackWidget ?? const SizedBox.shrink();
  }
}

/// Widget simplificado para mostrar contenido solo a administradores
class AdminOnlyWidget extends StatelessWidget {
  final Widget child;
  final Widget? fallbackWidget;
  final Map<String, dynamic>? userData;

  const AdminOnlyWidget({
    Key? key,
    required this.child,
    this.fallbackWidget,
    this.userData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RoleBasedWidget(
      requiredRole: UserRole.admin,
      userData: userData,
      fallbackWidget: fallbackWidget,
      child: child,
    );
  }
}

/// Widget simplificado para mostrar contenido a admin y manager
class ManagerOnlyWidget extends StatelessWidget {
  final Widget child;
  final Widget? fallbackWidget;
  final Map<String, dynamic>? userData;

  const ManagerOnlyWidget({
    Key? key,
    required this.child,
    this.fallbackWidget,
    this.userData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RoleBasedWidget(
      requiredRole: UserRole.manager,
      userData: userData,
      fallbackWidget: fallbackWidget,
      child: child,
    );
  }
}

/// Función helper para verificar roles de manera síncrona con userData
class RoleChecker {
  static bool isAdmin(Map<String, dynamic>? userData) {
    if (userData == null) return false;
    final String? role = userData['role'] ?? userData['rol'];
    return role?.toLowerCase() == 'admin';
  }

  static bool isManager(Map<String, dynamic>? userData) {
    if (userData == null) return false;
    final String? role = userData['role'] ?? userData['rol'];
    return role?.toLowerCase() == 'manager';
  }

  static bool hasAdminPrivileges(Map<String, dynamic>? userData) {
    return isAdmin(userData) || isManager(userData);
  }

  static UserRole getUserRole(Map<String, dynamic>? userData) {
    if (userData == null) return UserRole.user;
    final String? role = userData['role'] ?? userData['rol'];
    return UserRole.fromString(role);
  }

  static String getRoleDisplayName(Map<String, dynamic>? userData) {
    final role = getUserRole(userData);
    switch (role) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.manager:
        return 'Manager';
      case UserRole.user:
        return 'Usuario';
    }
  }
}
