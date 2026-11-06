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

