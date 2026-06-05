# Carpeta test lista - Store Mood / SpazioCosmeticApp

Esta carpeta reemplaza la carpeta `test/` anterior.

Cambios principales:
- Ya no exige rutas rígidas como `lib/controllers/catalogo/checkout_controller.dart`.
- Busca archivos alternativos dentro de `lib/` cuando la lógica está integrada en Pages, Services o Controllers.
- Corrige la detección de conflictos Git: líneas decorativas como `// ========` ya no fallan.
- Mantiene la estructura de tests que pediste: helpers, unit/controllers, unit/models, widget y widget_test.dart.

Comando recomendado:

```bash
flutter test
```

Si querés coverage:

```bash
flutter test --coverage
```
