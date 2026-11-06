# DistriMax (proyecto legacy de práctica)

Sistema de gestión para una distribuidora mayorista, construido **a propósito** como un sistema legacy en .NET Framework 4.8: funciona bien, pero por dentro tiene deuda técnica catalogada (`// AP-XX` en el código) para practicar refactorización y migración a .NET moderno.

La especificación completa está en `docs/DistriMax_Especificacion_Tecnica.md`.

## Requisitos

- Windows con Visual Studio 2022 (workload **ASP.NET and web development** y el targeting pack de **.NET Framework 4.8**).
- SQL Server LocalDB (viene con Visual Studio) o SQL Server Express.
- SSMS o Azure Data Studio para correr los scripts.
- Internet en la primera compilación (restauración de NuGet) y para los CSS/JS del front, que cargan desde CDN.

## Paso a paso

1. **Base de datos.** Conéctate a `(localdb)\MSSQLLocalDB` y ejecuta los scripts de `Database/` en orden: `01` → `02` → `03` → `04` → `05`. El `99_Verificacion.sql` es opcional y sirve para confirmar que todo quedó consistente.
2. **Abrir la solución.** Abre `DistriMax.sln`. Visual Studio restaura los paquetes NuGet al compilar (si no, clic derecho en la solución → *Restore NuGet Packages*).
3. **Proyectos de inicio.** Clic derecho en la solución → *Configure Startup Projects…* → *Multiple startup projects* → `DistriMax.Api` y `DistriMax.Web` en **Start**. Pon la API primero en el orden.
4. **F5.** La API queda en `http://localhost:5301` y el front en `http://localhost:5300`.
5. **Ingresar** con `admin / admin123`.

Si usas SQL Express en lugar de LocalDB, cambia `Data Source=(localdb)\MSSQLLocalDB` por `Data Source=.\SQLEXPRESS` en **los dos** `Web.config` (sí, la cadena está duplicada; es parte de la deuda, AP-19).

Para probar que la API responde: `http://localhost:5301/api/general/ping`.

## Usuarios de prueba

| Usuario | Contraseña | Rol |
|---|---|---|
| admin | admin123 | Administrador |
| gerente | gerente123 | Gerencia |
| vendedor1 | vend123 | Vendedor |
| vendedor2 | vend123 | Vendedor |
| bodega | bodega123 | Bodeguero |
| cartera | cartera123 | Cartera |

## Estado actual

Listo: base de datos completa (tablas, 27 SPs, vistas y ~6 meses de datos simulados), seguridad (login con token, sesión, menú por rol), usuarios, clientes, proveedores, productos y el tablero de inicio.

Pendiente (próximas fases): inventario, compras, pedidos, facturación, cartera y reportes. Los SPs de esos módulos ya existen en la base de datos.

## Problemas comunes

- **"No fue posible conectar con el servidor de la API"**: la API no está corriendo. Revisa el paso 3.
- **Error 401 después de un rato**: el token de la API expiró (8 horas) y el front no lo maneja bien. Es el BUG-03 documentado; cierra sesión y vuelve a entrar.
- **Error de puertos**: si 5300/5301 están ocupados, cámbialos en *Propiedades del proyecto → Web* y actualiza `UrlApi` en el `Web.config` del front.
